import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';

/// Represents a structured QC item failure to be submitted as part of
/// `POST /api/kitchen-fulfillment/qc-attempts/{attemptId}/reject`.
@immutable
class QcItemRejection {
  const QcItemRejection({
    required this.orderItemId,
    required this.portionNumber,
    required this.reason,
    this.itemName,
  });

  final String orderItemId;
  final int portionNumber;
  final String reason;
  final String? itemName;

  Map<String, dynamic> toJson() => {
    'order_item_id': orderItemId,
    'portion_number': portionNumber,
    'rejection_reason': 'INCOMPLETE',
    'description': reason,
  };
}

/// Modal dialog presented when a QC checker fails an item to send the ticket to rework.
///
/// Collects the portion number (up to item quantity) and mandatory rejection reason
/// (up to 280 characters), returning a [QcItemRejection] to be attached to the
/// `POST /api/kitchen-fulfillment/qc-attempts/{attemptId}/reject` request.
class FailQcSendToReworkDialog extends ConsumerStatefulWidget {
  const FailQcSendToReworkDialog({
    super.key,
    required this.ticket,
    this.item,
    this.initialPortionNumber,
    this.initialReason,
    this.onConfirm,
    this.onCancel,
  });

  final KitchenBoardTicket ticket;
  final KitchenTicketItem? item;
  final int? initialPortionNumber;
  final String? initialReason;
  final dynamic onConfirm;
  final VoidCallback? onCancel;

  static const double maxDialogWidth = 480.0;
  static const int maxReasonLength = 280;

  @override
  ConsumerState<FailQcSendToReworkDialog> createState() =>
      _FailQcSendToReworkDialogState();
}

class _FailQcSendToReworkDialogState
    extends ConsumerState<FailQcSendToReworkDialog> {
  late final TextEditingController _reasonController;
  late final TextEditingController _portionController;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.initialReason ?? '');
    _portionController = TextEditingController(
      text: widget.initialPortionNumber?.toString() ?? '1',
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  void _handleTextChanged(String value) {
    if (_errorMessage != null) {
      final trimmed = _reasonController.text.trim();
      final portion = int.tryParse(_portionController.text.trim());
      if (trimmed.isNotEmpty &&
          trimmed.length <= FailQcSendToReworkDialog.maxReasonLength &&
          portion != null &&
          portion >= 1) {
        setState(() {
          _errorMessage = null;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    final portionText = _portionController.text.trim();
    final portion = int.tryParse(portionText);

    if (portion == null || portion < 1) {
      setState(() {
        _errorMessage = 'Enter a valid portion number (at least 1).';
      });
      return;
    }

    if (widget.item != null && portion > widget.item!.quantity) {
      setState(() {
        _errorMessage =
            'Portion number must not exceed item quantity (${widget.item!.quantity}).';
      });
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a reason (up to 280 characters).';
      });
      return;
    }

    if (reason.length > FailQcSendToReworkDialog.maxReasonLength) {
      setState(() {
        _errorMessage =
            'Reason must not exceed ${FailQcSendToReworkDialog.maxReasonLength} characters.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    final rejection = QcItemRejection(
      orderItemId: widget.item?.orderItemId ?? '',
      portionNumber: portion,
      reason: reason,
      itemName: widget.item?.name,
    );

    final bool success;
    if (widget.onConfirm != null) {
      if (widget.onConfirm is Future<bool> Function(QcItemRejection)) {
        success =
            await (widget.onConfirm as Future<bool> Function(QcItemRejection))(
              rejection,
            );
      } else if (widget.onConfirm is Future<bool> Function(String)) {
        success = await (widget.onConfirm as Future<bool> Function(String))(
          reason,
        );
      } else {
        final dynamic res = (widget.onConfirm as dynamic)(rejection);
        success = res is Future ? await res : (res == true);
      }
    } else {
      success = true;
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(rejection);
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;

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
              Text(
                widget.item != null
                    ? 'Specify the portion number and correction for ${widget.item!.name}. The ticket moves to Rework in the Preparing lane.'
                    : 'Say what the kitchen needs to correct. The ticket moves to Rework in the Preparing lane.',
                style: const TextStyle(
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: KkfcColors.danger,
                      ),
                      const SizedBox(width: KkfcSpace.s8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
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

              // 4. Portion Number Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Portion number',
                    style: TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: KkfcTextSizes.textSm,
                      fontWeight: KkfcFontWeights.semiBold,
                      color: KkfcColors.ink,
                    ),
                  ),
                  if (widget.item != null)
                    Text(
                      'Max: ${widget.item!.quantity}',
                      style: const TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: KkfcTextSizes.textSm,
                        fontWeight: KkfcFontWeights.regular,
                        color: KkfcColors.ink2,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: KkfcSpace.s8),
              TextField(
                key: const ValueKey('fail-qc-portion-field'),
                controller: _portionController,
                keyboardType: TextInputType.number,
                onChanged: _handleTextChanged,
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textBase,
                  color: KkfcColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: '1',
                  hintStyle: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: KkfcTextSizes.textBase,
                    fontWeight: KkfcFontWeights.regular,
                    color: KkfcColors.ink3,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: KkfcSpace.s12,
                    vertical: KkfcSpace.s8,
                  ),
                  filled: true,
                  fillColor: KkfcColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KkfcRadius.sm),
                    borderSide: BorderSide(
                      color:
                          hasError &&
                              (_errorMessage?.contains('portion') ?? false)
                          ? KkfcColors.dangerBorder
                          : KkfcColors.border,
                      width: KkfcBorderWidth.thin,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KkfcRadius.sm),
                    borderSide: BorderSide(
                      color:
                          hasError &&
                              (_errorMessage?.contains('portion') ?? false)
                          ? KkfcColors.danger
                          : KkfcColors.focus,
                      width: KkfcBorderWidth.thick,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: KkfcSpace.s16),

              // 5. Reason Label
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

              // 6. Multi-line Text Area
              TextField(
                key: const ValueKey('fail-qc-reason-field'),
                controller: _reasonController,
                onChanged: _handleTextChanged,
                minLines: 4,
                maxLines: 5,
                maxLength: FailQcSendToReworkDialog.maxReasonLength,
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
                      color:
                          hasError &&
                              (_errorMessage?.contains('reason') ?? false)
                          ? KkfcColors.dangerBorder
                          : KkfcColors.border,
                      width: KkfcBorderWidth.thin,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KkfcRadius.sm),
                    borderSide: BorderSide(
                      color:
                          hasError &&
                              (_errorMessage?.contains('reason') ?? false)
                          ? KkfcColors.danger
                          : KkfcColors.focus,
                      width: KkfcBorderWidth.thick,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: KkfcSpace.s20),

              // 7. Action buttons: Cancel and Confirm QC failure
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
                                  () => Navigator.of(context).pop(null)),
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
/// Returns the confirmed [QcItemRejection], or `null` if cancelled.
Future<QcItemRejection?> showFailQcSendToReworkDialog(
  BuildContext context, {
  required KitchenBoardTicket ticket,
  KitchenTicketItem? item,
  int? initialPortionNumber,
  String? initialReason,
  dynamic onConfirm,
}) {
  return showDialog<QcItemRejection>(
    context: context,
    barrierColor: KkfcColors.ink.withValues(alpha: KkfcOpacity.scrim),
    builder: (dialogContext) {
      return FailQcSendToReworkDialog(
        ticket: ticket,
        item: item,
        initialPortionNumber: initialPortionNumber,
        initialReason: initialReason,
        onConfirm: onConfirm,
        onCancel: () => Navigator.of(dialogContext).pop(null),
      );
    },
  );
}
