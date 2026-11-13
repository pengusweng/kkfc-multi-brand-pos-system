import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { QcRejectionReason } from '@prisma/client';

const rejectionSchema = {
  type: 'object' as const,
  properties: {
    rejection_id: { type: 'string', format: 'uuid' },
    qc_attempt_id: { type: 'string', format: 'uuid' },
    order_item_id: { type: 'string', format: 'uuid' },
    portion_number: { type: 'integer', minimum: 1 },
    rejection_reason: {
      type: 'string',
      enum: Object.values(QcRejectionReason),
    },
    description: { type: 'string', maxLength: 2000 },
    rejected_at: { type: 'string', format: 'date-time' },
  },
};
const rejectionArraySchema = { type: 'array' as const, items: rejectionSchema };

export function OrderItemQcRejectionDocs() {
  return applyDecorators(
    ApiTags('Order Item QC Rejections'),
    ApiBearerAuth(),
    ApiResponse({ status: 400, description: 'Invalid UUID.' }),
    ApiResponse({
      status: 401,
      description: 'Missing, invalid, or expired bearer session.',
    }),
    ApiResponse({
      status: 403,
      description:
        'Requires SUPERADMIN, SUPERVISOR, KITCHEN_HEAD, or KITCHEN_STAFF.',
    }),
  );
}

export function FindOneOrderItemQcRejectionDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'Get an order item QC rejection by its ID.' }),
    ApiParam({ name: 'id', format: 'uuid' }),
    ApiResponse({ status: 200, schema: rejectionSchema }),
    ApiResponse({
      status: 404,
      description: 'Order item QC rejection not found.',
    }),
  );
}

export function FindOrderItemQcRejectionsByAttemptDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List order item QC rejections for a QC attempt.',
      description:
        'Returns all matching rejections, or an empty array when none match.',
    }),
    ApiParam({ name: 'attemptId', format: 'uuid' }),
    ApiResponse({ status: 200, schema: rejectionArraySchema }),
  );
}

export function FindOrderItemQcRejectionsByOrderItemDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List QC rejections for an order item across attempts.',
      description:
        'Returns all matching rejections, or an empty array when none match.',
    }),
    ApiParam({ name: 'orderItemId', format: 'uuid' }),
    ApiResponse({ status: 200, schema: rejectionArraySchema }),
  );
}
