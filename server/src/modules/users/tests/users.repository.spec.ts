import { UserRole } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { UsersRepository } from '../users.repository';

describe('UsersRepository', () => {
  let prisma: {
    user: { findMany: jest.Mock; count: jest.Mock };
    $transaction: jest.Mock;
  };
  let repository: UsersRepository;

  beforeEach(() => {
    prisma = {
      user: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn(({ where }: { where: { is_active: boolean } }) =>
          Promise.resolve(where.is_active ? 4 : 2),
        ),
      },
      $transaction: jest.fn((queries: Promise<unknown>[]) =>
        Promise.all(queries),
      ),
    };
    repository = new UsersRepository(prisma as unknown as PrismaService);
  });

  it.each([
    { status: 'active', is_active: true },
    { status: 'inactive', is_active: false },
    { status: 'all', is_active: undefined },
  ] as const)(
    'UT-USER-028: filters by status=$status and counts both statuses',
    async ({ status, is_active }) => {
      await expect(repository.findAll(5, 10, { status })).resolves.toEqual({
        users: [],
        counts: { all: 6, active: 4, inactive: 2 },
      });

      expect(prisma.user.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { is_active }, skip: 5, take: 10 }),
      );
      expect(prisma.user.count).toHaveBeenCalledWith({
        where: { is_active: true },
      });
      expect(prisma.user.count).toHaveBeenCalledWith({
        where: { is_active: false },
      });
    },
  );

  it('UT-USER-029: requires every search term to match a username or name, case-insensitively', async () => {
    await repository.findAll(0, 10, { status: 'all', search: 'ana  rey' });

    const fieldsMatching = (term: string) => ({
      OR: ['username', 'first_name', 'last_name'].map((field) => ({
        [field]: { contains: term, mode: 'insensitive' },
      })),
    });
    const search = { AND: [fieldsMatching('ana'), fieldsMatching('rey')] };

    expect(prisma.user.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ...search, is_active: undefined } }),
    );
    // Counts honour the search but ignore the requested status.
    expect(prisma.user.count).toHaveBeenCalledWith({
      where: { ...search, is_active: true },
    });
    expect(prisma.user.count).toHaveBeenCalledWith({
      where: { ...search, is_active: false },
    });
  });

  it('UT-USER-030: filters the list and both status counts by role', async () => {
    await repository.findAll(0, 10, {
      status: 'active',
      role: UserRole.KITCHEN_STAFF,
    });

    expect(prisma.user.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { role: UserRole.KITCHEN_STAFF, is_active: true },
      }),
    );
    expect(prisma.user.count).toHaveBeenCalledWith({
      where: { role: UserRole.KITCHEN_STAFF, is_active: true },
    });
    expect(prisma.user.count).toHaveBeenCalledWith({
      where: { role: UserRole.KITCHEN_STAFF, is_active: false },
    });
  });
});
