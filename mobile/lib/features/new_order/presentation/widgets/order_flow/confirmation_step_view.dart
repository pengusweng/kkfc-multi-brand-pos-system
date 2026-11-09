import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Step 5: Order confirmation view matching the "Kitchen ticket confirmed" visual design.
class ConfirmationStepView extends ConsumerWidget {
  const ConfirmationStepView({
    super.key,
    required this.onDone,
    this.ticketNumber = 'T-017',
    this.orderId = 'ORD-2026-1105-017',
    this.onCancelOrder,
  });

  final VoidCallback onDone;
  final String ticketNumber;
  final String orderId;
  final VoidCallback? onCancelOrder;

  void _showCancelDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'This will cancel the order and notify the kitchen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        onCancelOrder?.call();
        onDone();
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(menuChannelProvider);
    final reference = ref.watch(orderReferenceProvider);

    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFF7F4EE),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Confirmed Card with Mint Border
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: const Color(0xFFA3D9B5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Green Checkmark Circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF166B3A),
                            width: 3.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check,
                            size: 32,
                            color: Color(0xFF166B3A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      const Text(
                        'Kitchen ticket confirmed',
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF19293E),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Kitchen ticket callout box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18.0,
                          vertical: 14.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2ECE1),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Kitchen ticket',
                              style: TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF586579),
                              ),
                            ),
                            Text(
                              ticketNumber,
                              style: const TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: 26.0,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF19293E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Order Details Table
                      // Row 1: Order
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Order',
                            style: TextStyle(
                              fontFamily: KkfcFonts.text,
                              fontSize: 14.5,
                              color: Color(0xFF586579),
                            ),
                          ),
                          Text(
                            orderId,
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 2: Channel
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Channel',
                            style: TextStyle(
                              fontFamily: KkfcFonts.text,
                              fontSize: 14.5,
                              color: Color(0xFF586579),
                            ),
                          ),
                          Text(
                            channel.label,
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 3: Table / Reference
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            channel == MenuChannel.dineIn
                                ? 'Table'
                                : 'Reference',
                            style: const TextStyle(
                              fontFamily: KkfcFonts.text,
                              fontSize: 14.5,
                              color: Color(0xFF586579),
                            ),
                          ),
                          Text(
                            reference.isNotEmpty ? reference : 'Table 7',
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 4: Payment status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment status',
                            style: TextStyle(
                              fontFamily: KkfcFonts.text,
                              fontSize: 14.5,
                              color: Color(0xFF586579),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF1F5),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Text(
                              'Unpaid',
                              style: TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF586579),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Actions
        Container(
          color: const Color(0xFFF7F4EE),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary: "+ New order"
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: Material(
                    color: const Color(0xFFA8562A),
                    borderRadius: BorderRadius.circular(10.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.0),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onDone();
                      },
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20.0,
                            ),
                            SizedBox(width: 6.0),
                            Text(
                              'New order',
                              style: TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary: "Cancel this order"
                TextButton(
                  onPressed: () => _showCancelDialog(context),
                  child: const Text(
                    'Cancel this order',
                    style: TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB42318),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
