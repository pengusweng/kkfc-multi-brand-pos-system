import { Logger } from '@nestjs/common';
import {
  KitchenTicketQcStatus,
  KitchenTicketStatus,
  OrderItemQcRejection,
  Prisma,
  QcRejectionReason,
} from '@prisma/client';
import { CreateOrderItemQcRejectionDTO } from '../dto/create-order-item-qc-rejection.dto';
import { OrderItemQcRejectionRepository } from '../order-item-qc-rejection.repository';
import { OrderItemQcRejectionService } from '../order-item-qc-rejection.service';

describe('OrderItemQcRejectionService', () => {
  const rejection: OrderItemQcRejection = {
    rejection_id: 'rejection',
    qc_attempt_id: 'attempt',
    order_item_id: 'item',
    portion_number: 1,
    rejection_reason: QcRejectionReason.INCOMPLETE,
    description: 'Portion failed inspection.',
    rejected_at: new Date('2026-11-03T04:00:00Z'),
  };
  let repository: jest.Mocked<
    Pick<
      OrderItemQcRejectionRepository,
      | 'create'
      | 'findAttempt'
      | 'findOrderItem'
      | 'findOne'
      | 'findManyByAttemptId'
      | 'findManyByOrderItemId'
    >
  >;
  let service: OrderItemQcRejectionService;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repository = {
      create: jest.fn().mockResolvedValue(rejection),
      findAttempt: jest.fn().mockResolvedValue({
        qc_attempt_id: 'attempt',
        status: KitchenTicketQcStatus.IN_PROGRESS,
        kitchen_ticket: {
          order_id: 'order',
          status: KitchenTicketStatus.CHECKING,
        },
      }),
      findOrderItem: jest
        .fn()
        .mockResolvedValue({ order_id: 'order', quantity: 2 }),
      findOne: jest.fn().mockResolvedValue(rejection),
      findManyByAttemptId: jest.fn().mockResolvedValue([rejection]),
      findManyByOrderItemId: jest.fn().mockResolvedValue([rejection]),
    };
    service = new OrderItemQcRejectionService(
      repository as unknown as OrderItemQcRejectionRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  describe('create', () => {
    const dto: CreateOrderItemQcRejectionDTO = {
      portion_number: 1,
      rejection_reason: QcRejectionReason.INCOMPLETE,
      description: 'Portion failed inspection.',
    };

    it.each([1, 2])(
      'UT-QCR-001: creates a rejection for portion %s within the ticket quantity',
      async (portion) => {
        const input = { ...dto, portion_number: portion };

        await expect(service.create('attempt', 'item', input)).resolves.toEqual(
          rejection,
        );
        expect(repository.findAttempt).toHaveBeenCalledWith(
          'attempt',
          undefined,
        );
        expect(repository.findOrderItem).toHaveBeenCalledWith(
          'item',
          undefined,
        );
        expect(repository.create).toHaveBeenCalledWith(
          'attempt',
          'item',
          input,
          undefined,
        );
      },
    );

    it('UT-QCR-002: forwards the caller transaction to every lookup and write', async () => {
      const tx = {} as Prisma.TransactionClient;

      await service.create('attempt', 'item', dto, tx);

      expect(repository.findAttempt).toHaveBeenCalledWith('attempt', tx);
      expect(repository.findOrderItem).toHaveBeenCalledWith('item', tx);
      expect(repository.create).toHaveBeenCalledWith(
        'attempt',
        'item',
        dto,
        tx,
      );
    });

    it('UT-QCR-003: rejects a missing QC attempt before inserting', async () => {
      repository.findAttempt.mockResolvedValue(null);

      await expect(
        service.create('missing', 'item', dto),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'KITCHEN_TICKET_QC_ATTEMPT_NOT_FOUND' },
      });
      expect(repository.create).not.toHaveBeenCalled();
    });

    it('UT-QCR-004: rejects a missing order item before inserting', async () => {
      repository.findOrderItem.mockResolvedValue(null);

      await expect(
        service.create('attempt', 'missing', dto),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'ORDER_ITEM_NOT_FOUND' },
      });
      expect(repository.create).not.toHaveBeenCalled();
    });

    it.each([KitchenTicketQcStatus.PASSED, KitchenTicketQcStatus.FAILED])(
      'UT-QCR-005: rejects a completed %s attempt',
      async (status) => {
        repository.findAttempt.mockResolvedValue({
          qc_attempt_id: 'attempt',
          status,
          kitchen_ticket: {
            order_id: 'order',
            status: KitchenTicketStatus.CHECKING,
          },
        });

        await expect(
          service.create('attempt', 'item', dto),
        ).rejects.toMatchObject({ status: 409 });
        expect(repository.create).not.toHaveBeenCalled();
      },
    );

    it.each(
      Object.values(KitchenTicketStatus).filter(
        (status) => status !== KitchenTicketStatus.CHECKING,
      ),
    )('UT-QCR-006: rejects creation when the ticket is %s', async (status) => {
      repository.findAttempt.mockResolvedValue({
        qc_attempt_id: 'attempt',
        status: KitchenTicketQcStatus.IN_PROGRESS,
        kitchen_ticket: { order_id: 'order', status },
      });

      await expect(
        service.create('attempt', 'item', dto),
      ).rejects.toMatchObject({ status: 409 });
      expect(repository.create).not.toHaveBeenCalled();
    });

    it('UT-QCR-007: rejects an order item belonging to a different ticket order', async () => {
      repository.findOrderItem.mockResolvedValue({
        order_id: 'other-order',
        quantity: 2,
      });

      await expect(
        service.create('attempt', 'item', dto),
      ).rejects.toMatchObject({ status: 400 });
      expect(repository.create).not.toHaveBeenCalled();
    });

    it('UT-QCR-008: rejects a portion exceeding the order item quantity', async () => {
      await expect(
        service.create('attempt', 'item', { ...dto, portion_number: 3 }),
      ).rejects.toMatchObject({ status: 400 });
      expect(repository.create).not.toHaveBeenCalled();
    });

    it.each([
      { method: 'findAttempt', writes: 0 },
      { method: 'findOrderItem', writes: 0 },
      { method: 'create', writes: 1 },
    ] as const)(
      'UT-QCR-009: propagates $method failures',
      async ({ method, writes }) => {
        const error = new Error('Database unavailable');
        repository[method].mockRejectedValue(error);

        await expect(service.create('attempt', 'item', dto)).rejects.toBe(
          error,
        );
        expect(repository.create).toHaveBeenCalledTimes(writes);
      },
    );

    it('UT-QCR-010: preserves the database uniqueness error for an already rejected portion', async () => {
      const error = new Prisma.PrismaClientKnownRequestError(
        'Duplicate portion',
        {
          code: 'P2002',
          clientVersion: '7',
        },
      );
      repository.create.mockRejectedValue(error);

      await expect(service.create('attempt', 'item', dto)).rejects.toBe(error);
      expect(repository.create).toHaveBeenCalledTimes(1);
    });
  });

  it('UT-QCR-011: returns a rejection by its ID', async () => {
    await expect(service.findOne('rejection')).resolves.toEqual(rejection);
    expect(repository.findOne).toHaveBeenCalledWith('rejection');
  });

  it('UT-QCR-012: returns the standard not-found error for an unknown rejection', async () => {
    repository.findOne.mockResolvedValue(null);

    await expect(service.findOne('missing')).rejects.toMatchObject({
      status: 404,
      response: { code: 'ORDER_ITEM_QC_REJECTION_NOT_FOUND' },
    });
  });

  it.each([
    { method: 'findManyByAttemptId', id: 'attempt' },
    { method: 'findManyByOrderItemId', id: 'item' },
  ] as const)(
    'UT-QCR-013: $method returns matching rejections',
    async ({ method, id }) => {
      await expect(service[method](id)).resolves.toEqual([rejection]);
      expect(repository[method]).toHaveBeenCalledWith(id);
    },
  );

  it.each(['findManyByAttemptId', 'findManyByOrderItemId'] as const)(
    'UT-QCR-014: %s returns an empty array when nothing matches',
    async (method) => {
      repository[method].mockResolvedValue([]);
      await expect(service[method]('missing')).resolves.toEqual([]);
    },
  );

  it.each(['findOne', 'findManyByAttemptId', 'findManyByOrderItemId'] as const)(
    'UT-QCR-015: %s propagates repository failures',
    async (method) => {
      const error = new Error('Lookup failed');
      repository[method].mockRejectedValue(error);
      await expect(service[method]('id')).rejects.toBe(error);
    },
  );
});
