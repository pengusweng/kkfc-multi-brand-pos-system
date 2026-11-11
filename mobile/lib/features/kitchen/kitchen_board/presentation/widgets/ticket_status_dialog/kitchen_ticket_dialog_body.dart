import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_item_tile.dart';

/// Stateless body content for [KitchenTicketStatusDialog], displaying the
/// items to prepare and the order/timestamp metadata grid.
class KitchenTicketDialogBody extends StatelessWidget {
  const KitchenTicketDialogBody({super.key, required this.ticket});

  final KitchenBoardTicket ticket;

  @override
  Widget build(BuildContext context) {
    final data = ticket.data;
    final displayOrderCode = ticket.orderCode.isNotEmpty
        ? ticket.orderCode
        : data.ticketNumber;

    return ColoredBox(
      color: KkfcColors.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KkfcSpace.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card 1: Items to prepare
            Container(
              padding: const EdgeInsets.all(KkfcSpace.s16),
              decoration: BoxDecoration(
                color: KkfcColors.surface,
                borderRadius: BorderRadius.circular(KkfcRadius.md),
                border: Border.all(
                  color: KkfcColors.border,
                  width: KkfcBorderWidth.thin,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items to prepare',
                    style: TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: KkfcTextSizes.textBase,
                      fontWeight: KkfcFontWeights.bold,
                      color: KkfcColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < data.items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    KitchenTicketItemTile(item: data.items[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: KkfcSpace.s12),

            // Card 2: Order, Payment, Sent to kitchen, Preparation started
            Container(
              padding: const EdgeInsets.all(KkfcSpace.s16),
              decoration: BoxDecoration(
                color: KkfcColors.surface,
                borderRadius: BorderRadius.circular(KkfcRadius.md),
                border: Border.all(
                  color: KkfcColors.border,
                  width: KkfcBorderWidth.thin,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MetadataCell(
                          label: 'Order',
                          value: displayOrderCode,
                        ),
                      ),
                      const SizedBox(width: KkfcSpace.s12),
                      Expanded(
                        child: _MetadataCell(
                          label: 'Payment',
                          value: data.paymentStatus,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MetadataCell(
                          label: 'Sent to kitchen',
                          value: ticket.sentToKitchenLabel,
                        ),
                      ),
                      const SizedBox(width: KkfcSpace.s12),
                      Expanded(
                        child: _MetadataCell(
                          label: 'Preparation started',
                          value: ticket.preparationStartedLabel,
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
    );
  }
}

class _MetadataCell extends StatelessWidget {
  const _MetadataCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: KkfcFonts.ibmPlexSans,
            fontSize: KkfcTextSizes.textSm,
            fontWeight: KkfcFontWeights.regular,
            color: KkfcColors.ink3,
          ),
        ),
        const SizedBox(height: KkfcSpace.s4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: KkfcFonts.ibmPlexSans,
            fontSize: KkfcTextSizes.textMd,
            fontWeight: KkfcFontWeights.bold,
            color: KkfcColors.ink,
          ),
        ),
      ],
    );
  }
}
