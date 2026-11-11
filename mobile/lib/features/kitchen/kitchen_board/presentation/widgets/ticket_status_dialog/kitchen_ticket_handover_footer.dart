import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

/// Bottom action footer for the Handover ticket state popup.
///
/// Supports 3 dynamic button states:
/// 1. Checklist incomplete: `Finish the check to hand over` (disabled, muted)
/// 2. Delivery order missing photos: `Add the photo to hand over` (disabled, muted)
/// 3. All requirements satisfied: `Confirm handover` (active, terracotta)
class KitchenTicketHandoverFooter extends StatelessWidget {
  const KitchenTicketHandoverFooter({
    super.key,
    required this.canHandover,
    required this.isChecklistComplete,
    this.isDelivery = false,
    this.isPhotoAttached = false,
    required this.isActionLoading,
    required this.onConfirmHandover,
  });

  final bool canHandover;
  final bool isChecklistComplete;
  final bool isDelivery;
  final bool isPhotoAttached;
  final bool isActionLoading;
  final VoidCallback? onConfirmHandover;

  @override
  Widget build(BuildContext context) {
    final effectiveCanHandover = canHandover && !isActionLoading;

    final backgroundColor = effectiveCanHandover
        ? KkfcColors.action
        : KkfcColors.action.withValues(alpha: 0.45);

    final foregroundColor = effectiveCanHandover
        ? KkfcColors.onSolid
        : KkfcColors.onSolid.withValues(alpha: 0.85);

    final String actionLabel;
    final IconData actionIcon;

    if (effectiveCanHandover) {
      actionLabel = 'Confirm handover';
      actionIcon = Icons.volunteer_activism_outlined;
    } else if (isDelivery && isChecklistComplete && !isPhotoAttached) {
      actionLabel = 'Add the photo to hand over';
      actionIcon = Icons.check_rounded;
    } else {
      actionLabel = 'Finish the check to hand over';
      actionIcon = Icons.check_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KkfcSpace.s16),
      decoration: const BoxDecoration(
        color: KkfcColors.surface,
        border: Border(
          top: BorderSide(
            color: KkfcColors.border,
            width: KkfcBorderWidth.thin,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: KkfcSizing.controlMd,
        child: FilledButton(
          key: const ValueKey('kitchen-ticket-handover-confirm-button'),
          onPressed: effectiveCanHandover ? onConfirmHandover : null,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            disabledBackgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            disabledForegroundColor: foregroundColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KkfcRadius.sm),
            ),
          ),
          child: isActionLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KkfcColors.onSolid,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(actionIcon, size: 20, color: foregroundColor),
                    const SizedBox(width: KkfcSpace.s8),
                    Flexible(
                      child: Text(
                        actionLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: KkfcTextSizes.textBase,
                          fontWeight: KkfcFontWeights.bold,
                          color: foregroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
