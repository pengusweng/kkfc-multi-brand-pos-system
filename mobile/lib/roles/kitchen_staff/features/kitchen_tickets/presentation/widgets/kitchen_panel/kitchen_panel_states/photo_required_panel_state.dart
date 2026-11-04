import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildPhotoRequiredPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'PHOTO MISSING · BLOCKED',
    badgeColor: const Color(0xFF0284C7),
    headerBackgroundColor: Colors.white,
    title: 'Photo required',
    subtitle: 'Handover remains unavailable',
    confirmTitle: 'REQUIRED EVIDENCE MISSING',
    confirmTitleColor: const Color(0xFF16A34A),
    confirmItems: const [
      'Add an authorized pre-handover photo',
      'Ticket stays READY until verified',
    ],
    showCheckIcon: false,
    permissionNotice: 'No completion is implied by missing evidence.',
    statusOverride: KkfcStatus.ready,
    backLabel: 'Keep READY',
    actionLabel: 'Add photo',
    onBack: context.dismiss,
    onAction: context.onAddPhoto ?? context.onAcknowledge,
    isActionEnabled: context.ticket.isActionEnabled,
  );
}
