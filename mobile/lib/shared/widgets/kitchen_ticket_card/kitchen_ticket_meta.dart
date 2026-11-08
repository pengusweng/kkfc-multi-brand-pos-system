import 'package:flutter/material.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status_badge.dart';

/// "🛍 Takeaway · Call: Ana"
class KitchenTicketChannelLine extends StatelessWidget {
  const KitchenTicketChannelLine({
    super.key,
    required this.channel,
    required this.reference,
  });

  final String channel;
  final String reference;

  @override
  Widget build(BuildContext context) {
    final label = reference.isNotEmpty ? '$channel · $reference' : channel;
    return Row(
      children: [
        const Icon(
          Icons.shopping_bag_outlined,
          size: 16,
          color: Color(0xFF102A43),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102A43),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// [KK] King Kungs Kafé
class KitchenTicketBrandRow extends StatelessWidget {
  const KitchenTicketBrandRow({super.key, required this.brand});

  final AssignedBrand brand;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF64748B), width: 1),
          ),
          child: Text(
            brand.code,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102A43),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            brand.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Status badge helper
class KitchenTicketStatusRow extends StatelessWidget {
  const KitchenTicketStatusRow({super.key, required this.status});

  final KkfcStatus status;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: KkfcStatusBadge(status: status),
    );
  }
}
