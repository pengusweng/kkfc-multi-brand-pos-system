import 'package:flutter/material.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_qc_dialog_body.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_qc_dialog_footer.dart';

/// Stateful coordinator for Quality Check modal workflow.
///
/// Enforces that the QC checker must explicitly click `Pass` on every item
/// in the ticket before the `All items passed` CTA activates.
class KitchenTicketQcView extends StatefulWidget {
  const KitchenTicketQcView({
    super.key,
    required this.ticket,
    required this.isActionLoading,
    required this.isActionEnabled,
    required this.onPass,
    this.onFail,
  });

  final KitchenBoardTicket ticket;
  final bool isActionLoading;
  final bool isActionEnabled;
  final VoidCallback? onPass;
  final VoidCallback? onFail;

  @override
  State<KitchenTicketQcView> createState() => _KitchenTicketQcViewState();
}

class _KitchenTicketQcViewState extends State<KitchenTicketQcView> {
  final Map<int, bool> _decisions = {};

  bool get _allPassed {
    final items = widget.ticket.data.items;
    if (items.isEmpty) return false;
    if (_decisions.length != items.length) return false;
    return _decisions.values.every((passed) => passed == true);
  }

  void _handleDecisionChanged(int index, bool passed) {
    setState(() {
      _decisions[index] = passed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPassAll = widget.isActionEnabled && _allPassed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: KitchenTicketQcDialogBody(
            ticket: widget.ticket,
            decisions: _decisions,
            onDecisionChanged: _handleDecisionChanged,
          ),
        ),
        KitchenTicketQcDialogFooter(
          isActionLoading: widget.isActionLoading,
          isActionEnabled: canPassAll,
          onPass: canPassAll ? widget.onPass : null,
          onFail: widget.onFail,
        ),
      ],
    );
  }
}
