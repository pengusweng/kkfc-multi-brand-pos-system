import 'package:flutter/foundation.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// Represents an active kitchen ticket on the KDS board, wrapping
/// [KitchenTicketData] with backend identifiers and lane routing.
@immutable
class KitchenBoardTicket {
  const KitchenBoardTicket({
    required this.kitchenTicketId,
    required this.orderId,
    required this.orderCode,
    required this.lane,
    required this.data,
    this.rawStatus = 'QUEUED',
  });

  final String kitchenTicketId;
  final String orderId;
  final String orderCode;
  final KitchenBoardLane lane;
  final KitchenTicketData data;
  final String rawStatus;

  KitchenBoardTicket copyWith({
    String? kitchenTicketId,
    String? orderId,
    String? orderCode,
    KitchenBoardLane? lane,
    KitchenTicketData? data,
    String? rawStatus,
  }) {
    return KitchenBoardTicket(
      kitchenTicketId: kitchenTicketId ?? this.kitchenTicketId,
      orderId: orderId ?? this.orderId,
      orderCode: orderCode ?? this.orderCode,
      lane: lane ?? this.lane,
      data: data ?? this.data,
      rawStatus: rawStatus ?? this.rawStatus,
    );
  }

  /// Parses a JSON map from `GET /api/kitchen-ticket/today`.
  /// Returns `null` if the ticket is in a terminal state (`HANDED_OVER` or `CANCELLED`).
  static KitchenBoardTicket? tryFromApiJson(
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final rawStatus = (json['status'] as String? ?? 'QUEUED')
        .trim()
        .toUpperCase();
    final kkfcStatus = _parseStatus(rawStatus);
    if (kkfcStatus == null) return null;

    final lane = KitchenBoardLane.fromStatus(kkfcStatus);
    if (lane == null) return null;

    final ticketId =
        (json['kitchen_ticket_id'] as String?) ??
        (json['id'] as String?) ??
        '';
    final orderId = (json['order_id'] as String?) ?? '';
    final orderCode = (json['order_code'] as String?)?.trim() ?? '';
    final ticketNumber = (json['ticket_number'] as String?)?.trim() ?? 'T-000';

    final orderMap = json['order'] is Map<String, dynamic>
        ? json['order'] as Map<String, dynamic>
        : null;

    final elapsed = _parseElapsed(json, now: now ?? DateTime.now());
    final age = _parseAge(json, elapsed);
    final brand = _parseBrand(json, orderMap, orderCode);
    final channel = _parseChannel(json, orderMap);
    final reference = _parseReference(json, orderMap, channel, orderCode);
    final paymentStatus = _parsePaymentStatus(json, orderMap);
    final items = _parseItems(json, orderMap, orderCode);

    return KitchenBoardTicket(
      kitchenTicketId: ticketId.isNotEmpty ? ticketId : ticketNumber,
      orderId: orderId,
      orderCode: orderCode,
      lane: lane,
      rawStatus: rawStatus,
      data: KitchenTicketData(
        ticketNumber: ticketNumber,
        elapsed: elapsed,
        age: age,
        status: kkfcStatus,
        channel: channel,
        reference: reference,
        brand: brand,
        items: items,
        paymentStatus: paymentStatus,
      ),
    );
  }

  static KkfcStatus? _parseStatus(String status) => switch (status) {
    'QUEUED' => KkfcStatus.queued,
    'ACKNOWLEDGED' => KkfcStatus.acknowledged,
    'PREPARING' => KkfcStatus.preparing,
    'FOR_CHECKING' || 'CHECKING' => KkfcStatus.checking,
    'REWORKING' => KkfcStatus.reworking,
    'READY' => KkfcStatus.ready,
    'HANDED_OVER' || 'CANCELLED' => null,
    _ => KkfcStatus.queued,
  };

  static Duration _parseElapsed(
    Map<String, dynamic> json, {
    required DateTime now,
  }) {
    final explicitSeconds = json['elapsed_seconds'] ?? json['elapsedSeconds'];
    if (explicitSeconds is num && explicitSeconds >= 0) {
      return Duration(seconds: explicitSeconds.round());
    }

    final createdAtRaw = json['created_at'] as String?;
    if (createdAtRaw != null) {
      final createdAt = DateTime.tryParse(createdAtRaw);
      if (createdAt != null) {
        final diff = now.toUtc().difference(createdAt.toUtc());
        return diff.isNegative ? Duration.zero : diff;
      }
    }
    return Duration.zero;
  }

