import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildReadyForDispatchPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'READY · OUTGOING CHECK',
    badgeColor: const Color(0xFF16A34A),
    headerBackgroundColor: const Color(0xFFF0FAF4),
    topAccentColor: const Color(0xFF16A34A),
    title: 'Outgoing check',
    subtitle: 'Dispatcher final review',
    confirmTitle: 'DISPATCHER CHECK',
    confirmTitleColor: const Color(0xFF16A34A),
    confirmItems: const [
      'Confirm packing and destination',
      'Review photo evidence rule',
    ],
    permissionNotice: 'Dispatcher authorization and photo policy pending.',
    statusOverride: KkfcStatus.ready,
    backLabel: 'Keep READY',
    actionLabel: 'Continue to handover',
    onBack: context.dismiss,
    onAction: context.onContinueToHandover,
    isActionEnabled: context.ticket.isActionEnabled,
  );
}
