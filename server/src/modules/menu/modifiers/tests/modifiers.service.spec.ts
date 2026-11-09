import { Test } from '@nestjs/testing';
import { Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AppModule } from '../../../../app.module';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { StorageService } from '../../../../shared/storage/storage.service';
import { ModifiersController } from '../modifiers.controller';
import { ModifiersRepository } from '../modifiers.repository';
import { ModifiersService } from '../modifiers.service';
import { FindAllModifiersDTO } from '../dto/find-all-modifiers.dto';

describe('ModifiersService', () => {
  it('UT-MOD-001: resolves the service, repository, and controller through the application module', async () => {
    const module = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue({})
      .overrideProvider(StorageService)
      .useValue({})
      .compile();

    expect(module.get(ModifiersService)).toBeInstanceOf(ModifiersService);
    expect(module.get(ModifiersRepository)).toBeInstanceOf(ModifiersRepository);
    expect(module.get(ModifiersController)).toBeInstanceOf(ModifiersController);

    await module.close();
  });
});

describe('ModifiersService operations', () => {
  const modifierId = 'f0e05342-1288-4d30-8eb0-5f4273785475';
  const modifier = { modifier_id: modifierId, code: 'EXTRA', is_active: true };
  let repository: {
    createModifier: jest.Mock;
    findOneModifierByUID: jest.Mock;
    findOneModifierByCode: jest.Mock;
    findAll: jest.Mock;
    updateModifier: jest.Mock;
    reactivateModifier: jest.Mock;
    deleteModifier: jest.Mock;
  };
  let service: ModifiersService;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repository = {
      createModifier: jest.fn().mockResolvedValue(modifier),
      findOneModifierByUID: jest.fn().mockResolvedValue(modifier),
      findOneModifierByCode: jest.fn().mockResolvedValue(modifier),
      findAll: jest
        .fn()
        .mockResolvedValue({ modifiers: [modifier], total: 21 }),
      updateModifier: jest
        .fn()
        .mockResolvedValue({ ...modifier, name: 'Updated' }),
      reactivateModifier: jest.fn().mockResolvedValue(modifier),
      deleteModifier: jest
        .fn()
        .mockResolvedValue({ ...modifier, is_active: false }),
    };
    service = new ModifiersService(
      repository as unknown as ModifiersRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it('UT-MOD-002: creates a modifier', async () => {
    const dto = { code: 'EXTRA', name: 'Extra' };
    await expect(service.create(dto)).resolves.toEqual(modifier);
    expect(repository.createModifier).toHaveBeenCalledWith(dto);
  });

  it.each([
    {
      identifier: modifierId,
      method: 'findOneModifierByUID',
      value: modifierId,
      activeOnly: true,
    },
    {
      identifier: 'EXTRA',
      method: 'findOneModifierByCode',
      value: 'EXTRA',
      activeOnly: true,
    },
    {
      identifier: { modifier_id: 'explicit-id' },
      method: 'findOneModifierByUID',
      value: 'explicit-id',
      activeOnly: false,
    },
    {
      identifier: modifierId,
      method: 'findOneModifierByUID',
      value: modifierId,
      activeOnly: false,
    },
    {
      identifier: 'EXTRA',
      method: 'findOneModifierByCode',
      value: 'EXTRA',
      activeOnly: false,
    },
  ] as const)(
    'UT-MOD-005: finds $value using $method with activeOnly=$activeOnly',
    async ({ identifier, method, value, activeOnly }) => {
      await expect(service.findOne(identifier, activeOnly)).resolves.toEqual(
        modifier,
      );
      expect(repository[method]).toHaveBeenCalledWith(value, activeOnly);
      expect(
        repository.findOneModifierByUID.mock.calls.length +
          repository.findOneModifierByCode.mock.calls.length,
      ).toBe(1);
    },
  );

  it.each([modifierId, 'MISSING'])(
    'UT-MOD-006: rejects a missing modifier identified by %s',
    async (identifier) => {
      repository.findOneModifierByUID.mockResolvedValue(null);
      repository.findOneModifierByCode.mockResolvedValue(null);
      await expect(service.findOne(identifier)).rejects.toMatchObject({
        status: 404,
        response: { code: 'MODIFIER_NOT_FOUND' },
      });
    },
  );

  it.each([true, false])(
    'UT-MOD-009: paginates modifiers with activeOnly=%s',
    async (activeOnly) => {
      await expect(
        service.findAll({ page: 2, limit: 10, activeOnly }),
      ).resolves.toEqual({
        data: [modifier],
        meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
      });
      expect(repository.findAll).toHaveBeenCalledWith(10, 10, activeOnly);
    },
  );

  it('UT-MOD-010: returns empty pagination results using the default query', async () => {
    repository.findAll.mockResolvedValue({ modifiers: [], total: 0 });
    await expect(service.findAll(new FindAllModifiersDTO())).resolves.toEqual({
      data: [],
      meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
    });
    expect(repository.findAll).toHaveBeenCalledWith(0, 10, true);
  });

  it('UT-MOD-011: rejects pagination overflow before querying', async () => {
    await expect(
      service.findAll({ page: 2_147_483_647, limit: 2, activeOnly: true }),
    ).rejects.toMatchObject({
      status: 400,
      response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
    });
    expect(repository.findAll).not.toHaveBeenCalled();
  });

  it('UT-MOD-012: updates an existing modifier', async () => {
    const dto = { name: 'Updated' };
    await expect(service.update(modifierId, dto)).resolves.toEqual({
      ...modifier,
      name: 'Updated',
    });
    expect(repository.findOneModifierByUID).toHaveBeenCalledWith(modifierId);
    expect(repository.updateModifier).toHaveBeenCalledWith(modifierId, dto);
  });

  it('UT-MOD-015: reactivates an inactive modifier', async () => {
    repository.findOneModifierByUID.mockResolvedValue({
      ...modifier,
      is_active: false,
    });
    await expect(service.reactivate(modifierId)).resolves.toEqual(modifier);
    expect(repository.findOneModifierByUID).toHaveBeenCalledWith(
      modifierId,
      false,
    );
    expect(repository.reactivateModifier).toHaveBeenCalledWith(modifierId);
  });

  it('UT-MOD-016: rejects reactivating an already-active modifier', async () => {
    await expect(service.reactivate(modifierId)).rejects.toMatchObject({
      status: 409,
      response: { code: 'MODIFIER_ALREADY_ACTIVE' },
    });
    expect(repository.reactivateModifier).not.toHaveBeenCalled();
  });

  it('UT-MOD-017: soft-deletes an active modifier', async () => {
    await expect(service.delete(modifierId)).resolves.toEqual({
      ...modifier,
      is_active: false,
    });
    expect(repository.findOneModifierByUID).toHaveBeenCalledWith(modifierId);
    expect(repository.deleteModifier).toHaveBeenCalledWith(modifierId);
  });

  const mutations = [
    {
      name: 'updateModifier',
      run: () => service.update(modifierId, { name: 'Updated' }),
    },
    { name: 'reactivateModifier', run: () => service.reactivate(modifierId) },
    { name: 'deleteModifier', run: () => service.delete(modifierId) },
  ] as const;

  it.each(mutations)(
    'UT-MOD-018: $name rejects missing modifiers without writing',
    async ({ run }) => {
      repository.findOneModifierByUID.mockResolvedValue(null);
      await expect(run()).rejects.toMatchObject({
        status: 404,
        response: { code: 'MODIFIER_NOT_FOUND' },
      });
      expect(repository.updateModifier).not.toHaveBeenCalled();
      expect(repository.reactivateModifier).not.toHaveBeenCalled();
      expect(repository.deleteModifier).not.toHaveBeenCalled();
    },
  );

  it.each(mutations)(
    'UT-MOD-019: $name preserves repository failures',
    async ({ name, run }) => {
      repository.findOneModifierByUID.mockResolvedValue({
        ...modifier,
        is_active: false,
      });
      const error = new Error('Database write failed');
      repository[name].mockRejectedValue(error);
      await expect(run()).rejects.toBe(error);
    },
  );
});

describe('Modifiers persistence', () => {
  const modifier = { modifier_id: 'modifier-id', code: 'EXTRA', name: 'Extra' };
  let repository: ModifiersRepository;
  let prisma: {
    modifier: {
      create: jest.Mock;
      findUnique: jest.Mock;
      findMany: jest.Mock;
      count: jest.Mock;
      update: jest.Mock;
    };
    $transaction: jest.Mock;
  };

  beforeEach(() => {
    prisma = {
      modifier: {
        create: jest.fn().mockResolvedValue(modifier),
        findUnique: jest.fn().mockResolvedValue(modifier),
        findMany: jest.fn().mockResolvedValue([modifier]),
        count: jest.fn().mockResolvedValue(1),
        update: jest.fn().mockResolvedValue(modifier),
      },
      $transaction: jest.fn().mockResolvedValue([[modifier], 1]),
    };
    repository = new ModifiersRepository(prisma as unknown as PrismaService);
  });

  it('UT-MOD-020: creates a modifier', async () => {
    const dto = { code: 'EXTRA', name: 'Extra', description: null };

    await expect(repository.createModifier(dto)).resolves.toEqual(modifier);
    expect(prisma.modifier.create).toHaveBeenCalledWith({ data: dto });
  });

  it.each([undefined, true, false])(
    'UT-MOD-021: applies activeOnly=%s to every find and the total count',
    async (activeOnly) => {
      const is_active = activeOnly === false ? undefined : true;

      await repository.findOneModifierByUID('modifier-id', activeOnly);
      expect(prisma.modifier.findUnique).toHaveBeenLastCalledWith({
        where: { modifier_id: 'modifier-id', is_active },
      });

      await repository.findOneModifierByCode('EXTRA', activeOnly);
      expect(prisma.modifier.findUnique).toHaveBeenLastCalledWith({
        where: { code: 'EXTRA', is_active },
      });

      await expect(repository.findAll(10, 5, activeOnly)).resolves.toEqual({
        modifiers: [modifier],
        total: 1,
      });
      expect(prisma.modifier.findMany).toHaveBeenLastCalledWith({
        where: { is_active },
        skip: 10,
        take: 5,
        orderBy: [{ created_at: 'desc' }, { modifier_id: 'asc' }],
      });
      expect(prisma.modifier.count).toHaveBeenCalledWith({
        where: { is_active },
      });
      expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Array), {
        isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
      });
    },
  );

  it('UT-MOD-022: lists modifiers using a supplied transaction client', async () => {
    const tx = { modifier: prisma.modifier };

    await expect(
      repository.findAll(
        0,
        10,
        false,
        tx as unknown as Prisma.TransactionClient,
      ),
    ).resolves.toEqual({ modifiers: [modifier], total: 1 });
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it.each(['Updated description', null])(
    'UT-MOD-023: updates a modifier and sets its description to %s',
    async (description) => {
      const dto = { name: 'Updated', description };

      await repository.updateModifier('modifier-id', dto);
      expect(prisma.modifier.update).toHaveBeenCalledWith({
        where: { modifier_id: 'modifier-id', is_active: true },
        data: { ...dto, modified_at: expect.any(Date) as Date },
      });
    },
  );

  it('UT-MOD-024: reactivates an inactive modifier and updates its modification timestamp', async () => {
    await expect(repository.reactivateModifier('modifier-id')).resolves.toEqual(
      modifier,
    );

    expect(prisma.modifier.update).toHaveBeenCalledWith({
      where: { modifier_id: 'modifier-id', is_active: false },
      data: { is_active: true, modified_at: expect.any(Date) as Date },
    });
  });

  it('UT-MOD-025: soft deletes an active modifier without removing its references', async () => {
    await repository.deleteModifier('modifier-id');

    expect(prisma.modifier.update).toHaveBeenCalledWith({
      where: { modifier_id: 'modifier-id', is_active: true },
      data: { is_active: false, modified_at: expect.any(Date) as Date },
    });
  });

  it('UT-MOD-026: preserves database errors for the application exception filters', async () => {
    const error = new Error('Unique constraint failed');
    prisma.modifier.update.mockRejectedValueOnce(error);

    await expect(
      repository.updateModifier('modifier-id', { code: 'TAKEN' }),
    ).rejects.toBe(error);
  });
});
