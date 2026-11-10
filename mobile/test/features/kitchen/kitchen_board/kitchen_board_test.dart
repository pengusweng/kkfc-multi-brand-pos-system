import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/core/auth/token_store.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/repositories/kitchen_board_repository.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/seed/sample_kitchen_board_tickets.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/pages/kitchen_board_screen.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_status_dialog.dart';
import 'package:mobile/shared/widgets/app_header.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_card.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.responder);

  final Future<ResponseBody> Function(RequestOptions options) responder;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object? body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _FakeKitchenBoardRepository extends KitchenBoardRepository {
  _FakeKitchenBoardRepository(this.onFetch) : super(Dio());

  final Future<List<KitchenBoardTicket>> Function() onFetch;
  int fetchCount = 0;
  final List<String> acknowledgedTicketIds = [];
  final List<String> preparedTicketIds = [];
  final List<({String ticketId, String preparerId})> assignedPreparers = [];

  @override
  Future<List<KitchenBoardTicket>> fetchTodaysTickets({DateTime? now}) {
    fetchCount++;
    return onFetch();
  }

  @override
  Future<void> acknowledgeTicket(
    String kitchenTicketId, {
    String? preparerId,
  }) async {
    acknowledgedTicketIds.add(kitchenTicketId);
    if (preparerId != null) {
      assignedPreparers.add((ticketId: kitchenTicketId, preparerId: preparerId));
    }
  }

  @override
  Future<void> prepareTicket(
    String kitchenTicketId, {
    String? preparerId,
  }) async {
    preparedTicketIds.add(kitchenTicketId);
    if (preparerId != null) {
      assignedPreparers.add((ticketId: kitchenTicketId, preparerId: preparerId));
    }
  }

  @override
  Future<void> assignPreparer(
    String kitchenTicketId,
    String preparerId,
  ) async {
    assignedPreparers.add((ticketId: kitchenTicketId, preparerId: preparerId));
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(Dio(), TokenStore());

  @override
  Future<String?> getCurrentUserId() async =>
      '00000000-0000-4000-8000-000000000001';
}

void main() {
  group('KitchenBoardRepository', () {
    test(
      'requests GET /api/kitchen-ticket/today and parses active lanes',
      () async {
        final adapter = _RecordingAdapter(
          (_) async => _jsonResponse([
            {
              'kitchen_ticket_id': '00000000-0000-4000-8000-000000000016',
              'order_id': '00000000-0000-4000-8000-000000000116',
              'order_code': 'KK-00016',
              'ticket_number': 'T-016',
              'status': 'QUEUED',
              'created_at': '2026-11-10T09:39:00.000Z',
              'channel': 'Takeaway',
              'reference': 'Call: Ana',
              'payment_status': 'PAID',
              'items': [
                {
                  'quantity': 2,
                  'item_name': 'Iced Sea Salt Cream Latte',
                  'modifiers': ['50% Less Sweet', '22oz Large Cup'],
                  'notes': 'Separate straws',
                },
              ],
            },
            {
              'kitchen_ticket_id': '00000000-0000-4000-8000-000000000015',
              'order_id': '00000000-0000-4000-8000-000000000115',
              'order_code': 'AI-00015',
              'ticket_number': 'T-015',
              'status': 'PREPARING',
              'created_at': '2026-11-10T09:35:00.000Z',
            },
            {
              'kitchen_ticket_id': '00000000-0000-4000-8000-000000000099',
              'order_id': '00000000-0000-4000-8000-000000000199',
              'order_code': 'GC-00099',
              'ticket_number': 'T-099',
              'status': 'HANDED_OVER',
              'created_at': '2026-11-10T09:00:00.000Z',
            },
          ]),
        );

        final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          ..httpClientAdapter = adapter;
        final repo = KitchenBoardRepository(dio);

        final tickets = await repo.fetchTodaysTickets(
          now: DateTime.parse('2026-11-10T09:41:00.000Z'),
        );

        expect(adapter.requests, hasLength(1));
        expect(adapter.requests.first.method, 'GET');
        expect(
          adapter.requests.first.uri.toString(),
          'http://localhost:3000/api/kitchen-ticket/today',
        );

        // Terminal HANDED_OVER ticket is filtered out
        expect(tickets, hasLength(2));
        expect(tickets[0].data.ticketNumber, 'T-016');
        expect(tickets[0].lane, KitchenBoardLane.queued);
        expect(tickets[0].data.brand.code, 'KK');
        expect(tickets[0].data.items.first.name, 'Iced Sea Salt Cream Latte');
        expect(
          tickets[0].data.items.first.modifiers,
          contains('Note: Separate straws'),
        );

        expect(tickets[1].data.ticketNumber, 'T-015');
        expect(tickets[1].lane, KitchenBoardLane.preparing);
        expect(tickets[1].data.brand.code, 'AI');
      },
    );

    test(
      'acknowledgeTicket sends POST /api/kitchen-fulfillment/{kitchenTicketId}/acknowledge',
      () async {
        const ticketId = '00000000-0000-4000-8000-000000000016';
        final adapter = _RecordingAdapter(
          (_) async => _jsonResponse({
            'kitchen_ticket_id': ticketId,
            'status': 'ACKNOWLEDGED',
          }),
        );

        final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          ..httpClientAdapter = adapter;
        final repo = KitchenBoardRepository(dio);

        await repo.acknowledgeTicket(ticketId);

        expect(adapter.requests, hasLength(1));
        expect(adapter.requests.first.method, 'POST');
        expect(
          adapter.requests.first.uri.toString(),
          'http://localhost:3000/api/kitchen-fulfillment/$ticketId/acknowledge',
        );
      },
    );

    test(
      'prepareTicket sends POST /api/kitchen-fulfillment/{kitchenTicketId}/prepare',
      () async {
        const ticketId = '00000000-0000-4000-8000-000000000016';
        final adapter = _RecordingAdapter(
          (_) async => _jsonResponse({
            'kitchen_ticket_id': ticketId,
            'status': 'PREPARING',
          }),
        );

        final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          ..httpClientAdapter = adapter;
        final repo = KitchenBoardRepository(dio);

        await repo.prepareTicket(ticketId);

        expect(adapter.requests, hasLength(1));
        expect(adapter.requests.first.method, 'POST');
        expect(
          adapter.requests.first.uri.toString(),
          'http://localhost:3000/api/kitchen-fulfillment/$ticketId/prepare',
        );
      },
    );

    test(
      'prepareTicket assigns preparer before calling prepare if preparerId is provided',
      () async {
        const ticketId = '00000000-0000-4000-8000-000000000016';
        const preparerId = '00000000-0000-4000-8000-000000000001';
        final adapter = _RecordingAdapter(
          (_) async => _jsonResponse({
            'kitchen_ticket_id': ticketId,
            'status': 'PREPARING',
          }),
        );

        final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          ..httpClientAdapter = adapter;
        final repo = KitchenBoardRepository(dio);

        await repo.prepareTicket(ticketId, preparerId: preparerId);

        expect(adapter.requests, hasLength(2));
        expect(adapter.requests[0].method, 'PATCH');
        expect(
          adapter.requests[0].uri.toString(),
          'http://localhost:3000/api/kitchen-ticket/$ticketId/preparer',
        );
        expect(adapter.requests[0].data, {'preparer_id': preparerId});

        expect(adapter.requests[1].method, 'POST');
        expect(
          adapter.requests[1].uri.toString(),
          'http://localhost:3000/api/kitchen-fulfillment/$ticketId/prepare',
        );
      },
    );
  });

  group('KitchenBoardScreen & KitchenTicketStatusDialog UI', () {
    Future<void> pumpBoard(
      WidgetTester tester, {
      required KitchenBoardRepository repository,
      Size size = const Size(1280, 900),
      double textScale = 1.0,
      UserRole role = UserRole.kitchenHead,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          kitchenBoardRepositoryProvider.overrideWithValue(repository),
          initialRoleProvider.overrideWithValue(role),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: counterTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const KitchenBoardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'renders AppHeader, toolbar, 4 lanes, empty QC state, and KitchenTicketCard items',
      (tester) async {
        final repo = _FakeKitchenBoardRepository(
          () async => sampleKitchenBoardTickets,
        );

        await pumpBoard(tester, repository: repo);

        // 1. Shared AppHeader with Kitchen title and Kitchen Head role
        expect(find.byType(AppHeader), findsOneWidget);
        expect(find.text('Kitchen'), findsOneWidget);
        expect(find.text('Kitchen Head'), findsOneWidget);

        // 2. Toolbar active count & Refresh button
        expect(
          find.textContaining('3 active', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Refresh'), findsOneWidget);

        // 3. All 4 lane headers
        expect(find.text('Queued'), findsOneWidget);
        expect(find.text('Preparing'), findsOneWidget);
        expect(find.text('QC check'), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget);

        // 4. Empty QC check lane message
        expect(find.text('Nothing waiting for QC'), findsOneWidget);

        // 5. Three KitchenTicketCard components
        expect(find.byType(KitchenTicketCard), findsNWidgets(3));
        expect(find.text('T-016'), findsOneWidget);
        expect(find.text('T-015'), findsOneWidget);
        expect(find.text('T-014'), findsOneWidget);

        // 6. Action buttons on the cards
        expect(find.text('Acknowledge'), findsOneWidget);
        expect(find.text('Send to QC'), findsOneWidget);
        expect(find.text('Hand over'), findsOneWidget);

        // 7. Clicking Refresh re-fetches from repository
        expect(repo.fetchCount, 1);
        await tester.tap(
          find.byKey(const ValueKey('kitchen-board-refresh-button')),
        );
        await tester.pumpAndSettle();
        expect(repo.fetchCount, 2);
      },
    );

    testWidgets(
      'acknowledging ticket closes popup, updates board to Acknowledged lane with Start Preparing CTA, and opening popup shows fire icon & Acknowledged badge',
      (tester) async {
        final repo = _FakeKitchenBoardRepository(
          () async => sampleKitchenBoardTickets,
        );

        await pumpBoard(tester, repository: repo);

        // Tap Acknowledge on T-016 card on the board to open the popup
        final cardAcknowledgeButton = find.descendant(
          of: find.byKey(const ValueKey('kitchen-ticket-card-T-016')),
          matching: find.text('Acknowledge'),
        );
        await tester.tap(cardAcknowledgeButton);
        await tester.pumpAndSettle();

        // Clicking the card button only opens the popup; API is not called yet
        expect(repo.acknowledgedTicketIds, isEmpty);
        expect(repo.preparedTicketIds, isEmpty);
        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        expect(find.text('TICKET DETAILS'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
        expect(find.text('Items to prepare'), findsOneWidget);
        expect(find.text('ORD-2026-1105-016'), findsOneWidget);
        expect(find.text('7:39 PM'), findsOneWidget);
        expect(find.text('Not started'), findsOneWidget);

        // Dialog initially displays 'Queued' status badge and 'Acknowledge' button with check icon
        final queuedStatusBadge = find.byKey(
          const ValueKey('kitchen-ticket-dialog-status-badge'),
        );
        expect(
          find.descendant(of: queuedStatusBadge, matching: find.text('Queued')),
          findsOneWidget,
        );

        final dialogActionButton = find.byKey(
          const ValueKey('kitchen-ticket-dialog-action-button'),
        );
        expect(
          find.descendant(
            of: dialogActionButton,
            matching: find.text('Acknowledge'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialogActionButton,
            matching: find.byIcon(Icons.check_rounded),
          ),
          findsOneWidget,
        );

        // Tap the Acknowledge button inside the dialog
        await tester.tap(dialogActionButton);
        await tester.pumpAndSettle();

        // 1. Verify POST /api/kitchen-fulfillment/{kitchenTicketId}/acknowledge was called
        expect(repo.acknowledgedTicketIds, [
          '00000000-0000-4000-8000-000000000016',
        ]);

        // 2. Popup closes after clicking the button inside it
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);

        // 3. On the board, T-016 is now in Preparing lane with 'Start Preparing' CTA
        final preparingCard = find.byKey(
          const ValueKey('kitchen-ticket-card-T-016'),
        );
        expect(preparingCard, findsOneWidget);
        expect(find.text('Start'), findsNothing);
        final startPreparingCta = find.descendant(
          of: preparingCard,
          matching: find.text('Start Preparing'),
        );
        expect(startPreparingCta, findsOneWidget);

        // 4. Tap 'Start Preparing' on the card to open popup for acknowledged ticket
        await tester.tap(startPreparingCta);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);

        // 5. Status badge of the ticket is now 'Acknowledged'
        final ackBadge = find.byKey(
          const ValueKey('kitchen-ticket-dialog-status-badge'),
        );
        expect(
          find.descendant(of: ackBadge, matching: find.text('Acknowledged')),
          findsOneWidget,
        );

        // 6. Button says 'Start Preparing' and icon changed from check to fire
        final ackDialogButton = find.byKey(
          const ValueKey('kitchen-ticket-dialog-action-button'),
        );
        expect(
          find.descendant(
            of: ackDialogButton,
            matching: find.text('Start Preparing'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: ackDialogButton,
            matching: find.byIcon(Icons.check_rounded),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: ackDialogButton,
            matching: find.byIcon(Icons.local_fire_department_rounded),
          ),
          findsOneWidget,
        );

        // 7. Clicking the start preparing button calls the api: POST/api/kitchen-fulfillment/{kitchenTicketId}/prepare
        await tester.tap(ackDialogButton);
        await tester.pumpAndSettle();

        expect(repo.preparedTicketIds, [
          '00000000-0000-4000-8000-000000000016',
        ]);

        // 8. Popup closes after clicking the start preparing button inside it
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);
      },
    );

    testWidgets(
      'KitchenTicketStatusDialog renders Acknowledged badge, Start Preparing label, and fire icon for acknowledged ticket',
      (tester) async {
        final acknowledgedTicket = sampleKitchenBoardTickets.first.copyWith(
          rawStatus: 'ACKNOWLEDGED',
          lane: KitchenBoardLane.preparing,
          data: sampleKitchenBoardTickets.first.data.copyWith(
            status: KkfcStatus.acknowledged,
          ),
        );

        var actionTapped = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: counterTheme,
            home: Scaffold(
              body: KitchenTicketStatusDialog(
                ticket: acknowledgedTicket,
                onAction: () => actionTapped = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Status badge displays Acknowledged
        final statusBadge = find.byKey(
          const ValueKey('kitchen-ticket-dialog-status-badge'),
        );
        expect(statusBadge, findsOneWidget);
        expect(
          find.descendant(of: statusBadge, matching: find.text('Acknowledged')),
          findsOneWidget,
        );

        // 2. Primary button displays 'Start Preparing' and fire icon
        expect(find.text('Start Preparing'), findsOneWidget);
        expect(find.text('Start'), findsNothing);
        expect(
          find.byIcon(Icons.local_fire_department_rounded),
          findsOneWidget,
        );

        // 3. Tapping the action button triggers onAction
        await tester.tap(
          find.byKey(const ValueKey('kitchen-ticket-dialog-action-button')),
        );
        await tester.pumpAndSettle();
        expect(actionTapped, isTrue);
      },
    );

    testWidgets('adapts cleanly across tablet portrait and phone viewports', (
      tester,
    ) async {
      final repo = _FakeKitchenBoardRepository(
        () async => sampleKitchenBoardTickets,
      );

      // Tablet Portrait (768px -> 2x2 lanes)
      await pumpBoard(tester, repository: repo, size: const Size(768, 1024));
      expect(tester.takeException(), isNull);
      expect(find.byType(KitchenTicketCard), findsNWidgets(3));

      // Phone (390px -> stacked lanes)
      await pumpBoard(tester, repository: repo, size: const Size(390, 844));
      expect(tester.takeException(), isNull);
    });
  });
}
