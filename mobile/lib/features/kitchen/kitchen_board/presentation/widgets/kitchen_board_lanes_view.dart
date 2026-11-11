import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/core/models/user_role.dart';
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
    this.userRole,
    this.canPassQc = true,
    this.onTicketAction,
    this.onTicketDetails,
  });

  final KitchenBoardState state;
  final UserRole? userRole;
  final bool canPassQc;
  final ValueChanged<KitchenBoardTicket>? onTicketAction;
  final ValueChanged<KitchenBoardTicket>? onTicketDetails;

  static const double _fourLaneBreakpoint = 960.0;
  static const double _twoByTwoBreakpoint = 600.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
    );
  }

  Widget _buildLane(KitchenBoardLane lane, {required bool scrollable}) {
    return _StaggeredLaneEntrance(
      key: ValueKey('lane-entrance-${lane.name}'),
      laneIndex: lane.index,
      child: KitchenBoardLaneColumn(
        lane: lane,
        tickets: state.ticketsForLane(lane),
        loadingTicketIds: state.loadingTicketIds,
        userRole: userRole,
        canPassQc: canPassQc,
        onTicketAction: onTicketAction,
        onTicketDetails: onTicketDetails,
        scrollable: scrollable,
      ),
    );
  }
}

/// Choreographs a staggered entrance for each KDS lane column (`0..3`).
class _StaggeredLaneEntrance extends StatefulWidget {
  const _StaggeredLaneEntrance({
    super.key,
    required this.laneIndex,
    required this.child,
  });

  final int laneIndex;
  final Widget child;

  @override
  State<_StaggeredLaneEntrance> createState() => _StaggeredLaneEntranceState();
}

class _StaggeredLaneEntranceState extends State<_StaggeredLaneEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    final totalDurationMs =
        KkfcMotion.durScreen.inMilliseconds + (widget.laneIndex * 40);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDurationMs),
    );
    final delayFraction = (widget.laneIndex * 40) / totalDurationMs.toDouble();
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delayFraction.clamp(0.0, 0.75),
        1.0,
        curve: KkfcMotion.easeOut,
      ),
    );
    _fade = curved;
    _translateY = Tween<double>(
      begin: KkfcMotion.peerOffset,
      end: 0.0,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controller.isAnimating && !_controller.isCompleted) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (_controller.isCompleted) {
          return child!;
        }
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: child,
          ),
        );
      },
    );
  }
}
