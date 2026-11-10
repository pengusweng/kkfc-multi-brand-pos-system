import 'package:flutter/material.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

/// Card showing Subtotal, Total, and Payment status note.
class OrderDetailsSummaryCard extends StatelessWidget {
  const OrderDetailsSummaryCard({
    super.key,
    required this.subtotalCentavos,
    required this.totalCentavos,
    required this.channel,
  });

  final int subtotalCentavos;
  final int totalCentavos;
  final MenuChannel channel;

  String _paymentNote(MenuChannel channel) {
    switch (channel) {
      case MenuChannel.dineIn:
        return 'Guests pay after eating. Sending does not wait for payment.';
      case MenuChannel.takeaway:
        return 'Guests pay before eating or when claiming takeaway order.';
      case MenuChannel.grabFood:
      case MenuChannel.foodpanda:
        return 'Paid through delivery platform.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFDDD6C9), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontFamily: KkfcFonts.text,
                  fontSize: 15.0,
                  color: Color(0xFF586579),
                ),
              ),
              Text(
                formatPeso(subtotalCentavos),
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF586579),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF19293E),
                ),
              ),
              Text(
                formatPeso(totalCentavos),
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF19293E),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Payment status ',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF19293E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF1F5),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Color(0xFF586579),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Unpaid',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF586579),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _paymentNote(channel),
            style: const TextStyle(
              fontFamily: KkfcFonts.text,
              fontSize: 13.5,
              color: Color(0xFF586579),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
