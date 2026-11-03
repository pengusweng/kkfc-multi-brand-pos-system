import { ConflictException, Injectable, Logger } from '@nestjs/common';
import { AssetsService } from '../../assets/assets.service';
import { UsersRepository } from '../../users/users.repository';
import { KitchenTicketRepository } from '../kitchen-ticket/kitchen-ticket.repository';
import { HandoffRepository } from './handoff.repository';
import { CreateHandoffDTO } from './dto/create-handoff.dto';
import {
  Handoff,
  KitchenTicket,
  KitchenTicketStatus,
  Prisma,
} from '@prisma/client';
import { assertExists } from '../../../shared/assertions/assert-exists';
import { assertValidPagination } from '../../../shared/assertions/assert-valid-pagination';
import { StorageService } from '../../../shared/storage/storage.service';

@Injectable()
export class HandoffService {
  private readonly logger = new Logger(HandoffService.name);

  constructor(
    private readonly handoffRepository: HandoffRepository,
    private readonly kitchenTicketRepository: KitchenTicketRepository,
    private readonly usersRepository: UsersRepository,
    private readonly assetsService: AssetsService,
    private readonly storage: StorageService,
  ) {}

  async create(
    kitchenTicketId: string,
    actorId: string,
    dto: CreateHandoffDTO,
    tx?: Prisma.TransactionClient,
  ) {
    this.logger.debug(
      `Creating handoff entry for kitchen ticket ${kitchenTicketId}. Actor=${actorId}`,
    );

    const kitchenTicket = await this.kitchenTicketRepository.findOne(
      kitchenTicketId,
      tx,
    );

    assertExists(kitchenTicket, 'KitchenTicket', kitchenTicketId, this.logger);

    const user = await this.usersRepository.findOne(actorId, true, tx);
    assertExists(user, 'User', actorId, this.logger);

    await this.assertHandoffCreatable(kitchenTicket, actorId, dto, tx);

    const handoffEntry = await this.handoffRepository.create(
      kitchenTicketId,
      actorId,
      dto,
      tx,
    );

    this.logger.log(
      `Created handoff entry for ${kitchenTicketId} with handoff id ${handoffEntry.handoff_id}.`,
    );

    return this.response(handoffEntry);
  }

  async findOne(handoffId: string) {
    this.logger.debug(`Finding handoff ${handoffId}`);

    const handoff = await this.handoffRepository.findOne(handoffId);
    assertExists(handoff, 'Handoff', handoffId, this.logger);

    this.logger.log(`Found handoff ${handoff.handoff_id}`);
    return this.response(handoff);
  }

  async findOneByKitchenTicket(kitchenTicketId: string) {
    this.logger.debug(`Finding handoff for kitchen ticket ${kitchenTicketId}`);

    const kitchenTicket =
      await this.kitchenTicketRepository.findOne(kitchenTicketId);
    assertExists(kitchenTicket, 'KitchenTicket', kitchenTicketId, this.logger);

    const handoff =
      await this.handoffRepository.findOneByKitchenTicket(kitchenTicketId);
    assertExists(handoff, 'Handoff', kitchenTicketId, this.logger);

    this.logger.log(
      `Found handoff ${handoff.handoff_id} for kitchen ticket ${kitchenTicketId}`,
    );
    return this.response(handoff);
  }

  async findManyByActor(actorId: string, skip: number, take: number) {
    this.logger.debug(
      `Listing handoffs: actor=${actorId}, skip=${skip}, take=${take}`,
    );
    assertValidPagination(skip, this.logger);

    const result = await this.handoffRepository.findManyByActor(
      actorId,
      skip,
      take,
    );

    this.logger.log(
      `Listed handoffs for actor ${actorId}: returned=${result.handoffs.length}, total=${result.total}`,
    );
    return {
      ...result,
      handoffs: await Promise.all(
        result.handoffs.map((handoff) => this.response(handoff)),
      ),
    };
  }

  async findAll(skip: number, take: number) {
    this.logger.debug(`Listing handoffs: skip=${skip}, take=${take}`);
    assertValidPagination(skip, this.logger);
    const result = await this.handoffRepository.findAll(skip, take);

    this.logger.log(
      `Listed handoffs: returned=${result.handoffs.length}, total=${result.total}`,
    );
    return {
      ...result,
      handoffs: await Promise.all(
        result.handoffs.map((handoff) => this.response(handoff)),
      ),
    };
  }

  private async response(handoff: Handoff) {
    const { img_keys, ...data } = handoff;
    return {
      ...data,
      img_urls: await Promise.all(
        img_keys.map((key) => this.storage.createDownloadUrl(key)),
      ),
    };
  }

  async assertHandoffCreatable(
    kitchenTicket: KitchenTicket,
    actorId: string,
    dto: CreateHandoffDTO,
    tx?: Prisma.TransactionClient,
  ) {
    if (kitchenTicket.status !== KitchenTicketStatus.READY) {
      this.logger.warn(
        `Kitchen ticket ${kitchenTicket.kitchen_ticket_id} is not ready for handoff.`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_NOT_READY',
        message: 'Kitchen ticket must be READY before handoff.',
      });
    }

    const existingHandoff = await this.handoffRepository.findOneByKitchenTicket(
      kitchenTicket.kitchen_ticket_id,
      tx,
    );

    if (existingHandoff) {
      this.logger.warn(
        `Kitchen ticket ${kitchenTicket.kitchen_ticket_id} is has already a handoff entry.`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_HAS_EXISTING_HANDOFF',
        message: 'Kitchen ticket already has an existing handoff record.',
      });
    }

    for (const key of dto.img_keys) {
      await this.assetsService.download(actorId, key);
    }
  }
}
