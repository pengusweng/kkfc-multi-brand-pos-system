import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/kitchen_board_lane_column.dart';
import 'package:mobile/features/kitchen/kitchen_board/providers/kitchen_board_providers.dart';

/// Responsive 4-lane KDS board layout:
/// - `>= 960px`: 4 equal-width columns side-by-side (Tablet Landscape / Web)
/// - `>= 600px`: 2×2 lane grid (Tablet Portrait)
/// - `< 600px`: Vertically stacked lanes (Phone)
class KitchenBoardLanesView extends StatelessWidget {
  const KitchenBoardLanesView({
    super.key,
    required this.state,
    this.canPassQc = true,
    this.onTicketAction,
    this.onTicketDetails,
  });

  final KitchenBoardState state;
  final bool canPassQc;
  final ValueChanged<KitchenBoardTicket>? onTicketAction;
  final ValueChanged<KitchenBoardTicket>? onTicketDetails;

  static const double _fourLaneBreakpoint = 960.0;
  static const double _twoByTwoBreakpoint = 600.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: KkfcColors.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width >= _fourLaneBreakpoint) {
            return Padding(
              padding: const EdgeInsets.all(KkfcSpace.s16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < KitchenBoardLane.values.length; i++) ...[
                    if (i > 0) const SizedBox(width: KkfcSpace.s12),
                    Expanded(
                      child: _buildLane(
                        KitchenBoardLane.values[i],
                        scrollable: true,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          if (width >= _twoByTwoBreakpoint) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(KkfcSpace.s16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLane(
                          KitchenBoardLane.queued,
                          scrollable: false,
                        ),
                      ),
                      const SizedBox(width: KkfcSpace.s12),
                      Expanded(
                        child: _buildLane(
                          KitchenBoardLane.preparing,
                          scrollable: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KkfcSpace.s12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLane(
                          KitchenBoardLane.qcCheck,
                          scrollable: false,
                        ),
                      ),
                      const SizedBox(width: KkfcSpace.s12),
                      Expanded(
                        child: _buildLane(
                          KitchenBoardLane.ready,
                          scrollable: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(KkfcSpace.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < KitchenBoardLane.values.length; i++) ...[
                  if (i > 0) const SizedBox(height: KkfcSpace.s12),
                  _buildLane(KitchenBoardLane.values[i], scrollable: false),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLane(KitchenBoardLane lane, {required bool scrollable}) {
    return KitchenBoardLaneColumn(
      lane: lane,
      tickets: state.ticketsForLane(lane),
      loadingTicketIds: state.loadingTicketIds,
      canPassQc: canPassQc,
      onTicketAction: onTicketAction,
      onTicketDetails: onTicketDetails,
      scrollable: scrollable,
    );
  }
}
