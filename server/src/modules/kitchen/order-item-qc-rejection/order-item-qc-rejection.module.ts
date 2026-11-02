import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { OrderItemQcRejectionRepository } from './order-item-qc-rejection.repository';

@Module({
  imports: [PrismaModule],
  providers: [OrderItemQcRejectionRepository],
  exports: [OrderItemQcRejectionRepository],
})
export class OrderItemQcRejectionModule {}
