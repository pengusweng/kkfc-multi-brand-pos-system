import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/user_role.dart';
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
    this.userRole,
    this.canPassQc = true,
    this.onTicketAction,
    this.onTicketDetails,
    this.scrollable = true,
  });

  final KitchenBoardLane lane;
  final List<KitchenBoardTicket> tickets;
  final Set<String> loadingTicketIds;
  final UserRole? userRole;
  final bool canPassQc;
  final ValueChanged<KitchenBoardTicket>? onTicketAction;
  final ValueChanged<KitchenBoardTicket>? onTicketDetails;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Widget body;
    if (tickets.isEmpty) {
      body = Padding(
        key: ValueKey('lane-empty-${lane.name}'),
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
          _AnimatedTicketEntry(
            key: ValueKey('ticket-entry-${tickets[i].kitchenTicketId}'),
            index: i,
            child: _buildTicketCard(tickets[i]),
          ),
        ],
      ];

      body = scrollable
          ? ListView(
              key: ValueKey('lane-list-${lane.name}'),
              padding: const EdgeInsets.all(10.0),
              children: cards,
            )
          : Padding(
              key: ValueKey('lane-column-${lane.name}'),
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cards,
              ),
            );
    }

    final animatedBody = AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : KkfcMotion.durLayout,
      reverseDuration: reduceMotion ? Duration.zero : KkfcMotion.durExit,
      switchInCurve: KkfcMotion.easeOut,
      switchOutCurve: KkfcMotion.easeIn,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previousChildren,
          ?currentChild,
        ],
      ),
      child: body,
    );

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
          if (scrollable)
            Expanded(child: animatedBody)
          else
            AnimatedSize(
              duration: reduceMotion ? Duration.zero : KkfcMotion.durLayout,
              curve: KkfcMotion.easeMove,
              alignment: Alignment.topCenter,
              child: animatedBody,
            ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(KitchenBoardTicket boardTicket) {
    final actionLabel = lane.actionLabelFor(boardTicket.data.status);
    final isQcLane = lane == KitchenBoardLane.qcCheck ||
        boardTicket.data.status == KkfcStatus.checking ||
        boardTicket.rawStatus.toUpperCase() == 'FOR_CHECKING' ||
        boardTicket.rawStatus.toUpperCase() == 'CHECKING';
    final isActionEnabled = userRole != null
        ? userRole!.canChangeTicketStatus(isQcCheck: isQcLane)
        : (!isQcLane || canPassQc);
    final isLoading = loadingTicketIds.contains(boardTicket.kitchenTicketId);

    return KitchenTicketCard.board(
      key: ValueKey('kitchen-ticket-card-${boardTicket.data.ticketNumber}'),
      ticket: boardTicket.data,
      actionLabel: actionLabel,
      isActionEnabled: isActionEnabled,
      isActionLoading: isLoading,
      onAction: isActionEnabled && onTicketAction != null
          ? () => onTicketAction!(boardTicket)
          : null,
      onDetails: onTicketDetails != null
          ? () => onTicketDetails!(boardTicket)
          : null,
    );
  }
}

/// Animates each kitchen ticket card into its lane with a staggered `18ms`
/// offset (capped at [KkfcMotion.staggerMaxRows]) and a subtle `6px` vertical
/// rise ([KkfcMotion.peerOffset]) over [KkfcMotion.durLayout] (`320ms`).
class _AnimatedTicketEntry extends StatefulWidget {
  const _AnimatedTicketEntry({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AnimatedTicketEntry> createState() => _AnimatedTicketEntryState();
}

class _AnimatedTicketEntryState extends State<_AnimatedTicketEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _translateY;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    final staggerDelayMs = widget.index.clamp(0, KkfcMotion.staggerMaxRows) *
        KkfcMotion.stagger.inMilliseconds;
    final totalDurationMs =
        KkfcMotion.durLayout.inMilliseconds + staggerDelayMs;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDurationMs),
    );
    final delayFraction =
        staggerDelayMs / totalDurationMs.toDouble();
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delayFraction.clamp(0.0, 0.75),
        1.0,
        curve: KkfcMotion.easeOut,
      ),
    );
    final springCurved = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delayFraction.clamp(0.0, 0.75),
        1.0,
        curve: KkfcMotion.easeSpring,
      ),
    );
    _fade = curved;
    _translateY = Tween<double>(
      begin: KkfcMotion.peerOffset,
      end: 0.0,
    ).animate(curved);
    _scale = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(springCurved);
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
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
