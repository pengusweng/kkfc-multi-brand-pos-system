import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/cart_step_view.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/confirmation_step_view.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_details_step_view.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_flow_header.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_flow_stepper.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/review_order_step_view.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/new_order/providers/order_draft_provider.dart';
import 'package:mobile/shared/widgets/app_header.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

/// The mobile multi-step order flow screen.
/// Ready for multiple steps (Order, Details, Payment, Confirm) without rerouting.
class MobileOrderFlowScreen extends ConsumerStatefulWidget {
  const MobileOrderFlowScreen({super.key, this.initialStep = 2});

  final int initialStep;

  @override
  ConsumerState<MobileOrderFlowScreen> createState() =>
      _MobileOrderFlowScreenState();
}

class _MobileOrderFlowScreenState extends ConsumerState<MobileOrderFlowScreen> {
  late int _currentStep = widget.initialStep;

  void _onBack() {
    if (_currentStep > 2) {
      setState(() => _currentStep--);
    } else {
      _closeFlow();
    }
  }

  void _closeFlow() {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _onClearOrder() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear order?'),
        content: const Text(
          'This will remove all items from your current order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        ref.read(cartProvider.notifier).clear();
        ref.read(orderReferenceProvider.notifier).clear();
        ref.read(activeOrderDraftProvider.notifier).clear();
        ref.read(clientOrderIdProvider.notifier).regenerate();
        _closeFlow();
      }
    });
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 2:
        return 'Current order';
      case 3:
        return 'Order details';
      case 4:
        return 'Review order';
      case 5:
        return 'Confirmation';
      default:
        return 'Current order';
    }
  }

  @override
  Widget build(BuildContext context) {
    return KkfcScaffold(
      body: Column(
        children: [
          // Navy App Header: "Orders" with Cashier Staff dropdown
          const AppHeader(title: 'Orders', compact: true),

          // Sub-header: [< Back] Current order [Clear] (hidden on final Sent step)
          if (_currentStep < 5) ...[
            OrderFlowHeader(
              title: _stepTitle,
              onBack: _onBack,
              onClear: _onClearOrder,
              showClear: _currentStep == 2,
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEDE8DF)),
          ],

          // Stepper: (✓) —— (2) Order —— (3) —— (4) —— (5)
          OrderFlowStepper(
            currentStep: _currentStep,
            onStepTapped: (step) {
              if (step >= 2 && step <= 5) {
                setState(() => _currentStep = step);
              } else if (step == 1) {
                _closeFlow();
              }
            },
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFEDE8DF)),

          // Step Body with smooth slide & fade animation
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: _buildCurrentStepView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 2:
        return KeyedSubtree(
          key: const ValueKey('step-2-cart'),
          child: CartStepView(
            onContinue: () => setState(() => _currentStep = 3),
            onReturnToMenu: _closeFlow,
          ),
        );
      case 3:
        return KeyedSubtree(
          key: const ValueKey('step-3-details'),
          child: OrderDetailsStepView(
            onContinue: () => setState(() => _currentStep = 4),
          ),
        );
      case 4:
        return KeyedSubtree(
          key: const ValueKey('step-4-review'),
          child: ReviewOrderStepView(
            onConfirm: () {
              setState(() => _currentStep = 5);
            },
            onCancelOrder: () {
              ref.read(cartProvider.notifier).clear();
              ref.read(orderReferenceProvider.notifier).clear();
              ref.read(activeOrderDraftProvider.notifier).clear();
              ref.read(clientOrderIdProvider.notifier).regenerate();
              _closeFlow();
            },
          ),
        );
      case 5:
        return KeyedSubtree(
          key: const ValueKey('step-5-confirm'),
          child: ConfirmationStepView(
            onDone: () {
              ref.read(cartProvider.notifier).clear();
              _closeFlow();
            },
            onCancelOrder: () {
              ref.read(cartProvider.notifier).clear();
            },
          ),
        );
      default:
        return KeyedSubtree(
          key: const ValueKey('step-default'),
          child: CartStepView(
            onContinue: () => setState(() => _currentStep = 3),
            onReturnToMenu: _closeFlow,
          ),
        );
    }
  }
}
