import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';

/// Modal dialog presented when a QC checker clicks "Fail QC and rework".
///
/// Collects a mandatory rejection reason (up to 280 characters), sends it to
/// `POST /api/kitchen-fulfillment/qc-attempts/{attemptId}/reject`, and moves
/// the ticket back to the Preparing lane under `REWORKING` status at the top
/// of the column.
class FailQcSendToReworkDialog extends ConsumerStatefulWidget {
  const FailQcSendToReworkDialog({
    super.key,
    required this.ticket,
    this.onConfirm,
    this.onCancel,
  });

  final KitchenBoardTicket ticket;
  final Future<bool> Function(String reason)? onConfirm;
  final VoidCallback? onCancel;

  static const double maxDialogWidth = 480.0;
  static const int maxReasonLength = 280;

  @override
  ConsumerState<FailQcSendToReworkDialog> createState() =>
      _FailQcSendToReworkDialogState();
}

class _FailQcSendToReworkDialogState
    extends ConsumerState<FailQcSendToReworkDialog> {
  late final TextEditingController _controller;
  bool _showError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged(String value) {
    if (_showError) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty &&
          trimmed.length <= FailQcSendToReworkDialog.maxReasonLength) {
        setState(() {
          _showError = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty ||
        text.length > FailQcSendToReworkDialog.maxReasonLength) {
      setState(() {
        _showError = true;
      });
      return;
    }

    setState(() {
      _showError = false;
      _isSubmitting = true;
    });

    final bool success;
    if (widget.onConfirm != null) {
      success = await widget.onConfirm!(text);
    } else {
      // Static behavior: do nothing to the ticket and simply close the dialog.
      success = true;
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _showError;

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
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: FailQcSendToReworkDialog.maxDialogWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(KkfcSpace.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Title
              const Text(
                'Fail QC and send to rework',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textXl,
                  fontWeight: KkfcFontWeights.bold,
                  color: KkfcColors.ink,
                ),
              ),
              const SizedBox(height: KkfcSpace.s8),

              // 2. Subtitle
              const Text(
                'Say what the kitchen needs to correct. The ticket moves to Rework in the Preparing lane.',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textBase,
                  fontWeight: KkfcFontWeights.regular,
                  color: KkfcColors.ink2,
                  height: 1.35,
                ),
              ),

              // 3. Validation Error Banner
              if (hasError) ...[
                const SizedBox(height: KkfcSpace.s16),
                Container(
                  key: const ValueKey('fail-qc-error-banner'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: KkfcSpace.s12,
                    vertical: KkfcSpace.s8,
                  ),
                  decoration: BoxDecoration(
                    color: KkfcColors.dangerBg,
                    border: Border.all(
                      color: KkfcColors.dangerBorder,
                      width: KkfcBorderWidth.thin,
                    ),
                    borderRadius: BorderRadius.circular(KkfcRadius.sm),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: KkfcColors.danger,
                      ),
                      SizedBox(width: KkfcSpace.s8),
                      Expanded(
                        child: Text(
                          'Enter a reason (up to 280 characters).',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textSm,
                            fontWeight: KkfcFontWeights.medium,
                            color: KkfcColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: KkfcSpace.s16),

              // 4. Reason Label
              const Text(
                'Reason',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textSm,
                  fontWeight: KkfcFontWeights.semiBold,
                  color: KkfcColors.ink,
                ),
              ),
              const SizedBox(height: KkfcSpace.s8),

              // 5. Multi-line Text Area
              TextField(
                key: const ValueKey('fail-qc-reason-field'),
                controller: _controller,
                onChanged: _handleTextChanged,
                minLines: 4,
                maxLines: 5,
                maxLength: FailQcSendToReworkDialog.maxReasonLength,
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) =>
                    null,
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textBase,
                  color: KkfcColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'For example: under-cooked, missing sauce',
                  hintStyle: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: KkfcTextSizes.textBase,
                    fontWeight: KkfcFontWeights.regular,
                    color: KkfcColors.ink3,
                  ),
                  contentPadding: const EdgeInsets.all(KkfcSpace.s12),
                  filled: true,
                  fillColor: KkfcColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KkfcRadius.sm),
                    borderSide: BorderSide(
                      color: hasError
                          ? KkfcColors.dangerBorder
                          : KkfcColors.border,
                      width: KkfcBorderWidth.thin,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KkfcRadius.sm),
                    borderSide: BorderSide(
                      color: hasError ? KkfcColors.danger : KkfcColors.focus,
                      width: KkfcBorderWidth.thick,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: KkfcSpace.s20),

              // 6. Action buttons: Cancel and Confirm QC failure
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: KkfcSizing.controlMd,
                      child: OutlinedButton(
                        key: const ValueKey('fail-qc-cancel-button'),
                        onPressed: _isSubmitting
                            ? null
                            : (widget.onCancel ??
                                () => Navigator.of(context).pop(false)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: KkfcColors.surface,
                          foregroundColor: KkfcColors.ink,
                          side: const BorderSide(
                            color: KkfcColors.border,
                            width: KkfcBorderWidth.thin,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(KkfcRadius.sm),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textBase,
                            fontWeight: KkfcFontWeights.semiBold,
                            color: KkfcColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: KkfcSpace.s12),
                  Expanded(
                    child: SizedBox(
                      height: KkfcSizing.controlMd,
                      child: OutlinedButton(
                        key: const ValueKey('fail-qc-confirm-button'),
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: KkfcColors.surface,
                          foregroundColor: KkfcColors.danger,
                          side: const BorderSide(
                            color: KkfcColors.qcFailBorder,
                            width: KkfcBorderWidth.thin,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(KkfcRadius.sm),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: KkfcColors.danger,
                                ),
                              )
                            : const Text(
                                'Confirm QC failure',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: KkfcFonts.ibmPlexSans,
                                  fontSize: KkfcTextSizes.textBase,
                                  fontWeight: KkfcFontWeights.semiBold,
                                  color: KkfcColors.danger,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to display [FailQcSendToReworkDialog].
/// Returns `true` if the failure was confirmed and processed successfully.
Future<bool?> showFailQcSendToReworkDialog(
  BuildContext context, {
  required KitchenBoardTicket ticket,
  Future<bool> Function(String reason)? onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: KkfcColors.ink.withValues(alpha: KkfcOpacity.scrim),
    builder: (dialogContext) {
      return FailQcSendToReworkDialog(
        ticket: ticket,
        onConfirm: onConfirm,
        onCancel: () => Navigator.of(dialogContext).pop(false),
      );
    },
  );
}
