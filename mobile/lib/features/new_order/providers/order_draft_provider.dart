import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/new_order/data/models/order_draft_models.dart';
import 'package:mobile/features/order_entry/data/repositories/order_entry_repository.dart';

/// Holds the client-generated RFC 4122 v4 UUID for idempotent order creation requests.
class ClientOrderIdNotifier extends Notifier<String> {
  @override
  String build() => generateOrderId();

  void regenerate() => state = generateOrderId();
}

final clientOrderIdProvider = NotifierProvider<ClientOrderIdNotifier, String>(
  ClientOrderIdNotifier.new,
);

/// Holds the current active order draft returned by `POST /brands/:brandId/orders`
/// or updated by `POST /brands/:brandId/orders/:orderId/confirm`.
class ActiveOrderDraftNotifier extends Notifier<OrderDraft?> {
  @override
  OrderDraft? build() => null;

  void set(OrderDraft draft) => state = draft;

  void updateTicket({
    required String ticketNumber,
    required String status,
    String? orderCode,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      ticketNumber: ticketNumber,
      status: status,
      orderCode: orderCode ?? state!.orderCode,
    );
  }

  void clear() => state = null;
}

final activeOrderDraftProvider =
    NotifierProvider<ActiveOrderDraftNotifier, OrderDraft?>(
  ActiveOrderDraftNotifier.new,
);
