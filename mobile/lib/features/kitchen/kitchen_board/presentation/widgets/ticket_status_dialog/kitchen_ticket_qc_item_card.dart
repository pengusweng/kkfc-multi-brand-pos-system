import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';

/// Card item widget for Quality Check dialog, displaying an item's details,
/// special request note, and interactive Pass / Fail toggle buttons.
class KitchenTicketQcItemCard extends StatelessWidget {
  const KitchenTicketQcItemCard({
    super.key,
    required this.item,
    this.isPassed,
    this.onPassedChanged,
  });

  final KitchenTicketItem item;
  final bool? isPassed;
  final ValueChanged<bool>? onPassedChanged;

  @override
  Widget build(BuildContext context) {
    final nonNotes = item.modifiers
        .where((m) => !m.trim().toLowerCase().startsWith('note:'))
        .toList();
    final notes = item.modifiers
        .where((m) => m.trim().toLowerCase().startsWith('note:'))
        .toList();

    return Container(
      width: double.infinity,
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
          // Item quantity & name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.quantity}×  ',
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textBase,
                  fontWeight: KkfcFontWeights.bold,
                  color: KkfcColors.ticketInk,
                ),
              ),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: KkfcTextSizes.textBase,
                    fontWeight: KkfcFontWeights.bold,
                    color: KkfcColors.ticketInk,
                  ),
                ),
              ),
            ],
          ),

          // Modifiers / options (excluding notes)
          if (nonNotes.isNotEmpty) ...[
            const SizedBox(height: KkfcSpace.s4),
            Text(
              nonNotes.join(' · '),
              style: const TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: KkfcTextSizes.textSm,
                fontWeight: KkfcFontWeights.medium,
                color: KkfcColors.ticketMuted,
              ),
            ),
          ],

          // Special requests / note callout
          if (notes.isNotEmpty) ...[
            const SizedBox(height: KkfcSpace.s8),
            for (final note in notes)
              Container(
                margin: const EdgeInsets.only(bottom: KkfcSpace.s4),
                padding: const EdgeInsets.symmetric(
                  horizontal: KkfcSpace.s12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: KkfcColors.ticketNoteBg,
                  borderRadius: BorderRadius.circular(KkfcRadius.sm),
                  border: Border.all(
                    color: KkfcColors.ticketNoteBorder,
                    width: KkfcBorderWidth.thin,
                  ),
                ),
                child: Text(
                  note,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: KkfcTextSizes.textSm,
                    fontWeight: KkfcFontWeights.bold,
                    color: KkfcColors.warning,
                  ),
                ),
              ),
          ],

          const SizedBox(height: KkfcSpace.s12),

          // Pass / Fail toggle buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QcDecisionButton(
                label: 'Pass',
                icon: Icons.check_rounded,
                isSelected: isPassed == true,
                activeColor: KkfcColors.qcPassBg,
                onPressed: () => onPassedChanged?.call(true),
              ),
              const SizedBox(width: KkfcSpace.s8),
              _QcDecisionButton(
                label: 'Fail',
                icon: Icons.close_rounded,
                isSelected: isPassed == false,
                activeColor: KkfcColors.dangerSolid,
                onPressed: () => onPassedChanged?.call(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QcDecisionButton extends StatelessWidget {
  const _QcDecisionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isSelected ? activeColor : KkfcColors.canvasSunken;
    final foregroundColor =
        isSelected ? KkfcColors.onSolid : KkfcColors.ink;
    final borderColor =
        isSelected ? activeColor : KkfcColors.borderStrong;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KkfcRadius.sm),
        side: BorderSide(
          color: borderColor,
          width: KkfcBorderWidth.thin,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(KkfcRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KkfcSpace.s16,
            vertical: KkfcSpace.s8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textSm,
                  fontWeight: KkfcFontWeights.bold,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
