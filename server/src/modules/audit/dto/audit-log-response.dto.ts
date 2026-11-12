import { ApiProperty } from '@nestjs/swagger';
import { AuditOutcome, UserRole } from '@prisma/client';

export class AuditActorDTO {
  @ApiProperty({ type: String })
  username: string;

  @ApiProperty({ type: String })
  first_name: string;

  @ApiProperty({ type: String })
  last_name: string;

  @ApiProperty({ enum: UserRole })
  role: UserRole;
}

export class AuditLogResponseDTO {
  @ApiProperty({ enum: AuditOutcome })
  outcome: AuditOutcome;

  @ApiProperty({ type: String, format: 'uuid' })
  audit_log_id: string;

  @ApiProperty({ type: String, nullable: true, format: 'uuid' })
  actor_id: string | null;

  @ApiProperty({ type: String })
  action: string;

  @ApiProperty({ type: String })
  entity_type: string;

  @ApiProperty({ type: String, nullable: true, format: 'uuid' })
  entity_id: string | null;

  @ApiProperty({ type: String, nullable: true })
  reason: string | null;

  @ApiProperty({
    description:
      'Nullable JSON snapshot; structure depends on the audited action.',
    nullable: true,
    oneOf: [
      { type: 'object', additionalProperties: true },
      { type: 'array', items: {} },
      { type: 'string' },
      { type: 'number' },
      { type: 'boolean' },
    ],
  })
  before_data: unknown;

  @ApiProperty({
    description:
      'Nullable JSON snapshot; structure depends on the audited action.',
    nullable: true,
    oneOf: [
      { type: 'object', additionalProperties: true },
      { type: 'array', items: {} },
      { type: 'string' },
      { type: 'number' },
      { type: 'boolean' },
    ],
  })
  after_data: unknown;

  @ApiProperty({ type: String, nullable: true })
  request_id: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  created_at: string;

  @ApiProperty({
    type: AuditActorDTO,
    nullable: true,
    description:
      'Display identity of the actor; null when nobody was signed in (e.g. a failed sign-in).',
  })
  actor: AuditActorDTO | null;
}

export class AuditOutcomeCountsDTO {
  @ApiProperty({ example: 12, description: 'Every outcome.' })
  all: number;
  @ApiProperty({ example: 10 })
  SUCCESS: number;
  @ApiProperty({ example: 1 })
  DENIED: number;
  @ApiProperty({ example: 1 })
  FAILED: number;
}

export class AuditPaginationResponseDTO {
  @ApiProperty({ example: 1 })
  page: number;
  @ApiProperty({ example: 10 })
  limit: number;
  @ApiProperty({ example: 1 })
  total: number;
  @ApiProperty({
    example: 1,
    description: 'Zero when there are no matching records.',
  })
  totalPages: number;
  @ApiProperty({
    type: AuditOutcomeCountsDTO,
    description:
      'Records per outcome under every filter except outcome, for labelling outcome tabs.',
  })
  counts: AuditOutcomeCountsDTO;
}

export class AuditLogsResponseDTO {
  @ApiProperty({ type: [AuditLogResponseDTO] })
  data: AuditLogResponseDTO[];
  @ApiProperty({ type: AuditPaginationResponseDTO })
  meta: AuditPaginationResponseDTO;
}
