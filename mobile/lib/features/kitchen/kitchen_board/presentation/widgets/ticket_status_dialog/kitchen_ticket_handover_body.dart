import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_handover_photo_card.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_handover_stepper.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_item_tile.dart';

/// The 3 checklist requirements for outgoing handover.
enum HandoverCheckItem {
  matchesTicket,
  cutleryIncluded,
  packagingSealed;

  String resolveLabel({int itemCount = 1}) {
    return switch (this) {
      HandoverCheckItem.matchesTicket =>
        itemCount > 1
            ? 'All $itemCount items match the ticket'
            : 'The item matches the ticket',
      HandoverCheckItem.cutleryIncluded =>
        'Cutlery, napkins and condiments included',
      HandoverCheckItem.packagingSealed => 'Packaging sealed',
    };
  }
}

/// Scrollable body for the Handover ticket state popup.
///
/// Contains the Stepper indicator (`1 Check — 2 Hand over` or `Check — Photo — Hand over`),
/// Outgoing check checklist card, Photo evidence card (for delivery tickets),
/// Order/Payment metadata card, and "Items in this order" card.
class KitchenTicketHandoverBody extends StatelessWidget {
  const KitchenTicketHandoverBody({
    super.key,
    required this.ticket,
    required this.checklist,
    required this.onToggleItem,
    this.photos = const [],
    required this.onAddPhoto,
    required this.onRemovePhoto,
    this.maxPhotos = 5,
  });

  final KitchenBoardTicket ticket;
  final Map<HandoverCheckItem, bool> checklist;
  final ValueChanged<HandoverCheckItem> onToggleItem;
  final List<HandoverPhotoEvidence> photos;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final int maxPhotos;

  bool get _isAllChecked =>
      HandoverCheckItem.values.every((item) => checklist[item] == true);

  @override
  Widget build(BuildContext context) {
    final data = ticket.data;
    final displayOrderCode = ticket.orderCode.isNotEmpty
        ? ticket.orderCode
        : data.ticketNumber;
    final isDelivery = ticket.isDelivery;
    final itemCount = data.items.length;

    return ColoredBox(
      color: KkfcColors.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KkfcSpace.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stepper indicator (2 steps for pickup/dine-in, 3 steps for delivery)
            KitchenTicketHandoverStepper(
              isDelivery: isDelivery,
              isChecklistComplete: _isAllChecked,
              isPhotoAttached: photos.isNotEmpty,
            ),
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
                      label: HandoverCheckItem.values[i].resolveLabel(
                        itemCount: itemCount,
                      ),
                      isChecked: checklist[HandoverCheckItem.values[i]] == true,
                      onToggle: () => onToggleItem(HandoverCheckItem.values[i]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: KkfcSpace.s12),

            // Card 2: Photo evidence (only for delivery orders: GrabFood or foodpanda)
            if (isDelivery) ...[
              KitchenTicketHandoverPhotoCard(
                photos: photos,
                onAddPhoto: onAddPhoto,
                onRemovePhoto: onRemovePhoto,
                maxPhotos: maxPhotos,
              ),
              const SizedBox(height: KkfcSpace.s12),
            ],

            // Card 3: Order & Payment info
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textSm,
                            fontWeight: KkfcFontWeights.regular,
                            color: KkfcColors.ink2,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textSm,
                            fontWeight: KkfcFontWeights.regular,
                            color: KkfcColors.ink2,
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

            // Card 4: Items in this order
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
                  const SizedBox(height: KkfcSpace.s12),
                  for (var i = 0; i < data.items.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        color: KkfcColors.divider,
                        height: 20,
                        thickness: KkfcBorderWidth.thin,
                      ),
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

/// A single interactive checklist item row with rounded square checkbox.
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.isChecked,
    required this.onToggle,
  });

  final String label;
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
                  color: isChecked ? KkfcColors.ink : KkfcColors.borderStrong,
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
                label,
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
