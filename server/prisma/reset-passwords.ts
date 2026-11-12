import { AuditOutcome, Prisma, PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import * as argon2 from 'argon2';

const resetAction = 'ALL_ACCOUNT_PASSWORDS_RESET';

export function readResetSettings(env: NodeJS.ProcessEnv) {
  const password = env.ACCOUNT_RESET_PASSWORD;
  const resetId = env.ACCOUNT_RESET_ID;
  if (
    !password ||
    !password.trim() ||
    password.length < 20 ||
    password.length > 32
  ) {
    throw new Error('ACCOUNT_RESET_PASSWORD must contain 20-32 characters.');
  }
  if (!resetId || !/^[A-Za-z0-9_-]{1,64}$/.test(resetId)) {
    throw new Error(
      'ACCOUNT_RESET_ID must contain 1-64 letters, digits, underscores or hyphens.',
    );
  }
  // Do not load .env or silently fall back to a developer's local DB_* settings.
  if (!env.DATABASE_URL) {
    throw new Error('An explicit DATABASE_URL is required for the bulk reset.');
  }
  return { password, resetId, databaseUrl: env.DATABASE_URL };
}

export async function resetAllPasswords(
  prisma: PrismaClient,
  settings: ReturnType<typeof readResetSettings>,
) {
  return prisma.$transaction(
    async (tx: Prisma.TransactionClient) => {
      // Serialize reset jobs; select a number instead of deserializing SQL void.
      await tx.$queryRaw`SELECT 1 AS locked FROM pg_advisory_xact_lock(143132, 1)`;
      const completed = await tx.auditLog.findFirst({
        where: {
          action: resetAction,
          entity_type: 'users',
          request_id: settings.resetId,
          outcome: AuditOutcome.SUCCESS,
        },
        select: { audit_log_id: true },
      });
      if (completed) {
        return { skipped: true, usersUpdated: 0, sessionsRevoked: 0 };
      }

      const users = await tx.user.findMany({
        select: { user_id: true },
        orderBy: { user_id: 'asc' },
      });
      if (users.length === 0) {
        throw new Error(
          'No users found; refusing to record a completed reset.',
        );
      }
      const modifiedAt = new Date();
      for (const user of users) {
        // Separate salts, sequential hashing to fit the Free host's memory.
        const passwordHash = await argon2.hash(settings.password);
        await tx.user.update({
          where: { user_id: user.user_id },
          data: { password_hash: passwordHash, modified_at: modifiedAt },
          select: { user_id: true },
        });
      }
      const sessions = await tx.userSession.deleteMany({});
      await tx.auditLog.create({
        data: {
          action: resetAction,
          entity_type: 'users',
          outcome: AuditOutcome.SUCCESS,
          request_id: settings.resetId,
          reason:
            'Operator requested a shared password reset for all accounts.',
          after_data: {
            users_updated: users.length,
            sessions_revoked: sessions.count,
          },
        },
        select: { audit_log_id: true },
      });
      return {
        skipped: false,
        usersUpdated: users.length,
        sessionsRevoked: sessions.count,
      };
    },
    { maxWait: 10_000, timeout: 300_000 },
  );
}

async function main() {
  const settings = readResetSettings(process.env);
  const prisma = new PrismaClient({
    adapter: new PrismaPg({ connectionString: settings.databaseUrl }),
  });
  try {
    const result = await resetAllPasswords(prisma, settings);
    console.log(
      result.skipped
        ? 'Password reset already completed for this ACCOUNT_RESET_ID; skipped.'
        : `Password reset completed: ${result.usersUpdated} accounts updated; ${result.sessionsRevoked} sessions revoked.`,
    );
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  main().catch(() => {
    // Raw adapter errors can include connection details. Never print secrets.
    console.error(
      'Bulk password reset failed. Check DATABASE_URL, ACCOUNT_RESET_PASSWORD (20-32 characters), ACCOUNT_RESET_ID, database availability, and applied migrations. No credentials are printed.',
    );
    process.exitCode = 1;
  });
}
