import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

export function KitchenFulfillmentDocs() {
  return applyDecorators(
    ApiTags('Kitchen fulfillment'),
    ApiBearerAuth(),
    ApiResponse({
      status: 400,
      description: 'Invalid UUID, request body, or image upload.',
    }),
    ApiResponse({
      status: 401,
      description: 'A valid bearer session is required.',
    }),
    ApiResponse({
      status: 403,
      description:
        'The session role or assigned user cannot perform this action.',
    }),
    ApiResponse({
      status: 404,
      description:
        'The requested ticket, order, attempt, user, or asset was not found.',
    }),
    ApiResponse({
      status: 409,
      description: 'The current state does not permit this action.',
    }),
  );
}

const kitchenRoles = 'SUPERADMIN, SUPERVISOR, KITCHEN_HEAD, and KITCHEN_STAFF.';
const checkerRoles = 'SUPERADMIN, SUPERVISOR, and KITCHEN_HEAD.';

const ticketExample = {
  kitchen_ticket_id: '00000000-0000-4000-8000-000000000001',
  order_id: '00000000-0000-4000-8000-000000000002',
  order_code: 'GC-00001',
  ticket_number: 'T-001',
  status: 'CHECKING',
  preparer_id: '00000000-0000-4000-8000-000000000003',
  checker_id: '00000000-0000-4000-8000-000000000004',
  created_by_id: '00000000-0000-4000-8000-000000000005',
  acknowledged_at: '2026-11-04T02:01:00.000Z',
  preparation_started_at: '2026-11-04T02:02:00.000Z',
  ready_at: null,
  handed_over_at: null,
  cancelled_at: null,
  notes: null,
  created_at: '2026-11-04T02:00:00.000Z',
  modified_at: '2026-11-04T02:03:00.000Z',
};
const attemptExample = {
  qc_attempt_id: '00000000-0000-4000-8000-000000000006',
  kitchen_ticket_id: ticketExample.kitchen_ticket_id,
  attempt_number: 1,
  checker_id: ticketExample.checker_id,
  status: 'IN_PROGRESS',
  started_at: '2026-11-04T02:03:00.000Z',
  completed_at: null,
};
const orderExample = {
  order_id: ticketExample.order_id,
  order_code: 'GC-00001',
  order_date: '2026-11-04T00:00:00.000Z',
  order_number: 1,
  brand_id: '00000000-0000-4000-8000-000000000007',
  created_by_id: ticketExample.created_by_id,
  order_channel: 'TAKEAWAY',
  merchant_store_reference: null,
  external_order_reference: null,
  table_reference: null,
  status: 'PREPARING',
  payment_method: 'CASH',
  payment_status: 'PAID',
  payment_reference: null,
  notes: null,
  cancelled_by_id: null,
  cancellation_reason: null,
  cancelled_at: null,
  confirmed_at: '2026-11-04T02:00:30.000Z',
  completed_at: null,
  created_at: ticketExample.created_at,
  modified_at: ticketExample.modified_at,
  order_items_order: [
    {
      order_item_id: '00000000-0000-4000-8000-000000000008',
      order_id: ticketExample.order_id,
      menu_item_id: '00000000-0000-4000-8000-000000000009',
      applied_recipe_id: null,
      item_name: 'Rice bowl',
      quantity: 1,
      unit_price: '125',
      notes: null,
      order_item_modifiers_order_item: [],
    },
  ],
  kitchen_tickets_order: { ...ticketExample, status: 'ACKNOWLEDGED' },
};
const rejectionExample = {
  rejection_id: '00000000-0000-4000-8000-000000000010',
  qc_attempt_id: attemptExample.qc_attempt_id,
  order_item_id: orderExample.order_items_order[0].order_item_id,
  portion_number: 1,
  rejection_reason: 'INCOMPLETE',
  description: 'Missing side dish.',
  rejected_at: '2026-11-04T02:04:00.000Z',
};

