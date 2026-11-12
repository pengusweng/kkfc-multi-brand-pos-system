import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

/// Stepper indicator for the handover modal.
///
/// Adapts dynamically between standard tickets (2 steps: Check, Hand over)
/// and delivery tickets (3 steps: Check, Photo, Hand over).
class KitchenTicketHandoverStepper extends StatelessWidget {
  const KitchenTicketHandoverStepper({
    super.key,
    required this.isDelivery,
    required this.isChecklistComplete,
    required this.isPhotoAttached,
  });

  final bool isDelivery;
  final bool isChecklistComplete;
  final bool isPhotoAttached;

  @override
  Widget build(BuildContext context) {
    if (!isDelivery) {
      return _TwoStepStepper(isChecklistComplete: isChecklistComplete);
    }
    return _ThreeStepStepper(
      isChecklistComplete: isChecklistComplete,
      isPhotoAttached: isPhotoAttached,
    );
  }
}

class _TwoStepStepper extends StatelessWidget {
  const _TwoStepStepper({required this.isChecklistComplete});

  final bool isChecklistComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Step 1: Check
        _StepperPill(
          label: 'Check',
          stepNumber: '1',
          isCompleted: isChecklistComplete,
          isActive: !isChecklistComplete,
        ),
        const SizedBox(width: KkfcSpace.s12),
        const _StepperLine(),
        const SizedBox(width: KkfcSpace.s12),
        // Step 2: Hand over
        _StepperPill(
          label: 'Hand over',
          stepNumber: '2',
          isCompleted: false,
          isActive: isChecklistComplete,
        ),
      ],
    );
  }
}

class _ThreeStepStepper extends StatelessWidget {
  const _ThreeStepStepper({
    required this.isChecklistComplete,
    required this.isPhotoAttached,
  });

  final bool isChecklistComplete;
  final bool isPhotoAttached;

  @override
  Widget build(BuildContext context) {
    final isStep1Complete = isChecklistComplete;
    final isStep2Active = isChecklistComplete && !isPhotoAttached;
    final isStep2Complete = isChecklistComplete && isPhotoAttached;
    final isStep3Active = isChecklistComplete && isPhotoAttached;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Step 1: Check
        _StepperPill(
          label: 'Check',
          stepNumber: '1',
          isCompleted: isStep1Complete,
          isActive: !isStep1Complete,
        ),
        const SizedBox(width: KkfcSpace.s8),
        const _StepperLine(),
        const SizedBox(width: KkfcSpace.s8),

        // Step 2: Photo
        _StepperPill(
          label: 'Photo',
          stepNumber: '2',
          isCompleted: isStep2Complete,
          isActive: isStep2Active,
        ),
        const SizedBox(width: KkfcSpace.s8),
        const _StepperLine(),
        const SizedBox(width: KkfcSpace.s8),

        // Step 3: Hand over
        _StepperPill(
          label: 'Hand over',
          stepNumber: '3',
          isCompleted: false,
          isActive: isStep3Active,
        ),
      ],
    );
  }
}

class _StepperLine extends StatelessWidget {
  const _StepperLine();

  @override
  Widget build(BuildContext context) {
    return Container(width: 18, height: 1.5, color: KkfcColors.borderStrong);
  }
}

class _StepperPill extends StatelessWidget {
  const _StepperPill({
    required this.label,
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
  });

  final String label;
  final String stepNumber;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KkfcColors.successBg,
              border: Border.all(
                color: KkfcColors.success,
                width: KkfcBorderWidth.thick,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: KkfcColors.success,
            ),
          ),
          const SizedBox(width: KkfcSpace.s8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: KkfcTextSizes.textSm,
              fontWeight: KkfcFontWeights.bold,
              color: KkfcColors.ink,
            ),
          ),
        ],
      );
    }

    if (isActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: KkfcColors.ink,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: const TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 12,
                fontWeight: KkfcFontWeights.bold,
                color: KkfcColors.onSolid,
              ),
            ),
          ),
          const SizedBox(width: KkfcSpace.s8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: KkfcTextSizes.textSm,
              fontWeight: KkfcFontWeights.bold,
              color: KkfcColors.ink,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: KkfcColors.ticketMuted, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 12,
              fontWeight: KkfcFontWeights.bold,
              color: KkfcColors.ticketMuted,
            ),
          ),
        ),
        const SizedBox(width: KkfcSpace.s8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: KkfcFonts.ibmPlexSans,
            fontSize: KkfcTextSizes.textSm,
            fontWeight: KkfcFontWeights.medium,
            color: KkfcColors.ticketMuted,
          ),
        ),
      ],
    );
  }
}
