import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { StorageModule } from '../../../shared/storage/storage.module';
import { AssetsModule } from '../../assets/assets.module';
import { UsersModule } from '../../users/users.module';
import { KitchenTicketModule } from '../kitchen-ticket/kitchen-ticket.module';
import { HandoffController } from './handoff.controller';
import { HandoffRepository } from './handoff.repository';
import { HandoffService } from './handoff.service';

@Module({
  imports: [
    PrismaModule,
    KitchenTicketModule,
    UsersModule,
    AssetsModule,
    StorageModule,
  ],
  controllers: [HandoffController],
  providers: [HandoffService, HandoffRepository],
  exports: [HandoffRepository],
})
export class HandoffModule {}
