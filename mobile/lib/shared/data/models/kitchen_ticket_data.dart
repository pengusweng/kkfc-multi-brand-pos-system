import 'package:flutter/foundation.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart'; // verify path

enum KitchenTicketAge { onTime, dueSoon, late }

@immutable
class KitchenTicketItem {
  const KitchenTicketItem({
    required this.quantity,
    required this.name,
    this.modifiers = const [],
  });

  final int quantity;
  final String name;
  final List<String> modifiers; // e.g. "EXTRA rice", "NO onions"
}

@immutable
class KitchenTicketData {
  const KitchenTicketData({
    required this.ticketNumber,
    required this.elapsed,
    required this.age,
    required this.status,
    required this.channel,
    required this.reference,
    required this.brand,
    required this.items,
    this.paymentStatus = 'Paid',
  });

  final String ticketNumber; // "T-014"
  final Duration elapsed;
  final KitchenTicketAge age;
  final KkfcStatus status;
  final String channel; // "GrabFood"
  final String reference; // "#GF-1001"
  final AssignedBrand brand; // brand.code -> tag, brand.name -> label
  final List<KitchenTicketItem> items;
  final String paymentStatus;

  KitchenTicketData copyWith({
    String? ticketNumber,
    Duration? elapsed,
    KitchenTicketAge? age,
    KkfcStatus? status,
    String? channel,
    String? reference,
    AssignedBrand? brand,
    List<KitchenTicketItem>? items,
    String? paymentStatus,
  }) {
    return KitchenTicketData(
      ticketNumber: ticketNumber ?? this.ticketNumber,
      elapsed: elapsed ?? this.elapsed,
      age: age ?? this.age,
      status: status ?? this.status,
      channel: channel ?? this.channel,
      reference: reference ?? this.reference,
      brand: brand ?? this.brand,
      items: items ?? this.items,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
