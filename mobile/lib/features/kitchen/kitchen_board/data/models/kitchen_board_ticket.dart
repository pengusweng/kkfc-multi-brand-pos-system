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
    this.sentToKitchenLabel = '—',
    this.preparationStartedLabel = 'Not started',
    this.preparerId,
    this.checkerId,
    this.qcAttemptId,
  });

  final String kitchenTicketId;
  final String orderId;
  final String orderCode;
  final KitchenBoardLane lane;
  final KitchenTicketData data;
  final String rawStatus;
  final String sentToKitchenLabel;
  final String preparationStartedLabel;
  final String? preparerId;
  final String? checkerId;
  final String? qcAttemptId;

  /// Quality check rejection reason if this ticket was returned to rework.
  String? get qcReturnedReason => data.qcReturnedReason;

  /// Notes added by the preparer when completing rework and returning to QC.
  String? get reworkNotes => data.reworkNotes;

  /// Whether this ticket is a delivery channel (GrabFood or foodpanda)
  /// requiring photo evidence before handover.
  bool get isDelivery => data.isDelivery;

  KitchenBoardTicket copyWith({
    String? kitchenTicketId,
    String? orderId,
    String? orderCode,
    KitchenBoardLane? lane,
    KitchenTicketData? data,
    String? rawStatus,
    String? sentToKitchenLabel,
    String? preparationStartedLabel,
    String? preparerId,
    String? checkerId,
    String? qcAttemptId,
    bool clearQcAttemptId = false,
    String? qcReturnedReason,
    String? reworkNotes,
  }) {
    var effectiveData = data ?? this.data;
    if (qcReturnedReason != null || reworkNotes != null) {
      effectiveData = effectiveData.copyWith(
        qcReturnedReason: qcReturnedReason ?? effectiveData.qcReturnedReason,
        reworkNotes: reworkNotes ?? effectiveData.reworkNotes,
      );
    }
    final effectiveRawStatus = rawStatus ?? this.rawStatus;
    if (effectiveRawStatus.toUpperCase() == 'REWORKING' ||
        effectiveData.status == KkfcStatus.reworking) {
      final reason = qcReturnedReason ?? effectiveData.qcReturnedReason;
      if (reason != null && reason.trim().isNotEmpty) {
        final anyItemHasFailReason = effectiveData.items.any(
          (it) => it.failReason != null && it.failReason!.trim().isNotEmpty,
        );
        if (!anyItemHasFailReason) {
          final updatedItems = effectiveData.items
              .map((it) => it.copyWith(failReason: reason))
              .toList();
          effectiveData = effectiveData.copyWith(items: updatedItems);
        }
      }
    }
    KitchenBoardLane? effectiveLane = lane;
    if (effectiveLane == null && rawStatus != null) {
      final statusEnum = _parseStatus(rawStatus);
      if (statusEnum != null) {
        effectiveLane = KitchenBoardLane.fromStatus(statusEnum);
      }
    }
    effectiveLane ??= this.lane;

    return KitchenBoardTicket(
      kitchenTicketId: kitchenTicketId ?? this.kitchenTicketId,
      orderId: orderId ?? this.orderId,
      orderCode: orderCode ?? this.orderCode,
      lane: effectiveLane,
      data: effectiveData,
      rawStatus: rawStatus ?? this.rawStatus,
      sentToKitchenLabel: sentToKitchenLabel ?? this.sentToKitchenLabel,
      preparationStartedLabel:
          preparationStartedLabel ?? this.preparationStartedLabel,
      preparerId: preparerId ?? this.preparerId,
      checkerId: checkerId ?? this.checkerId,
      qcAttemptId: clearQcAttemptId ? null : (qcAttemptId ?? this.qcAttemptId),
    );
  }

  /// Returns a copy of this ticket with channel, reference, payment status,
  /// and brand updated from the associated [orderMap].
  KitchenBoardTicket applyOrder(Map<String, dynamic> orderMap) {
    final channel = _parseChannel({}, orderMap, fallbackChannel: data.channel);
    final reference = _parseReference({}, orderMap, channel, orderCode);
    final paymentStatus = _parsePaymentStatus({}, orderMap);
    final brand = _parseBrand({}, orderMap, orderCode);

    return copyWith(
      data: data.copyWith(
        channel: channel,
        reference: reference,
        paymentStatus: paymentStatus,
        brand: brand,
      ),
    );
  }

  /// Returns a copy of this ticket with the given order [channel] and optional [reference].
  KitchenBoardTicket withChannel(String channel, {String? reference}) {
    final parsedChannel = switch (channel.trim().toUpperCase()) {
      'DINE_IN' || 'DINE-IN' || 'DINEIN' => 'Dine-in',
      'TAKEAWAY' || 'TAKE_AWAY' => 'Takeaway',
      'GRABFOOD' || 'GRAB_FOOD' => 'GrabFood',
      'FOODPANDA' || 'FOOD_PANDA' => 'Foodpanda',
      _ => channel.trim(),
    };
    return copyWith(
      data: data.copyWith(
        channel: parsedChannel,
        reference: reference ?? data.reference,
      ),
    );
  }

  /// Parses a JSON map from `GET /api/kitchen-ticket/today`.
  /// Returns `null` if the ticket is in a terminal state (`HANDED_OVER` or `CANCELLED`).
  static KitchenBoardTicket? tryFromApiJson(
    Map<String, dynamic> json, {
    DateTime? now,
    Map<String, dynamic>? order,
  }) {
    final rawStatus = (json['status'] as String? ?? 'QUEUED')
        .trim()
        .toUpperCase();
    final kkfcStatus = _parseStatus(rawStatus);
    if (kkfcStatus == null) return null;

    final lane = KitchenBoardLane.fromStatus(kkfcStatus);
    if (lane == null) return null;

    final ticketId =
        (json['kitchen_ticket_id'] as String?) ?? (json['id'] as String?) ?? '';
    final orderId = (json['order_id'] as String?) ?? '';
    final orderCode = (json['order_code'] as String?)?.trim() ?? '';
    final ticketNumber = (json['ticket_number'] as String?)?.trim() ?? 'T-000';

    final orderMap =
        (json['order'] is Map<String, dynamic>
            ? json['order'] as Map<String, dynamic>
            : (json['order'] is Map
                  ? Map<String, dynamic>.from(json['order'] as Map)
                  : null)) ??
        order;

    final elapsed = _parseElapsed(json, now: now ?? DateTime.now());
    final age = _parseAge(json, elapsed);
    final brand = _parseBrand(json, orderMap, orderCode);
    final channel = _parseChannel(json, orderMap);
    final reference = _parseReference(json, orderMap, channel, orderCode);
    final paymentStatus = _parsePaymentStatus(json, orderMap);
    final sentToKitchenLabel = _parseTimeLabel(
      json['created_at'] as String?,
      fallback: '—',
    );
    final preparationStartedLabel = _parseTimeLabel(
      json['preparation_started_at'] as String?,
      fallback: 'Not started',
    );

    final checkerId = (json['checker_id'] as String?)?.trim();
    final rawAttempts = json['qc_attempts'];
    final latestAttemptMap =
        (rawAttempts is List &&
            rawAttempts.isNotEmpty &&
            rawAttempts.first is Map)
        ? rawAttempts.first as Map
        : null;
    final latestStatus = (latestAttemptMap?['status'] as String?)
        ?.toUpperCase();
    final isAttemptInProgress =
        latestStatus == null || latestStatus == 'IN_PROGRESS';

    // A ticket waiting for QC in FOR_CHECKING state has no active attempt yet.
    // Also, finished attempts (FAILED or PASSED) are not active.
    final qcAttemptId = rawStatus == 'FOR_CHECKING'
        ? null
        : ((json['qc_attempt_id'] as String?)?.trim() ??
              (json['attempt_id'] as String?)?.trim() ??
              (isAttemptInProgress
                  ? (latestAttemptMap?['qc_attempt_id'] as String?)?.trim()
                  : null));

    final itemRejectionsMap = <String, String>{};
    void extractItemRejections(dynamic obj) {
      if (obj is List) {
        for (final entry in obj) {
          extractItemRejections(entry);
        }
      } else if (obj is Map<String, dynamic>) {
        final orderItemId = (obj['order_item_id'] as String?)?.trim();
        final desc =
            (obj['description'] as String?)?.trim() ??
            (obj['rejection_reason'] as String?)?.trim() ??
            (obj['reason'] as String?)?.trim();
        final portion = (obj['portion_number'] as num?)?.toInt();
        if (orderItemId != null &&
            orderItemId.isNotEmpty &&
            desc != null &&
            desc.isNotEmpty) {
          final text = portion != null && portion > 0
              ? 'Portion $portion: $desc'
              : desc;
          itemRejectionsMap[orderItemId] = text;
        }
        if (obj['rejections'] != null) extractItemRejections(obj['rejections']);
        if (obj['order_item_qc_rejections'] != null) {
          extractItemRejections(obj['order_item_qc_rejections']);
        }
      }
    }

    extractItemRejections(json['qc_attempts']);
    extractItemRejections(json['rejections']);
    extractItemRejections(json['order_item_qc_rejections']);

    final qcReturnedReason =
        (json['qc_returned_reason'] as String?)?.trim() ??
        (json['rejection_reason'] as String?)?.trim() ??
        _extractRejectionReason(json['qc_attempts']) ??
        _extractRejectionReason(json['rejections']);

    final reworkNotes =
        (json['rework_notes'] as String?)?.trim() ??
        (json['rework_note'] as String?)?.trim();

    final isRework =
        rawStatus == 'REWORKING' || kkfcStatus == KkfcStatus.reworking;
    final items = _parseItems(
      json,
      orderMap,
      orderCode,
      itemRejectionsMap: itemRejectionsMap,
      qcReturnedReason: qcReturnedReason,
      isRework: isRework,
    );

    return KitchenBoardTicket(
      kitchenTicketId: ticketId.isNotEmpty ? ticketId : ticketNumber,
      orderId: orderId,
      orderCode: orderCode,
      lane: lane,
      rawStatus: rawStatus,
      sentToKitchenLabel: sentToKitchenLabel,
      preparationStartedLabel: preparationStartedLabel,
      preparerId: (json['preparer_id'] as String?)?.trim(),
      checkerId: checkerId,
      qcAttemptId: qcAttemptId,
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
        qcReturnedReason: qcReturnedReason,
        reworkNotes: reworkNotes,
      ),
    );
  }

  static String? _extractRejectionReason(dynamic obj) {
    if (obj is List && obj.isNotEmpty) {
      for (final item in obj) {
        final reason = _extractRejectionReason(item);
        if (reason != null && reason.isNotEmpty) return reason;
      }
    } else if (obj is Map<String, dynamic>) {
      final desc = (obj['description'] as String?)?.trim();
      if (desc != null && desc.isNotEmpty) return desc;
      final reason =
          (obj['rejection_reason'] as String?)?.trim() ??
          (obj['reason'] as String?)?.trim();
      if (reason != null && reason.isNotEmpty) return reason;
      final rejections = obj['rejections'] ?? obj['order_item_qc_rejections'];
      if (rejections != null) {
        return _extractRejectionReason(rejections);
      }
    }
    return null;
  }

  static String _parseTimeLabel(String? isoString, {required String fallback}) {
    if (isoString == null || isoString.trim().isEmpty) return fallback;
    final parsed = DateTime.tryParse(isoString.trim());
    if (parsed == null) return fallback;
    final local = parsed.toLocal();
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
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
      final id =
          (brandObj['brand_id'] as String?) ?? (brandObj['id'] as String?);
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
      'GC' => const AssignedBrand(id: 'brand-gc', code: 'GC', name: 'Gamcheon'),
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
    Map<String, dynamic>? orderMap, {
    String? fallbackChannel,
  }) {
    final raw =
        (json['channel'] as String?) ??
        (json['order_channel'] as String?) ??
        (json['orderChannel'] as String?) ??
        (orderMap?['order_channel'] as String?) ??
        (orderMap?['channel'] as String?) ??
        (orderMap?['orderChannel'] as String?) ??
        fallbackChannel;
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
      if (channel == 'Dine-in' && !trimmed.toLowerCase().startsWith('table')) {
        return 'Table $trimmed';
      }
      if (channel == 'Takeaway' && !trimmed.toLowerCase().startsWith('call')) {
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
    String orderCode, {
    Map<String, String> itemRejectionsMap = const {},
    String? qcReturnedReason,
    bool isRework = false,
  }) {
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

          final orderItemId =
              (entry['order_item_id'] as String?) ?? (entry['id'] as String?);
          final failReason = orderItemId != null
              ? itemRejectionsMap[orderItemId]
              : null;

          parsed.add(
            KitchenTicketItem(
              quantity: qty,
              name: name,
              modifiers: mods,
              orderItemId: orderItemId,
              failReason: failReason,
            ),
          );
        }
      }
    }

    if (parsed.isNotEmpty) {
      if (isRework &&
          qcReturnedReason != null &&
          qcReturnedReason.isNotEmpty &&
          itemRejectionsMap.isEmpty) {
        if (parsed.length == 1) {
          parsed[0] = parsed[0].copyWith(failReason: qcReturnedReason);
        } else {
          for (var i = 0; i < parsed.length; i++) {
            parsed[i] = parsed[i].copyWith(failReason: qcReturnedReason);
          }
        }
      }

      if (ticketNote != null && ticketNote.isNotEmpty) {
        final formattedNote = ticketNote.toLowerCase().startsWith('note:')
            ? ticketNote
            : 'Note: $ticketNote';
        final first = parsed.first;
        if (!first.modifiers.contains(formattedNote)) {
          parsed[0] = parsed[0].copyWith(
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
