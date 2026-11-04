import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_ticket_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/acknowledged_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/dispatcher_check_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/handover_complete_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/missing_qc_reason_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/photo_preview_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/photo_required_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/preparing_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/qc_failure_reason_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/quality_check_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/queued_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/ready_for_dispatch_panel_state.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/rework_required_panel_state.dart';

/// Resolves the presentation config for the requested panel state.
KitchenPanelStateConfig resolveKitchenPanelState(
  KitchenTicketPanelState state,
  KitchenPanelStateContext context,
) {
  return switch (state) {
    KitchenTicketPanelState.queued => buildQueuedPanelState(context),
    KitchenTicketPanelState.acknowledged => buildAcknowledgedPanelState(
      context,
    ),
    KitchenTicketPanelState.preparing => buildPreparingPanelState(context),
    KitchenTicketPanelState.qualityCheck => buildQualityCheckPanelState(
      context,
    ),
    KitchenTicketPanelState.qcFailureReason => buildQcFailureReasonPanelState(
      context,
    ),
    KitchenTicketPanelState.missingQCReason => buildMissingQcReasonPanelState(
      context,
    ),
    KitchenTicketPanelState.reworkRequired => buildReworkRequiredPanelState(
      context,
    ),
    KitchenTicketPanelState.readyForDispatch => buildReadyForDispatchPanelState(
      context,
    ),
    KitchenTicketPanelState.photoRequired => buildPhotoRequiredPanelState(
      context,
    ),
    KitchenTicketPanelState.photoPreview => buildPhotoPreviewPanelState(
      context,
    ),
    KitchenTicketPanelState.dispatcherCheck => buildDispatcherCheckPanelState(
      context,
    ),
    KitchenTicketPanelState.handoverComplete => buildHandoverCompletePanelState(
      context,
    ),
  };
}
