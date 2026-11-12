import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_action.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_header.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_item_tile.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_meta.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

export 'package:mobile/shared/data/models/kitchen_ticket_data.dart';

enum KitchenTicketVariant { standard, board }

/// Interactive Kitchen Ticket Card matching the KKFC Kitchen Display System,
/// featuring tactile physical compression (`0.97` scale on press, spring
/// rebound on release) and hover elevation lift.
class KitchenTicketCard extends StatefulWidget {
  const KitchenTicketCard({
    super.key,
    required this.ticket,
    this.onAction,
    this.isActionLoading = false,
    this.variant = KitchenTicketVariant.standard,
    this.actionLabel,
    this.isActionEnabled = true,
    this.onDetails,
  });

  const KitchenTicketCard.board({
    super.key,
    required this.ticket,
    this.onAction,
    this.isActionLoading = false,
    this.actionLabel,
    this.isActionEnabled = true,
    this.onDetails,
  }) : variant = KitchenTicketVariant.board;

  final KitchenTicketData ticket;

  /// Null hides the primary action button (e.g. read-only boards).
  final VoidCallback? onAction;
  final bool isActionLoading;
  final KitchenTicketVariant variant;
  final String? actionLabel;
  final bool isActionEnabled;
  final VoidCallback? onDetails;

  @override
  State<KitchenTicketCard> createState() => _KitchenTicketCardState();
}

