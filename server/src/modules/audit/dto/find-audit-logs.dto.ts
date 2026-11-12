import { ApiPropertyOptional } from '@nestjs/swagger';
import { AuditOutcome } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsISO8601,
  IsString,
  Length,
  Matches,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { PaginationDTO } from '../../../shared/dto/pagination.dto';

const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

export class FindAuditLogsDTO extends PaginationDTO {
  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsString()
  @Length(1, 100)
  @Matches(/\S/, { message: 'Action must not be blank.' })
  @ApiPropertyOptional({
    description: 'Exact, case-sensitive action match.',
    example: 'ORDER_CONFIRMED',
    maxLength: 100,
  })
  action?: string;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsEnum(AuditOutcome)
  @ApiPropertyOptional({ enum: AuditOutcome })
  outcome?: AuditOutcome;

  // Blank or whitespace-only searches are treated as no search.
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() || undefined : value,
  )
  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsString({ message: 'search must be a single string.' })
  @MaxLength(100, { message: 'search must be at most 100 characters.' })
  @ApiPropertyOptional({
    maxLength: 100,
    example: 'ana rey',
    description:
      "Case-insensitive partial match on the actor's username, first_name, and last_name. Each space-separated term must match at least one of those fields. Rows without an actor never match.",
  })
  search?: string;

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
      'Only return records created on or after this Asia/Manila date (from midnight).',
  })
  from?: string;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @Matches(DATE_PATTERN, { message: 'to must use the YYYY-MM-DD format.' })
  @IsISO8601({ strict: true }, { message: 'to must be a valid calendar date.' })
  @ApiPropertyOptional({
    type: String,
    format: 'date',
    example: '2026-11-12',
    description:
      'Only return records created on or before this Asia/Manila date (through the end of that day). Must not be before from.',
  })
  to?: string;
}
