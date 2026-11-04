/// Available presentation states for the ticket detail panel.
enum KitchenTicketPanelState {
  /// Initial queued state (02 · Queued Ticket).
  queued,

  /// Acknowledged state (03 · Acknowledge Ticket).
  acknowledged,

  /// In-progress preparation state (04 · Preparation).
  preparing,

  /// Quality check / inspection state (05 · Quality Check).
  qualityCheck,

  /// QC failure reason record state (06 · QC Failure Reason).
  qcFailureReason,

  /// Missing QC reason state when QC is failed without a reason (07 · Missing QC Reason).
  missingQCReason,

  /// Rework required state after QC failure (08 · Reworking).
  reworkRequired,

  /// Ready for dispatch / outgoing check state (09 · Ready for Dispatch).
  readyForDispatch,

  /// Photo missing / required state (18 · Photo Missing).
  photoRequired,

  /// Photo preview / attachment review state (19 · Photo Preview).
  photoPreview,

  /// Dispatcher final check / confirm handover state (10 · Dispatcher Check).
  dispatcherCheck,

  /// Handover completed / final release state (11 · Handover Completed).
  handoverComplete,
}
