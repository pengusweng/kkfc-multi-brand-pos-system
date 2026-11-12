import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';

/// Modal dialog presented when a user clicks "Cancel ticket" on a queued
/// kitchen ticket.
///
/// Collects a mandatory cancellation reason (up to 200 characters) and closes
/// the popup upon submission (static flow).
class CancelKitchenTicketDialog extends ConsumerStatefulWidget {
  const CancelKitchenTicketDialog({
    super.key,
    required this.ticket,
    this.onConfirm,
    this.onCancel,
  });

  final KitchenBoardTicket ticket;
  final Future<bool> Function(String reason)? onConfirm;
  final VoidCallback? onCancel;

  static const double maxDialogWidth = 480.0;
  static const int maxReasonLength = 200;

  @override
  ConsumerState<CancelKitchenTicketDialog> createState() =>
      _CancelKitchenTicketDialogState();
}

class _CancelKitchenTicketDialogState
    extends ConsumerState<CancelKitchenTicketDialog> {
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
          trimmed.length <= CancelKitchenTicketDialog.maxReasonLength) {
        setState(() {
          _showError = false;
        });
      }
    } else {
      setState(() {});
    }
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty ||
        text.length > CancelKitchenTicketDialog.maxReasonLength) {
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
    final currentLength = _controller.text.length;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduceMotion ? 1.0 : 0.96, end: 1.0),
      duration: reduceMotion ? Duration.zero : KkfcMotion.durOverlay,
      curve: KkfcMotion.easeSpring,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Dialog(
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
            maxWidth: CancelKitchenTicketDialog.maxDialogWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(KkfcSpace.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Cancel ticket ${widget.ticket.data.ticketNumber}',
                        style: const TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: KkfcTextSizes.textXl,
                          fontWeight: KkfcFontWeights.bold,
                          color: KkfcColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('cancel-ticket-close-icon-button'),
                      onPressed: _isSubmitting
                          ? null
                          : (widget.onCancel ??
                                () => Navigator.of(context).pop(false)),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: KkfcColors.ink2,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: KkfcSpace.s8),

                // 2. Subtitle
                const Text(
                  'Provide a reason for cancelling this queued ticket (up to 200 characters).',
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
                    key: const ValueKey('cancel-ticket-error-banner'),
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
                            'Enter a cancellation reason (up to 200 characters).',
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

                // 4. Reason Label + character counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cancellation reason',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: KkfcTextSizes.textSm,
                        fontWeight: KkfcFontWeights.semiBold,
                        color: KkfcColors.ink,
                      ),
                    ),
                    Text(
                      '$currentLength/${CancelKitchenTicketDialog.maxReasonLength}',
                      style: const TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: KkfcTextSizes.textXs,
                        fontWeight: KkfcFontWeights.medium,
                        color: KkfcColors.ink3,
                        fontFeatures: tabularNumberFeatures,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KkfcSpace.s8),

                // 5. Multi-line Text Area (max 200 characters)
                TextField(
                  key: const ValueKey('cancel-ticket-reason-field'),
                  controller: _controller,
                  onChanged: _handleTextChanged,
                  minLines: 4,
                  maxLines: 5,
                  maxLength: CancelKitchenTicketDialog.maxReasonLength,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: KkfcTextSizes.textBase,
                    color: KkfcColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'For example: customer requested cancellation, out of stock',
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

                // 6. Action buttons: Cancel and Submit
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: KkfcSizing.controlMd,
                        child: OutlinedButton(
                          key: const ValueKey('cancel-ticket-dismiss-button'),
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
                              borderRadius: BorderRadius.circular(
                                KkfcRadius.sm,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Back',
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
                        child: FilledButton(
                          key: const ValueKey('cancel-ticket-submit-button'),
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: FilledButton.styleFrom(
                            backgroundColor: KkfcColors.danger,
                            foregroundColor: KkfcColors.onSolid,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                KkfcRadius.sm,
                              ),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: KkfcColors.onSolid,
                                  ),
                                )
                              : const Text(
                                  'Submit',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: KkfcFonts.ibmPlexSans,
                                    fontSize: KkfcTextSizes.textBase,
                                    fontWeight: KkfcFontWeights.bold,
                                    color: KkfcColors.onSolid,
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
      ),
    );
  }
}

/// Helper function to display [CancelKitchenTicketDialog].
/// Returns `true` if the cancellation reason was submitted.
Future<bool?> showCancelKitchenTicketDialog(
  BuildContext context, {
  required KitchenBoardTicket ticket,
  Future<bool> Function(String reason)? onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: KkfcColors.ink.withValues(alpha: KkfcOpacity.scrim),
    builder: (dialogContext) {
      return CancelKitchenTicketDialog(
        ticket: ticket,
        onConfirm: onConfirm,
        onCancel: () => Navigator.of(dialogContext).pop(false),
      );
    },
  );
}
