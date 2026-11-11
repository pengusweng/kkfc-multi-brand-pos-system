import { ApiPropertyOptional } from '@nestjs/swagger';
import { OrderChannel, OrderStatus } from '@prisma/client';
import { IsEnum, IsISO8601, IsOptional, Matches } from 'class-validator';
import { PaginationDTO } from '../../../../shared/dto/pagination.dto';

export class FindOrdersDTO extends PaginationDTO {
  @ApiPropertyOptional({
    enum: OrderStatus,
    description: 'Only return orders with this status.',
  })
  @IsOptional()
  @IsEnum(OrderStatus, { message: 'status must be a valid order status.' })
  status?: OrderStatus;

  @ApiPropertyOptional({
    enum: OrderChannel,
    description: 'Only return orders from this channel.',
  })
  @IsOptional()
  @IsEnum(OrderChannel, {
    message: 'order_channel must be a valid order channel.',
  })
  order_channel?: OrderChannel;

  @ApiPropertyOptional({
    type: String,
    format: 'date',
    example: '2026-10-29',
    description:
      'Only return orders for this Asia/Manila business date (YYYY-MM-DD), the same date used for daily order numbers.',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'order_date must use the YYYY-MM-DD format.',
  })
  @IsISO8601(
    { strict: true },
    { message: 'order_date must be a valid calendar date.' },
  )
  order_date?: string;
}
