import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app/theme/typography.dart';

class OrderFlowStepItem {
  const OrderFlowStepItem({required this.stepNumber, required this.label});

  final int stepNumber;
  final String label;
}

/// Stepper bar matching the visual design:
/// `[✓] —— [2] Order —— [3] —— [4] —— [5]`
class OrderFlowStepper extends StatelessWidget {
  const OrderFlowStepper({
    super.key,
    required this.currentStep,
    this.onStepTapped,
    this.steps = const [
      OrderFlowStepItem(stepNumber: 1, label: 'Menu'),
      OrderFlowStepItem(stepNumber: 2, label: 'Order'),
      OrderFlowStepItem(stepNumber: 3, label: 'Details'),
      OrderFlowStepItem(stepNumber: 4, label: 'Payment'),
      OrderFlowStepItem(stepNumber: 5, label: 'Confirm'),
    ],
  });

  final int currentStep;
  final ValueChanged<int>? onStepTapped;
  final List<OrderFlowStepItem> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 22.0,
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    color: const Color(0xFFCBD5E1),
                  ),
                _buildStep(steps[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(OrderFlowStepItem step) {
    final isCompleted = step.stepNumber < currentStep;
    final isActive = step.stepNumber == currentStep;

    Widget indicator;

    if (isCompleted) {
      indicator = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F4E9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFA3D9B5), width: 1.0),
        ),
        child: const Center(
          child: Icon(Icons.check, size: 14, color: Color(0xFF166B3A)),
        ),
      );
    } else if (isActive) {
      indicator = Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF19293E),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${step.stepNumber}',
            style: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      indicator = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF76849A), width: 1.5),
        ),
        child: Center(
          child: Text(
            '${step.stepNumber}',
            style: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF586579),
            ),
          ),
        ),
      );
    }

    final canTap = isCompleted && onStepTapped != null;

    return InkWell(
      key: ValueKey('step-${step.stepNumber}'),
      borderRadius: BorderRadius.circular(16.0),
      onTap: canTap
          ? () {
              HapticFeedback.selectionClick();
              onStepTapped!(step.stepNumber);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator,
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                step.label,
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF19293E),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
