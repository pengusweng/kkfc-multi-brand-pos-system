import { Logger } from '@nestjs/common';
import {
  KitchenTicket,
  KitchenTicketQcAttempt,
  KitchenTicketQcStatus,
  KitchenTicketStatus,
  Prisma,
  User,
  UserRole,
} from '@prisma/client';
import { UsersRepository } from '../../users/users.repository';
import { KitchenTicketRepository } from '../kitchen-ticket/kitchen-ticket.repository';
import { KitchenQcRepository } from './kitchen-qc.repository';
import { KitchenQcService } from './kitchen-qc.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';

describe('KitchenQcService', () => {
  const now = new Date('2026-11-01T04:00:00Z');
  const ticket: KitchenTicket = {
    kitchen_ticket_id: 'ticket',
    order_id: 'order',
    order_code: 'GC-00001',
    ticket_number: 'T-001',
    status: KitchenTicketStatus.FOR_CHECKING,
    preparer_id: null,
    checker_id: 'checker',
    created_by_id: 'creator',
    acknowledged_at: null,
    preparation_started_at: null,
    ready_at: null,
    handed_over_at: null,
    cancelled_at: null,
    notes: null,
    created_at: now,
    modified_at: now,
  };
  const user: Omit<User, 'password_hash'> = {
    user_id: 'checker',
    username: 'checker',
    first_name: 'Test',
    last_name: 'Checker',
    role: UserRole.KITCHEN_HEAD,
    is_active: true,
    created_at: now,
    modified_at: now,
  };
  const attempt: KitchenTicketQcAttempt = {
    qc_attempt_id: 'attempt',
    kitchen_ticket_id: ticket.kitchen_ticket_id,
    attempt_number: 1,
    checker_id: user.user_id,
    status: KitchenTicketQcStatus.IN_PROGRESS,
    started_at: now,
    completed_at: null,
  };
  let repository: jest.Mocked<
    Pick<
      KitchenQcRepository,
      | 'create'
      | 'findOneUID'
      | 'findOneLatest'
      | 'findAll'
      | 'findMany'
      | 'updateStatus'
    >
  >;
  let ticketRepository: jest.Mocked<Pick<KitchenTicketRepository, 'findOne'>>;
  let usersRepository: jest.Mocked<Pick<UsersRepository, 'findOne'>>;
  let service: KitchenQcService;
  let log: jest.SpyInstance;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    log = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repository = {
      create: jest.fn().mockResolvedValue(attempt),
      findOneUID: jest.fn().mockResolvedValue(attempt),
      findOneLatest: jest.fn().mockResolvedValue(null),
      findAll: jest
        .fn()
        .mockResolvedValue({ qcAttempts: [attempt], total: 21 }),
      findMany: jest.fn().mockResolvedValue([attempt]),
      updateStatus: jest.fn().mockResolvedValue({
        ...attempt,
        status: KitchenTicketQcStatus.PASSED,
        completed_at: now,
      }),
    };
    ticketRepository = {
      findOne: jest.fn().mockResolvedValue(ticket),
    };
    usersRepository = {
      findOne: jest.fn().mockResolvedValue(user),
    };
    service = new KitchenQcService(
      repository as unknown as KitchenQcRepository,
      ticketRepository as unknown as KitchenTicketRepository,
      usersRepository as unknown as UsersRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it.each(['pass', 'fail'] as const)(
    'UT-KQC-042: rejects an unassigned checker before the %s status update',
    async (action) => {
      ticketRepository.findOne.mockResolvedValue({
        ...ticket,
        status: KitchenTicketStatus.CHECKING,
      });
      const result =
        action === 'pass'
          ? service.passAttempt('other', 'attempt')
          : service.failAttempt('attempt', 'other');
      await expect(result).rejects.toMatchObject({
        status: 403,
        response: { code: 'UNAUTHORIZED_CHECKER' },
      });
      expect(repository.updateStatus).not.toHaveBeenCalled();
    },
  );

  it.each(['pass', 'fail'] as const)(
    'UT-KQC-043: forwards the caller transaction through %s validation and update',
    async (action) => {
      const tx = {} as Prisma.TransactionClient;
      ticketRepository.findOne.mockResolvedValue({
        ...ticket,
        status: KitchenTicketStatus.CHECKING,
      });
      if (action === 'pass')
        await service.passAttempt('checker', 'attempt', tx);
      else await service.failAttempt('attempt', 'checker', tx);
      expect(repository.findOneUID).toHaveBeenCalledWith('attempt', tx);
      expect(ticketRepository.findOne).toHaveBeenCalledWith('ticket', tx);
      expect(usersRepository.findOne).toHaveBeenCalledWith('checker', true, tx);
      expect(repository.updateStatus).toHaveBeenCalledWith(
        'attempt',
        action === 'pass'
          ? KitchenTicketQcStatus.PASSED
          : KitchenTicketQcStatus.FAILED,
        KitchenTicketQcStatus.IN_PROGRESS,
        tx,
      );
    },
  );

  describe('passAttempt', () => {
    beforeEach(() => {
      ticketRepository.findOne.mockResolvedValue({
        ...ticket,
        status: KitchenTicketStatus.CHECKING,
      });
    });

    it('UT-KQC-001: passes an in-progress attempt for a ticket being checked and returns the saved attempt', async () => {
      await expect(service.passAttempt('checker', 'attempt')).resolves.toEqual({
        ...attempt,
        status: KitchenTicketQcStatus.PASSED,
        completed_at: now,
      });

      expect(repository.findOneUID).toHaveBeenCalledWith('attempt', undefined);
      expect(ticketRepository.findOne).toHaveBeenCalledWith(
        'ticket',
        undefined,
      );
      expect(repository.updateStatus).toHaveBeenCalledTimes(1);
      expect(repository.updateStatus).toHaveBeenCalledWith(
        'attempt',
        KitchenTicketQcStatus.PASSED,
        KitchenTicketQcStatus.IN_PROGRESS,
        undefined,
      );
    });

    it('UT-KQC-002: rejects a missing attempt before looking up the ticket or updating', async () => {
      repository.findOneUID.mockResolvedValue(null);

      await expect(
        service.passAttempt('checker', 'missing'),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'KITCHEN_TICKET_QC_ATTEMPT_NOT_FOUND' },
      });
      expect(ticketRepository.findOne).not.toHaveBeenCalled();
      expect(repository.updateStatus).not.toHaveBeenCalled();
    });

    it('UT-KQC-003: rejects a missing kitchen ticket without updating the attempt', async () => {
      ticketRepository.findOne.mockResolvedValue(null);

      await expect(
        service.passAttempt('checker', 'attempt'),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'KITCHEN_TICKET_NOT_FOUND' },
      });
      expect(repository.updateStatus).not.toHaveBeenCalled();
    });

    it.each(
      Object.values(KitchenTicketStatus).filter(
        (status) => status !== KitchenTicketStatus.CHECKING,
      ),
    )(
      'UT-KQC-004: rejects approval when the ticket status is %s',
      async (status) => {
        ticketRepository.findOne.mockResolvedValue({ ...ticket, status });

        await expect(
          service.passAttempt('checker', 'attempt'),
        ).rejects.toMatchObject({
          status: 409,
          response: { code: 'UNABLE_TO_APPROVE_QC_ATTEMPT' },
        });
        expect(repository.updateStatus).not.toHaveBeenCalled();
      },
    );

    it.each([KitchenTicketQcStatus.PASSED, KitchenTicketQcStatus.FAILED])(
      'UT-KQC-005: rejects an attempt that is already %s',
      async (status) => {
        repository.findOneUID.mockResolvedValue({ ...attempt, status });

        await expect(
          service.passAttempt('checker', 'attempt'),
        ).rejects.toMatchObject({
          status: 409,
          response: {
            code: 'UNABLE_TO_APPROVE_QC_ATTEMPT',
            message: `Cannot approve kitchen QC. Kitchen QC attempt is already ${status}.`,
          },
        });
        expect(repository.updateStatus).not.toHaveBeenCalled();
      },
    );

    it('UT-KQC-006: propagates an attempt lookup failure without looking up the ticket or updating', async () => {
      const error = new Error('QC attempt lookup failed');
      repository.findOneUID.mockRejectedValue(error);

      await expect(service.passAttempt('checker', 'attempt')).rejects.toBe(
        error,
      );
      expect(ticketRepository.findOne).not.toHaveBeenCalled();
      expect(repository.updateStatus).not.toHaveBeenCalled();
    });

    it('UT-KQC-007: propagates a ticket lookup failure without updating the attempt', async () => {
      const error = new Error('Kitchen ticket lookup failed');
      ticketRepository.findOne.mockRejectedValue(error);

      await expect(service.passAttempt('checker', 'attempt')).rejects.toBe(
        error,
      );
      expect(repository.updateStatus).not.toHaveBeenCalled();
    });

    it('UT-KQC-008: propagates an update failure without logging that the attempt passed', async () => {
      const error = new Error('QC status update failed');
      repository.updateStatus.mockRejectedValue(error);

      await expect(service.passAttempt('checker', 'attempt')).rejects.toBe(
        error,
      );
      expect(log).not.toHaveBeenCalledWith('Passed attempt attempt');
    });
  });

  describe('failAttempt', () => {
    const failedAttempt = {
      ...attempt,
      status: KitchenTicketQcStatus.FAILED,
      completed_at: now,
    };

    beforeEach(() => {
      ticketRepository.findOne.mockResolvedValue({
        ...ticket,
        status: KitchenTicketStatus.CHECKING,
      });
      repository.updateStatus.mockResolvedValue(failedAttempt);
    });

    it('UT-KQC-009: fails an in-progress attempt for a ticket being checked and returns the saved attempt', async () => {
      await expect(service.failAttempt('attempt', 'checker')).resolves.toBe(
        failedAttempt,
      );

      expect(repository.findOneUID).toHaveBeenCalledWith('attempt', undefined);
      expect(ticketRepository.findOne).toHaveBeenCalledWith(
        'ticket',
        undefined,
      );
      expect(repository.updateStatus).toHaveBeenCalledTimes(1);
      expect(repository.updateStatus).toHaveBeenCalledWith(
        'attempt',
        KitchenTicketQcStatus.FAILED,
        KitchenTicketQcStatus.IN_PROGRESS,
        undefined,
      );
    });

    it('UT-KQC-010: rejects a missing attempt before looking up the ticket or updating', async () => {
      repository.findOneUID.mockResolvedValue(null);

      await expect(
        service.failAttempt('missing', 'checker'),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'KITCHEN_TICKET_QC_ATTEMPT_NOT_FOUND' },
      });
      expect(ticketRepository.findOne).not.toHaveBeenCalled();
      expect(repository.updateStatus).not.toHaveBeenCalled();
    });

    it('UT-KQC-011: rejects a missing kitchen ticket without updating the attempt', async () => {
      ticketRepository.findOne.mockResolvedValue(null);

      await expect(
        service.failAttempt('attempt', 'checker'),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'KITCHEN_TICKET_NOT_FOUND' },
      });
      expect(repository.updateStatus).not.toHaveBeenCalled();
    });

    it.each(
      Object.values(KitchenTicketStatus).filter(
        (status) => status !== KitchenTicketStatus.CHECKING,
      ),
    )(
      'UT-KQC-012: rejects failing an attempt when the ticket status is %s',
      async (status) => {
        ticketRepository.findOne.mockResolvedValue({ ...ticket, status });

        await expect(
          service.failAttempt('attempt', 'checker'),
        ).rejects.toMatchObject({
          status: 409,
          response: {
            code: 'UNABLE_TO_REJECT_QC_ATTEMPT',
            message:
              'Cannot reject kitchen QC attempt. Kitchen ticket is not for checking.',
          },
        });
        expect(repository.updateStatus).not.toHaveBeenCalled();
      },
    );

    it.each([KitchenTicketQcStatus.PASSED, KitchenTicketQcStatus.FAILED])(
      'UT-KQC-013: rejects an attempt that is already %s',
      async (status) => {
        repository.findOneUID.mockResolvedValue({ ...attempt, status });

        await expect(
          service.failAttempt('attempt', 'checker'),
        ).rejects.toMatchObject({
          status: 409,
          response: {
            code: 'UNABLE_TO_REJECT_QC_ATTEMPT',
            message: `Cannot reject kitchen QC. Kitchen QC attempt is already ${status}.`,
          },
        });
        expect(repository.updateStatus).not.toHaveBeenCalled();
      },
    );

    it('UT-KQC-014: propagates an attempt lookup failure without looking up the ticket or updating', async () => {
      const error = new Error('QC attempt lookup failed');
      repository.findOneUID.mockRejectedValue(error);

      await expect(service.failAttempt('attempt', 'checker')).rejects.toBe(
        error,
      );
      expect(ticketRepository.findOne).not.toHaveBeenCalled();
      expect(repository.updateStatus).not.toHaveBeenCalled();
    });

    it('UT-KQC-015: propagates a ticket lookup failure without updating the attempt', async () => {
      const error = new Error('Kitchen ticket lookup failed');
      ticketRepository.findOne.mockRejectedValue(error);

      await expect(service.failAttempt('attempt', 'checker')).rejects.toBe(
        error,
      );
      expect(repository.updateStatus).not.toHaveBeenCalled();
    });

    it('UT-KQC-016: propagates an update failure without logging that the attempt failed QC', async () => {
      const error = new Error('QC status update failed');
      repository.updateStatus.mockRejectedValue(error);

      await expect(service.failAttempt('attempt', 'checker')).rejects.toBe(
        error,
      );
      expect(log).not.toHaveBeenCalledWith('Failed attempt attempt');
    });
  });

  describe('findAll', () => {
    it('UT-KQC-017: forwards the pagination offset and limit and returns the attempts and total', async () => {
      await expect(service.findAll(10, 5)).resolves.toEqual({
        qcAttempts: [attempt],
        total: 21,
      });
      expect(repository.findAll).toHaveBeenCalledWith(10, 5);
    });

    it('UT-KQC-018: preserves the total when the requested page is empty', async () => {
      repository.findAll.mockResolvedValue({ qcAttempts: [], total: 21 });

      await expect(service.findAll(25, 5)).resolves.toEqual({
        qcAttempts: [],
        total: 21,
      });
    });

    it('UT-KQC-019: accepts the largest supported pagination offset', async () => {
      await service.findAll(2_147_483_647, 5);

      expect(repository.findAll).toHaveBeenCalledWith(2_147_483_647, 5);
    });

    it('UT-KQC-020: rejects an unsupported pagination offset before querying the repository', async () => {
      await expect(service.findAll(2_147_483_648, 5)).rejects.toMatchObject({
        status: 400,
        response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
      });
      expect(repository.findAll).not.toHaveBeenCalled();
    });
  });

  describe('findMany', () => {
    it('UT-KQC-021: validates the kitchen ticket and returns its QC attempts', async () => {
      await expect(service.findMany('ticket')).resolves.toEqual([attempt]);

      expect(ticketRepository.findOne).toHaveBeenCalledWith('ticket');
      expect(repository.findMany).toHaveBeenCalledWith('ticket');
    });

    it('UT-KQC-022: returns an empty list when the kitchen ticket has no attempts', async () => {
      repository.findMany.mockResolvedValue([]);

      await expect(service.findMany('ticket')).resolves.toEqual([]);
    });

    it('UT-KQC-023: rejects a missing kitchen ticket before querying its attempts', async () => {
      ticketRepository.findOne.mockResolvedValue(null);

      await expect(service.findMany('ticket')).rejects.toMatchObject({
        status: 404,
        response: { code: 'KITCHEN_TICKET_NOT_FOUND' },
      });
      expect(repository.findMany).not.toHaveBeenCalled();
    });
  });

  describe('findManyByChecker', () => {
    let client: {
      kitchenTicketQcAttempt: { findMany: jest.Mock; count: jest.Mock };
      $transaction: jest.Mock;
    };

    beforeEach(() => {
      client = {
        kitchenTicketQcAttempt: {
          findMany: jest.fn().mockResolvedValue([attempt]),
          count: jest.fn().mockResolvedValue(21),
        },
        $transaction: jest.fn((queries: Promise<unknown>[]) =>
          Promise.all(queries),
        ),
      };
      service = new KitchenQcService(
        new KitchenQcRepository(client as unknown as PrismaService),
        ticketRepository as unknown as KitchenTicketRepository,
        usersRepository as unknown as UsersRepository,
      );
    });

    it('UT-KQC-024: queries only IN_PROGRESS attempts for the supplied checker by default', async () => {
      await expect(service.findManyByChecker('checker')).resolves.toEqual({
        qcAttempts: [attempt],
        total: 1,
      });
      expect(client.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith({
        where: {
          checker_id: 'checker',
          status: KitchenTicketQcStatus.IN_PROGRESS,
        },
        orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
      });
      expect(client.kitchenTicketQcAttempt.count).not.toHaveBeenCalled();
      expect(client.$transaction).not.toHaveBeenCalled();
    });

    it('UT-KQC-025: paginates all statuses and counts only the supplied checker when activeOnly is false', async () => {
      const completed = { ...attempt, status: KitchenTicketQcStatus.PASSED };
      client.kitchenTicketQcAttempt.findMany.mockResolvedValue([
        attempt,
        completed,
      ]);

      await expect(
        service.findManyByChecker('checker', false, 10, 5),
      ).resolves.toEqual({ qcAttempts: [attempt, completed], total: 21 });
      expect(client.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith({
        where: { checker_id: 'checker', status: undefined },
        skip: 10,
        take: 5,
        orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
      });
      expect(client.kitchenTicketQcAttempt.count).toHaveBeenCalledWith({
        where: { checker_id: 'checker', status: undefined },
      });
      expect(client.$transaction).toHaveBeenCalledWith(expect.any(Array), {
        isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
      });
    });

    it('UT-KQC-026: returns an empty list when the checker has no matching attempts', async () => {
      client.kitchenTicketQcAttempt.findMany.mockResolvedValue([]);

      await expect(service.findManyByChecker('checker')).resolves.toEqual({
        qcAttempts: [],
        total: 0,
      });
    });

    it('UT-KQC-027: uses the supplied transaction client instead of the default client', async () => {
      const transaction = {
        kitchenTicketQcAttempt: {
          findMany: jest.fn().mockResolvedValue([attempt]),
        },
      };

      await expect(
        service.findManyByChecker(
          'checker',
          true,
          0,
          10,
          transaction as unknown as Prisma.TransactionClient,
        ),
      ).resolves.toEqual({ qcAttempts: [attempt], total: 1 });
      expect(transaction.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith({
        where: {
          checker_id: 'checker',
          status: KitchenTicketQcStatus.IN_PROGRESS,
        },
        orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
      });
      expect(client.kitchenTicketQcAttempt.findMany).not.toHaveBeenCalled();
    });

    it('UT-KQC-028: defaults history pagination to offset 0 and limit 10', async () => {
      await service.findManyByChecker('checker', false);

      expect(client.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ skip: 0, take: 10 }),
      );
    });

    it('UT-KQC-029: preserves the checker total when a history page is empty', async () => {
      client.kitchenTicketQcAttempt.findMany.mockResolvedValue([]);

      await expect(
        service.findManyByChecker('checker', false, 25, 5),
      ).resolves.toEqual({ qcAttempts: [], total: 21 });
    });

    it('UT-KQC-030: rejects an unsupported history offset before querying the database', async () => {
      await expect(
        service.findManyByChecker('checker', false, 2_147_483_648, 5),
      ).rejects.toMatchObject({
        status: 400,
        response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
      });
      expect(client.kitchenTicketQcAttempt.findMany).not.toHaveBeenCalled();
      expect(client.kitchenTicketQcAttempt.count).not.toHaveBeenCalled();
    });

    it('UT-KQC-031: ignores pagination arguments for active-only attempts', async () => {
      await expect(
        service.findManyByChecker('checker', true, 2_147_483_648, 1),
      ).resolves.toEqual({ qcAttempts: [attempt], total: 1 });

      expect(client.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith({
        where: {
          checker_id: 'checker',
          status: KitchenTicketQcStatus.IN_PROGRESS,
        },
        orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
      });
      expect(client.kitchenTicketQcAttempt.count).not.toHaveBeenCalled();
    });

    it('UT-KQC-032: queries and counts history using an existing transaction client', async () => {
      const transaction = {
        kitchenTicketQcAttempt: {
          findMany: jest.fn().mockResolvedValue([attempt]),
          count: jest.fn().mockResolvedValue(21),
        },
      };

      await expect(
        service.findManyByChecker(
          'checker',
          false,
          10,
          5,
          transaction as unknown as Prisma.TransactionClient,
        ),
      ).resolves.toEqual({ qcAttempts: [attempt], total: 21 });
      expect(transaction.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith({
        where: { checker_id: 'checker', status: undefined },
        skip: 10,
        take: 5,
        orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
      });
      expect(transaction.kitchenTicketQcAttempt.count).toHaveBeenCalledWith({
        where: { checker_id: 'checker', status: undefined },
      });
      expect(client.kitchenTicketQcAttempt.findMany).not.toHaveBeenCalled();
      expect(client.kitchenTicketQcAttempt.count).not.toHaveBeenCalled();
      expect(client.$transaction).not.toHaveBeenCalled();
    });
  });

  it('UT-KQC-033: creates attempt 1 when the ticket has no previous QC attempt', async () => {
    await expect(service.create('checker', 'ticket')).resolves.toEqual(attempt);

    expect(ticketRepository.findOne).toHaveBeenCalledWith('ticket', undefined);
    expect(usersRepository.findOne).toHaveBeenCalledWith(
      'checker',
      true,
      undefined,
    );
    expect(repository.findOneLatest).toHaveBeenCalledWith('ticket', undefined);
    expect(repository.create).toHaveBeenCalledTimes(1);
    expect(repository.create).toHaveBeenCalledWith(
      'checker',
      'ticket',
      1,
      undefined,
    );
  });

  it.each([1, 4])(
    'UT-KQC-034: creates attempt number %i + 1 after the latest attempt FAILED',
    async (latestNumber) => {
      repository.findOneLatest.mockResolvedValue({
        ...attempt,
        status: KitchenTicketQcStatus.FAILED,
        attempt_number: latestNumber,
        completed_at: now,
      });
      const created = { ...attempt, attempt_number: latestNumber + 1 };
      repository.create.mockResolvedValue(created);

      await expect(service.create('checker', 'ticket')).resolves.toEqual(
        created,
      );
      expect(repository.create).toHaveBeenCalledTimes(1);
      expect(repository.create).toHaveBeenCalledWith(
        'checker',
        'ticket',
        latestNumber + 1,
        undefined,
      );
    },
  );

  it.each([KitchenTicketQcStatus.PASSED, KitchenTicketQcStatus.IN_PROGRESS])(
    'UT-KQC-035: rejects creation with a conflict when the latest attempt is %s',
    async (status) => {
      repository.findOneLatest.mockResolvedValue({ ...attempt, status });

      await expect(service.create('checker', 'ticket')).rejects.toMatchObject({
        status: 409,
        response: { code: 'CANNOT_CREATE_KITCHEN_QC_ATTEMPT' },
      });
      expect(repository.create).not.toHaveBeenCalled();
    },
  );

  it('UT-KQC-036: rejects a missing kitchen ticket without looking up the user or creating an attempt', async () => {
    ticketRepository.findOne.mockResolvedValue(null);

    await expect(service.create('checker', 'ticket')).rejects.toMatchObject({
      status: 404,
      response: { code: 'KITCHEN_TICKET_NOT_FOUND' },
    });
    expect(usersRepository.findOne).not.toHaveBeenCalled();
    expect(repository.findOneLatest).not.toHaveBeenCalled();
    expect(repository.create).not.toHaveBeenCalled();
  });

  it.each(
    Object.values(KitchenTicketStatus).filter(
      (status) => status !== KitchenTicketStatus.FOR_CHECKING,
    ),
  )('UT-KQC-037: rejects a ticket with status %s', async (status) => {
    ticketRepository.findOne.mockResolvedValue({ ...ticket, status });

    await expect(service.create('checker', 'ticket')).rejects.toMatchObject({
      status: 409,
      response: { code: 'KITCHEN_TICKET_INVALID_STATUS' },
    });
    expect(usersRepository.findOne).not.toHaveBeenCalled();
    expect(repository.findOneLatest).not.toHaveBeenCalled();
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('UT-KQC-038: rejects a missing user without looking up or creating a QC attempt', async () => {
    usersRepository.findOne.mockResolvedValue(null);

    await expect(service.create('checker', 'ticket')).rejects.toMatchObject({
      status: 404,
      response: { code: 'USER_NOT_FOUND' },
    });
    expect(repository.findOneLatest).not.toHaveBeenCalled();
    expect(repository.create).not.toHaveBeenCalled();
  });

  it.each([null, 'another-checker'])(
    'UT-KQC-039: rejects the caller when the assigned checker is %s',
    async (checkerId) => {
      ticketRepository.findOne.mockResolvedValue({
        ...ticket,
        checker_id: checkerId,
      });

      await expect(service.create('checker', 'ticket')).rejects.toMatchObject({
        status: 403,
        response: { code: 'INVALID_CHECKER_FOR_TICKET' },
      });
      expect(repository.findOneLatest).not.toHaveBeenCalled();
      expect(repository.create).not.toHaveBeenCalled();
    },
  );

  it('UT-KQC-040: propagates a latest-attempt lookup failure without creating an attempt', async () => {
    const error = new Error('QC attempt lookup failed');
    repository.findOneLatest.mockRejectedValue(error);

    await expect(service.create('checker', 'ticket')).rejects.toBe(error);
    expect(repository.create).not.toHaveBeenCalled();
  });

  it.each([
    { name: 'first attempt', latest: null },
    {
      name: 'retry',
      latest: { ...attempt, status: KitchenTicketQcStatus.FAILED },
    },
  ])(
    'UT-KQC-041: propagates a creation failure for a $name',
    async ({ latest }) => {
      repository.findOneLatest.mockResolvedValue(latest);
      const error = new Error('QC attempt creation failed');
      repository.create.mockRejectedValue(error);

      await expect(service.create('checker', 'ticket')).rejects.toBe(error);
      expect(repository.create).toHaveBeenCalledTimes(1);
    },
  );
});
