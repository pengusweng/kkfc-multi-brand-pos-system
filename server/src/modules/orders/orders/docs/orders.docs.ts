import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiTags,
  ApiParam,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import {
  OrderResponseDTO,
  OrderListResponseDTO,
  OrdersPageResponseDTO,
  VerifyOrderResponseDTO,
  CreateOrderConflictResponseDTO,
} from '../dto/order-response.dto';

export function OrdersDocs() {
  return applyDecorators(
    ApiTags('Orders'),
    ApiBearerAuth(),
    ApiParam({
      name: 'brandId',
      format: 'uuid',
      description: 'Brand UUID. Allowed roles may operate on any brand.',
    }),
    ApiResponse({
      status: 400,
      description:
        'Invalid UUID/body, unavailable catalog data, or invalid channel/payment requirements.',
    }),
    ApiResponse({
      status: 401,
      description: 'Missing, invalid or expired bearer session.',
    }),
    ApiResponse({ status: 403, description: 'Role access denied.' }),
    ApiResponse({
      status: 404,
      description: 'Order not found in the requested brand.',
    }),
    ApiResponse({
      status: 409,
      description:
        'Duplicate identity, conflicting replay, invalid lifecycle state or concurrent request; retry concurrency conflicts with the same order ID.',
    }),
  );
}

export function FindOrdersDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List orders for a brand',
      description:
        'Paginated with page (default 1) and limit (default 10, maximum 100). Optional status, order_channel and order_date (Asia/Manila YYYY-MM-DD) filters. Sorted by created_at descending, then order_id ascending. Includes every status, items and the kitchen ticket. Request hashes and recipe snapshots are omitted.',
    }),
    ApiResponse({
      status: 200,
      type: OrderListResponseDTO,
      description:
        'A page of orders and the total number of matching orders, without a data/meta wrapper. Returns an empty array when nothing matches.',
    }),
  );
}

export function FindOneOrderDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get an order by UUID',
      description:
        'Returns the saved order with items and kitchen ticket in any status. Orders belonging to another brand return 404. Kitchen head and kitchen staff may also read orders.',
    }),
    ApiParam({
      name: 'orderId',
      format: 'uuid',
      description: 'Order UUID belonging to brandId.',
    }),
    ApiResponse({ status: 200, type: OrderResponseDTO }),
  );
}

export function CreateOrderDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Create an order draft',
      description:
        'Requires a client UUID, channel and 1-100 lines. DINE_IN requires a table reference; GRABFOOD/FOODPANDA require store and external order references. Replays with identical payload return the existing order, which may already be confirmed.',
    }),
    ApiResponse({
      status: 201,
      type: OrderResponseDTO,
      description:
        'Created draft or existing order on an identical replay. Internal drafts have null payment_method; platform drafts use PLATFORM_SETTLED/PAID. No ticket until confirmation.',
    }),
    ApiResponse({
      status: 409,
      type: CreateOrderConflictResponseDTO,
      description:
        'DUPLICATE_PLATFORM_ORDER blocks a second draft and includes existing_order only within the requested brand (otherwise null). ORDER_ID_CONFLICT rejects a changed payload or brand. ORDER_RETRY_REQUIRED means retry the same UUID and payload.',
    }),
  );
}

export function VerifyOrderDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Validate a draft without saving',
      description:
        'Returns current catalog prices and recipe IDs; does not reserve prices or stock. Only drafts can be verified. Internal orders require payment_method and payment_status; platform orders may send an empty object.',
    }),
    ApiParam({
      name: 'orderId',
      format: 'uuid',
      description: 'Order UUID belonging to brandId.',
    }),
    ApiResponse({
      status: 200,
      type: VerifyOrderResponseDTO,
      description:
        'Returns current catalog prices and recipe IDs; does not reserve prices or stock. Only drafts can be verified.',
    }),
  );
}

export function ConfirmOrderDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Confirm an order and create its kitchen ticket',
      description:
        'Saves current catalog snapshots and a QUEUED ticket atomically. Repeated confirmation returns the saved order and ticket without changing payment. Internal orders require payment_method and payment_status; platform orders may send an empty object.',
    }),
    ApiParam({
      name: 'orderId',
      format: 'uuid',
      description: 'Order UUID belonging to brandId.',
    }),
    ApiResponse({
      status: 200,
      type: OrderResponseDTO,
      description:
        'Saves current catalog snapshots and a QUEUED ticket atomically. Repeated confirmation returns the saved order and ticket without changing payment.',
    }),
    ApiResponse({
      status: 503,
      description: 'Kitchen ticket sequence unavailable or invalid.',
    }),
  );
}

export function CancelOrderDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Cancel a draft order',
      description:
        'Cancels only a draft order without a kitchen ticket. Requires a nonblank reason. Repeated cancellation of the same draft returns the original saved result. Orders with kitchen tickets must be cancelled through kitchen fulfillment. No refund is performed.',
    }),
    ApiParam({
      name: 'orderId',
      format: 'uuid',
      description: 'Order UUID belonging to brandId.',
    }),
    ApiResponse({
      status: 200,
      type: OrderResponseDTO,
      description:
        'Cancelled draft order with cancellation actor, reason and timestamp. Its kitchen ticket remains null.',
    }),
  );
}

export function FindAllOrdersDocs() {
  return applyDecorators(
    ApiTags('Orders'),
    ApiBearerAuth(),
    ApiOperation({
      summary: 'List orders across every brand',
      description:
        'For the back-office orders list. Paginated with page (default 1) and limit (default 10, maximum 100). Optional search (order_code, case-insensitive partial), status, brand_id, payment_status and an Asia/Manila from/to order_date range; filters combine using AND. Sorted by created_at descending, then order_id ascending. Rows carry their brand but no lines or kitchen ticket; read one order through GET /brands/{brandId}/orders/{orderId} for those.',
    }),
    ApiResponse({
      status: 200,
      type: OrdersPageResponseDTO,
      description:
        'A page of orders plus pagination meta with per-status counts. Returns an empty data array when nothing matches.',
    }),
    ApiResponse({
      status: 400,
      description: 'Invalid query parameters, or from after to.',
    }),
    ApiResponse({
      status: 401,
      description: 'Missing, invalid or expired bearer session.',
    }),
    ApiResponse({ status: 403, description: 'Role access denied.' }),
  );
}
