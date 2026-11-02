import { ApiProperty } from '@nestjs/swagger';
import { QcRejectionReason } from '@prisma/client';
import {
  IsEnum,
  IsInt,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateOrderItemQcRejectionDTO {
  @ApiProperty({ type: 'integer', minimum: 1, maximum: 2147483647 })
  @IsInt({ message: 'Portion number must be an integer.' })
  @Min(1, { message: 'Portion number must be at least 1.' })
  @Max(2147483647, {
    message: 'Portion number must not exceed 2147483647.',
  })
  portion_number!: number;

  @ApiProperty({ enum: QcRejectionReason })
  @IsEnum(QcRejectionReason, {
    message: 'Rejection reason must be a valid QC rejection reason.',
  })
  rejection_reason!: QcRejectionReason;

  @ApiProperty({ minLength: 1, maxLength: 2000 })
  @IsString({ message: 'Description must be a string.' })
  @Matches(/\S/, { message: 'Description must not be blank.' })
  @MaxLength(2000, {
    message: 'Description must be at most 2000 characters long.',
  })
  description!: string;
}
