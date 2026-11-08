import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_action.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_header.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_item_tile.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_meta.dart';

export 'package:mobile/shared/data/models/kitchen_ticket_data.dart';

enum KitchenTicketVariant { standard, board }

/// Stateless Kitchen Ticket Card matching the KKFC Kitchen Display System.
class KitchenTicketCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final defaultLabel = kitchenTicketActionLabel(ticket.status);
    final resolvedLabel = actionLabel ?? defaultLabel ?? 'Acknowledge';
    final showAction = onAction != null || actionLabel != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
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
            ticketNumber: ticket.ticketNumber,
            elapsed: ticket.elapsed,
            age: ticket.age,
          ),
          const SizedBox(height: 14),

          // 2. Brand badge and name
          KitchenTicketBrandRow(brand: ticket.brand),
          const SizedBox(height: 8),

          // 3. Channel and reference line (🛍 Takeaway · Call: Ana)
          KitchenTicketChannelLine(
            channel: ticket.channel,
            reference: ticket.reference,
          ),
          const SizedBox(height: 16),

          // 4. Ticket items list
          for (var i = 0; i < ticket.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            KitchenTicketItemTile(item: ticket.items[i]),
          ],
          const SizedBox(height: 16),

          // 5. Payment status
          Text(
            'Payment: ${ticket.paymentStatus}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          // 6. Action buttons footer (Details and Action)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onDetails,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFF334155),
                ),
                child: const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              if (showAction) ...[
                const SizedBox(width: 8),
                // Flexible so long labels wrap instead of overflowing at
                // large text scales.
                Flexible(
                  child: FilledButton(
                    onPressed: isActionEnabled && !isActionLoading
                        ? onAction
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: KkfcColors.action, // #A8562A
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      minimumSize: const Size(100, 42),
                    ),
                    child: isActionLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            resolvedLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