class _KitchenTicketCardState extends State<KitchenTicketCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  bool get _hasInteractiveTarget =>
      widget.onDetails != null ||
      (widget.isActionEnabled &&
          !widget.isActionLoading &&
          widget.onAction != null);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isBoard = widget.variant == KitchenTicketVariant.board;
    final statusColors = KkfcTicketStatusColors.forStatus(widget.ticket.status);
    final defaultLabel = isBoard && widget.ticket.status == KkfcStatus.queued
        ? 'Acknowledge'
        : kitchenTicketActionLabel(widget.ticket.status);
    final resolvedLabel = widget.actionLabel ?? defaultLabel ?? 'Acknowledge';
    final showAction = widget.onAction != null || widget.actionLabel != null;
    final isRework = widget.ticket.status == KkfcStatus.reworking;
    final hideDetailsForFullWidthAction =
        isBoard &&
        (widget.ticket.status == KkfcStatus.ready || isRework) &&
        widget.isActionEnabled;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: Listener(
        onPointerDown: _hasInteractiveTarget
            ? (_) => setState(() => _isPressed = true)
            : null,
        onPointerUp: (_) {
          if (_isPressed) {
            setState(() => _isPressed = false);
          }
        },
        onPointerCancel: (_) {
          if (_isPressed) {
            setState(() => _isPressed = false);
          }
        },
        child: AnimatedScale(
          scale: !reduceMotion && _isPressed ? KkfcMotion.pressScale : 1.0,
          duration: reduceMotion
              ? Duration.zero
              : (_isPressed ? KkfcMotion.durPress : KkfcMotion.durRelease),
          curve: _isPressed ? KkfcMotion.easeOut : KkfcMotion.easeSpring,
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : KkfcMotion.durMicro,
            curve: KkfcMotion.easeOut,
            decoration: BoxDecoration(
              color: KkfcColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered && !reduceMotion
                    ? KkfcColors.borderStrong
                    : statusColors.cardBorder,
                width: 1.5,
              ),
              boxShadow: _isHovered && !reduceMotion
                  ? KkfcElevation.shadow2
                  : const [
                      BoxShadow(
                        color: KkfcColors.ticketShadow,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 0. Status accent top bar
                Container(
                  key: const ValueKey('kitchen-ticket-status-accent-bar'),
                  height: 4,
                  decoration: BoxDecoration(
                    color: statusColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Header with Ticket number, elapsed time, and progress bar
                KitchenTicketHeader(
                  ticketNumber: widget.ticket.ticketNumber,
                  elapsed: widget.ticket.elapsed,
                  age: widget.ticket.age,
                ),
                const SizedBox(height: 14),

                // 2. Brand badge and name
                KitchenTicketBrandRow(brand: widget.ticket.brand),
                const SizedBox(height: 8),

                // 3. Channel and reference line (🛍 Takeaway · Call: Ana)
                KitchenTicketChannelLine(
                  channel: widget.ticket.channel,
                  reference: widget.ticket.reference,
                  useChannelSpecificIcon: isBoard,
                ),
                if (isRework) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      key: const ValueKey('kitchen-ticket-rework-badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: KkfcColors.reworkBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: KkfcColors.reworkBorder,
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: KkfcColors.reworkText,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Rework',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: KkfcColors.reworkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (widget.ticket.status == KkfcStatus.acknowledged ||
                    !isBoard) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      key: const ValueKey('kitchen-ticket-status-badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColors.background,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIconFor(widget.ticket.status),
                            size: 14,
                            color: statusColors.foreground,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _statusLabelFor(widget.ticket.status),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: statusColors.foreground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (widget.ticket.status == KkfcStatus.checking &&
                    widget.ticket.reworkNotes != null &&
                    widget.ticket.reworkNotes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    key: const ValueKey('kitchen-ticket-rework-note-box'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: KkfcColors.ticketNoteBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: KkfcColors.ticketNoteBorder,
                        width: 1,
                      ),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Rework note: ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: KkfcColors.ticketInk,
                            ),
                          ),
                          TextSpan(
                            text: widget.ticket.reworkNotes!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: KkfcColors.ticketInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // 4. Ticket items list
                for (var i = 0; i < widget.ticket.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  KitchenTicketItemTile(
                    item: _resolveItemWithFailReason(widget.ticket.items[i], i),
                  ),
                ],
                const SizedBox(height: 16),

                // 5. Action buttons footer (Details and Action)
                if (hideDetailsForFullWidthAction && showAction)
                  _buildPrimaryActionButton(resolvedLabel)
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: widget.onDetails,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: KkfcColors.ticketSubtleInk,
                        ),
                        child: const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: KkfcColors.ticketSubtleInk,
                          ),
                        ),
                      ),
                      if (showAction) ...[
                        const SizedBox(width: 8),
                        // Flexible so long labels wrap instead of overflowing at
                        // large text scales.
                        Flexible(
                          child: _buildPrimaryActionButton(resolvedLabel),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      child: widget.isActionLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: KkfcColors.onSolid,
              ),
            )
          : Text(
              resolvedLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: widget.isActionEnabled
                    ? KkfcColors.onSolid
                    : KkfcColors.ticketMuted,
              ),
            ),
    );
  }

  KitchenTicketItem _resolveItemWithFailReason(
    KitchenTicketItem item,
    int index,
  ) {
    if (item.failReason != null && item.failReason!.trim().isNotEmpty) {
      return item;
    }
    if (widget.ticket.status == KkfcStatus.reworking) {
      final anyItemHasFailReason = widget.ticket.items.any(
        (it) => it.failReason != null && it.failReason!.trim().isNotEmpty,
      );
      if (!anyItemHasFailReason) {
        final reason = widget.ticket.qcReturnedReason?.trim().isNotEmpty == true
            ? widget.ticket.qcReturnedReason!
            : 'Rice portion short; plate again';
        return item.copyWith(failReason: reason);
      }
    }
    return item;
  }

  Widget _buildPrimaryActionButton(String resolvedLabel) {
    return FilledButton(
      onPressed: widget.isActionEnabled && !widget.isActionLoading
          ? widget.onAction
          : null,
      style: FilledButton.styleFrom(
        backgroundColor: KkfcColors.action, // #A8562A
        disabledBackgroundColor: KkfcColors.ticketDisabledBg,
        foregroundColor: KkfcColors.onSolid,
        disabledForegroundColor: KkfcColors.ticketMuted,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        minimumSize: const Size(100, 42),
      ),
      child: widget.isActionLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: KkfcColors.onSolid,
              ),
            )
          : Text(
              resolvedLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: widget.isActionEnabled
                    ? KkfcColors.onSolid
                    : KkfcColors.ticketMuted,
              ),
            ),
    );
  }

  static String _statusLabelFor(KkfcStatus status) => switch (status) {
    KkfcStatus.queued => 'Queued',
    KkfcStatus.acknowledged => 'Acknowledged',
    KkfcStatus.preparing => 'Preparing',
    KkfcStatus.checking => 'QC check',
    KkfcStatus.ready => 'Ready',
    _ => status.label,
  };

  static IconData _statusIconFor(KkfcStatus status) => switch (status) {
    KkfcStatus.queued => Icons.schedule_rounded,
    KkfcStatus.acknowledged => Icons.visibility_outlined,
    KkfcStatus.preparing => Icons.local_fire_department_rounded,
    KkfcStatus.checking => Icons.search_rounded,
    KkfcStatus.ready => Icons.check_circle_outline_rounded,
    _ => Icons.label_outline_rounded,
  };
}
