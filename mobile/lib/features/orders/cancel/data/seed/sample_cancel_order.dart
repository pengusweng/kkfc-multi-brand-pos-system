import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';

/// Demo fixture for the cancel-order screens matching design specs.
const sampleCancelOrder = CancelOrderTicket(
  number: 'T-017',
  brandName: "Aurelia's Inasal",
  staffName: 'Cashier Staff',
  staffRole: 'Cashier Staff',
  currentStage: 'Queued · preparation not started',
  kitchenStage: 'Queued · preparation not started',
  maxReasonLength: 280,
);

/// Prefilled reason from design.
const sampleCancellationReason = 'Duplicate entry at counter';
