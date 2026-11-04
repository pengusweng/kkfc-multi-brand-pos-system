import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_config.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/presentation/widgets/kitchen_panel/kitchen_panel_states/kitchen_panel_state_context.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

KitchenPanelStateConfig buildQcFailureReasonPanelState(
  KitchenPanelStateContext context,
) {
  return KitchenPanelStateConfig(
    badgeText: 'QC · CHECKER AUTHORIZATION PENDING',
    badgeColor: const Color(0xFF7C3AED),
    headerBackgroundColor: const Color(0xFFF7F3FD),
    topAccentColor: const Color(0xFF7C3AED),
    title: 'Record QC failure',
    subtitle: 'Reason required for rework',
    confirmTitle: 'QC FAILURE REASON *',
    confirmTitleColor: const Color(0xFF7C3AED),
    confirmItems: const [
      'Sample: missing requested modifier',
      'Try blank to test error state',
    ],
    footer: _QcFailureReasonBox(context: context),
    permissionNotice:
        'QC action shown as demo; approved checker rights required.',
    statusOverride: KkfcStatus.checking,
    backLabel: 'Test blank reason',
    actionLabel: 'Confirm QC fail',
    onBack: context.onTestBlankReason ?? context.onBack ?? context.dismiss,
    onAction: context.onConfirmQCFail ?? context.onAcknowledge,
    isActionEnabled: true,
  );
}

class _QcFailureReasonBox extends StatelessWidget {
  const _QcFailureReasonBox({required this.context});

  final KitchenPanelStateContext context;

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      key: const ValueKey('kitchen_panel_qc_failure_reason_box'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Text(
        context.failureReasonText ??
            (context.reasonController?.text.trim().isNotEmpty == true
                ? context.reasonController!.text.trim()
                : 'Missing requested modifier'),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
