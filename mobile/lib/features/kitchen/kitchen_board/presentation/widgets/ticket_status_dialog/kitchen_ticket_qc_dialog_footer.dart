import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

/// Bottom action area for the Quality Check popup dialog, providing:
/// 1. `✕ Fail QC and rework` (secondary outlined danger CTA, enabled when at least 1 item failed)
/// 2. `✓ All items passed` (primary action calling the QC pass endpoint when all items pass)
class KitchenTicketQcDialogFooter extends StatelessWidget {
  const KitchenTicketQcDialogFooter({
    super.key,
    required this.isActionLoading,
    required this.isActionEnabled,
    this.isFailEnabled = false,
    required this.onPass,
    this.onFail,
  });

  final bool isActionLoading;
  final bool isActionEnabled;
  final bool isFailEnabled;
  final VoidCallback? onPass;
  final VoidCallback? onFail;

  @override
  Widget build(BuildContext context) {
    final passForeground = isActionEnabled
        ? KkfcColors.onSolid
        : KkfcColors.ticketMuted;
    final failForeground = isFailEnabled && !isActionLoading
        ? KkfcColors.danger
        : KkfcColors.ticketMuted;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Fail QC and rework button (disabled and muted when no failed item)
          SizedBox(
            width: double.infinity,
            height: KkfcSizing.controlMd,
            child: OutlinedButton(
              key: const ValueKey('kitchen-ticket-dialog-fail-qc-button'),
              onPressed: isFailEnabled && !isActionLoading ? onFail : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: KkfcColors.surface,
                foregroundColor: failForeground,
                disabledForegroundColor: KkfcColors.ticketMuted,
                side: BorderSide(
                  color: isFailEnabled && !isActionLoading
                      ? KkfcColors.qcFailBorder
                      : KkfcColors.border,
                  width: isFailEnabled && !isActionLoading
                      ? KkfcBorderWidth.thick
                      : KkfcBorderWidth.thin,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KkfcRadius.sm),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close_rounded, size: 18, color: failForeground),
                  const SizedBox(width: KkfcSpace.s8),
                  Flexible(
                    child: Text(
                      'Fail QC and rework',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: KkfcTextSizes.textBase,
                        fontWeight: KkfcFontWeights.bold,
                        color: failForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KkfcSpace.s12),

          // 2. All items passed button (calls POST /api/kitchen-fulfillment/qc-attempts/{attemptId}/pass)
          SizedBox(
            width: double.infinity,
            height: KkfcSizing.controlMd,
            child: FilledButton(
              key: const ValueKey('kitchen-ticket-dialog-action-button'),
              onPressed: isActionEnabled && !isActionLoading ? onPass : null,
              style: FilledButton.styleFrom(
                backgroundColor: KkfcColors.action,
                disabledBackgroundColor: KkfcColors.ticketDisabledBg,
                foregroundColor: KkfcColors.onSolid,
                disabledForegroundColor: KkfcColors.ticketMuted,
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
                          Icons.check_rounded,
                          size: 18,
                          color: passForeground,
                        ),
                        const SizedBox(width: KkfcSpace.s8),
                        Flexible(
                          child: Text(
                            'All items passed',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: KkfcTextSizes.textBase,
                              fontWeight: KkfcFontWeights.bold,
                              color: passForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
