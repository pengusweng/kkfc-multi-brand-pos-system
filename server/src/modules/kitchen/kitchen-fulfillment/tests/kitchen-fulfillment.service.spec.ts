import { ConflictException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { OrderChannel, Prisma } from '@prisma/client';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { OrdersService } from '../../../orders/orders/orders.service';
import { OrdersRepository } from '../../../orders/orders/orders.repository';
import { HandoffService } from '../../handoff/handoff.service';
import { KitchenTicketService } from '../../kitchen-ticket/kitchen-ticket.service';
import { KitchenQcService } from '../../kitchen-qc/kitchen-qc.service';
import { OrderItemQcRejectionService } from '../../order-item-qc-rejection/order-item-qc-rejection.service';
import { QcRejectionReason } from '@prisma/client';
import { KitchenFulfillmentService } from '../kitchen-fulfillment.service';

describe('KitchenFulfillmentService', () => {
  describe('rejectQcAttempt', () => {
    const tx = {} as Prisma.TransactionClient;
    const dto = {
      rejections: [
        {
          order_item_id: 'item',
          portion_number: 1,
          rejection_reason: Object.values(QcRejectionReason)[0],
          description: 'Needs rework',
        },
      ],
    };
    const rejection = { rejection_id: 'rejection' };
    const attempt = {
      qc_attempt_id: 'attempt',
      kitchen_ticket_id: 'ticket',
      status: 'FAILED',
    };
    const ticket = { kitchen_ticket_id: 'ticket', status: 'REWORKING' };
    let module: TestingModule;
    let service: KitchenFulfillmentService;
    let rejections: { create: jest.Mock };
    let qc: { failAttempt: jest.Mock };
    let tickets: { rework: jest.Mock; notifyChange: jest.Mock };

    beforeEach(async () => {
      rejections = { create: jest.fn().mockResolvedValue(rejection) };
      qc = { failAttempt: jest.fn().mockResolvedValue(attempt) };
      tickets = {
        rework: jest.fn().mockResolvedValue(ticket),
        notifyChange: jest.fn(),
      };
      const prisma = {
        $transaction: jest.fn(
          (work: (client: Prisma.TransactionClient) => Promise<unknown>) =>
            work(tx),
        ),
      };
      module = await Test.createTestingModule({
        providers: [KitchenFulfillmentService],
      })
        .useMocker((token) => {
          if (token === PrismaService) return prisma;
          if (token === KitchenQcService) return qc;
          if (token === KitchenTicketService) return tickets;
          if (token === OrderItemQcRejectionService) return rejections;
          return {};
        })
        .compile();
      service = module.get(KitchenFulfillmentService);
    });
    afterEach(async () => module.close());

    it('UT-KFUL-007: records rejections before failing QC and marking the ticket for rework in one transaction', async () => {
      await expect(
        service.rejectQcAttempt('attempt', 'checker', dto),
      ).resolves.toEqual({ attempt, ticket, rejections: [rejection] });
      expect(rejections.create).toHaveBeenCalledWith(
        'attempt',
        'item',
        {
          portion_number: 1,
          rejection_reason: dto.rejections[0].rejection_reason,
          description: 'Needs rework',
        },
        tx,
      );
      expect(qc.failAttempt).toHaveBeenCalledWith('attempt', 'checker', tx);
      expect(tickets.rework).toHaveBeenCalledWith('ticket', 'checker', tx);
      expect(rejections.create.mock.invocationCallOrder[0]).toBeLessThan(
        qc.failAttempt.mock.invocationCallOrder[0],
      );
      expect(qc.failAttempt.mock.invocationCallOrder[0]).toBeLessThan(
        tickets.rework.mock.invocationCallOrder[0],
      );
    });

    it('UT-KFUL-008: propagates a rejection write failure without changing QC or ticket status', async () => {
      const error = new Error('Rejection failed');
      rejections.create.mockRejectedValue(error);
      await expect(
        service.rejectQcAttempt('attempt', 'checker', dto),
      ).rejects.toBe(error);
      expect(qc.failAttempt).not.toHaveBeenCalled();
      expect(tickets.rework).not.toHaveBeenCalled();
    });
  });
  it.each(Object.values(OrderChannel))(
    'UT-KFUL-001: returns the final ticket state in the completed order after %s handover',
    async (orderChannel) => {
      const tx = {} as Prisma.TransactionClient;
      const ticket = {
        kitchen_ticket_id: 'ticket',
        order_id: 'order',
        status: 'READY',
        handed_over_at: null,
        modified_at: new Date('2026-11-03T04:00:00Z'),
      };
      const handedOverTicket = {
        ...ticket,
        status: 'HANDED_OVER',
        handed_over_at: new Date('2026-11-03T04:01:00Z'),
        modified_at: new Date('2026-11-03T04:01:00Z'),
      };
      const order = {
        order_id: 'order',
        order_channel: orderChannel,
        status: 'COMPLETED',
        kitchen_tickets_order: ticket,
      };
      const prisma = {
        $transaction: jest.fn(
          (work: (client: Prisma.TransactionClient) => Promise<unknown>) =>
            work(tx),
        ),
      };
      const tickets = {
        findOne: jest.fn().mockResolvedValue(ticket),
        handOver: jest.fn().mockResolvedValue(handedOverTicket),
        notifyChange: jest.fn(),
      };
      const orders = { complete: jest.fn().mockResolvedValue(order) };
      const handoffs = { create: jest.fn().mockResolvedValue({}) };
      const module = await Test.createTestingModule({
        providers: [KitchenFulfillmentService],
      })
        .useMocker((token) => {
          if (token === PrismaService) return prisma;
          if (token === KitchenTicketService) return tickets;
          if (token === OrdersService) return orders;
          if (token === HandoffService) return handoffs;
          return {};
        })
        .compile();

      try {
        const service = module.get(KitchenFulfillmentService);
        const result = await service.handOver('ticket', 'actor', {
          img_keys: ['uploads/handoff.png'],
        });

        expect(result).toEqual({
          order: { ...order, kitchen_tickets_order: handedOverTicket },
          handedOverTicket,
        });
        expect(orders.complete).toHaveBeenCalledWith('order', tx);
        expect(tickets.handOver).toHaveBeenCalledWith('ticket', tx);
      } finally {
        await module.close();
      }
    },
  );

  describe('cancel', () => {
    const dto = { cancellation_reason: 'Customer requested cancellation.' };
    const ticket = { kitchen_ticket_id: 'ticket', status: 'CANCELLED' };
    const order = {
      order_id: 'order',
      status: 'CANCELLED',
      cancelled_by_id: 'actor',
      cancellation_reason: dto.cancellation_reason,
      kitchen_tickets_order: ticket,
    };
    let orders: { cancel: jest.Mock };
    let tickets: { cancel: jest.Mock; notifyChange: jest.Mock };
    let repository: { transaction: jest.Mock; findByBrand: jest.Mock };
    const tx = {} as Prisma.TransactionClient;
    let module: TestingModule;
    let service: KitchenFulfillmentService;

    beforeEach(async () => {
      orders = { cancel: jest.fn().mockResolvedValue(order) };
      tickets = {
        cancel: jest.fn().mockResolvedValue(ticket),
        notifyChange: jest.fn(),
      };
      repository = {
        transaction: jest.fn(
          (work: (client: Prisma.TransactionClient) => Promise<unknown>) =>
            work(tx),
        ),
        findByBrand: jest.fn().mockResolvedValue({
          order_id: 'order',
          kitchen_tickets_order: { ...ticket, status: 'QUEUED' },
        }),
      };
      module = await Test.createTestingModule({
        providers: [KitchenFulfillmentService],
      })
        .useMocker((token) => {
          if (token === OrdersService) return orders;
          if (token === KitchenTicketService) return tickets;
          if (token === OrdersRepository) return repository;
          return {};
        })
        .compile();
      service = module.get(KitchenFulfillmentService);
    });

    afterEach(async () => module.close());

    it('UT-KFUL-002: cancels the order and ticket using the same transaction', async () => {
      await expect(
        service.cancel('brand', 'order', 'actor', dto),
      ).resolves.toEqual({ order, ticket });
      expect(orders.cancel).toHaveBeenCalledTimes(1);
      expect(orders.cancel).toHaveBeenCalledWith(
        'brand',
        'order',
        'actor',
        dto,
        tx,
      );
      expect(tickets.cancel).toHaveBeenCalledWith('ticket', tx);
      expect(repository.findByBrand).toHaveBeenCalledWith('brand', 'order', tx);
    });

    it('UT-KFUL-003: rejects a draft without a kitchen ticket before writing', async () => {
      repository.findByBrand.mockResolvedValue({
        order_id: 'order',
        kitchen_tickets_order: null,
      });

      await expect(
        service.cancel('brand', 'order', 'actor', dto),
      ).rejects.toMatchObject({
        response: { code: 'ORDER_HAS_NO_KITCHEN_TICKET' },
      });
      expect(tickets.cancel).not.toHaveBeenCalled();
      expect(orders.cancel).not.toHaveBeenCalled();
    });

    it('UT-KFUL-005: rejects a missing or wrong-brand order before writing', async () => {
      repository.findByBrand.mockResolvedValue(null);
      await expect(
        service.cancel('other-brand', 'order', 'actor', dto),
      ).rejects.toMatchObject({ status: 404 });
      expect(tickets.cancel).not.toHaveBeenCalled();
      expect(orders.cancel).not.toHaveBeenCalled();
    });

    it('UT-KFUL-006: preserves the order when ticket cancellation fails', async () => {
      const error = new ConflictException(
        'Ticket has already been handed over.',
      );
      tickets.cancel.mockRejectedValue(error);
      await expect(service.cancel('brand', 'order', 'actor', dto)).rejects.toBe(
        error,
      );
      expect(orders.cancel).not.toHaveBeenCalled();
    });

    it('UT-KFUL-004: propagates cancellation failures without reporting success', async () => {
      const error = new ConflictException(
        'Completed orders cannot be cancelled.',
      );
      orders.cancel.mockRejectedValue(error);

      await expect(service.cancel('brand', 'order', 'actor', dto)).rejects.toBe(
        error,
      );
      expect(orders.cancel).toHaveBeenCalledTimes(1);
    });
  });
});
