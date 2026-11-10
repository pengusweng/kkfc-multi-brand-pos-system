import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_header.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_meta.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// Stateless top header section for [KitchenTicketStatusDialog].
class KitchenTicketDialogHeader extends StatelessWidget {
  const KitchenTicketDialogHeader({
    super.key,
    required this.ticket,
    required this.statusLabel,
    this.statusIcon,
    this.onClose,
  });

  final KitchenBoardTicket ticket;
  final String statusLabel;
  final IconData? statusIcon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final lane = ticket.lane;
    final data = ticket.data;
    final elapsedText = KitchenTicketHeader.formatElapsed(data.elapsed);

    final isAcknowledged =
        data.status == KkfcStatus.acknowledged ||
        ticket.rawStatus.toUpperCase() == 'ACKNOWLEDGED';

    final isQc = lane == KitchenBoardLane.qcCheck ||
        data.status == KkfcStatus.checking ||
        ticket.rawStatus.toUpperCase() == 'FOR_CHECKING' ||
        ticket.rawStatus.toUpperCase() == 'CHECKING';

    final subtitle = isQc ? 'QUALITY CHECK' : 'TICKET DETAILS';

    final badgeIcon = statusIcon ??
        (isAcknowledged ? Icons.visibility_outlined : lane.icon);
    final badgeForeground =
        isAcknowledged ? KkfcColors.info : lane.headerForeground;
    final badgeBackground =
        isAcknowledged ? KkfcColors.infoBg : lane.headerBackground;
    final badgeBorder =
        isAcknowledged ? KkfcColors.infoBorder : lane.headerBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        KkfcSpace.s20,
        KkfcSpace.s16,
        KkfcSpace.s20,
        KkfcSpace.s16,
      ),
      decoration: const BoxDecoration(
        color: KkfcColors.surface,
        border: Border(
          bottom: BorderSide(
            color: KkfcColors.border,
            width: KkfcBorderWidth.thin,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Close button + TICKET DETAILS / T-016 + Status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('kitchen-ticket-dialog-close-button'),
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: KkfcColors.surface,
                  foregroundColor: KkfcColors.ink,
                  minimumSize: const Size(0, KkfcTargets.webControl),
                  padding: const EdgeInsets.symmetric(
                    horizontal: KkfcSpace.s12,
                    vertical: KkfcSpace.s8,
                  ),
                  side: const BorderSide(
                    color: KkfcColors.borderStrong,
                    width: KkfcBorderWidth.thin,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KkfcRadius.sm),
                  ),
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: KkfcColors.ink,
                ),
                label: const Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: KkfcTextSizes.textMd,
                    fontWeight: KkfcFontWeights.bold,
                    color: KkfcColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: KkfcSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 11,
                        fontWeight: KkfcFontWeights.bold,
                        letterSpacing: 0.8,
                        color: KkfcColors.ink3,
                      ),
                    ),
                    Text(
                      data.ticketNumber,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: KkfcColors.ticketInk,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KkfcSpace.s8),
              Container(
                key: const ValueKey('kitchen-ticket-dialog-status-badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: KkfcSpace.s12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(KkfcRadius.pill),
                  border: Border.all(
                    color: badgeBorder,
                    width: KkfcBorderWidth.thin,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 16, color: badgeForeground),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: KkfcTextSizes.textSm,
                        fontWeight: KkfcFontWeights.bold,
                        color: badgeForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KkfcSpace.s12),

          // Row 2: Brand badge + name and Channel + reference inline
          Wrap(
            spacing: KkfcSpace.s12,
            runSpacing: KkfcSpace.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
               IntrinsicWidth(child: KitchenTicketBrandRow(brand: data.brand)),
              IntrinsicWidth(
                child: KitchenTicketChannelLine(
                  channel: data.channel,
                  reference: data.reference,
                  useChannelSpecificIcon: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: KkfcSpace.s12),

          // Row 3: Elapsed timer + progress bar
          Text(
            elapsedText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: KkfcColors.ticketInk,
              fontFeatures: tabularNumberFeatures,
            ),
          ),
          const SizedBox(height: 6),
          KitchenTicketProgressBar(elapsed: data.elapsed, age: data.age),
        ],
      ),
    );
  }
}
