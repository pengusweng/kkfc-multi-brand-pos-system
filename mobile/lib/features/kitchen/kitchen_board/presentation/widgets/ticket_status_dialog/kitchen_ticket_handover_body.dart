import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_item_tile.dart';

/// The 3 checklist requirements for outgoing handover.
enum HandoverCheckItem {
  matchesTicket('The item matches the ticket'),
  cutleryIncluded('Cutlery, napkins and condiments included'),
  packagingSealed('Packaging sealed');

  const HandoverCheckItem(this.label);
  final String label;
}

/// Scrollable body for the Handover ticket state popup.
///
/// Contains the Stepper indicator (`1 Check — 2 Hand over`), the
/// Outgoing check checklist card, the Order/Payment metadata card, and
/// the "Items in this order" card.
class KitchenTicketHandoverBody extends StatelessWidget {
  const KitchenTicketHandoverBody({
    super.key,
    required this.ticket,
    required this.checklist,
    required this.onToggleItem,
  });

  final KitchenBoardTicket ticket;
  final Map<HandoverCheckItem, bool> checklist;
  final ValueChanged<HandoverCheckItem> onToggleItem;

  bool get _isAllChecked =>
      HandoverCheckItem.values.every((item) => checklist[item] == true);

  @override
  Widget build(BuildContext context) {
    final data = ticket.data;
    final displayOrderCode =
        ticket.orderCode.isNotEmpty ? ticket.orderCode : data.ticketNumber;

    return ColoredBox(
      color: KkfcColors.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KkfcSpace.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stepper indicator: 1 Check — 2 Hand over
            _HandoverStepper(isChecklistComplete: _isAllChecked),
            const SizedBox(height: KkfcSpace.s16),

            // Card 1: Outgoing check with 3 interactive checkboxes
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
                    'Outgoing check',
                    style: TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: KkfcTextSizes.textLg,
                      fontWeight: KkfcFontWeights.bold,
                      color: KkfcColors.ink,
                    ),
                  ),
                  const SizedBox(height: KkfcSpace.s12),
                  for (var i = 0; i < HandoverCheckItem.values.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        color: KkfcColors.divider,
                        height: 20,
                        thickness: KkfcBorderWidth.thin,
                      ),
                    _ChecklistRow(
                      item: HandoverCheckItem.values[i],
                      isChecked: checklist[HandoverCheckItem.values[i]] == true,
                      onToggle: () =>
                          onToggleItem(HandoverCheckItem.values[i]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: KkfcSpace.s12),

            // Card 2: Order & Payment info
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textXs,
                            fontWeight: KkfcFontWeights.regular,
                            color: KkfcColors.ticketMuted,
                          ),
                        ),
                        const SizedBox(height: KkfcSpace.s4),
                        Text(
                          displayOrderCode,
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textBase,
                            fontWeight: KkfcFontWeights.bold,
                            color: KkfcColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KkfcSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textXs,
                            fontWeight: KkfcFontWeights.regular,
                            color: KkfcColors.ticketMuted,
                          ),
                        ),
                        const SizedBox(height: KkfcSpace.s4),
                        Text(
                          data.paymentStatus,
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textBase,
                            fontWeight: KkfcFontWeights.bold,
                            color: KkfcColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KkfcSpace.s12),

            // Card 3: Items in this order
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
                    'Items in this order',
                    style: TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: KkfcTextSizes.textLg,
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
          ],
        ),
      ),
    );
  }
}

/// The Stepper row matching Image 1 and 2:
/// `1 Check — 2 Hand over` (transitions step 1 to checked green and step 2 to active).
class _HandoverStepper extends StatelessWidget {
  const _HandoverStepper({required this.isChecklistComplete});

  final bool isChecklistComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Step 1: Check
        if (isChecklistComplete)
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KkfcColors.successBg,
              border: Border.all(
                color: KkfcColors.successBorder,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: KkfcColors.success,
            ),
          )
        else
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: KkfcColors.ink,
            ),
            alignment: Alignment.center,
            child: const Text(
              '1',
              style: TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 12,
                fontWeight: KkfcFontWeights.bold,
                color: KkfcColors.onSolid,
              ),
            ),
          ),
        const SizedBox(width: KkfcSpace.s8),
        Text(
          'Check',
          style: TextStyle(
            fontFamily: KkfcFonts.ibmPlexSans,
            fontSize: KkfcTextSizes.textSm,
            fontWeight: isChecklistComplete
                ? KkfcFontWeights.medium
                : KkfcFontWeights.bold,
            color: KkfcColors.ink,
          ),
        ),
        const SizedBox(width: KkfcSpace.s8),

        // Connecting line
        Container(
          width: 18,
          height: 1.5,
          color: KkfcColors.border,
        ),
        const SizedBox(width: KkfcSpace.s8),

        // Step 2: Hand over
        if (isChecklistComplete)
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: KkfcColors.ink,
            ),
            alignment: Alignment.center,
            child: const Text(
              '2',
              style: TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 12,
                fontWeight: KkfcFontWeights.bold,
                color: KkfcColors.onSolid,
              ),
            ),
          )
        else
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: KkfcColors.ticketMuted,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              '2',
              style: TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 12,
                fontWeight: KkfcFontWeights.bold,
                color: KkfcColors.ticketMuted,
              ),
            ),
          ),
        const SizedBox(width: KkfcSpace.s8),
        Text(
          'Hand over',
          style: TextStyle(
            fontFamily: KkfcFonts.ibmPlexSans,
            fontSize: KkfcTextSizes.textSm,
            fontWeight: isChecklistComplete
                ? KkfcFontWeights.bold
                : KkfcFontWeights.medium,
            color: isChecklistComplete
                ? KkfcColors.ink
                : KkfcColors.ticketMuted,
          ),
        ),
      ],
    );
  }
}

/// A single interactive checklist item row with rounded square checkbox.
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.item,
    required this.isChecked,
    required this.onToggle,
  });

  final HandoverCheckItem item;
  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(KkfcRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KkfcSpace.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Custom checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isChecked ? KkfcColors.ink : Colors.transparent,
                border: Border.all(
                  color: isChecked
                      ? KkfcColors.ink
                      : KkfcColors.borderStrong,
                  width: 2.0,
                ),
              ),
              alignment: Alignment.center,
              child: isChecked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: KkfcColors.onSolid,
                    )
                  : null,
            ),
            const SizedBox(width: KkfcSpace.s12),

            // Item label
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textBase,
                  fontWeight: KkfcFontWeights.regular,
                  color: KkfcColors.ink,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
