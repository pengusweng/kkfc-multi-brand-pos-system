import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildAcknowledgedPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'ACKNOWLEDGED',
    badgeColor: const Color(0xFF0284C7),
    headerBackgroundColor: Colors.white,
    title: 'Begin preparation',
    subtitle: 'Ticket claimed by kitchen staff',
    confirmTitle: 'START COOKING',
    confirmTitleColor: const Color(0xFF0284C7),
    confirmItems: const [
      'Review quantities and modifiers',
      'Begin preparation when ready',
    ],
    permissionNotice: 'Server must confirm the next status.',
    statusOverride: KkfcStatus.acknowledged,
    backLabel: context.isTablet ? 'Stay acknowledged' : 'Stay here',
    actionLabel: 'Begin preparation',
    onBack: context.dismiss,
    onAction: context.onBeginPreparation ?? context.onAcknowledge,
    isActionEnabled: context.ticket.isActionEnabled,
  );
}
