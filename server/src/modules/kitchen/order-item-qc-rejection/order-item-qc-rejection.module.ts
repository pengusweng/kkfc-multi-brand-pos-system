import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { OrderItemQcRejectionRepository } from './order-item-qc-rejection.repository';
import { OrderItemQcRejectionController } from './order-item-qc-rejection.controller';
import { OrderItemQcRejectionService } from './order-item-qc-rejection.service';

@Module({
  imports: [PrismaModule],
  controllers: [OrderItemQcRejectionController],
  providers: [OrderItemQcRejectionService, OrderItemQcRejectionRepository],
  exports: [OrderItemQcRejectionService, OrderItemQcRejectionRepository],
})
export class OrderItemQcRejectionModule {}