  static KitchenTicketAge _parseAge(
    Map<String, dynamic> json,
    Duration elapsed,
  ) {
    final rawAge = (json['age'] as String?)?.trim().toLowerCase();
    if (rawAge != null) {
      return switch (rawAge) {
        'ontime' || 'on_time' => KitchenTicketAge.onTime,
        'duesoon' || 'due_soon' => KitchenTicketAge.dueSoon,
        'late' || 'overdue' => KitchenTicketAge.late,
        _ => _ageFromElapsed(elapsed),
      };
    }
    return _ageFromElapsed(elapsed);
  }

  static KitchenTicketAge _ageFromElapsed(Duration elapsed) {
    if (elapsed >= const Duration(minutes: KkfcKitchen.ageLateMin)) {
      return KitchenTicketAge.late;
    }
    if (elapsed >= const Duration(minutes: KkfcKitchen.ageCautionMin)) {
      return KitchenTicketAge.dueSoon;
    }
    return KitchenTicketAge.onTime;
  }

  static AssignedBrand _parseBrand(
    Map<String, dynamic> json,
    Map<String, dynamic>? orderMap,
    String orderCode,
  ) {
    final brandObj = json['brand'] ?? orderMap?['brand'];
    if (brandObj is Map<String, dynamic>) {
      final code = (brandObj['code'] as String?)?.trim();
      final name = (brandObj['name'] as String?)?.trim();
      final id = (brandObj['brand_id'] as String?) ?? (brandObj['id'] as String?);
      if (code != null && code.isNotEmpty && name != null && name.isNotEmpty) {
        return AssignedBrand(id: id ?? 'brand-$code', code: code, name: name);
      }
    }

    final prefix = orderCode.contains('-')
        ? orderCode.split('-').first.trim().toUpperCase()
        : orderCode.trim().toUpperCase();

    return switch (prefix) {
      'KK' => const AssignedBrand(
        id: 'brand-kk',
        code: 'KK',
        name: 'King Kungs Kafé',
      ),
      'AI' => const AssignedBrand(
        id: 'brand-ai',
        code: 'AI',
        name: "Aurelia's Inasal",
      ),
      'GC' => const AssignedBrand(
        id: 'brand-gc',
        code: 'GC',
        name: 'Gamcheon',
      ),
      _ => AssignedBrand(
        id: 'brand-${prefix.isEmpty ? 'gc' : prefix.toLowerCase()}',
        code: prefix.isEmpty ? 'GC' : prefix,
        name: prefix == 'KK'
            ? 'King Kungs Kafé'
            : prefix == 'AI'
            ? "Aurelia's Inasal"
            : 'Gamcheon',
      ),
    };
  }

  static String _parseChannel(
    Map<String, dynamic> json,
    Map<String, dynamic>? orderMap,
  ) {
    final raw =
        (json['channel'] as String?) ??
        (json['order_channel'] as String?) ??
        (orderMap?['order_channel'] as String?) ??
        (orderMap?['channel'] as String?);
    if (raw == null || raw.trim().isEmpty) {
      return 'Takeaway';
    }
    return switch (raw.trim().toUpperCase()) {
      'DINE_IN' || 'DINE-IN' || 'DINEIN' => 'Dine-in',
      'TAKEAWAY' || 'TAKE_AWAY' => 'Takeaway',
      'GRABFOOD' || 'GRAB_FOOD' => 'GrabFood',
      'FOODPANDA' || 'FOOD_PANDA' => 'Foodpanda',
      _ => raw.trim(),
    };
  }

