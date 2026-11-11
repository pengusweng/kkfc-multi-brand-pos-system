import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_dialog_header.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_card.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

void main() {
  const brand = AssignedBrand(id: 'brand-1', code: 'KK', name: 'King Kungs');

  KitchenTicketData makeTicket({
    required KkfcStatus status,
    String ticketNumber = 'T-001',
  }) {
    return KitchenTicketData(
      ticketNumber: ticketNumber,
      brand: brand,
      status: status,
      items: const [KitchenTicketItem(quantity: 1, name: 'Burger')],
      channel: 'Takeaway',
      reference: 'Ref-1',
      elapsed: const Duration(minutes: 2),
      age: KitchenTicketAge.onTime,
    );
  }

  group('KkfcTicketStatusColors & theme token declarations', () {
    test('acknowledged and preparing have distinctly different shades of blue', () {
      final ackColors = KkfcTicketStatusColors.forStatus(KkfcStatus.acknowledged);
      final prepColors = KkfcTicketStatusColors.forStatus(KkfcStatus.preparing);

      // Acknowledged is darker blue
      expect(ackColors.foreground, KkfcColors.statusAcknowledgedFg);
      expect(ackColors.background, KkfcColors.statusAcknowledgedBg);
      expect(ackColors.border, KkfcColors.statusAcknowledgedBorder);
      expect(ackColors.accent, KkfcColors.statusAcknowledgedSolid);

      // Preparing is lighter blue
      expect(prepColors.foreground, KkfcColors.statusPreparingFg);
      expect(prepColors.background, KkfcColors.statusPreparingBg);
      expect(prepColors.border, KkfcColors.statusPreparingBorder);
      expect(prepColors.accent, KkfcColors.statusPreparingSolid);

      // Foreground and background shades must be distinct
      expect(ackColors.foreground, isNot(equals(prepColors.foreground)));
      expect(ackColors.background, isNot(equals(prepColors.background)));
      expect(ackColors.accent, isNot(equals(prepColors.accent)));

      // Verify darker vs lighter luminance
      expect(
        ackColors.foreground.computeLuminance(),
        lessThan(prepColors.foreground.computeLuminance()),
      );
    });

    test('rework colors use theme tokens without color literals', () {
      final rework = KkfcTicketStatusColors.forStatus(KkfcStatus.reworking);
      expect(rework.background, KkfcColors.reworkBg);
      expect(rework.border, KkfcColors.reworkBorder);
      expect(rework.foreground, KkfcColors.reworkText);
      expect(rework.accent, KkfcColors.reworkSolid);
    });

    test('queued, checking, and ready map to their badge colors', () {
      final queued = KkfcTicketStatusColors.forStatus(KkfcStatus.queued);
      expect(queued.background, KkfcColors.statusQueuedBg);
      expect(queued.foreground, KkfcColors.statusQueuedFg);

      final checking = KkfcTicketStatusColors.forStatus(KkfcStatus.checking);
      expect(checking.background, KkfcColors.statusCheckingBg);
      expect(checking.foreground, KkfcColors.statusCheckingFg);

      final ready = KkfcTicketStatusColors.forStatus(KkfcStatus.ready);
      expect(ready.background, KkfcColors.statusReadyBg);
      expect(ready.foreground, KkfcColors.statusReadyFg);
    });
  });

  group('KitchenTicketCard color coding', () {
    testWidgets('ticket card renders status accent bar matching status color', (
      tester,
    ) async {
      final ackTicket = makeTicket(status: KkfcStatus.acknowledged);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KitchenTicketCard.board(ticket: ackTicket),
          ),
        ),
      );

      final accentBarFinder = find.byKey(
        const ValueKey('kitchen-ticket-status-accent-bar'),
      );
      expect(accentBarFinder, findsOneWidget);

      final container = tester.widget<Container>(accentBarFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, KkfcColors.statusAcknowledgedSolid);
    });

    testWidgets('acknowledged card renders darker blue Acknowledged badge', (
      tester,
    ) async {
      final ackTicket = makeTicket(status: KkfcStatus.acknowledged);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KitchenTicketCard.board(ticket: ackTicket),
          ),
        ),
      );

      final badgeFinder = find.byKey(
        const ValueKey('kitchen-ticket-status-badge'),
      );
      expect(badgeFinder, findsOneWidget);

      final container = tester.widget<Container>(badgeFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, KkfcColors.statusAcknowledgedBg);

      expect(
        find.descendant(of: badgeFinder, matching: find.text('Acknowledged')),
        findsOneWidget,
      );
    });

    testWidgets('preparing card renders lighter blue status accent bar', (
      tester,
    ) async {
      final prepTicket = makeTicket(status: KkfcStatus.preparing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KitchenTicketCard.board(ticket: prepTicket),
          ),
        ),
      );

      final accentBarFinder = find.byKey(
        const ValueKey('kitchen-ticket-status-accent-bar'),
      );
      expect(accentBarFinder, findsOneWidget);

      final container = tester.widget<Container>(accentBarFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, KkfcColors.statusPreparingSolid);
    });
  });

  group('KitchenTicketDialogHeader status badge coloring', () {
    testWidgets('acknowledged ticket dialog header uses darker blue badge colors', (
      tester,
    ) async {
      final ackTicket = KitchenBoardTicket(
        kitchenTicketId: 'kt-1',
        orderId: 'order-1',
        orderCode: 'ORD-001',
        lane: KitchenBoardLane.preparing,
        rawStatus: 'ACKNOWLEDGED',
        data: makeTicket(status: KkfcStatus.acknowledged),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KitchenTicketDialogHeader(
              ticket: ackTicket,
              statusLabel: 'Acknowledged',
            ),
          ),
        ),
      );

      final badgeFinder = find.byKey(
        const ValueKey('kitchen-ticket-dialog-status-badge'),
      );
      expect(badgeFinder, findsOneWidget);

      final container = tester.widget<Container>(badgeFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, KkfcColors.statusAcknowledgedBg);
      expect(
        (decoration.border as Border).top.color,
        KkfcColors.statusAcknowledgedBorder,
      );

      final text = tester.widget<Text>(
        find.descendant(of: badgeFinder, matching: find.text('Acknowledged')),
      );
      expect(text.style?.color, KkfcColors.statusAcknowledgedFg);
    });

    testWidgets('preparing ticket dialog header uses lighter blue badge colors', (
      tester,
    ) async {
      final prepTicket = KitchenBoardTicket(
        kitchenTicketId: 'kt-2',
        orderId: 'order-2',
        orderCode: 'ORD-002',
        lane: KitchenBoardLane.preparing,
        rawStatus: 'PREPARING',
        data: makeTicket(status: KkfcStatus.preparing),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KitchenTicketDialogHeader(
              ticket: prepTicket,
              statusLabel: 'Preparing',
            ),
          ),
        ),
      );

      final badgeFinder = find.byKey(
        const ValueKey('kitchen-ticket-dialog-status-badge'),
      );
      expect(badgeFinder, findsOneWidget);

      final container = tester.widget<Container>(badgeFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, KkfcColors.statusPreparingBg);
      expect(
        (decoration.border as Border).top.color,
        KkfcColors.statusPreparingBorder,
      );

      final text = tester.widget<Text>(
        find.descendant(of: badgeFinder, matching: find.text('Preparing')),
      );
      expect(text.style?.color, KkfcColors.statusPreparingFg);
    });
  });
}
