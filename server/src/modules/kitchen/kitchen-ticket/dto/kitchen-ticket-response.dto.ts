import { ApiProperty } from '@nestjs/swagger';
import { OrderTicketResponseDTO } from '../../../orders/orders/dto/order-response.dto';

export class KitchenTicketItemModifierDTO {
  @ApiProperty({ type: String, format: 'uuid' })
  order_item_modifier_id: string;

  @ApiProperty({ type: String, format: 'uuid' })
  modifier_id: string;

  @ApiProperty({ type: String })
  modifier_name: string;
}

export class KitchenTicketItemDTO {
  @ApiProperty({
    type: String,
    format: 'uuid',
    description:
      'Order item UUID. Use as order_item_id when rejecting a QC attempt.',
  })
  order_item_id: string;

  @ApiProperty({ type: String, format: 'uuid' })
  menu_item_id: string;

  @ApiProperty({ type: String })
  item_name: string;

  @ApiProperty({
    type: 'integer',
    minimum: 1,
    description: 'Number of portions; QC portion_number ranges from 1 to this.',
  })
  quantity: number;

  @ApiProperty({ type: String, nullable: true })
  notes: string | null;

  @ApiProperty({ type: [KitchenTicketItemModifierDTO] })
  modifiers: KitchenTicketItemModifierDTO[];
}

export class KitchenTicketWithItemsDTO extends OrderTicketResponseDTO {
  @ApiProperty({
    type: [KitchenTicketItemDTO],
    description:
      "The ticket's order items. Prices and recipe snapshots are not included.",
  })
  order_items: KitchenTicketItemDTO[];
}