  static String _parseReference(
    Map<String, dynamic> json,
    Map<String, dynamic>? orderMap,
    String channel,
    String orderCode,
  ) {
    final directRef =
        (json['reference'] as String?) ?? (orderMap?['reference'] as String?);
    if (directRef != null && directRef.trim().isNotEmpty) {
      return directRef.trim();
    }

    final tableRef =
        (json['table_reference'] as String?) ??
        (orderMap?['table_reference'] as String?);
    if (tableRef != null && tableRef.trim().isNotEmpty) {
      final trimmed = tableRef.trim();
      if (channel == 'Dine-in' &&
          !trimmed.toLowerCase().startsWith('table')) {
        return 'Table $trimmed';
      }
      if (channel == 'Takeaway' &&
          !trimmed.toLowerCase().startsWith('call')) {
        return 'Call: $trimmed';
      }
      return trimmed;
    }

    final extRef =
        (json['external_order_reference'] as String?) ??
        (orderMap?['external_order_reference'] as String?);
    if (extRef != null && extRef.trim().isNotEmpty) {
      final trimmed = extRef.trim();
      return trimmed.toLowerCase().startsWith('ref ')
          ? trimmed
          : 'Ref $trimmed';
    }

    return orderCode;
  }

  static String _parsePaymentStatus(
    Map<String, dynamic> json,
    Map<String, dynamic>? orderMap,
  ) {
    final raw =
        (json['payment_status'] as String?) ??
        (json['paymentStatus'] as String?) ??
        (orderMap?['payment_status'] as String?) ??
        (orderMap?['paymentStatus'] as String?);
    if (raw == null || raw.trim().isEmpty) return 'Paid';

    return switch (raw.trim().toUpperCase()) {
      'PAID' => 'Paid',
      'UNPAID' => 'Unpaid',
      'REFUNDED' => 'Refunded',
      _ => raw.trim(),
    };
  }

  static List<KitchenTicketItem> _parseItems(
    Map<String, dynamic> json,
    Map<String, dynamic>? orderMap,
    String orderCode,
  ) {
    final rawItems =
        json['items'] ??
        json['order_items'] ??
        json['order_items_order'] ??
        orderMap?['order_items_order'] ??
        orderMap?['items'];

    final ticketNote = (json['notes'] as String?)?.trim();
    final parsed = <KitchenTicketItem>[];

    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is Map<String, dynamic>) {
          final qty = (entry['quantity'] as num?)?.toInt() ?? 1;
          final name =
              (entry['name'] as String?) ??
              (entry['item_name'] as String?) ??
              'Order Item';
          final mods = <String>[];

          final rawMods =
              entry['modifiers'] ?? entry['order_item_modifiers_order_item'];
          if (rawMods is List) {
            for (final mod in rawMods) {
              if (mod is String && mod.trim().isNotEmpty) {
                mods.add(mod.trim());
              } else if (mod is Map<String, dynamic>) {
                final modName =
                    (mod['modifier_name'] as String?) ??
                    (mod['name'] as String?);
                if (modName != null && modName.trim().isNotEmpty) {
                  mods.add(modName.trim());
                }
              }
            }
          }

          final itemNote = (entry['notes'] as String?)?.trim();
          if (itemNote != null && itemNote.isNotEmpty) {
            mods.add(
              itemNote.toLowerCase().startsWith('note:')
                  ? itemNote
                  : 'Note: $itemNote',
            );
          }

          parsed.add(
            KitchenTicketItem(quantity: qty, name: name, modifiers: mods),
          );
        }
      }
    }

    if (parsed.isNotEmpty) {
      if (ticketNote != null && ticketNote.isNotEmpty) {
        final formattedNote = ticketNote.toLowerCase().startsWith('note:')
            ? ticketNote
            : 'Note: $ticketNote';
        final first = parsed.first;
        if (!first.modifiers.contains(formattedNote)) {
          parsed[0] = KitchenTicketItem(
            quantity: first.quantity,
            name: first.name,
            modifiers: [...first.modifiers, formattedNote],
          );
        }
      }
      return parsed;
    }

    // Fallback when GET /api/kitchen-ticket/today returns ticket-level metadata without joined items
    final fallbackMods = <String>[];
    if (ticketNote != null && ticketNote.isNotEmpty) {
      fallbackMods.add(
        ticketNote.toLowerCase().startsWith('note:')
            ? ticketNote
            : 'Note: $ticketNote',
      );
    }
    return [
      KitchenTicketItem(
        quantity: 1,
        name: orderCode.isNotEmpty ? 'Order $orderCode' : 'Kitchen Order',
        modifiers: fallbackMods,
      ),
    ];
  }
}
