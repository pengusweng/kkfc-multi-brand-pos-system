import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_item_tile.dart';

/// Modal view for inspecting a rejected ticket in the rework state and
/// returning it to Quality Check upon completion.
class KitchenTicketReworkView extends StatefulWidget {
  const KitchenTicketReworkView({
    super.key,
    required this.ticket,
    required this.isActionLoading,
    required this.isActionEnabled,
    required this.onReworkDone,
  });

  final KitchenBoardTicket ticket;
  final bool isActionLoading;
  final bool isActionEnabled;
  final Future<void> Function(String? reworkNotes) onReworkDone;

  @override
  State<KitchenTicketReworkView> createState() => _KitchenTicketReworkViewState();
}

class _KitchenTicketReworkViewState extends State<KitchenTicketReworkView> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.ticket.reworkNotes ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  KitchenTicketItem _resolveItemWithFailReason(
    KitchenTicketItem item,
    int index,
  ) {
    if (item.failReason != null && item.failReason!.trim().isNotEmpty) {
      return item;
    }
    final anyItemHasFailReason = widget.ticket.data.items.any(
      (it) => it.failReason != null && it.failReason!.trim().isNotEmpty,
    );
    if (!anyItemHasFailReason) {
      final reason = widget.ticket.qcReturnedReason?.trim().isNotEmpty == true
          ? widget.ticket.qcReturnedReason!
          : 'Rice portion short; plate again';
      return item.copyWith(failReason: reason);
    }
    return item;
  }

  Future<void> _handleSubmit() async {
    final notes = _notesController.text.trim();
    await widget.onReworkDone(notes.isNotEmpty ? notes : null);
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.isActionEnabled
        ? KkfcColors.onSolid
        : KkfcColors.ticketMuted;
    final reasonText = widget.ticket.qcReturnedReason?.trim().isNotEmpty == true
        ? widget.ticket.qcReturnedReason!
        : 'Rice portion short; plate again';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ColoredBox(
            color: KkfcColors.canvas,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(KkfcSpace.s16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: Rework details & notes
                  Container(
                    decoration: BoxDecoration(
                      color: KkfcColors.surface,
                      borderRadius: BorderRadius.circular(KkfcRadius.md),
                      border: Border.all(
                        color: KkfcColors.border,
                        width: KkfcBorderWidth.thin,
                      ),
                    ),
                    padding: const EdgeInsets.all(KkfcSpace.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.sync_rounded,
                              size: 16,
                              color: KkfcColors.reworkText,
                            ),
                            SizedBox(width: KkfcSpace.s8),
                            Text(
                              'Rework',
                              style: TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: KkfcTextSizes.textMd,
                                fontWeight: KkfcFontWeights.bold,
                                color: KkfcColors.reworkText,
                              ),
                            ),
                            Text(
                              ' · returned from QC',
                              style: TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: KkfcTextSizes.textMd,
                                fontWeight: KkfcFontWeights.medium,
                                color: KkfcColors.ink2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: KkfcSpace.s12),
                        const Text(
                          'Reason',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textSm,
                            fontWeight: KkfcFontWeights.regular,
                            color: KkfcColors.ink3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reasonText,
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textBase,
                            fontWeight: KkfcFontWeights.medium,
                            color: KkfcColors.ticketInk,
                          ),
                        ),
                        const SizedBox(height: KkfcSpace.s16),
                        const Text(
                          'Rework notes (optional)',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textSm,
                            fontWeight: KkfcFontWeights.bold,
                            color: KkfcColors.ink,
                          ),
                        ),
                        const SizedBox(height: KkfcSpace.s8),
                        TextField(
                          key: const ValueKey('rework-notes-input-field'),
                          controller: _notesController,
                          maxLength: 200,
                          maxLines: 3,
                          minLines: 2,
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
                            hintText: 'e.g. Replated with a full portion.',
                            hintStyle: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: KkfcTextSizes.textSm,
                              color: KkfcColors.ticketMuted,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: KkfcSpace.s12,
                              vertical: KkfcSpace.s12,
                            ),
                            filled: true,
                            fillColor: KkfcColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(KkfcRadius.sm),
                              borderSide: const BorderSide(
                                color: KkfcColors.border,
                                width: KkfcBorderWidth.thin,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(KkfcRadius.sm),
                              borderSide: const BorderSide(
                                color: KkfcColors.border,
                                width: KkfcBorderWidth.thin,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(KkfcRadius.sm),
                              borderSide: const BorderSide(
                                color: KkfcColors.focus,
                                width: KkfcBorderWidth.thick,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KkfcSpace.s16),

                  // Card 2: Items on this ticket
                  Container(
                    decoration: BoxDecoration(
                      color: KkfcColors.surface,
                      borderRadius: BorderRadius.circular(KkfcRadius.md),
                      border: Border.all(
                        color: KkfcColors.border,
                        width: KkfcBorderWidth.thin,
                      ),
                    ),
                    padding: const EdgeInsets.all(KkfcSpace.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Items on this ticket',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textBase,
                            fontWeight: KkfcFontWeights.bold,
                            color: KkfcColors.ticketInk,
                          ),
                        ),
                        const SizedBox(height: KkfcSpace.s12),
                        for (var i = 0;
                            i < widget.ticket.data.items.length;
                            i++) ...[
                          if (i > 0) const SizedBox(height: 14),
                          KitchenTicketItemTile(
                            item: _resolveItemWithFailReason(
                              widget.ticket.data.items[i],
                              i,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Footer: Full-width "Rework done · return to QC" button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(KkfcSpace.s16),
          decoration: const BoxDecoration(
            color: KkfcColors.surface,
            border: Border(
              top: BorderSide(
                color: KkfcColors.border,
                width: KkfcBorderWidth.thin,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: KkfcSizing.controlMd,
            child: FilledButton(
              key: const ValueKey('rework-done-return-to-qc-button'),
              onPressed: widget.isActionEnabled && !widget.isActionLoading
                  ? _handleSubmit
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: KkfcColors.action,
                disabledBackgroundColor: KkfcColors.ticketDisabledBg,
                foregroundColor: KkfcColors.onSolid,
                disabledForegroundColor: KkfcColors.ticketMuted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: widget.isActionLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KkfcColors.onSolid,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: foreground,
                        ),
                        const SizedBox(width: KkfcSpace.s8),
                        Flexible(
                          child: Text(
                            'Rework done · return to QC',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: KkfcTextSizes.textBase,
                              fontWeight: KkfcFontWeights.bold,
                              color: foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
