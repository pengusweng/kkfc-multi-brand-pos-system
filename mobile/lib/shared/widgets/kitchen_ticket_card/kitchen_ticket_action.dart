import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// Primary kitchen action for each status. Null means no action button.
String? kitchenTicketActionLabel(KkfcStatus status) => switch (status) {
  KkfcStatus.queued => 'Take ticket',
  KkfcStatus.acknowledged => 'Start Preparing',
  KkfcStatus.preparing => 'Send to QC',
  KkfcStatus.checking => 'QC check',
  KkfcStatus.reworking => 'View rework',
  KkfcStatus.ready => 'Hand over',
  _ => null,
};
