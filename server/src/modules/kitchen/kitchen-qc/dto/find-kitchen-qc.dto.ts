import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean } from 'class-validator';
import { PaginationDTO } from '../../../../shared/dto/pagination.dto';

export class FindKitchenQcDTO extends PaginationDTO {
  @ApiPropertyOptional({
    type: Boolean,
    default: true,
    description:
      'Return only IN_PROGRESS attempts. False includes all statuses with pagination.',
  })
  @Transform(({ value }: { value: unknown }) =>
    value === 'true' ? true : value === 'false' ? false : value,
  )
  @IsBoolean({ message: 'activeOnly must be true or false.' })
  activeOnly: boolean = true;
}
