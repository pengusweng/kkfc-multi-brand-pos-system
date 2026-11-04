import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';

KitchenPanelStateConfig buildQueuedPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'NEW ORDER · QUEUED',
    badgeColor: const Color(0xFF0284C7),
    headerBackgroundColor: Colors.white,
    title: 'Ticket ${context.rawNumber}',
    subtitle: 'Ready to acknowledge',
    confirmTitle: 'CONFIRM THE ORDER',
    confirmTitleColor: const Color(0xFF0284C7),
    confirmItems: const [
      'Check all items and modifiers',
      'Verify brand and destination',
    ],
    permissionNotice: 'Preparer permission requires Backend approval.',
    backLabel: 'Back to board',
    actionLabel: 'Acknowledge ticket',
    onBack: context.dismiss,
    onAction: context.onAcknowledge,
    isActionEnabled: context.ticket.isActionEnabled,
  );
}
