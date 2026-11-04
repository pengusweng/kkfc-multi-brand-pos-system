import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildReworkRequiredPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'REWORKING',
    badgeColor: const Color(0xFF7C3AED),
    headerBackgroundColor: const Color(0xFFF7F3FD),
    topAccentColor: const Color(0xFF7C3AED),
    title: 'Rework required',
    subtitle: 'Correct the failed order',
    confirmTitle: 'REWORK CHECKLIST',
    confirmTitleColor: const Color(0xFF7C3AED),
    confirmItems: const ['Fix the QC issue', 'Submit for another QC check'],
    permissionNotice: 'Never skip directly to READY.',
    statusOverride: KkfcStatus.reworking,
    backLabel: 'Back to board',
    actionLabel: 'Return to QC',
    onBack: context.onBackToKitchenBoard ?? context.onBack ?? context.dismiss,
    onAction: context.onReturnToQC ?? context.onAcknowledge,
    isActionEnabled: true,
  );
}
