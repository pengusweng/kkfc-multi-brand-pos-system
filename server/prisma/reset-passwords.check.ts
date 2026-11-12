import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { Prisma, PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';
import { readResetSettings, resetAllPasswords } from './reset-passwords';

async function check() {
  const password = randomUUID().replaceAll('-', '').slice(0, 24);
  const env = {
    DATABASE_URL: 'postgresql://example.invalid/demo',
    ACCOUNT_RESET_PASSWORD: password,
    ACCOUNT_RESET_ID: 'check-reset-1',
  };
  for (const key of Object.keys(env)) {
    const missing: NodeJS.ProcessEnv = { ...env };
    delete missing[key];
    assert.throws(() => readResetSettings(missing));
  }
  for (const invalid of ['short', 'x'.repeat(33), ' '.repeat(24)]) {
    assert.throws(() =>
      readResetSettings({ ...env, ACCOUNT_RESET_PASSWORD: invalid }),
    );
  }
  assert.throws(() =>
    readResetSettings({ ...env, ACCOUNT_RESET_ID: 'invalid id' }),
  );
  const settings = readResetSettings(env);
  let state = {
    users: [
      { user_id: randomUUID(), password_hash: 'old-1', is_active: true },
      { user_id: randomUUID(), password_hash: 'old-2', is_active: false },
    ],
    sessions: 3,
    audits: [] as Prisma.AuditLogCreateInput[],
  };
  let failAudit = false;
  let lockCalls = 0;
  const database = {
    $transaction: async (
      callback: (tx: Prisma.TransactionClient) => Promise<unknown>,
      options: { timeout: number },
    ) => {
      assert.equal(options.timeout, 300_000);
      const pending = structuredClone(state);
      const tx = {
        $queryRaw: async (sql: TemplateStringsArray) => {
          assert.match(sql[0], /pg_advisory_xact_lock/);
          lockCalls++;
          return [{ locked: 1 }];
        },
        auditLog: {
          findFirst: async (args: Prisma.AuditLogFindFirstArgs) => {
            assert.equal(args.where?.action, 'ALL_ACCOUNT_PASSWORDS_RESET');
            return pending.audits.find(
              (audit) => audit.request_id === args.where?.request_id,
            );
          },
          create: async (args: Prisma.AuditLogCreateArgs) => {
            if (failAudit)
              throw new Error('Simulated audit persistence failure');
            pending.audits.push(args.data as Prisma.AuditLogCreateInput);
            return { audit_log_id: randomUUID() };
          },
        },
        user: {
          findMany: async (args: Prisma.UserFindManyArgs) => {
            assert.equal(args.where, undefined, 'Include inactive accounts');
            return pending.users.map(({ user_id }) => ({ user_id }));
          },
          update: async (args: Prisma.UserUpdateArgs) => {
            assert.deepEqual(Object.keys(args.data).sort(), [
              'modified_at',
              'password_hash',
            ]);
            const user = pending.users.find(
              (row) => row.user_id === args.where.user_id,
            )!;
            user.password_hash = args.data.password_hash as string;
            return { user_id: user.user_id };
          },
        },
        userSession: {
          deleteMany: async (args: Prisma.UserSessionDeleteManyArgs) => {
            assert.deepEqual(args, {});
            const count = pending.sessions;
            pending.sessions = 0;
            return { count };
          },
        },
      } as unknown as Prisma.TransactionClient;
      const result = await callback(tx);
      state = pending;
      return result;
    },
  } as unknown as PrismaClient;
  const before = structuredClone(state);
  failAudit = true;
  await assert.rejects(resetAllPasswords(database, settings), /Simulated/);
  assert.deepEqual(state, before, 'Failure must not commit partial results');

  failAudit = false;
  assert.deepEqual(await resetAllPasswords(database, settings), {
    skipped: false,
    usersUpdated: 2,
    sessionsRevoked: 3,
  });
  for (const user of state.users) {
    assert(await argon2.verify(user.password_hash, password));
    assert.equal(
      await argon2.verify(user.password_hash, 'old-password'),
      false,
    );
  }
  assert.notEqual(state.users[0].password_hash, state.users[1].password_hash);
  assert.equal(state.users[1].is_active, false);
  assert.equal(state.sessions, 0);
  assert.equal(state.audits.length, 1);
  assert.equal(JSON.stringify(state.audits).includes(password), false);
  assert.equal(JSON.stringify(state.audits).includes('$argon2'), false);

  state.sessions = 1;
  const updated = structuredClone(state);
  assert.deepEqual(await resetAllPasswords(database, settings), {
    skipped: true,
    usersUpdated: 0,
    sessionsRevoked: 0,
  });
  assert.deepEqual(state, updated, 'A restart must preserve subsequent logins');
  state.users = [];
  await assert.rejects(
    resetAllPasswords(database, { ...settings, resetId: 'empty-check' }),
    /No users found/,
  );
  assert.equal(state.audits.length, 1);
  assert.equal(lockCalls, 4);
  console.log(
    'Bulk reset checks passed: validation, active/inactive users, distinct Argon2 salts, session revocation, audit privacy, rollback model, repeat-ID skip, and empty-database refusal. No real database used.',
  );
}

check().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
