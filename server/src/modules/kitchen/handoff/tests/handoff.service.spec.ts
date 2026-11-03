import { Logger } from '@nestjs/common';
import { Handoff } from '@prisma/client';
import { UsersRepository } from '../../../users/users.repository';
import { KitchenTicketRepository } from '../../kitchen-ticket/kitchen-ticket.repository';
import { HandoffRepository } from '../handoff.repository';
import { HandoffService } from '../handoff.service';

describe('HandoffService retrievals', () => {
  const handoff: Handoff = {
    handoff_id: 'handoff',
    kitchen_ticket_id: 'ticket',
    actor_id: 'actor',
    img_keys: ['uploads/actor/image.png'],
    created_at: new Date('2026-11-03T04:00:00Z'),
  };
  let repository: jest.Mocked<
    Pick<
      HandoffRepository,
      'findOne' | 'findOneByKitchenTicket' | 'findManyByActor' | 'findAll'
    >
  >;
  let ticketRepository: jest.Mocked<Pick<KitchenTicketRepository, 'findOne'>>;
  let service: HandoffService;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repository = {
      findOne: jest.fn().mockResolvedValue(handoff),
      findOneByKitchenTicket: jest.fn().mockResolvedValue(handoff),
      findManyByActor: jest.fn().mockResolvedValue([handoff]),
      findAll: jest.fn().mockResolvedValue({ handoffs: [handoff], total: 21 }),
    };
    ticketRepository = {
      findOne: jest.fn().mockResolvedValue({ kitchen_ticket_id: 'ticket' }),
    };
    service = new HandoffService(
      repository as unknown as HandoffRepository,
      ticketRepository as unknown as KitchenTicketRepository,
      {} as UsersRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it('UT-HAND-001: returns a handoff by its ID', async () => {
    await expect(service.findOne('handoff')).resolves.toEqual(handoff);
    expect(repository.findOne).toHaveBeenCalledWith('handoff');
  });

  it('UT-HAND-002: rejects a missing handoff with the standard not-found code', async () => {
    repository.findOne.mockResolvedValue(null);

    await expect(service.findOne('missing')).rejects.toMatchObject({
      status: 404,
      response: { code: 'HANDOFF_NOT_FOUND' },
    });
  });

  it('UT-HAND-003: validates the ticket and returns its handoff', async () => {
    await expect(service.findOneByKitchenTicket('ticket')).resolves.toEqual(
      handoff,
    );
    expect(ticketRepository.findOne).toHaveBeenCalledWith('ticket');
    expect(repository.findOneByKitchenTicket).toHaveBeenCalledWith('ticket');
  });

  it('UT-HAND-004: rejects a missing ticket before querying its handoff', async () => {
    ticketRepository.findOne.mockResolvedValue(null);

    await expect(
      service.findOneByKitchenTicket('missing'),
    ).rejects.toMatchObject({
      status: 404,
      response: { code: 'KITCHEN_TICKET_NOT_FOUND' },
    });
    expect(repository.findOneByKitchenTicket).not.toHaveBeenCalled();
  });

  it('UT-HAND-005: rejects a ticket without a handoff', async () => {
    repository.findOneByKitchenTicket.mockResolvedValue(null);

    await expect(
      service.findOneByKitchenTicket('ticket'),
    ).rejects.toMatchObject({
      status: 404,
      response: { code: 'HANDOFF_NOT_FOUND' },
    });
  });

  it('UT-HAND-006: forwards pagination and returns handoffs with their total', async () => {
    await expect(service.findAll(10, 5)).resolves.toEqual({
      handoffs: [handoff],
      total: 21,
    });
    expect(repository.findAll).toHaveBeenCalledWith(10, 5);
  });

  it('UT-HAND-007: preserves the total when the requested page is empty', async () => {
    repository.findAll.mockResolvedValue({ handoffs: [], total: 21 });

    await expect(service.findAll(25, 5)).resolves.toEqual({
      handoffs: [],
      total: 21,
    });
  });

  it('UT-HAND-008: rejects an unsupported pagination offset before querying', async () => {
    await expect(service.findAll(2_147_483_648, 5)).rejects.toMatchObject({
      status: 400,
      response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
    });
    expect(repository.findAll).not.toHaveBeenCalled();
  });

  it('UT-HAND-009: returns an actor handoff history', async () => {
    await expect(service.findManyByActor('actor')).resolves.toEqual([handoff]);
    expect(repository.findManyByActor).toHaveBeenCalledWith('actor');
  });

  it('UT-HAND-010: returns an empty history when no handoffs match the actor', async () => {
    repository.findManyByActor.mockResolvedValue([]);

    await expect(service.findManyByActor('missing')).resolves.toEqual([]);
  });

  it.each([
    { method: 'findOne', run: () => service.findOne('handoff') },
    {
      method: 'findOneByKitchenTicket',
      run: () => service.findOneByKitchenTicket('ticket'),
    },
    { method: 'findManyByActor', run: () => service.findManyByActor('actor') },
    { method: 'findAll', run: () => service.findAll(0, 10) },
  ] as const)(
    'UT-HAND-011: propagates $method repository failures',
    async ({ method, run }) => {
      const error = new Error('Lookup failed');
      repository[method].mockRejectedValue(error);

      await expect(run()).rejects.toBe(error);
    },
  );

  it('UT-HAND-012: accepts the largest supported pagination offset', async () => {
    await service.findAll(2_147_483_647, 5);
    expect(repository.findAll).toHaveBeenCalledWith(2_147_483_647, 5);
  });

  it('UT-HAND-013: propagates ticket lookup failures before querying a handoff', async () => {
    const error = new Error('Ticket lookup failed');
    ticketRepository.findOne.mockRejectedValue(error);

    await expect(service.findOneByKitchenTicket('ticket')).rejects.toBe(error);
    expect(repository.findOneByKitchenTicket).not.toHaveBeenCalled();
  });
});
