import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildPhotoPreviewPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'PHOTO EVIDENCE · PREVIEW',
    badgeColor: const Color(0xFF0284C7),
    headerBackgroundColor: Colors.white,
    title: 'Review attachment',
    subtitle: 'Illustrative local preview · not uploaded',
    confirmTitle: 'ATTACHMENT PREVIEW · SAMPLE',
    confirmTitleColor: const Color(0xFF16A34A),
    confirmItems: const [
      'Photo selected for this ticket (demo)',
      'Confirm the correct order and contents',
    ],
    showCheckIcon: false,
    permissionNotice: 'Preview alone does not persist evidence.',
    statusOverride: KkfcStatus.ready,
    backLabel: 'Retake photo',
    actionLabel: 'Submit photo (demo)',
    onBack: context.onRetakePhoto ?? context.onBack ?? context.dismiss,
    onAction: context.onSubmitPhoto ?? context.onAcknowledge,
    isActionEnabled: context.ticket.isActionEnabled,
  );
}
