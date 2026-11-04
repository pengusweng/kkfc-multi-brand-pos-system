import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildDispatcherCheckPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'HANDOVER',
    badgeColor: const Color(0xFF16A34A),
    headerBackgroundColor: const Color(0xFFF0FAF4),
    topAccentColor: const Color(0xFF16A34A),
    title: 'Confirm handover',
    subtitle: 'Record final order release',
    confirmTitle: 'PRE-HANDOVER CHECK',
    confirmTitleColor: const Color(0xFF16A34A),
    confirmItems: const [
      'Correct order and recipient',
      'Check approved photo requirement',
    ],
    permissionNotice: 'Dispatcher authorization and photo policy pending.',
    statusOverride: KkfcStatus.ready,
    backLabel: 'Not yet',
    actionLabel: 'Confirm handover',
    onBack: context.onNotYet ?? context.onBack ?? context.dismiss,
    onAction: context.onConfirmHandover ?? context.onAcknowledge,
    isActionEnabled: context.ticket.isActionEnabled,
  );
}
