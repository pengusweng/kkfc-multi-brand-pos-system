import { ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Transform } from 'class-transformer';
import { IsEnum, IsIn, IsString, MaxLength, ValidateIf } from 'class-validator';
import { PaginationDTO } from '../../../shared/dto/pagination.dto';

export const USER_STATUS_FILTERS = ['all', 'active', 'inactive'] as const;
export type UserStatusFilter = (typeof USER_STATUS_FILTERS)[number];

export const USER_SORT_FIELDS = [
  'name',
  'username',
  'role',
  'status',
  'created_at',
] as const;
export type UserSortField = (typeof USER_SORT_FIELDS)[number];

export const SORT_ORDERS = ['asc', 'desc'] as const;
export type SortOrder = (typeof SORT_ORDERS)[number];

export class FindUsersDTO extends PaginationDTO {
  @IsIn(USER_STATUS_FILTERS, {
    message: 'status must be one of: all, active, inactive.',
  })
  @ApiPropertyOptional({
    enum: USER_STATUS_FILTERS,
    default: 'active',
    description:
      'Which accounts to return: active only (default), inactive only, or all.',
  })
  status: UserStatusFilter = 'active';

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
      'Case-insensitive partial match on username, first_name, and last_name. Each space-separated term must match at least one of those fields.',
  })
  search?: string;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsEnum(UserRole, {
    message: `role must be one of: ${Object.values(UserRole).join(', ')}.`,
  })
  @ApiPropertyOptional({
    enum: UserRole,
    description: 'Only return users with this role. Omit for every role.',
  })
  role?: UserRole;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsIn(USER_SORT_FIELDS, {
    message: `sortBy must be one of: ${USER_SORT_FIELDS.join(', ')}.`,
  })
  @ApiPropertyOptional({
    enum: USER_SORT_FIELDS,
    description:
      'Column to sort by. Omit for newest accounts first. name sorts by first then last name; role sorts by seniority (SUPERADMIN first when ascending); status puts active accounts first when ascending. Ties fall back to name.',
  })
  sortBy?: UserSortField;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsIn(SORT_ORDERS, { message: 'sortOrder must be asc or desc.' })
  @ApiPropertyOptional({
    enum: SORT_ORDERS,
    default: 'asc',
    description: 'Sort direction for sortBy. Ignored when sortBy is omitted.',
  })
  sortOrder?: SortOrder;
}
