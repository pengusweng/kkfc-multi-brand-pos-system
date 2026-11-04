import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildPreparingPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'COOKING · PREPARING',
    badgeColor: const Color(0xFFD97706),
    headerBackgroundColor: const Color(0xFFFDF6EE),
    title: 'Prepare ${context.rawNumber}',
    subtitle: 'Cooking in progress',
    confirmTitle: 'PREPARATION CHECK',
    confirmTitleColor: const Color(0xFFD97706),
    confirmItems: const [
      '2 × Paa Inasal · extra rice',
      '1 × Pecho Inasal · no onions',
    ],
    permissionNotice: 'Next approved transition is CHECKING.',
    statusOverride: KkfcStatus.preparing,
    backLabel: 'Keep preparing',
    actionLabel: 'Send to QC',
    onBack: context.dismiss,
    onAction: context.onSendToQC,
    isActionEnabled: context.ticket.isActionEnabled,
  );
}
