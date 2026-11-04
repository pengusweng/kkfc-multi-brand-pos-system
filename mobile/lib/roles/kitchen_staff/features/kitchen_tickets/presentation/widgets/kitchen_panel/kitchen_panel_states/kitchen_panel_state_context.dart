import 'package:flutter/material.dart';
import 'package:mobile/roles/kitchen_staff/features/kitchen_tickets/data/models/kitchen_board_sample_data.dart';

/// Runtime inputs shared by every per-state panel config builder.
class KitchenPanelStateContext {
  const KitchenPanelStateContext({
    required this.isTablet,
    required this.ticket,
    required this.rawNumber,
    required this.dismiss,
    this.onClose,
    this.onBack,
    this.onAcknowledge,
    this.onBeginPreparation,
    this.onSendToQC,
    this.onPassQC,
    this.onFailQC,
    this.onBackToQC,
    this.onUseSampleReason,
    this.onSubmitReason,
    this.onTestBlankReason,
    this.onConfirmQCFail,
    this.failureReasonText,
    this.onReturnToQC,
    this.onContinueToHandover,
    this.onAddPhoto,
    this.onRetakePhoto,
    this.onSubmitPhoto,
    this.onConfirmHandover,
    this.onNotYet,
    this.onBackToKitchenBoard,
    this.onHistoryPending,
    this.reasonController,
    this.onReasonChanged,
    this.reasonPlaceholder,
  });

  final bool isTablet;
  final KitchenBoardItem ticket;
  final String rawNumber;
  final VoidCallback dismiss;

  final VoidCallback? onClose;
  final VoidCallback? onBack;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onBeginPreparation;
  final VoidCallback? onSendToQC;
  final VoidCallback? onPassQC;
  final VoidCallback? onFailQC;
  final VoidCallback? onBackToQC;
  final VoidCallback? onUseSampleReason;
  final VoidCallback? onSubmitReason;
  final VoidCallback? onTestBlankReason;
  final VoidCallback? onConfirmQCFail;
  final String? failureReasonText;
  final VoidCallback? onReturnToQC;
  final VoidCallback? onContinueToHandover;
  final VoidCallback? onAddPhoto;
  final VoidCallback? onRetakePhoto;
  final VoidCallback? onSubmitPhoto;
  final VoidCallback? onConfirmHandover;
  final VoidCallback? onNotYet;
  final VoidCallback? onBackToKitchenBoard;
  final VoidCallback? onHistoryPending;

  final TextEditingController? reasonController;
  final ValueChanged<String>? onReasonChanged;
  final String? reasonPlaceholder;
}
