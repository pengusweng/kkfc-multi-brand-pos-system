import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_qc_item_card.dart';

/// Stateless body section for the Quality Check popup, matching the design
/// in which checkers review each item against kitchen quality standards.
class KitchenTicketQcDialogBody extends StatelessWidget {
  const KitchenTicketQcDialogBody({
    super.key,
    required this.ticket,
    this.decisions = const {},
    this.onDecisionChanged,
  });

  final KitchenBoardTicket ticket;
  final Map<int, bool> decisions;
  final void Function(int index, bool passed)? onDecisionChanged;

  @override
  Widget build(BuildContext context) {
    final items = ticket.data.items;

    return ColoredBox(
      color: KkfcColors.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KkfcSpace.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Check temperature, plating, portion and special requests for each item.',
              style: TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: KkfcTextSizes.textSm,
                fontWeight: KkfcFontWeights.regular,
                color: KkfcColors.ink2,
              ),
            ),
            const SizedBox(height: KkfcSpace.s12),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: KkfcSpace.s12),
              KitchenTicketQcItemCard(
                item: items[i],
                isPassed: decisions[i],
                onPassedChanged: (passed) => onDecisionChanged?.call(i, passed),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
