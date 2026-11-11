import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/providers/kitchen_board_providers.dart';

/// Modal dialog presented when a ticket has successfully been handed over.
///
/// Matches the reference design showing a circular green checkmark,
/// confirmation message, and "Back to board" action button.
class HandedOverSuccessDialog extends StatelessWidget {
  const HandedOverSuccessDialog({
    super.key,
    required this.ticket,
    this.handedOverAtLabel,
    this.onDismiss,
  });

  final KitchenBoardTicket ticket;
  final String? handedOverAtLabel;
  final VoidCallback? onDismiss;

  static const double maxDialogWidth = 420.0;

  @override
  Widget build(BuildContext context) {
    final effectiveTime =
        handedOverAtLabel ?? KitchenBoardState.formatTimeOfDay(DateTime.now());
    final ticketNumber = ticket.data.ticketNumber;

    return Dialog(
      backgroundColor: KkfcColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: KkfcSpace.s24,
        vertical: KkfcSpace.s24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KkfcRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxDialogWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KkfcSpace.s24,
            KkfcSpace.s32,
            KkfcSpace.s24,
            KkfcSpace.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular success icon
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KkfcColors.surface,
                  border: Border.all(color: KkfcColors.success, width: 3.0),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  size: 38,
                  color: KkfcColors.success,
                ),
              ),
              const SizedBox(height: KkfcSpace.s20),

              // Title
              const Text(
                'Handed over',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.text2xl,
                  fontWeight: KkfcFontWeights.bold,
                  color: KkfcColors.ink,
                ),
              ),
              const SizedBox(height: KkfcSpace.s8),

              // Subtitle
              Text(
                '$ticketNumber was handed over at $effectiveTime. It is no longer on the board.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textBase,
                  fontWeight: KkfcFontWeights.regular,
                  color: KkfcColors.ink2,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: KkfcSpace.s24),

              // Back to board button
              SizedBox(
                width: double.infinity,
                height: KkfcSizing.controlMd,
                child: FilledButton(
                  key: const ValueKey('handed-over-back-to-board-button'),
                  onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: KkfcColors.action,
                    foregroundColor: KkfcColors.onSolid,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KkfcRadius.sm),
                    ),
                  ),
                  child: const Text(
                    'Back to board',
                    style: TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: KkfcTextSizes.textBase,
                      fontWeight: KkfcFontWeights.bold,
                      color: KkfcColors.onSolid,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays the [HandedOverSuccessDialog] in a modal barrier.
Future<void> showHandedOverSuccessDialog(
  BuildContext context, {
  required KitchenBoardTicket ticket,
  String? handedOverAtLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: KkfcColors.ink.withValues(alpha: KkfcOpacity.scrim),
    builder: (dialogContext) => HandedOverSuccessDialog(
      ticket: ticket,
      handedOverAtLabel: handedOverAtLabel,
      onDismiss: () => Navigator.of(dialogContext).pop(),
    ),
  );
}
