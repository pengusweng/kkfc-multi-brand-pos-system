import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_dialog_body.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_dialog_header.dart';
import 'package:mobile/features/kitchen/kitchen_board/providers/kitchen_board_providers.dart';

/// Stateless popup dialog used to inspect a kitchen ticket and advance its
/// fulfillment status (e.g. `Acknowledge`, `Start`, `Send to QC`, `Pass`,
/// `Hand over`).
class KitchenTicketStatusDialog extends StatelessWidget {
  const KitchenTicketStatusDialog({
    super.key,
    required this.ticket,
    this.actionLabel,
    this.actionIcon = Icons.check_rounded,
    this.statusLabel,
    this.isActionLoading = false,
    this.isActionEnabled = true,
    this.onAction,
    this.onClose,
  });

  final KitchenBoardTicket ticket;
  final String? actionLabel;
  final IconData? actionIcon;
  final String? statusLabel;
  final bool isActionLoading;
  final bool isActionEnabled;
  final VoidCallback? onAction;
  final VoidCallback? onClose;

  static const double _maxDialogWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final resolvedActionLabel =
        actionLabel ?? ticket.lane.actionLabelFor(ticket.data.status);
    final resolvedStatusLabel = statusLabel ?? ticket.lane.title;

    return Dialog(
      backgroundColor: KkfcColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: KkfcSpace.s24,
        vertical: KkfcSpace.s24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KkfcRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxDialogWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitchenTicketDialogHeader(
              ticket: ticket,
              statusLabel: resolvedStatusLabel,
              onClose: onClose,
            ),
            Flexible(child: KitchenTicketDialogBody(ticket: ticket)),
            _KitchenTicketDialogFooter(
              actionLabel: resolvedActionLabel,
              actionIcon: actionIcon,
              isActionLoading: isActionLoading,
              isActionEnabled: isActionEnabled,
              onAction: onAction,
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenTicketDialogFooter extends StatelessWidget {
  const _KitchenTicketDialogFooter({
    required this.actionLabel,
    required this.actionIcon,
    required this.isActionLoading,
    required this.isActionEnabled,
    required this.onAction,
  });

  final String actionLabel;
  final IconData? actionIcon;
  final bool isActionLoading;
  final bool isActionEnabled;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
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
          key: const ValueKey('kitchen-ticket-dialog-action-button'),
          onPressed: isActionEnabled && !isActionLoading ? onAction : null,
          style: FilledButton.styleFrom(
            backgroundColor: KkfcColors.action,
            disabledBackgroundColor: KkfcColors.ticketDisabledBg,
            foregroundColor: KkfcColors.onSolid,
            disabledForegroundColor: KkfcColors.onSolid,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                    if (actionIcon != null) ...[
                      Icon(actionIcon, size: 18, color: KkfcColors.onSolid),
                      const SizedBox(width: KkfcSpace.s8),
                    ],
                    Flexible(
                      child: Text(
                        actionLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: KkfcTextSizes.textBase,
                          fontWeight: KkfcFontWeights.bold,
                          color: KkfcColors.onSolid,
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

/// Displays [KitchenTicketStatusDialog] and connects its primary action to
/// [kitchenBoardProvider] (including `POST /api/kitchen-fulfillment/{kitchenTicketId}/acknowledge`).
Future<void> showKitchenTicketStatusDialog(
  BuildContext context, {
  required KitchenBoardTicket ticket,
  String? actionLabel,
  IconData? actionIcon = Icons.check_rounded,
  String? statusLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: KkfcColors.ink.withValues(alpha: KkfcOpacity.scrim),
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          final boardState = ref.watch(kitchenBoardProvider);
          final isLoading = boardState.loadingTicketIds.contains(
            ticket.kitchenTicketId,
          );

          return KitchenTicketStatusDialog(
            ticket: ticket,
            actionLabel: actionLabel,
            actionIcon: actionIcon,
            statusLabel: statusLabel,
            isActionLoading: isLoading,
            onClose: () => Navigator.of(dialogContext).maybePop(),
            onAction: () async {
              final success = await ref
                  .read(kitchenBoardProvider.notifier)
                  .performTicketAction(ticket);
              if (success && dialogContext.mounted) {
                Navigator.of(dialogContext).maybePop();
              }
            },
          );
        },
      );
    },
  );
}
