import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/kitchen_board_lane_header.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_card.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// A single sunken lane column on the KDS board containing a
/// [KitchenBoardLaneHeader] and either an empty-state placeholder or a list of
/// [KitchenTicketCard] components.
class KitchenBoardLaneColumn extends StatelessWidget {
  const KitchenBoardLaneColumn({
    super.key,
    required this.lane,
    required this.tickets,
    required this.loadingTicketIds,
    this.canPassQc = true,
    this.onTicketAction,
    this.onTicketDetails,
    this.scrollable = true,
  });

  final KitchenBoardLane lane;
  final List<KitchenBoardTicket> tickets;
  final Set<String> loadingTicketIds;
  final bool canPassQc;
  final ValueChanged<KitchenBoardTicket>? onTicketAction;
  final ValueChanged<KitchenBoardTicket>? onTicketDetails;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (tickets.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.only(
          top: KkfcSpace.s24,
          left: KkfcSpace.s16,
          right: KkfcSpace.s16,
          bottom: KkfcSpace.s32,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            lane.emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: KkfcTextSizes.textMd,
              fontWeight: KkfcFontWeights.regular,
              color: KkfcColors.ink2,
            ),
          ),
        ),
      );
    } else {
      final cards = <Widget>[
        for (var i = 0; i < tickets.length; i++) ...[
          if (i > 0) const SizedBox(height: KkfcSpace.s12),
          _buildTicketCard(tickets[i]),
        ],
      ];

      body = scrollable
          ? ListView(
              padding: const EdgeInsets.all(10.0),
              children: cards,
            )
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cards,
              ),
            );
    }

    return Container(
      key: ValueKey('kitchen-lane-${lane.name}'),
      decoration: BoxDecoration(
        color: KkfcColors.canvasSunken,
        borderRadius: BorderRadius.circular(KkfcRadius.lg),
      ),
      child: Column(
        mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitchenBoardLaneHeader(lane: lane, count: tickets.length),
          if (scrollable) Expanded(child: body) else body,
        ],
      ),
    );
  }

  Widget _buildTicketCard(KitchenBoardTicket boardTicket) {
    final actionLabel = lane.actionLabelFor(boardTicket.data.status);
    final isQcLane = lane == KitchenBoardLane.qcCheck ||
        boardTicket.data.status == KkfcStatus.checking;
    final isActionEnabled = !isQcLane || canPassQc;

    return KitchenTicketCard.board(
      key: ValueKey('kitchen-ticket-card-${boardTicket.data.ticketNumber}'),
      ticket: boardTicket.data,
      actionLabel: actionLabel,
      isActionEnabled: isActionEnabled,
      onAction: isActionEnabled && onTicketAction != null
          ? () => onTicketAction!(boardTicket)
          : null,
      onDetails: onTicketDetails != null
          ? () => onTicketDetails!(boardTicket)
          : null,
    );
  }
}
