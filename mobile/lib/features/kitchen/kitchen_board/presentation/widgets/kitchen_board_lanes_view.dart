import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/kitchen_board_lane_column.dart';
import 'package:mobile/features/kitchen/kitchen_board/providers/kitchen_board_providers.dart';

/// Operational KDS board layout with 6 distinct status columns:
/// Queued, Acknowledged, Preparing, Rework, QC Check, and Ready.
///
/// Supports smooth sideways horizontal scrolling across viewports,
/// while each column scrolls tickets vertically.
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

  static const double _minLaneWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final hasBoundedHeight = constraints.hasBoundedHeight;

        // Provide a minimum width of 280px per lane so cards and actions remain
        // easily readable, clear, and comfortably tappable.
        // If the screen is wider than the lanes combined, expand lanes equally.
        const horizontalPadding = KkfcSpace.s16 * 2;
        final totalGaps = KkfcSpace.s12 * (KitchenBoardLane.values.length - 1);
        final availableWidth = width - horizontalPadding - totalGaps;
        final computedWidth = availableWidth / KitchenBoardLane.values.length;
        final laneWidth = math.max(_minLaneWidth, computedWidth);

        final laneList = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < KitchenBoardLane.values.length; i++) ...[
              if (i > 0) const SizedBox(width: KkfcSpace.s12),
              SizedBox(
                width: laneWidth,
                child: _buildLane(
                  KitchenBoardLane.values[i],
                  scrollable: hasBoundedHeight,
                ),
              ),
            ],
          ],
        );

        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            key: const ValueKey('kitchen-board-horizontal-scroll-view'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.all(KkfcSpace.s16),
            child: hasBoundedHeight
                ? SizedBox(
                    height: math.max(0.0, height - (KkfcSpace.s16 * 2)),
                    child: laneList,
                  )
                : laneList,
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
