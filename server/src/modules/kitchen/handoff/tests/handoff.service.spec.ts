import {
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  Handoff,
  KitchenTicket,
  KitchenTicketStatus,
  Prisma,
} from '@prisma/client';
import { AssetsService } from '../../../assets/assets.service';
import { StorageService } from '../../../../shared/storage/storage.service';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { UsersRepository } from '../../../users/users.repository';
import { KitchenTicketRepository } from '../../kitchen-ticket/kitchen-ticket.repository';
import { HandoffRepository } from '../handoff.repository';
import { HandoffService } from '../handoff.service';
import { CreateHandoffDTO } from '../dto/create-handoff.dto';

describe('HandoffService', () => {
  const handoff: Handoff = {
    handoff_id: 'handoff',
    kitchen_ticket_id: 'ticket',
    actor_id: 'actor',
    img_keys: ['uploads/actor/00000000-0000-4000-8000-000000000001.png'],
    created_at: new Date('2026-11-03T04:00:00Z'),
  };
  const ticket: KitchenTicket = {
    kitchen_ticket_id: 'ticket',
    order_id: 'order',
    order_code: 'GC-00001',
    ticket_number: 'T-001',
    status: KitchenTicketStatus.READY,
    preparer_id: 'preparer',
    checker_id: 'checker',
    created_by_id: 'creator',
    acknowledged_at: null,
    preparation_started_at: null,
    ready_at: handoff.created_at,
    handed_over_at: null,
    cancelled_at: null,
    notes: null,
    created_at: handoff.created_at,
    modified_at: handoff.created_at,
  };
  const imageUrl = 'https://files.example.test/handoff.png?signature=test';
  const response = {
    handoff_id: handoff.handoff_id,
    kitchen_ticket_id: handoff.kitchen_ticket_id,
    actor_id: handoff.actor_id,
    created_at: handoff.created_at,
    img_urls: [imageUrl],
  };
  let repository: jest.Mocked<
    Pick<
      HandoffRepository,
      | 'create'
      | 'findOne'
      | 'findOneByKitchenTicket'
      | 'findManyByActor'
      | 'findAll'
    >
  >;
  let ticketRepository: jest.Mocked<Pick<KitchenTicketRepository, 'findOne'>>;
  let usersRepository: jest.Mocked<Pick<UsersRepository, 'findOne'>>;
  let assetsService: jest.Mocked<Pick<AssetsService, 'download'>>;
  let storage: jest.Mocked<Pick<StorageService, 'createDownloadUrl'>>;
  let service: HandoffService;
  let log: jest.SpyInstance;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    log = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repository = {
      create: jest.fn().mockResolvedValue(handoff),
      findOne: jest.fn().mockResolvedValue(handoff),
      findOneByKitchenTicket: jest.fn().mockResolvedValue(handoff),
      findManyByActor: jest
        .fn()
        .mockResolvedValue({ handoffs: [handoff], total: 21 }),
      findAll: jest.fn().mockResolvedValue({ handoffs: [handoff], total: 21 }),
    };
    ticketRepository = {
      findOne: jest.fn().mockResolvedValue(ticket),
    };
    usersRepository = {
      findOne: jest.fn().mockResolvedValue({ user_id: 'actor' }),
    };
    assetsService = {
      download: jest.fn().mockResolvedValue({
        key: handoff.img_keys[0],
        downloadUrl: 'https://files.example.test/handoff.png',
        expiresIn: 3600,
      }),
    };
    storage = {
      createDownloadUrl: jest.fn().mockResolvedValue(imageUrl),
    };
    service = new HandoffService(
      repository as unknown as HandoffRepository,
      ticketRepository as unknown as KitchenTicketRepository,
      usersRepository as unknown as UsersRepository,
      assetsService as unknown as AssetsService,
      storage as unknown as StorageService,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it('UT-HAND-001: returns a handoff by its ID', async () => {
    await expect(service.findOne('handoff')).resolves.toEqual(response);
    expect(repository.findOne).toHaveBeenCalledWith('handoff');
    expect(storage.createDownloadUrl).toHaveBeenCalledWith(handoff.img_keys[0]);
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
      response,
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
      handoffs: [response],
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
    await expect(service.findManyByActor('actor', 10, 5)).resolves.toEqual({
      handoffs: [response],
      total: 21,
    });
    expect(repository.findManyByActor).toHaveBeenCalledWith('actor', 10, 5);
  });

  it('UT-HAND-010: returns an empty history when no handoffs match the actor', async () => {
    repository.findManyByActor.mockResolvedValue({ handoffs: [], total: 0 });

    await expect(service.findManyByActor('missing', 0, 10)).resolves.toEqual({
      handoffs: [],
      total: 0,
    });
  });

  it.each([
    { method: 'findOne', run: () => service.findOne('handoff') },
    {
      method: 'findOneByKitchenTicket',
      run: () => service.findOneByKitchenTicket('ticket'),
    },
    {
      method: 'findManyByActor',
      run: () => service.findManyByActor('actor', 0, 10),
    },
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

  describe('create', () => {
    const dto: CreateHandoffDTO = {
      img_keys: [
        ...handoff.img_keys,
        'uploads/actor/00000000-0000-4000-8000-000000000002.jpg',
      ],
    };
    const savedHandoff: Handoff = { ...handoff, img_keys: dto.img_keys };

    beforeEach(() => {
      repository.findOneByKitchenTicket.mockResolvedValue(null);
      repository.create.mockResolvedValue(savedHandoff);
    });

    it('UT-HAND-014: validates every image and saves the original keys for a READY ticket', async () => {
      await expect(service.create('ticket', 'actor', dto)).resolves.toEqual({
        ...response,
        img_urls: [imageUrl, imageUrl],
      });

      expect(usersRepository.findOne).toHaveBeenCalledWith(
        'actor',
        true,
        undefined,
      );
      expect(assetsService.download.mock.calls).toEqual([
        ['actor', dto.img_keys[0]],
        ['actor', dto.img_keys[1]],
      ]);
      expect(repository.create).toHaveBeenCalledWith(
        'ticket',
        'actor',
        dto,
        undefined,
      );
      expect(log).toHaveBeenCalledWith(
        'Created handoff entry for ticket with handoff id handoff.',
      );
    });

    it('UT-HAND-015: forwards the transaction to database operations and not asset validation', async () => {
      const tx = {} as Prisma.TransactionClient;

      await service.create('ticket', 'actor', dto, tx);

      expect(ticketRepository.findOne).toHaveBeenCalledWith('ticket', tx);
      expect(usersRepository.findOne).toHaveBeenCalledWith('actor', true, tx);
      expect(repository.findOneByKitchenTicket).toHaveBeenCalledWith(
        'ticket',
        tx,
      );
      expect(repository.create).toHaveBeenCalledWith(
        'ticket',
        'actor',
        dto,
        tx,
      );
      expect(assetsService.download.mock.calls).toEqual([
        ['actor', dto.img_keys[0]],
        ['actor', dto.img_keys[1]],
      ]);
    });

    it('UT-HAND-016: rejects a missing ticket before looking up the actor or writing', async () => {
      ticketRepository.findOne.mockResolvedValue(null);

      await expect(
        service.create('missing', 'actor', dto),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'KITCHEN_TICKET_NOT_FOUND' },
      });
      expect(usersRepository.findOne).not.toHaveBeenCalled();
      expect(assetsService.download).not.toHaveBeenCalled();
      expect(repository.create).not.toHaveBeenCalled();
    });

    it('UT-HAND-017: rejects a missing or inactive actor before validating images or writing', async () => {
      usersRepository.findOne.mockResolvedValue(null);

      await expect(
        service.create('ticket', 'missing', dto),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'USER_NOT_FOUND' },
      });
      expect(usersRepository.findOne).toHaveBeenCalledWith(
        'missing',
        true,
        undefined,
      );
      expect(repository.findOneByKitchenTicket).not.toHaveBeenCalled();
      expect(assetsService.download).not.toHaveBeenCalled();
      expect(repository.create).not.toHaveBeenCalled();
    });

    it.each(
      Object.values(KitchenTicketStatus).filter(
        (status) => status !== KitchenTicketStatus.READY,
      ),
    )('UT-HAND-018: rejects a ticket with status %s', async (status) => {
      ticketRepository.findOne.mockResolvedValue({ ...ticket, status });

      await expect(
        service.create('ticket', 'actor', dto),
      ).rejects.toMatchObject({
        status: 409,
        response: { code: 'KITCHEN_TICKET_NOT_READY' },
      });
      expect(repository.findOneByKitchenTicket).not.toHaveBeenCalled();
      expect(assetsService.download).not.toHaveBeenCalled();
      expect(repository.create).not.toHaveBeenCalled();
    });

    it('UT-HAND-019: rejects an existing handoff before validating images or inserting', async () => {
      repository.findOneByKitchenTicket.mockResolvedValue(handoff);

      await expect(
        service.create('ticket', 'actor', dto),
      ).rejects.toMatchObject({
        status: 409,
        response: { code: 'KITCHEN_TICKET_HAS_EXISTING_HANDOFF' },
      });
      expect(assetsService.download).not.toHaveBeenCalled();
      expect(repository.create).not.toHaveBeenCalled();
    });

    it.each([
      {
        name: 'missing or unowned image',
        error: new NotFoundException('Asset not found'),
      },
      {
        name: 'unavailable storage',
        error: new ServiceUnavailableException('Asset storage is unavailable'),
      },
    ])(
      'UT-HAND-020: propagates $name errors without inserting',
      async ({ error }) => {
        assetsService.download.mockRejectedValueOnce(error);

        await expect(service.create('ticket', 'actor', dto)).rejects.toBe(
          error,
        );
        expect(repository.create).not.toHaveBeenCalled();
        expect(log).not.toHaveBeenCalled();
      },
    );

    it('UT-HAND-021: does not insert when a later image fails validation', async () => {
      const error = new NotFoundException('Second asset not found');
      assetsService.download
        .mockResolvedValueOnce({
          key: dto.img_keys[0],
          downloadUrl: 'https://files.example.test/first.png',
          expiresIn: 3600,
        })
        .mockRejectedValueOnce(error);

      await expect(service.create('ticket', 'actor', dto)).rejects.toBe(error);
      expect(assetsService.download).toHaveBeenCalledTimes(2);
      expect(repository.create).not.toHaveBeenCalled();
    });

    it.each([
      { dependency: 'ticket', writes: 0 },
      { dependency: 'user', writes: 0 },
      { dependency: 'duplicate', writes: 0 },
      { dependency: 'insert', writes: 1 },
    ] as const)(
      'UT-HAND-022: propagates $dependency failures without logging success',
      async ({ dependency, writes }) => {
        const error = new Error('Database unavailable');
        const mocks = {
          ticket: ticketRepository.findOne,
          user: usersRepository.findOne,
          duplicate: repository.findOneByKitchenTicket,
          insert: repository.create,
        };
        mocks[dependency].mockRejectedValue(error);

        await expect(service.create('ticket', 'actor', dto)).rejects.toBe(
          error,
        );
        expect(repository.create).toHaveBeenCalledTimes(writes);
        expect(log).not.toHaveBeenCalled();
      },
    );

    it('UT-HAND-023: preserves a database uniqueness conflict after the duplicate precheck passes', async () => {
      const error = new Prisma.PrismaClientKnownRequestError(
        'Duplicate ticket handoff',
        {
          code: 'P2002',
          clientVersion: '7',
        },
      );
      repository.create.mockRejectedValue(error);

      await expect(service.create('ticket', 'actor', dto)).rejects.toBe(error);
      expect(repository.findOneByKitchenTicket).toHaveBeenCalledWith(
        'ticket',
        undefined,
      );
      expect(repository.create).toHaveBeenCalledTimes(1);
      expect(log).not.toHaveBeenCalled();
    });
  });

  it('UT-HAND-024: returns signed URLs in image order without exposing or mutating stored keys', async () => {
    const keys = [
      ...handoff.img_keys,
      'uploads/actor/00000000-0000-4000-8000-000000000002.jpg',
    ];
    const storedHandoff = { ...handoff, img_keys: [...keys] };
    repository.findOne.mockResolvedValue(storedHandoff);
    const urls = [
      'https://files.example.test/first.png?signature=first',
      'https://files.example.test/second.jpg?signature=second',
    ];
    storage.createDownloadUrl
      .mockResolvedValueOnce(urls[0])
      .mockResolvedValueOnce(urls[1]);

    const result = await service.findOne('handoff');

    expect(result).toEqual({ ...response, img_urls: urls });
    expect(result).not.toHaveProperty('img_keys');
    expect(storage.createDownloadUrl.mock.calls).toEqual([
      [keys[0]],
      [keys[1]],
    ]);
    expect(storedHandoff).toEqual({ ...handoff, img_keys: keys });
  });

  it.each([
    { method: 'findOne', run: () => service.findOne('handoff') },
    {
      method: 'findOneByKitchenTicket',
      run: () => service.findOneByKitchenTicket('ticket'),
    },
    {
      method: 'findManyByActor',
      run: () => service.findManyByActor('actor', 0, 10),
    },
    { method: 'findAll', run: () => service.findAll(0, 10) },
  ] as const)(
    'UT-HAND-025: propagates URL signing failures from $method',
    async ({ run }) => {
      const error = new ServiceUnavailableException(
        'Image signing unavailable',
      );
      storage.createDownloadUrl.mockRejectedValue(error);

      await expect(run()).rejects.toBe(error);
    },
  );

  it('UT-HAND-026: returns an empty image URL array for a handoff without images', async () => {
    repository.findOne.mockResolvedValue({ ...handoff, img_keys: [] });

    await expect(service.findOne('handoff')).resolves.toEqual({
      ...response,
      img_urls: [],
    });
    expect(storage.createDownloadUrl).not.toHaveBeenCalled();
  });

  it('UT-HAND-027: rejects an unsupported actor-history offset before querying', async () => {
    await expect(
      service.findManyByActor('actor', 2_147_483_648, 5),
    ).rejects.toMatchObject({
      status: 400,
      response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
    });
    expect(repository.findManyByActor).not.toHaveBeenCalled();
    expect(storage.createDownloadUrl).not.toHaveBeenCalled();
  });

  it('UT-HAND-028: preserves the actor total when a history page is empty', async () => {
    repository.findManyByActor.mockResolvedValue({ handoffs: [], total: 21 });

    await expect(service.findManyByActor('actor', 25, 5)).resolves.toEqual({
      handoffs: [],
      total: 21,
    });
    expect(repository.findManyByActor).toHaveBeenCalledWith('actor', 25, 5);
    expect(storage.createDownloadUrl).not.toHaveBeenCalled();
  });

  it('UT-HAND-029: accepts the largest supported actor-history offset', async () => {
    await service.findManyByActor('actor', 2_147_483_647, 5);
    expect(repository.findManyByActor).toHaveBeenCalledWith(
      'actor',
      2_147_483_647,
      5,
    );
  });

  it('UT-HAND-030: filters actor rows and totals consistently with stable pagination', async () => {
    const prisma = {
      handoff: {
        findMany: jest.fn().mockResolvedValue([handoff]),
        count: jest.fn().mockResolvedValue(21),
      },
      $transaction: jest.fn((queries: Promise<unknown>[]) =>
        Promise.all(queries),
      ),
    };
    service = new HandoffService(
      new HandoffRepository(prisma as unknown as PrismaService),
      ticketRepository as unknown as KitchenTicketRepository,
      usersRepository as unknown as UsersRepository,
      assetsService as unknown as AssetsService,
      storage as unknown as StorageService,
    );

    await expect(service.findManyByActor('actor', 10, 5)).resolves.toEqual({
      handoffs: [response],
      total: 21,
    });
    expect(prisma.handoff.findMany).toHaveBeenCalledWith({
      where: { actor_id: 'actor' },
      skip: 10,
      take: 5,
      orderBy: [{ created_at: 'desc' }, { handoff_id: 'asc' }],
    });
    expect(prisma.handoff.count).toHaveBeenCalledWith({
      where: { actor_id: 'actor' },
    });
    expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Array), {
      isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
    });
  });
});
