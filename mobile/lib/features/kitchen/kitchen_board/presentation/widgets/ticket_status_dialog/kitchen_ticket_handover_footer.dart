import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

/// Bottom action footer for the Handover ticket state popup.
///
/// When the outgoing check items are not yet all ticked, the button displays
/// `Finish the check to hand over` in a disabled, muted state.
/// Once all 3 check items are ticked, it activates to `Confirm handover`.
class KitchenTicketHandoverFooter extends StatelessWidget {
  const KitchenTicketHandoverFooter({
    super.key,
    required this.isChecklistComplete,
    required this.isActionLoading,
    required this.onConfirmHandover,
  });

  final bool isChecklistComplete;
  final bool isActionLoading;
  final VoidCallback? onConfirmHandover;

  @override
  Widget build(BuildContext context) {
    final canHandover = isChecklistComplete && !isActionLoading;

    final backgroundColor = isChecklistComplete
        ? KkfcColors.action
        : KkfcColors.action.withValues(alpha: 0.45);

    final foregroundColor = isChecklistComplete
        ? KkfcColors.onSolid
        : KkfcColors.onSolid.withValues(alpha: 0.85);

    final actionLabel = isChecklistComplete
        ? 'Confirm handover'
        : 'Finish the check to hand over';

    final actionIcon = isChecklistComplete
        ? Icons.volunteer_activism_outlined
        : Icons.check_rounded;

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
          onPressed: canHandover ? onConfirmHandover : null,
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
                    Icon(
                      actionIcon,
                      size: 20,
                      color: foregroundColor,
                    ),
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
