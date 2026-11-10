import 'package:flutter/material.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_handover_body.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_handover_footer.dart';

/// Stateful coordinator for the Handover modal workflow.
///
/// Ensures the user cannot press `Confirm handover` until all 3 outgoing
/// checklist items have been ticked.
class KitchenTicketHandoverView extends StatefulWidget {
  const KitchenTicketHandoverView({
    super.key,
    required this.ticket,
    required this.isActionLoading,
    required this.onHandover,
  });

  final KitchenBoardTicket ticket;
  final bool isActionLoading;
  final VoidCallback? onHandover;

  @override
  State<KitchenTicketHandoverView> createState() =>
      _KitchenTicketHandoverViewState();
}

class _KitchenTicketHandoverViewState extends State<KitchenTicketHandoverView> {
  final Map<HandoverCheckItem, bool> _checklist = {
    for (final item in HandoverCheckItem.values) item: false,
  };

  bool get _allChecked =>
      HandoverCheckItem.values.every((item) => _checklist[item] == true);

  void _handleToggle(HandoverCheckItem item) {
    setState(() {
      _checklist[item] = !(_checklist[item] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: KitchenTicketHandoverBody(
            ticket: widget.ticket,
            checklist: _checklist,
            onToggleItem: _handleToggle,
          ),
        ),
        KitchenTicketHandoverFooter(
          isChecklistComplete: _allChecked,
          isActionLoading: widget.isActionLoading,
          onConfirmHandover: _allChecked ? widget.onHandover : null,
        ),
      ],
    );
  }
}
