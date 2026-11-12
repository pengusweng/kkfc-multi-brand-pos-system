import { Module } from '@nestjs/common';
import { KitchenTicketChanges } from './kitchen-ticket-changes.service';

@Module({
  providers: [KitchenTicketChanges],
  exports: [KitchenTicketChanges],
})
export class KitchenTicketChangesModule {}
