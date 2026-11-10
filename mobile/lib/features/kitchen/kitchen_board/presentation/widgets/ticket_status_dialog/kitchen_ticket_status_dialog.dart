import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_dialog_body.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_dialog_header.dart';
import 'package:mobile/features/kitchen/kitchen_board/providers/kitchen_board_providers.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// Stateless popup dialog used to inspect a kitchen ticket and advance its
/// fulfillment status (e.g. `Acknowledge`, `Start`, `Send to QC`, `Pass`,
/// `Hand over`).
class KitchenTicketStatusDialog extends StatelessWidget {
  const KitchenTicketStatusDialog({
    super.key,
    required this.ticket,
    this.actionLabel,
    this.actionIcon,
    this.statusLabel,
    this.statusIcon,
    this.isActionLoading = false,
    this.isActionEnabled = true,
    this.onAction,
    this.onClose,
  });

  final KitchenBoardTicket ticket;
  final String? actionLabel;
  final IconData? actionIcon;
  final String? statusLabel;
  final IconData? statusIcon;
  final bool isActionLoading;
  final bool isActionEnabled;
  final VoidCallback? onAction;
  final VoidCallback? onClose;

  static const double _maxDialogWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final isAcknowledged =
        ticket.data.status == KkfcStatus.acknowledged ||
        ticket.rawStatus.toUpperCase() == 'ACKNOWLEDGED';

    final resolvedActionLabel = actionLabel ??
        (isAcknowledged
            ? 'Start Preparing'
            : ticket.lane.actionLabelFor(ticket.data.status));
    final resolvedStatusLabel =
        statusLabel ?? (isAcknowledged ? 'Acknowledged' : ticket.lane.title);
    final resolvedActionIcon = actionIcon ??
        (isAcknowledged
            ? Icons.local_fire_department_rounded
            : (ticket.lane == KitchenBoardLane.queued ||
                    ticket.data.status == KkfcStatus.queued
                ? Icons.check_rounded
                : null));

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
              statusIcon: statusIcon,
              onClose: onClose,
            ),
            Flexible(child: KitchenTicketDialogBody(ticket: ticket)),
            _KitchenTicketDialogFooter(
              actionLabel: resolvedActionLabel,
              actionIcon: resolvedActionIcon,
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
/// [kitchenBoardProvider] (including `POST /api/kitchen-fulfillment/{kitchenTicketId}/acknowledge`
/// and `POST /api/kitchen-fulfillment/{kitchenTicketId}/prepare`).
Future<void> showKitchenTicketStatusDialog(
  BuildContext context, {
  required KitchenBoardTicket ticket,
  String? actionLabel,
  IconData? actionIcon,
  String? statusLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: KkfcColors.ink.withValues(alpha: KkfcOpacity.scrim),
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          final boardState = ref.watch(kitchenBoardProvider);
          final currentTicket = boardState.tickets.firstWhere(
            (t) => t.kitchenTicketId == ticket.kitchenTicketId,
            orElse: () => ticket,
          );
          final isLoading = boardState.loadingTicketIds.contains(
            currentTicket.kitchenTicketId,
          );

          return KitchenTicketStatusDialog(
            ticket: currentTicket,
            actionLabel: actionLabel,
            actionIcon: actionIcon,
            statusLabel: statusLabel,
            isActionLoading: isLoading,
            onClose: () => Navigator.of(dialogContext).maybePop(),
            onAction: () async {
              final raw = currentTicket.rawStatus.toUpperCase();
              final wasQueued =
                  raw == 'QUEUED' ||
                  currentTicket.data.status == KkfcStatus.queued ||
                  currentTicket.lane == KitchenBoardLane.queued;

              final success = await ref
                  .read(kitchenBoardProvider.notifier)
                  .performTicketAction(currentTicket);

              if (success && dialogContext.mounted) {
                // When transitioning from QUEUED to ACKNOWLEDGED, keep the
                // dialog open so the user sees the 'Acknowledged' status badge,
                // the fire icon, and the 'Start Preparing' CTA.
                if (!wasQueued) {
                  Navigator.of(dialogContext).maybePop();
                }
              }
            },
          );
        },
      );
    },
  );
}
