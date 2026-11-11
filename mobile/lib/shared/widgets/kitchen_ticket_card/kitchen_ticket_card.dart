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
    final defaultLabel = isBoard && widget.ticket.status == KkfcStatus.queued
        ? 'Acknowledge'
        : kitchenTicketActionLabel(widget.ticket.status);
    final resolvedLabel = widget.actionLabel ?? defaultLabel ?? 'Acknowledge';
    final showAction = widget.onAction != null || widget.actionLabel != null;
    final hideDetailsForFullWidthAction =
        isBoard &&
        widget.ticket.status == KkfcStatus.ready &&
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
                    : KkfcColors.ticketBorder,
                width: 1,
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
                const SizedBox(height: 16),

                // 4. Ticket items list
                for (var i = 0; i < widget.ticket.items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  KitchenTicketItemTile(item: widget.ticket.items[i]),
                ],
                const SizedBox(height: 16),

                // 5. Payment status
                Text(
                  'Payment: ${widget.ticket.paymentStatus}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: KkfcColors.ticketMuted,
                  ),
                ),
                const SizedBox(height: 14),

                // 6. Action buttons footer (Details and Action)
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
    );
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
}
