import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsUUID,
  ValidateNested,
} from 'class-validator';
import { CreateOrderItemQcRejectionDTO } from '../../order-item-qc-rejection/dto/create-order-item-qc-rejection.dto';

export class RejectOrderItemPortionDTO extends CreateOrderItemQcRejectionDTO {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  order_item_id!: string;
}

export class RejectQcAttemptDTO {
  @ApiProperty({ type: [RejectOrderItemPortionDTO], minItems: 1 })
  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => RejectOrderItemPortionDTO)
  rejections!: RejectOrderItemPortionDTO[];
}
