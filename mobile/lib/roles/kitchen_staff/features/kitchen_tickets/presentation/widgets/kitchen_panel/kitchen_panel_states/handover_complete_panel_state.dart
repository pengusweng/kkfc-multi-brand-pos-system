import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildHandoverCompletePanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'HANDED OVER',
    badgeColor: const Color(0xFF16A34A),
    headerBackgroundColor: const Color(0xFFF0FAF4),
    topAccentColor: const Color(0xFF16A34A),
    title: 'Handover complete',
    subtitle: 'Illustrative successful state',
    confirmTitle: 'FINAL STATE',
    confirmTitleColor: const Color(0xFF16A34A),
    confirmItems: const [
      'Ticket handed over in prototype',
      'Payment remains independent',
    ],
    permissionNotice: 'Backend confirmation still required.',
    statusOverride: KkfcStatus.handedOver,
    backLabel: 'History (pending)',
    actionLabel: 'Back to Kitchen Board',
    onBack: context.onHistoryPending ?? context.onBack ?? () {},
    onAction:
        context.onBackToKitchenBoard ?? context.onClose ?? context.dismiss,
    isActionEnabled: true,
  );
}
