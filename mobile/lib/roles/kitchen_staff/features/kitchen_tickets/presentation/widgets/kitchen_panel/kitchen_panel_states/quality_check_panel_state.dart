import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildQualityCheckPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'QC · CHECKER AUTHORIZATION PENDING',
    badgeColor: const Color(0xFF7C3AED),
    headerBackgroundColor: const Color(0xFFF7F3FD),
    topAccentColor: const Color(0xFF7C3AED),
    title: 'Inspect ${context.rawNumber}',
    subtitle: 'Verify the prepared order',
    confirmTitle: 'QUALITY CHECKLIST',
    confirmTitleColor: const Color(0xFF7C3AED),
    confirmItems: const [
      'Quantities and modifiers match',
      'Packaging and destination correct',
    ],
    permissionNotice:
        'QC action shown as demo; approved checker rights required.',
    statusOverride: KkfcStatus.checking,
    backLabel: 'Pass QC',
    actionLabel: 'Fail QC',
    onBack: context.dismiss,
    onAction: context.onFailQC,
    isQC: true,
    isActionEnabled: context.ticket.isActionEnabled,
  );
}