export function AcknowledgeDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Acknowledge a queued kitchen ticket',
      description: `Allowed roles: ${kitchenRoles} Changes QUEUED to ACKNOWLEDGED.`,
    }),
    ApiParam({ name: 'kitchenTicketId', format: 'uuid' }),
    ApiResponse({
      status: 200,
      description: 'The acknowledged ticket.',
      schema: {
        example: {
          ...ticketExample,
          status: 'ACKNOWLEDGED',
          preparation_started_at: null,
        },
      },
    }),
  );
}
export function PrepareDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Start preparation as the assigned preparer',
      description: `Allowed roles: ${kitchenRoles} The assigned preparer moves the ticket from ACKNOWLEDGED to PREPARING and its confirmed order to PREPARING in one transaction.`,
    }),
    ApiResponse({
      status: 200,
      schema: {
        example: {
          ticket: { ...ticketExample, status: 'PREPARING' },
          order: {
            ...orderExample,
            kitchen_tickets_order: { ...ticketExample, status: 'PREPARING' },
          },
        },
      },
    }),
  );
}
export function ForCheckingDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Submit preparation or rework for checking',
      description: `Allowed roles: ${kitchenRoles} The assigned preparer moves a PREPARING or REWORKING ticket to FOR_CHECKING.`,
    }),
    ApiResponse({
      status: 200,
      schema: { example: { ...ticketExample, status: 'FOR_CHECKING' } },
    }),
  );
}
export function CheckDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Start a QC attempt as the assigned checker',
      description: `Allowed roles: ${checkerRoles} The assigned checker starts a new IN_PROGRESS attempt and moves the ticket to CHECKING in one transaction.`,
    }),
    ApiResponse({
      status: 200,
      schema: { example: { ticket: ticketExample, attempt: attemptExample } },
    }),
  );
}
export function PassQcDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Pass QC and mark its ticket ready',
      description: `Allowed roles: ${checkerRoles} The assigned checker passes the in-progress attempt and marks its ticket READY in one transaction.`,
    }),
    ApiResponse({
      status: 200,
      schema: {
        example: {
          ticket: {
            ...ticketExample,
            status: 'READY',
            ready_at: '2026-11-04T02:04:00.000Z',
          },
          attempt: {
            ...attemptExample,
            status: 'PASSED',
            completed_at: '2026-11-04T02:04:00.000Z',
          },
        },
      },
    }),
  );
}
export function RejectQcDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Record rejected portions and send the ticket for rework',
      description: `Allowed roles: ${checkerRoles} Supply a nonempty rejections array with order item, portion, reason, and description. The assigned checker records the rejections, fails the attempt, and marks the ticket REWORKING in one transaction.`,
    }),
    ApiBody({
      schema: {
        type: 'object',
        required: ['rejections'],
        properties: {
          rejections: {
            type: 'array',
            minItems: 1,
            items: {
              type: 'object',
              required: [
                'order_item_id',
                'portion_number',
                'rejection_reason',
                'description',
              ],
              properties: {
                order_item_id: { type: 'string', format: 'uuid' },
                portion_number: {
                  type: 'integer',
                  minimum: 1,
                  maximum: 2147483647,
                },
                rejection_reason: { type: 'string', enum: ['INCOMPLETE'] },
                description: { type: 'string', maxLength: 2000 },
              },
            },
          },
        },
        example: {
          rejections: [
            {
              order_item_id: rejectionExample.order_item_id,
              portion_number: 1,
              rejection_reason: 'INCOMPLETE',
              description: 'Missing side dish.',
            },
          ],
        },
      },
    }),
    ApiResponse({
      status: 200,
      schema: {
        example: {
          ticket: { ...ticketExample, status: 'REWORKING' },
          attempt: {
            ...attemptExample,
            status: 'FAILED',
            completed_at: '2026-11-04T02:04:00.000Z',
          },
          rejections: [rejectionExample],
        },
      },
    }),
  );
}
export function CancelDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Cancel an order and its kitchen ticket',
      description: `Allowed roles: ${checkerRoles} Requires a nonblank cancellation reason. Cancels the order and its ticket in one transaction. Completed orders and handed-over tickets cannot be cancelled.`,
    }),
    ApiBody({
      schema: {
        type: 'object',
        required: ['cancellation_reason'],
        properties: {
          cancellation_reason: { type: 'string', maxLength: 1000 },
        },
        example: { cancellation_reason: 'Customer requested cancellation.' },
      },
    }),
    ApiResponse({
      status: 200,
      schema: {
        example: {
          order: {
            ...orderExample,
            status: 'CANCELLED',
            cancelled_by_id: ticketExample.created_by_id,
            cancellation_reason: 'Customer requested cancellation.',
            cancelled_at: '2026-11-04T02:05:00.000Z',
            kitchen_tickets_order: {
              ...ticketExample,
              status: 'CANCELLED',
              cancelled_at: '2026-11-04T02:05:00.000Z',
            },
          },
          ticket: {
            ...ticketExample,
            status: 'CANCELLED',
            cancelled_at: '2026-11-04T02:05:00.000Z',
          },
        },
      },
    }),
  );
}
export function HandOverDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Hand over a ready ticket and complete its order',
      description: `Allowed roles: ${kitchenRoles} The ticket must be READY. Delivery orders require images; upload up to five JPG/PNG files (5 MiB each) in the files field or provide existing image keys. The combined total cannot exceed five. Non-delivery orders may omit the body.`,
    }),
    ApiConsumes('multipart/form-data', 'application/json'),
    ApiBody({
      required: false,
      schema: {
        type: 'object',
        properties: {
          files: {
            type: 'array',
            maxItems: 5,
            items: { type: 'string', format: 'binary' },
          },
          img_keys: {
            type: 'array',
            maxItems: 5,
            items: { type: 'string' },
            example: [
              'uploads/00000000-0000-4000-8000-000000000003/00000000-0000-4000-8000-000000000011.png',
            ],
          },
        },
        example: {
          img_keys: [
            'uploads/00000000-0000-4000-8000-000000000003/00000000-0000-4000-8000-000000000011.png',
          ],
        },
      },
    }),
    ApiResponse({
      status: 200,
      schema: {
        example: {
          order: {
            ...orderExample,
            status: 'COMPLETED',
            completed_at: '2026-11-04T02:05:00.000Z',
            kitchen_tickets_order: {
              ...ticketExample,
              status: 'HANDED_OVER',
              ready_at: '2026-11-04T02:04:00.000Z',
              handed_over_at: '2026-11-04T02:05:00.000Z',
            },
          },
          handedOverTicket: {
            ...ticketExample,
            status: 'HANDED_OVER',
            ready_at: '2026-11-04T02:04:00.000Z',
            handed_over_at: '2026-11-04T02:05:00.000Z',
          },
        },
      },
    }),
  );
}
