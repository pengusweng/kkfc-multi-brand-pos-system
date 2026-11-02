import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { KitchenTicketQcStatus } from '@prisma/client';

const attemptSchema = {
  type: 'object' as const,
  properties: {
    qc_attempt_id: { type: 'string', format: 'uuid' },
    kitchen_ticket_id: { type: 'string', format: 'uuid' },
    attempt_number: { type: 'integer', minimum: 1 },
    checker_id: { type: 'string', format: 'uuid' },
    status: { type: 'string', enum: Object.values(KitchenTicketQcStatus) },
    started_at: { type: 'string', format: 'date-time' },
    completed_at: { type: 'string', format: 'date-time', nullable: true },
  },
};
const attemptArraySchema = { type: 'array' as const, items: attemptSchema };
const pageSchema = {
  type: 'object' as const,
  required: ['qcAttempts', 'total'],
  properties: {
    qcAttempts: attemptArraySchema,
    total: { type: 'integer', minimum: 0 },
  },
};

export function KitchenQcDocs() {
  return applyDecorators(
    ApiTags('Kitchen QC'),
    ApiBearerAuth(),
    ApiResponse({
      status: 400,
      description: 'Invalid UUID or query parameters.',
    }),
    ApiResponse({
      status: 401,
      description: 'Missing, invalid, or expired bearer session.',
    }),
    ApiResponse({
      status: 403,
      description:
        'Requires SUPERADMIN, MANAGER, SUPERVISOR, KITCHEN_HEAD, or KITCHEN_STAFF.',
    }),
  );
}

export function FindAllKitchenQcDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List QC attempts with pagination.',
      description:
        'Includes all statuses. Uses page (default 1) and limit (default 10, maximum 100). Returns qcAttempts and total.',
    }),
    ApiResponse({ status: 200, schema: pageSchema }),
  );
}

export function FindLatestKitchenQcDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get the latest QC attempt for a kitchen ticket.',
    }),
    ApiParam({ name: 'ticketId', format: 'uuid' }),
    ApiResponse({ status: 200, schema: attemptSchema }),
    ApiResponse({
      status: 404,
      description: 'Ticket or QC attempt not found.',
    }),
  );
}

export function FindKitchenQcByTicketDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List all QC attempts for a kitchen ticket.',
      description:
        'Returns attempts by attempt_number descending, or an empty array when the ticket has no attempts.',
    }),
    ApiParam({ name: 'ticketId', format: 'uuid' }),
    ApiResponse({ status: 200, schema: attemptArraySchema }),
    ApiResponse({ status: 404, description: 'Kitchen ticket not found.' }),
  );
}

export function FindKitchenQcByCheckerDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List QC attempts assigned to a checker.',
      description:
        'Defaults to all IN_PROGRESS attempts without pagination. Set activeOnly=false to paginate all statuses using page and limit. Returns qcAttempts and total; an unknown checker has no matching attempts.',
    }),
    ApiParam({ name: 'checkerId', format: 'uuid' }),
    ApiResponse({ status: 200, schema: pageSchema }),
  );
}

export function FindOneKitchenQcDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'Get a QC attempt by its ID.' }),
    ApiParam({ name: 'id', format: 'uuid' }),
    ApiResponse({ status: 200, schema: attemptSchema }),
    ApiResponse({ status: 404, description: 'QC attempt not found.' }),
  );
}
