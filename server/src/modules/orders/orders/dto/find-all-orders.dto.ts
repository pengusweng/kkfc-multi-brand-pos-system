import { ApiPropertyOptional } from '@nestjs/swagger';
import { OrderStatus, PaymentStatus } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsISO8601,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { PaginationDTO } from '../../../../shared/dto/pagination.dto';

const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

/** Query for GET /orders: every brand, for the back-office orders list. */
export class FindAllOrdersDTO extends PaginationDTO {
  // Blank or whitespace-only searches are treated as no search.
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() || undefined : value,
  )
  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsString({ message: 'search must be a single string.' })
  @MaxLength(64, { message: 'search must be at most 64 characters.' })
  @ApiPropertyOptional({
    maxLength: 64,
    example: 'GC-0001',
    description: 'Case-insensitive partial match on order_code.',
  })
  search?: string;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsEnum(OrderStatus, { message: 'status must be a valid order status.' })
  @ApiPropertyOptional({
    enum: OrderStatus,
    description:
      'Only return orders with this status. Does not affect meta.counts.',
  })
  status?: OrderStatus;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsUUID('all', { message: 'brand_id must be a UUID.' })
  @ApiPropertyOptional({
    type: String,
    format: 'uuid',
    description: 'Only return orders for this brand.',
  })
  brand_id?: string;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsEnum(PaymentStatus, {
    message: 'payment_status must be a valid payment status.',
  })
  @ApiPropertyOptional({
    enum: PaymentStatus,
    description: 'Only return orders with this payment status.',
  })
  payment_status?: PaymentStatus;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @Matches(DATE_PATTERN, { message: 'from must use the YYYY-MM-DD format.' })
  @IsISO8601(
    { strict: true },
    { message: 'from must be a valid calendar date.' },
  )
  @ApiPropertyOptional({
    type: String,
    format: 'date',
    example: '2026-11-01',
    description:
      'Only return orders whose Asia/Manila business date (order_date) is on or after this date.',
  })
  from?: string;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @Matches(DATE_PATTERN, { message: 'to must use the YYYY-MM-DD format.' })
  @IsISO8601({ strict: true }, { message: 'to must be a valid calendar date.' })
  @ApiPropertyOptional({
    type: String,
    format: 'date',
    example: '2026-11-14',
    description:
      'Only return orders whose Asia/Manila business date (order_date) is on or before this date. Must not be before from.',
  })
  to?: string;
}
