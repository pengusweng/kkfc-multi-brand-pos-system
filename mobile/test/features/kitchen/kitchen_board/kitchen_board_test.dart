import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/app/theme/tokens.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/cancel_kitchen_ticket_dialog.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/fail_qc_send_to_rework_dialog.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/handed_over_success_dialog.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_handover_photo_card.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_handover_stepper.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_handover_view.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_rework_view.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_status_dialog.dart';
import 'package:mobile/features/kitchen/kitchen_board/providers/kitchen_board_providers.dart';
import 'package:mobile/shared/widgets/app_header.dart';
import 'package:mobile/shared/widgets/button/button.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_card.dart';
import 'package:mobile/shared/widgets/kitchen_ticket_card/kitchen_ticket_item_tile.dart';
import 'package:mobile/shared/widgets/logout_button.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';
import 'package:mobile/shared/widgets/wave_accents.dart';

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
  final List<String> sentToQcTicketIds = [];
  final List<String> passedQcAttemptIds = [];
  final List<String> rejectedQcAttemptIds = [];
  final List<String> handedOverTicketIds = [];
  final List<({String brandId, String orderId, String reason})>
  cancelledTickets = [];
  final List<
    ({String attemptId, String reason, List<Map<String, dynamic>> rejections})
  >
  rejectedQcAttempts = [];
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
      assignedPreparers.add((
        ticketId: kitchenTicketId,
        preparerId: preparerId,
      ));
    }
  }

  @override
  Future<void> prepareTicket(
    String kitchenTicketId, {
    String? preparerId,
  }) async {
    preparedTicketIds.add(kitchenTicketId);
    if (preparerId != null) {
      assignedPreparers.add((
        ticketId: kitchenTicketId,
        preparerId: preparerId,
      ));
    }
  }

  @override
  Future<void> sendToQc(String kitchenTicketId, {String? preparerId}) async {
    sentToQcTicketIds.add(kitchenTicketId);
    if (preparerId != null) {
      assignedPreparers.add((
        ticketId: kitchenTicketId,
        preparerId: preparerId,
      ));
    }
  }

  @override
  Future<void> assignPreparer(String kitchenTicketId, String preparerId) async {
    assignedPreparers.add((ticketId: kitchenTicketId, preparerId: preparerId));
  }

  @override
  Future<void> passQcAttempt(String attemptId) async {
    passedQcAttemptIds.add(attemptId);
  }

  @override
  Future<void> passQcForTicket({
    required String kitchenTicketId,
    String? attemptId,
    String? checkerId,
  }) async {
    passedQcAttemptIds.add(attemptId ?? kitchenTicketId);
  }

  @override
  Future<void> rejectQcAttempt(
    String attemptId, {
    required List<Map<String, dynamic>> rejections,
  }) async {
    rejectedQcAttemptIds.add(attemptId);
    rejectedQcAttempts.add((
      attemptId: attemptId,
      reason: rejections.isNotEmpty
          ? (rejections.first['description'] as String? ?? '')
          : '',
      rejections: rejections,
    ));
  }

  @override
  Future<void> rejectQcForTicket({
    required String kitchenTicketId,
    required String reason,
    String? attemptId,
    String? checkerId,
    List<String>? orderItemIds,
    List<Map<String, dynamic>>? rejections,
  }) async {
    final targetAttempt = attemptId ?? kitchenTicketId;
    final finalRejections = (rejections != null && rejections.isNotEmpty)
        ? rejections
        : (orderItemIds != null && orderItemIds.isNotEmpty)
        ? orderItemIds
              .map(
                (id) => {
                  'order_item_id': id,
                  'portion_number': 1,
                  'rejection_reason': 'INCOMPLETE',
                  'description': reason,
                },
              )
              .toList()
        : [
            {
              'order_item_id': kitchenTicketId,
              'portion_number': 1,
              'rejection_reason': 'INCOMPLETE',
              'description': reason,
            },
          ];
    await rejectQcAttempt(targetAttempt, rejections: finalRejections);
  }

  final handedOverPhotos = <String, List<HandoverPhotoEvidence>>{};

  @override
  Future<void> handOverTicket(
    String kitchenTicketId, {
    List<HandoverPhotoEvidence>? photos,
    List<String>? imgKeys,
  }) async {
    handedOverTicketIds.add(kitchenTicketId);
    if (photos != null) {
      handedOverPhotos[kitchenTicketId] = photos;
    }
  }

  @override
  Future<void> cancelTicket({
    required String brandId,
    required String orderId,
    required String reason,
  }) async {
    cancelledTickets.add((brandId: brandId, orderId: orderId, reason: reason));
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(Dio(), TokenStore());

  int logoutCount = 0;

  @override
  Future<String?> getCurrentUserId() async =>
      '00000000-0000-4000-8000-000000000001';

  @override
  Future<void> logout(String token) async {
    logoutCount++;
  }
}

void main() {
  group('KitchenBoardRepository', () {
    test(
      'requests GET /api/kitchen-ticket/today/stream first and parses active lanes',
      () async {
        final payload = [
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
        ];

        final adapter = _RecordingAdapter(
          (_) async => ResponseBody.fromString(
            ': ping\n\ndata: ${jsonEncode(payload)}\n\n',
            200,
            headers: {
              Headers.contentTypeHeader: ['text/event-stream'],
            },
          ),
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
          'http://localhost:3000/api/kitchen-ticket/today/stream',
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
      'falls back to GET /api/kitchen-ticket/today when GET /api/kitchen-ticket/today/stream fails',
      () async {
        final adapter = _RecordingAdapter((options) async {
          if (options.uri.path.endsWith('/today/stream')) {
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'SSE stream unavailable',
            );
          }
          return _jsonResponse([
            {
              'kitchen_ticket_id': '00000000-0000-4000-8000-000000000016',
              'order_id': '00000000-0000-4000-8000-000000000116',
              'order_code': 'KK-00016',
              'ticket_number': 'T-016',
              'status': 'QUEUED',
              'created_at': '2026-11-10T09:39:00.000Z',
            },
          ]);
        });

        final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          ..httpClientAdapter = adapter;
        final repo = KitchenBoardRepository(dio);

        final tickets = await repo.fetchTodaysTickets(
          now: DateTime.parse('2026-11-10T09:41:00.000Z'),
        );

        expect(adapter.requests, hasLength(2));
        expect(
          adapter.requests[0].uri.toString(),
          'http://localhost:3000/api/kitchen-ticket/today/stream',
        );
        expect(
          adapter.requests[1].uri.toString(),
          'http://localhost:3000/api/kitchen-ticket/today',
        );
        expect(tickets, hasLength(1));
        expect(tickets.first.data.ticketNumber, 'T-016');
      },
    );

    test(
      'streamTodaysTickets emits multiple SSE updates in real time and ignores : ping heartbeats',
      () async {
        final streamController = StreamController<Uint8List>();
        final adapter = _RecordingAdapter((options) async {
          return ResponseBody(
            streamController.stream,
            200,
            headers: {
              Headers.contentTypeHeader: ['text/event-stream'],
            },
          );
        });

        final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          ..httpClientAdapter = adapter;
        final repo = KitchenBoardRepository(dio);

        final emissions = <List<KitchenBoardTicket>>[];
        final sub = repo
            .streamTodaysTickets(now: DateTime.parse('2026-11-10T09:41:00.000Z'))
            .listen(emissions.add);

        // 1. Emit initial snapshot
        streamController.add(
          Uint8List.fromList(
            utf8.encode(
              'id: 1\ndata: ${jsonEncode([
                {
                  'kitchen_ticket_id': '00000000-0000-4000-8000-000000000016',
                  'order_id': '00000000-0000-4000-8000-000000000116',
                  'order_code': 'KK-00016',
                  'ticket_number': 'T-016',
                  'status': 'QUEUED',
                  'created_at': '2026-11-10T09:39:00.000Z',
                },
              ])}\n\n',
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(emissions, hasLength(1));
        expect(emissions.first.first.lane, KitchenBoardLane.queued);

        // 2. Emit heartbeat comment (: ping) — should be ignored
        streamController.add(Uint8List.fromList(utf8.encode(': ping\n\n')));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(emissions, hasLength(1));

        // 3. Emit updated snapshot where ticket moved to PREPARING
        streamController.add(
          Uint8List.fromList(
            utf8.encode(
              'id: 2\ndata: ${jsonEncode([
                {
                  'kitchen_ticket_id': '00000000-0000-4000-8000-000000000016',
                  'order_id': '00000000-0000-4000-8000-000000000116',
                  'order_code': 'KK-00016',
                  'ticket_number': 'T-016',
                  'status': 'PREPARING',
                  'created_at': '2026-11-10T09:39:00.000Z',
                },
              ])}\n\n',
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(emissions, hasLength(2));
        expect(emissions.last.first.lane, KitchenBoardLane.preparing);

        unawaited(sub.cancel());
        unawaited(streamController.close());
      },
    );

    test(
      'watchTodaysTickets falls back to GET /api/kitchen-ticket/today when stream fails',
      () async {
        final adapter = _RecordingAdapter((options) async {
          if (options.uri.path.endsWith('/today/stream')) {
            return ResponseBody.fromString('Service Unavailable', 503);
          }
          return _jsonResponse([
            {
              'kitchen_ticket_id': '00000000-0000-4000-8000-000000000015',
              'order_id': '00000000-0000-4000-8000-000000000115',
              'order_code': 'AI-00015',
              'ticket_number': 'T-015',
              'status': 'PREPARING',
              'created_at': '2026-11-10T09:35:00.000Z',
            },
          ]);
        });

        final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          ..httpClientAdapter = adapter;
        final repo = KitchenBoardRepository(dio);

        final results = await repo
            .watchTodaysTickets(now: DateTime.parse('2026-11-10T09:41:00.000Z'))
            .toList();

        expect(adapter.requests, hasLength(2));
        expect(
          adapter.requests[0].uri.toString(),
          'http://localhost:3000/api/kitchen-ticket/today/stream',
        );
        expect(
          adapter.requests[1].uri.toString(),
          'http://localhost:3000/api/kitchen-ticket/today',
        );
        expect(results, hasLength(1));
        expect(results.first.first.data.ticketNumber, 'T-015');
      },
    );

    test(
      'KitchenBoardNotifier updates state in real time from GET /api/kitchen-ticket/today/stream',
      () async {
        final streamController = StreamController<Uint8List>();
        final adapter = _RecordingAdapter((options) async {
          if (options.uri.path.endsWith('/today/stream')) {
            return ResponseBody(
              streamController.stream,
              200,
              headers: {
                Headers.contentTypeHeader: ['text/event-stream'],
              },
            );
          }
          return _jsonResponse([]);
        });

        final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          ..httpClientAdapter = adapter;
        final repo = KitchenBoardRepository(dio);

        final container = ProviderContainer(
          overrides: [
            kitchenBoardRepositoryProvider.overrideWithValue(repo),
            initialRoleProvider.overrideWithValue(UserRole.kitchenHead),
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
        );
        addTearDown(() {
          unawaited(streamController.close());
          container.dispose();
        });

        // Trigger initial build & stream subscription
        container.read(kitchenBoardProvider);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // 1. Server pushes first SSE snapshot with 1 queued ticket
        streamController.add(
          Uint8List.fromList(
            utf8.encode(
              'data: ${jsonEncode([
                {
                  'kitchen_ticket_id': '00000000-0000-4000-8000-000000000016',
                  'order_id': '',
                  'order_code': 'KK-00016',
                  'ticket_number': 'T-016',
                  'status': 'QUEUED',
                  'created_at': '2026-11-10T09:39:00.000Z',
                },
              ])}\n\n',
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        var boardState = container.read(kitchenBoardProvider);
        expect(boardState.isLoading, isFalse);
        expect(boardState.tickets, hasLength(1));
        expect(boardState.tickets.first.data.ticketNumber, 'T-016');
        expect(boardState.tickets.first.lane, KitchenBoardLane.queued);

        // 2. Server pushes second SSE snapshot moving T-016 to PREPARING and adding T-017
        streamController.add(
          Uint8List.fromList(
            utf8.encode(
              'data: ${jsonEncode([
                {
                  'kitchen_ticket_id': '00000000-0000-4000-8000-000000000016',
                  'order_id': '',
                  'order_code': 'KK-00016',
                  'ticket_number': 'T-016',
                  'status': 'PREPARING',
                  'created_at': '2026-11-10T09:39:00.000Z',
                },
                {
                  'kitchen_ticket_id': '00000000-0000-4000-8000-000000000017',
                  'order_id': '',
                  'order_code': 'GC-00017',
                  'ticket_number': 'T-017',
                  'status': 'READY',
                  'created_at': '2026-11-10T09:40:00.000Z',
                },
              ])}\n\n',
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        boardState = container.read(kitchenBoardProvider);
        expect(boardState.tickets, hasLength(2));
        expect(boardState.tickets[0].lane, KitchenBoardLane.preparing);
        expect(boardState.tickets[1].data.ticketNumber, 'T-017');
        expect(boardState.tickets[1].lane, KitchenBoardLane.ready);
      },
    );

    test('acknowledgeTicket sends POST /api/kitchen-fulfillment/{kitchenTicketId}/acknowledge', () async {
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
    });

    test('prepareTicket sends POST /api/kitchen-fulfillment/{kitchenTicketId}/prepare', () async {
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
    });

    test('prepareTicket assigns preparer before calling prepare if preparerId is provided', () async {
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
    });

    test('sendToQc sends POST /api/kitchen-fulfillment/{kitchenTicketId}/for-checking', () async {
      const ticketId = '00000000-0000-4000-8000-000000000015';
      final adapter = _RecordingAdapter(
        (_) async => _jsonResponse({
          'kitchen_ticket_id': ticketId,
          'status': 'FOR_CHECKING',
        }),
      );

      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
        ..httpClientAdapter = adapter;
      final repo = KitchenBoardRepository(dio);

      await repo.sendToQc(ticketId);

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.first.method, 'POST');
      expect(
        adapter.requests.first.uri.toString(),
        'http://localhost:3000/api/kitchen-fulfillment/$ticketId/for-checking',
      );
    });

    test('passQcAttempt sends POST /api/kitchen-fulfillment/qc-attempts/{attemptId}/pass', () async {
      const attemptId = '00000000-0000-4000-8000-000000000099';
      final adapter = _RecordingAdapter(
        (_) async =>
            _jsonResponse({'qc_attempt_id': attemptId, 'status': 'PASSED'}),
      );

      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
        ..httpClientAdapter = adapter;
      final repo = KitchenBoardRepository(dio);

      await repo.passQcAttempt(attemptId);

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.first.method, 'POST');
      expect(
        adapter.requests.first.uri.toString(),
        'http://localhost:3000/api/kitchen-fulfillment/qc-attempts/$attemptId/pass',
      );
    });

    test('passQcForTicket starts a new check attempt when latest attempt is FAILED', () async {
      const ticketId = '00000000-0000-4000-8000-000000000015';
      const newAttemptId = '00000000-0000-4000-8000-000000000022';
      final adapter = _RecordingAdapter((options) async {
        if (options.path.endsWith('/latest')) {
          return _jsonResponse({
            'qc_attempt_id': 'old-failed-attempt',
            'status': 'FAILED',
          });
        }
        if (options.path.endsWith('/check')) {
          return _jsonResponse({
            'attempt': {'qc_attempt_id': newAttemptId, 'status': 'IN_PROGRESS'},
          });
        }
        if (options.path.endsWith('/pass')) {
          return _jsonResponse({
            'qc_attempt_id': newAttemptId,
            'status': 'PASSED',
          });
        }
        return _jsonResponse({});
      });

      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
        ..httpClientAdapter = adapter;
      final repo = KitchenBoardRepository(dio);

      await repo.passQcForTicket(kitchenTicketId: ticketId);

      final checkRequest = adapter.requests.firstWhere(
        (r) => r.uri.path.endsWith('/check'),
      );
      expect(checkRequest.method, 'POST');

      final passRequest = adapter.requests.firstWhere(
        (r) => r.uri.path.endsWith('/pass'),
      );
      expect(passRequest.uri.path, endsWith('/qc-attempts/$newAttemptId/pass'));
    });

    test('handOverTicket sends POST /api/kitchen-fulfillment/{kitchenTicketId}/hand-over', () async {
      const ticketId = '00000000-0000-4000-8000-000000000014';
      final adapter = _RecordingAdapter(
        (_) async => _jsonResponse({
          'kitchen_ticket_id': ticketId,
          'status': 'HANDED_OVER',
        }),
      );

      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
        ..httpClientAdapter = adapter;
      final repo = KitchenBoardRepository(dio);

      await repo.handOverTicket(ticketId);

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.first.method, 'POST');
      expect(
        adapter.requests.first.uri.toString(),
        'http://localhost:3000/api/kitchen-fulfillment/$ticketId/hand-over',
      );
    });

    test('handOverTicket sends POST with FormData files for delivery orders with photo evidence', () async {
      const ticketId = '00000000-0000-4000-8000-000000000014';
      final adapter = _RecordingAdapter(
        (_) async => _jsonResponse({
          'kitchen_ticket_id': ticketId,
          'status': 'HANDED_OVER',
        }),
      );

      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
        ..httpClientAdapter = adapter;
      final repo = KitchenBoardRepository(dio);

      final photo = HandoverPhotoEvidence(
        name: 'package_sealed.png',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      await repo.handOverTicket(ticketId, photos: [photo]);

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.first;
      expect(request.method, 'POST');
      expect(
        request.uri.toString(),
        'http://localhost:3000/api/kitchen-fulfillment/$ticketId/hand-over',
      );
      expect(request.data, isA<FormData>());
      final formData = request.data as FormData;
      expect(formData.files, hasLength(1));
      expect(formData.files.first.key, 'files');
      expect(formData.files.first.value.filename, 'package_sealed.png');
      expect(formData.files.first.value.contentType?.mimeType, 'image/png');
    });

    test('handOverTicket normalizes photo extension and defaults content type to image/jpeg if missing extension', () async {
      const ticketId = '00000000-0000-4000-8000-000000000014';
      final adapter = _RecordingAdapter(
        (_) async => _jsonResponse({
          'kitchen_ticket_id': ticketId,
          'status': 'HANDED_OVER',
        }),
      );

      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
        ..httpClientAdapter = adapter;
      final repo = KitchenBoardRepository(dio);

      final photo = HandoverPhotoEvidence(
        name: 'camera_capture',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      await repo.handOverTicket(ticketId, photos: [photo]);

      final request = adapter.requests.first;
      final formData = request.data as FormData;
      expect(formData.files.first.key, 'files');
      expect(formData.files.first.value.filename, 'camera_capture.jpg');
      expect(formData.files.first.value.contentType?.mimeType, 'image/jpeg');
    });

    test('fetchOrder sends GET /api/brands/{brandId}/orders/{orderId} and returns order data', () async {
      const brandId = '00000000-0000-4000-8000-000000000001';
      const orderId = '00000000-0000-4000-8000-000000000115';
      final adapter = _RecordingAdapter(
        (_) async => _jsonResponse({
          'order_id': orderId,
          'order_channel': 'DINE_IN',
          'table_reference': 'Table 7',
          'status': 'CONFIRMED',
          'payment_status': 'PAID',
        }),
      );

      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
        ..httpClientAdapter = adapter;
      final repo = KitchenBoardRepository(dio);

      final order = await repo.fetchOrder(brandId: brandId, orderId: orderId);

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.first.method, 'GET');
      expect(
        adapter.requests.first.uri.toString(),
        'http://localhost:3000/api/brands/$brandId/orders/$orderId',
      );
      expect(order, isNotNull);
      expect(order!['order_channel'], 'DINE_IN');
      expect(order['table_reference'], 'Table 7');
    });
  });

  group('Order Channel & Kitchen Ticket', () {
    test('tryFromApiJson parses channel and reference when order is passed instead of Takeaway fallback', () {
      final ticket = KitchenBoardTicket.tryFromApiJson(
        {
          'kitchen_ticket_id': '00000000-0000-4000-8000-000000000015',
          'order_id': '00000000-0000-4000-8000-000000000115',
          'order_code': 'AI-00015',
          'ticket_number': 'T-015',
          'status': 'PREPARING',
        },
        order: {'order_channel': 'DINE_IN', 'table_reference': 'Table 4'},
      );

      expect(ticket, isNotNull);
      expect(ticket!.data.channel, 'Dine-in');
      expect(ticket.data.reference, 'Table 4');
    });

    test('applyOrder passes order channel to kitchen ticket and updates display details', () {
      final baseTicket = KitchenBoardTicket.tryFromApiJson({
        'kitchen_ticket_id': '00000000-0000-4000-8000-000000000015',
        'order_id': '00000000-0000-4000-8000-000000000115',
        'order_code': 'AI-00015',
        'ticket_number': 'T-015',
        'status': 'PREPARING',
      })!;

      // Initial ticket without order data falls back to Takeaway placeholder
      expect(baseTicket.data.channel, 'Takeaway');

      // Passing order data with GrabFood channel
      final updatedTicket = baseTicket.applyOrder({
        'order_channel': 'GRABFOOD',
        'external_order_reference': 'GF-8849',
        'payment_status': 'PAID',
      });

      expect(updatedTicket.data.channel, 'GrabFood');
      expect(updatedTicket.data.reference, 'Ref GF-8849');
      expect(updatedTicket.data.isDelivery, isTrue);
    });

    testWidgets(
      'KitchenTicketCard displays order channel and chair icon for Dine-in order instead of Takeaway',
      (tester) async {
        final ticket = KitchenBoardTicket.tryFromApiJson(
          {
            'kitchen_ticket_id': '00000000-0000-4000-8000-000000000015',
            'order_id': '00000000-0000-4000-8000-000000000115',
            'order_code': 'AI-00015',
            'ticket_number': 'T-015',
            'status': 'PREPARING',
          },
          order: {'order_channel': 'DINE_IN', 'table_reference': 'Table 8'},
        )!;

        await tester.pumpWidget(
          MaterialApp(
            theme: kitchenTheme,
            home: Scaffold(body: KitchenTicketCard.board(ticket: ticket.data)),
          ),
        );

        // Verify that Dine-in · Table 8 is displayed instead of Takeaway
        expect(find.text('Dine-in · Table 8'), findsOneWidget);
        expect(find.text('Takeaway'), findsNothing);
        expect(find.byIcon(Icons.chair_alt_outlined), findsOneWidget);
        expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
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
      Future<XFile?> Function(ImageSource source)? onPickImage,
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
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: KitchenBoardScreen(onPickImage: onPickImage),
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
        expect(find.byType(LogoutButton), findsOneWidget);

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

    testWidgets(
      'KitchenTicketStatusDialog renders magnifying glass icon next to Send to QC button for preparing ticket',
      (tester) async {
        final preparingTicket = sampleKitchenBoardTickets[1].copyWith(
          rawStatus: 'PREPARING',
          lane: KitchenBoardLane.preparing,
          data: sampleKitchenBoardTickets[1].data.copyWith(
            status: KkfcStatus.preparing,
          ),
        );

        var actionTapped = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: counterTheme,
            home: Scaffold(
              body: KitchenTicketStatusDialog(
                ticket: preparingTicket,
                onAction: () => actionTapped = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Status badge displays Preparing
        final statusBadge = find.byKey(
          const ValueKey('kitchen-ticket-dialog-status-badge'),
        );
        expect(statusBadge, findsOneWidget);
        expect(
          find.descendant(of: statusBadge, matching: find.text('Preparing')),
          findsOneWidget,
        );

        // 2. Button displays 'Send to QC' and magnifying glass icon
        final dialogActionButton = find.byKey(
          const ValueKey('kitchen-ticket-dialog-action-button'),
        );
        expect(
          find.descendant(
            of: dialogActionButton,
            matching: find.text('Send to QC'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialogActionButton,
            matching: find.byIcon(Icons.search_rounded),
          ),
          findsOneWidget,
        );

        // 3. Tapping the action button triggers onAction
        await tester.tap(dialogActionButton);
        await tester.pumpAndSettle();
        expect(actionTapped, isTrue);
      },
    );

    testWidgets(
      'clicking Send to QC on the card and popup calls POST /api/kitchen-fulfillment/{kitchenTicketId}/for-checking and closes popup',
      (tester) async {
        final repo = _FakeKitchenBoardRepository(
          () async => sampleKitchenBoardTickets,
        );

        await pumpBoard(tester, repository: repo);

        // T-015 is in Preparing lane with Send to QC action
        final cardSendToQcButton = find.descendant(
          of: find.byKey(const ValueKey('kitchen-ticket-card-T-015')),
          matching: find.text('Send to QC'),
        );
        expect(cardSendToQcButton, findsOneWidget);

        // Tapping Send to QC on the card opens the popup
        await tester.tap(cardSendToQcButton);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        expect(repo.sentToQcTicketIds, isEmpty);

        // The popup action button is 'Send to QC' with magnifying glass icon
        final dialogActionButton = find.byKey(
          const ValueKey('kitchen-ticket-dialog-action-button'),
        );
        expect(
          find.descendant(
            of: dialogActionButton,
            matching: find.text('Send to QC'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialogActionButton,
            matching: find.byIcon(Icons.search_rounded),
          ),
          findsOneWidget,
        );

        // Tapping Send to QC in the popup invokes sendToQc
        await tester.tap(dialogActionButton);
        await tester.pumpAndSettle();

        // Verifies POST /api/kitchen-fulfillment/{id}/for-checking is called
        expect(repo.sentToQcTicketIds, [
          '00000000-0000-4000-8000-000000000015',
        ]);

        // Popup closes after successful call
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);
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

    test('UserRole.canPassQc authorization rules', () {
      expect(UserRole.superadmin.canPassQc, isTrue);
      expect(UserRole.manager.canPassQc, isTrue);
      expect(UserRole.supervisor.canPassQc, isTrue);
      expect(UserRole.kitchenHead.canPassQc, isTrue);

      expect(UserRole.kitchenStaff.canPassQc, isFalse);
      expect(UserRole.cashierStaff.canPassQc, isFalse);
      expect(UserRole.recipeManager.canPassQc, isFalse);
      expect(UserRole.inventoryStaff.canPassQc, isFalse);
    });

    test(
      'UserRole supervisor read-only and ticket transition authorization rules',
      () {
        // Supervisor is explicitly read-only on the kitchen board except for QC
        expect(UserRole.supervisor.isKitchenReadOnlyExceptQc, isTrue);
        expect(UserRole.kitchenHead.isKitchenReadOnlyExceptQc, isFalse);
        expect(UserRole.kitchenStaff.isKitchenReadOnlyExceptQc, isFalse);
        expect(UserRole.manager.isKitchenReadOnlyExceptQc, isFalse);
        expect(UserRole.superadmin.isKitchenReadOnlyExceptQc, isFalse);

        // Supervisor can ONLY change ticket status for QC check
        expect(
          UserRole.supervisor.canChangeTicketStatus(isQcCheck: true),
          isTrue,
        );
        expect(
          UserRole.supervisor.canChangeTicketStatus(isQcCheck: false),
          isFalse,
        );

        // Kitchen Head and Manager can change status across all lanes
        expect(
          UserRole.kitchenHead.canChangeTicketStatus(isQcCheck: true),
          isTrue,
        );
        expect(
          UserRole.kitchenHead.canChangeTicketStatus(isQcCheck: false),
          isTrue,
        );
        expect(UserRole.manager.canChangeTicketStatus(isQcCheck: true), isTrue);
        expect(
          UserRole.manager.canChangeTicketStatus(isQcCheck: false),
          isTrue,
        );

        // Kitchen Staff can change non-QC lanes but cannot pass QC
        expect(
          UserRole.kitchenStaff.canChangeTicketStatus(isQcCheck: false),
          isTrue,
        );
        expect(
          UserRole.kitchenStaff.canChangeTicketStatus(isQcCheck: true),
          isFalse,
        );
      },
    );

    testWidgets(
      'Supervisor is in read-only mode for Queued, Preparing, and Ready tickets, but can execute QC check',
      (tester) async {
        final queuedTicket = sampleKitchenBoardTickets[0]; // T-016 (Queued)
        final preparingTicket =
            sampleKitchenBoardTickets[1]; // T-017 (Preparing)
        final readyTicket = sampleKitchenBoardTickets[2]; // T-018 (Ready)
        final qcTicket = sampleKitchenBoardTickets[1].copyWith(
          kitchenTicketId: '00000000-0000-4000-8000-000000000099',
          qcAttemptId: '00000000-0000-4000-8000-000000000099',
          lane: KitchenBoardLane.qcCheck,
          rawStatus: 'FOR_CHECKING',
          data: sampleKitchenBoardTickets[1].data.copyWith(
            ticketNumber: 'T-099',
            status: KkfcStatus.checking,
          ),
        );

        final repo = _FakeKitchenBoardRepository(
          () async => [queuedTicket, preparingTicket, qcTicket, readyTicket],
        );

        await pumpBoard(tester, repository: repo, role: UserRole.supervisor);

        // Header displays Supervisor role
        expect(find.text('Supervisor'), findsOneWidget);

        // Toolbar displays read-only mode indicator badge
        expect(
          find.byKey(const ValueKey('kitchen-board-readonly-badge')),
          findsOneWidget,
        );
        expect(find.text('Read-only (QC Check only)'), findsOneWidget);

        // 1. Queued Ticket (T-016): Action button is disabled
        final queuedCard = find.byKey(
          const ValueKey('kitchen-ticket-card-T-016'),
        );
        final queuedAction = find.descendant(
          of: queuedCard,
          matching: find.byType(FilledButton),
        );
        expect(tester.widget<FilledButton>(queuedAction).onPressed, isNull);

        // Tapping Details on queued ticket opens dialog in read-only mode
        final queuedDetails = find.descendant(
          of: queuedCard,
          matching: find.text('Details'),
        );
        await tester.tap(queuedDetails);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        final queuedDialogAction = find.byKey(
          const ValueKey('kitchen-ticket-dialog-action-button'),
        );
        expect(
          tester.widget<FilledButton>(queuedDialogAction).onPressed,
          isNull,
        );
        final queuedDialogCancel = find.byKey(
          const ValueKey('kitchen-ticket-dialog-cancel-ticket-button'),
        );
        expect(
          tester.widget<OutlinedButton>(queuedDialogCancel).onPressed,
          isNull,
        );

        // Close dialog
        await tester.tap(
          find.byKey(const ValueKey('kitchen-ticket-dialog-close-button')),
        );
        await tester.pumpAndSettle();

        // 2. Preparing Ticket (T-015): Action button is disabled
        final preparingCard = find.byKey(
          const ValueKey('kitchen-ticket-card-T-015'),
        );
        final preparingAction = find.descendant(
          of: preparingCard,
          matching: find.byType(FilledButton),
        );
        expect(tester.widget<FilledButton>(preparingAction).onPressed, isNull);

        // 3. Ready Ticket (T-014): Action button is disabled, Details button is available
        final readyCard = find.byKey(
          const ValueKey('kitchen-ticket-card-T-014'),
        );
        final readyAction = find.descendant(
          of: readyCard,
          matching: find.byType(FilledButton),
        );
        expect(tester.widget<FilledButton>(readyAction).onPressed, isNull);

        final readyDetails = find.descendant(
          of: readyCard,
          matching: find.text('Details'),
        );
        expect(readyDetails, findsOneWidget);
        await tester.tap(readyDetails);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        final handoverConfirm = find.byKey(
          const ValueKey('kitchen-ticket-handover-confirm-button'),
        );
        expect(tester.widget<FilledButton>(handoverConfirm).onPressed, isNull);

        await tester.tap(
          find.byKey(const ValueKey('kitchen-ticket-dialog-close-button')),
        );
        await tester.pumpAndSettle();

        // 4. QC Check Ticket (T-099): Action button is ENABLED for Supervisor!
        final qcCard = find.byKey(const ValueKey('kitchen-ticket-card-T-099'));
        final qcAction = find.descendant(
          of: qcCard,
          matching: find.byType(FilledButton),
        );
        expect(tester.widget<FilledButton>(qcAction).onPressed, isNotNull);

        // Tap QC Check button to open QC check modal
        await tester.tap(qcAction);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        expect(find.text('QUALITY CHECK'), findsOneWidget);

        // Supervisor marks items passed and submits
        await tester.tap(find.text('Pass').first);
        await tester.pumpAndSettle();

        final passAllButton = find.byKey(
          const ValueKey('kitchen-ticket-dialog-action-button'),
        );
        expect(tester.widget<FilledButton>(passAllButton).onPressed, isNotNull);

        await tester.tap(passAllButton);
        await tester.pumpAndSettle();

        expect(
          repo.passedQcAttemptIds,
          contains('00000000-0000-4000-8000-000000000099'),
        );
      },
    );

    test('KitchenBoardNotifier rejects status transitions for supervisor except QC', () async {
      final repo = _FakeKitchenBoardRepository(
        () async => sampleKitchenBoardTickets,
      );
      final container = ProviderContainer(
        overrides: [
          kitchenBoardRepositoryProvider.overrideWithValue(repo),
          initialRoleProvider.overrideWithValue(UserRole.supervisor),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(kitchenBoardProvider.notifier).loadInitial();

      final notifier = container.read(kitchenBoardProvider.notifier);

      // Non-QC actions are rejected (return false)
      expect(await notifier.acknowledgeTicket('any-id'), isFalse);
      expect(await notifier.prepareTicket('any-id'), isFalse);
      expect(await notifier.sendToQc('any-id'), isFalse);
      expect(await notifier.handOverTicket('any-id'), isFalse);

      // QC pass and reject are allowed for supervisor
      expect(
        await notifier.passQc(kitchenTicketId: 'any-id', attemptId: 'att-1'),
        isTrue,
      );
      expect(
        await notifier.rejectQc(
          kitchenTicketId: 'any-id',
          reason: 'Under-seasoned',
        ),
        isTrue,
      );
    });

    testWidgets(
      'QC Check button on ticket card says "QC check" and is unclickable and muted for unauthorized role (KITCHEN_STAFF)',
      (tester) async {
        final qcTicket = sampleKitchenBoardTickets[1].copyWith(
          kitchenTicketId: '00000000-0000-4000-8000-000000000017',
          lane: KitchenBoardLane.qcCheck,
          rawStatus: 'FOR_CHECKING',
          data: sampleKitchenBoardTickets[1].data.copyWith(
            ticketNumber: 'T-017',
            status: KkfcStatus.checking,
          ),
        );

        final repo = _FakeKitchenBoardRepository(() async => [qcTicket]);

        // Pump as KITCHEN_STAFF (unauthorized to pass QC)
        await pumpBoard(tester, repository: repo, role: UserRole.kitchenStaff);

        // Card is in QC check lane
        final card = find.byKey(const ValueKey('kitchen-ticket-card-T-017'));
        expect(card, findsOneWidget);

        // Action button on card says 'QC check'
        expect(
          find.descendant(of: card, matching: find.text('QC check')),
          findsOneWidget,
        );

        final passButtonFinder = find.descendant(
          of: card,
          matching: find.byType(FilledButton),
        );
        expect(passButtonFinder, findsOneWidget);

        final filledButton = tester.widget<FilledButton>(passButtonFinder);
        // Button is disabled (unclickable)
        expect(filledButton.onPressed, isNull);

        // Tap the disabled button - does not call any API or open dialog
        await tester.tap(passButtonFinder);
        await tester.pumpAndSettle();
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);

        // Opening details shows popup, but action button inside is also disabled
        final detailsFinder = find.descendant(
          of: card,
          matching: find.text('Details'),
        );
        await tester.tap(detailsFinder);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        expect(find.text('QUALITY CHECK'), findsOneWidget);
        final dialogActionButton = tester.widget<FilledButton>(
          find.byKey(const ValueKey('kitchen-ticket-dialog-action-button')),
        );
        expect(dialogActionButton.onPressed, isNull);
      },
    );

    testWidgets(
      'QC Check button is clickable for authorized role, renders QC modal layout, and clicking All items passed calls passQc',
      (tester) async {
        final qcTicket = sampleKitchenBoardTickets[1].copyWith(
          kitchenTicketId: '00000000-0000-4000-8000-000000000017',
          qcAttemptId: '00000000-0000-4000-8000-000000000099',
          lane: KitchenBoardLane.qcCheck,
          rawStatus: 'FOR_CHECKING',
          data: sampleKitchenBoardTickets[1].data.copyWith(
            ticketNumber: 'T-017',
            status: KkfcStatus.checking,
          ),
        );

        final repo = _FakeKitchenBoardRepository(() async => [qcTicket]);

        // Pump as KITCHEN_HEAD (authorized to pass QC)
        await pumpBoard(tester, repository: repo, role: UserRole.kitchenHead);

        final card = find.byKey(const ValueKey('kitchen-ticket-card-T-017'));
        expect(
          find.descendant(of: card, matching: find.text('QC check')),
          findsOneWidget,
        );

        final qcCardButton = find.descendant(
          of: card,
          matching: find.byType(FilledButton),
        );
        final filledButton = tester.widget<FilledButton>(qcCardButton);
        expect(filledButton.onPressed, isNotNull);

        // Tapping opens the QC check popup
        await tester.tap(qcCardButton);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);

        // 1. Header: Subtitle QUALITY CHECK, Ticket number T-017, Status badge QC check
        expect(find.text('QUALITY CHECK'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(KitchenTicketStatusDialog),
            matching: find.text('T-017'),
          ),
          findsOneWidget,
        );
        expect(find.text('QC check'), findsWidgets);

        // 2. Body: Instruction text and items list
        expect(
          find.text(
            'Check temperature, plating, portion and special requests for each item.',
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(KitchenTicketStatusDialog),
            matching: find.text("Aurelia's Chicken Inasal Pecho"),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(KitchenTicketStatusDialog),
            matching: find.text('Note: Extra calamansi please'),
          ),
          findsOneWidget,
        );
        expect(find.text('Pass'), findsOneWidget);
        expect(find.text('Fail'), findsOneWidget);

        // 3. Footer: Fail QC and rework button + All items passed button
        expect(find.text('Fail QC and rework'), findsOneWidget);
        final allItemsPassedFinder = find.byKey(
          const ValueKey('kitchen-ticket-dialog-action-button'),
        );
        expect(allItemsPassedFinder, findsOneWidget);
        expect(find.text('All items passed'), findsOneWidget);

        // Before clicking Pass on every item, the button is MUTED (unclickable)
        expect(
          tester.widget<FilledButton>(allItemsPassedFinder).onPressed,
          isNull,
        );

        // Tapping Fail opens fail dialog - cancelling leaves button muted
        await tester.tap(find.text('Fail'));
        await tester.pumpAndSettle();
        expect(find.byType(FailQcSendToReworkDialog), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('fail-qc-cancel-button')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(allItemsPassedFinder).onPressed,
          isNull,
        );

        // Tapping Pass marks the item passed - button becomes ENABLED
        await tester.tap(find.text('Pass'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(allItemsPassedFinder).onPressed,
          isNotNull,
        );

        // 4. Clicking All items passed calls passQcAttempt and closes dialog
        expect(repo.passedQcAttemptIds, isEmpty);
        await tester.tap(allItemsPassedFinder);
        await tester.pumpAndSettle();

        expect(
          repo.passedQcAttemptIds,
          contains('00000000-0000-4000-8000-000000000099'),
        );
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);
      },
    );

    testWidgets(
      'QC checker cannot press "All items passed" (button is muted) without clicking pass on every item in that ticket',
      (tester) async {
        final multiItemQcTicket = KitchenBoardTicket(
          kitchenTicketId: '00000000-0000-4000-8000-000000000088',
          qcAttemptId: '00000000-0000-4000-8000-000000000089',
          orderId: '00000000-0000-4000-8000-000000000188',
          orderCode: 'ORD-2026-1105-088',
          lane: KitchenBoardLane.qcCheck,
          rawStatus: 'FOR_CHECKING',
          data: KitchenTicketData(
            ticketNumber: 'T-088',
            elapsed: const Duration(minutes: 4),
            age: KitchenTicketAge.onTime,
            status: KkfcStatus.checking,
            channel: 'Dine-in',
            reference: 'Table 7',
            brand: sampleKitchenBoardTickets[0].data.brand,
            items: const [
              KitchenTicketItem(
                quantity: 2,
                name: 'Item Alpha',
                modifiers: ['Note: Hot'],
              ),
              KitchenTicketItem(quantity: 1, name: 'Item Beta', modifiers: []),
            ],
            paymentStatus: 'Paid',
          ),
        );

        final repo = _FakeKitchenBoardRepository(
          () async => [multiItemQcTicket],
        );

        await pumpBoard(tester, repository: repo, role: UserRole.kitchenHead);

        // Open the QC dialog from the card button
        final card = find.byKey(const ValueKey('kitchen-ticket-card-T-088'));
        final qcCardButton = find.descendant(
          of: card,
          matching: find.byType(FilledButton),
        );
        await tester.tap(qcCardButton);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);

        // Multiple item cards render with Pass/Fail buttons
        expect(
          find.descendant(
            of: find.byType(KitchenTicketStatusDialog),
            matching: find.text('Item Alpha'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(KitchenTicketStatusDialog),
            matching: find.text('Item Beta'),
          ),
          findsOneWidget,
        );

        final allItemsPassedBtn = find.byKey(
          const ValueKey('kitchen-ticket-dialog-action-button'),
        );
        expect(allItemsPassedBtn, findsOneWidget);

        // 1. Initially, without clicking pass on every item, button is MUTED
        expect(
          tester.widget<FilledButton>(allItemsPassedBtn).onPressed,
          isNull,
        );

        // Tapping muted button does not trigger pass or close dialog
        await tester.tap(allItemsPassedBtn);
        await tester.pumpAndSettle();
        expect(repo.passedQcAttemptIds, isEmpty);
        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);

        // 2. Click Pass on Item Alpha only -> button remains MUTED
        final passButtons = find.text('Pass');
        expect(passButtons, findsNWidgets(2));

        await tester.tap(passButtons.first);
        await tester.pumpAndSettle();

        expect(
          tester.widget<FilledButton>(allItemsPassedBtn).onPressed,
          isNull,
        );

        // 3. Click Fail on Item Beta -> opens dialog, cancelling leaves button MUTED
        final failButtons = find.text('Fail');
        expect(failButtons, findsNWidgets(2));

        await tester.tap(failButtons.last);
        await tester.pumpAndSettle();
        expect(find.byType(FailQcSendToReworkDialog), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('fail-qc-cancel-button')));
        await tester.pumpAndSettle();

        expect(
          tester.widget<FilledButton>(allItemsPassedBtn).onPressed,
          isNull,
        );

        // 4. Click Pass on Item Beta -> now EVERY item is passed, button is ENABLED
        await tester.tap(passButtons.last);
        await tester.pumpAndSettle();

        expect(
          tester.widget<FilledButton>(allItemsPassedBtn).onPressed,
          isNotNull,
        );

        // 5. Tapping the enabled button passes the ticket and closes dialog
        await tester.tap(allItemsPassedBtn);
        await tester.pumpAndSettle();

        expect(
          repo.passedQcAttemptIds,
          contains('00000000-0000-4000-8000-000000000089'),
        );
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);
      },
    );

    testWidgets(
      'tapping logout button in AppHeader displays confirmation dialog and can cancel or confirm',
      (tester) async {
        final repo = _FakeKitchenBoardRepository(
          () async => sampleKitchenBoardTickets,
        );
        final authRepo = _FakeAuthRepository();

        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer(
          overrides: [
            kitchenBoardRepositoryProvider.overrideWithValue(repo),
            initialRoleProvider.overrideWithValue(UserRole.kitchenHead),
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
        );
        addTearDown(container.dispose);

        // Prepopulate token so we can verify it gets cleared on confirm
        container
            .read(sessionTokenProvider.notifier)
            .setToken('kitchen-test-jwt');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: counterTheme,
              home: const KitchenBoardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final logoutFinder = find.byType(LogoutButton);
        expect(logoutFinder, findsOneWidget);

        // 1. Tapping logout opens confirmation dialog
        await tester.tap(logoutFinder);
        await tester.pumpAndSettle();

        expect(find.text('Do you want to logout?'), findsOneWidget);
        expect(
          find.text('Any active order draft will be cleared.'),
          findsOneWidget,
        );

        // 2. Tapping Cancel dismisses dialog without logging out
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Do you want to logout?'), findsNothing);
        expect(container.read(sessionTokenProvider), 'kitchen-test-jwt');
        expect(authRepo.logoutCount, 0);

        // 3. Tapping logout again and confirming clears session token
        await tester.tap(logoutFinder);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(KkfcPrimaryButton, 'Logout'));
        await tester.pumpAndSettle();

        expect(find.text('Do you want to logout?'), findsNothing);
        expect(container.read(sessionTokenProvider), isNull);
        expect(authRepo.logoutCount, 1);
      },
    );

    test('KitchenBoardState.ticketsForLane prioritizes REWORKING tickets at the top of Preparing lane', () {
      final samplePreparing = sampleKitchenBoardTickets.firstWhere(
        (t) => t.lane == KitchenBoardLane.preparing,
      );
      final normalPrep1 = samplePreparing.copyWith(
        kitchenTicketId: 'prep-1',
        orderCode: 'ORD-PREP-1',
        rawStatus: 'PREPARING',
        data: samplePreparing.data.copyWith(
          ticketNumber: 'T-101',
          status: KkfcStatus.preparing,
        ),
      );
      final normalPrep2 = samplePreparing.copyWith(
        kitchenTicketId: 'prep-2',
        orderCode: 'ORD-PREP-2',
        rawStatus: 'PREPARING',
        data: samplePreparing.data.copyWith(
          ticketNumber: 'T-102',
          status: KkfcStatus.preparing,
        ),
      );
      final reworkTicket = samplePreparing.copyWith(
        kitchenTicketId: 'prep-rework',
        orderCode: 'ORD-REWORK',
        rawStatus: 'REWORKING',
        data: samplePreparing.data.copyWith(
          ticketNumber: 'T-999',
          status: KkfcStatus.reworking,
        ),
      );

      // Input list has rework at the very end
      final state = KitchenBoardState(
        tickets: [normalPrep1, normalPrep2, reworkTicket],
      );

      final laneTickets = state.ticketsForLane(KitchenBoardLane.preparing);
      expect(laneTickets.length, 3);
      // Rework ticket must be prioritized at index 0 (top of column)
      expect(laneTickets[0].kitchenTicketId, 'prep-rework');
      expect(laneTickets[0].data.status, KkfcStatus.reworking);
      expect(laneTickets[1].kitchenTicketId, 'prep-1');
      expect(laneTickets[2].kitchenTicketId, 'prep-2');
    });

    testWidgets(
      'QC Fail flow: Fail QC button disabled when no failed items, item Fail button opens dialog with portion number, and Fail QC and rework dispatches rejections to API',
      (tester) async {
        final qcTicket = sampleKitchenBoardTickets
            .firstWhere((t) => t.lane == KitchenBoardLane.ready)
            .copyWith(
              kitchenTicketId: 'qc-test-ticket',
              lane: KitchenBoardLane.qcCheck,
              rawStatus: 'FOR_CHECKING',
              qcAttemptId: 'attempt-uuid-777',
              data: sampleKitchenBoardTickets.first.data.copyWith(
                ticketNumber: 'T-QC-777',
                status: KkfcStatus.checking,
                items: [
                  const KitchenTicketItem(
                    quantity: 2,
                    name: 'Iced Sea Salt Cream Latte',
                    orderItemId: 'item-uuid-1',
                  ),
                ],
              ),
            );

        final repo = _FakeKitchenBoardRepository(() async => [qcTicket]);

        await pumpBoard(tester, repository: repo, role: UserRole.kitchenHead);

        // 1. Open QC check dialog
        final qcCheckButton = find.widgetWithText(FilledButton, 'QC check');
        expect(qcCheckButton, findsOneWidget);
        await tester.tap(qcCheckButton);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        final failQcButton = find.byKey(
          const ValueKey('kitchen-ticket-dialog-fail-qc-button'),
        );
        expect(failQcButton, findsOneWidget);

        // 2. Fail QC and rework button is disabled and muted when no items failed
        final outlinedButton = tester.widget<OutlinedButton>(failQcButton);
        expect(outlinedButton.onPressed, isNull);

        // 3. Click "Fail" on the item card opens FailQcSendToReworkDialog
        final itemFailButton = find.widgetWithText(InkWell, 'Fail');
        expect(itemFailButton, findsOneWidget);
        await tester.tap(itemFailButton);
        await tester.pumpAndSettle();

        expect(find.byType(FailQcSendToReworkDialog), findsOneWidget);
        expect(find.text('Fail QC and send to rework'), findsOneWidget);
        expect(find.text('Portion number'), findsOneWidget);
        expect(find.text('Reason'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('fail-qc-portion-field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('fail-qc-reason-field')),
          findsOneWidget,
        );

        // 4. Click "Confirm QC failure" with empty reason -> shows error banner
        final confirmButton = find.byKey(
          const ValueKey('fail-qc-confirm-button'),
        );
        expect(confirmButton, findsOneWidget);
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('fail-qc-error-banner')),
          findsOneWidget,
        );
        expect(
          find.text('Enter a reason (up to 280 characters).'),
          findsOneWidget,
        );
        expect(repo.rejectedQcAttemptIds, isEmpty);

        // 5. Enter portion number and valid reason and confirm
        await tester.enterText(
          find.byKey(const ValueKey('fail-qc-portion-field')),
          '2',
        );
        await tester.enterText(
          find.byKey(const ValueKey('fail-qc-reason-field')),
          'under-cooked, missing sauce',
        );
        await tester.pumpAndSettle();

        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        // 6. FailQcSendToReworkDialog is closed; item shows rejection note and Fail is selected
        expect(find.byType(FailQcSendToReworkDialog), findsNothing);
        expect(
          find.text('Portion 2: under-cooked, missing sauce'),
          findsOneWidget,
        );

        // 7. Fail QC and rework button is now enabled
        final enabledFailQcButton = tester.widget<OutlinedButton>(
          find.byKey(const ValueKey('kitchen-ticket-dialog-fail-qc-button')),
        );
        expect(enabledFailQcButton.onPressed, isNotNull);

        // 8. Clicking "Fail QC and rework" calls the API and moves ticket to rework
        await tester.tap(
          find.byKey(const ValueKey('kitchen-ticket-dialog-fail-qc-button')),
        );
        await tester.pumpAndSettle();

        expect(repo.rejectedQcAttemptIds, contains('attempt-uuid-777'));
        expect(repo.rejectedQcAttempts.length, 1);
        expect(repo.rejectedQcAttempts.first.attemptId, 'attempt-uuid-777');
        expect(repo.rejectedQcAttempts.first.rejections, [
          {
            'order_item_id': 'item-uuid-1',
            'portion_number': 2,
            'rejection_reason': 'INCOMPLETE',
            'description': 'under-cooked, missing sauce',
          },
        ]);

        // 9. Status dialog closed
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);
      },
    );

    testWidgets(
      'Handover UI flow: renders outgoing check, disables confirm button until all 3 checkboxes ticked, and confirms handover with success dialog',
      (tester) async {
        final readyTicket = sampleKitchenBoardTickets
            .firstWhere((t) => t.lane == KitchenBoardLane.ready)
            .copyWith(
              kitchenTicketId: 'handover-test-ticket',
              lane: KitchenBoardLane.ready,
              rawStatus: 'READY',
              data: sampleKitchenBoardTickets.first.data.copyWith(
                ticketNumber: 'T-016',
                status: KkfcStatus.ready,
              ),
            );

        final repo = _FakeKitchenBoardRepository(() async => [readyTicket]);

        await pumpBoard(tester, repository: repo, role: UserRole.kitchenHead);

        // 1. Click "Hand over" button on ticket card in Ready lane
        final handOverButton = find.widgetWithText(FilledButton, 'Hand over');
        expect(handOverButton, findsOneWidget);
        await tester.tap(handOverButton);
        await tester.pumpAndSettle();

        // 2. Handover status dialog is opened
        final dialogFinder = find.byType(KitchenTicketStatusDialog);
        expect(dialogFinder, findsOneWidget);
        expect(find.byType(KitchenTicketHandoverView), findsOneWidget);
        expect(
          find.descendant(of: dialogFinder, matching: find.text('HANDOVER')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialogFinder, matching: find.text('T-016')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialogFinder, matching: find.text('Ready')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialogFinder,
            matching: find.text('Outgoing check'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialogFinder, matching: find.text('Check')),
          findsOneWidget,
        );
        expect(find.text('Hand over'), findsWidgets);

        // Check the 3 items exist
        final matchCheck = find.text('The item matches the ticket');
        final cutleryCheck = find.text(
          'Cutlery, napkins and condiments included',
        );
        final packagingCheck = find.text('Packaging sealed');
        expect(matchCheck, findsOneWidget);
        expect(cutleryCheck, findsOneWidget);
        expect(packagingCheck, findsOneWidget);

        // Footer button is initially disabled and muted
        final footerButtonFinder = find.byKey(
          const ValueKey('kitchen-ticket-handover-confirm-button'),
        );
        expect(footerButtonFinder, findsOneWidget);
        expect(find.text('Finish the check to hand over'), findsOneWidget);
        final initialFilledButton = tester.widget<FilledButton>(
          footerButtonFinder,
        );
        expect(initialFilledButton.onPressed, isNull);

        // 3. Tick first checkbox -> button remains disabled
        await tester.tap(matchCheck);
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(footerButtonFinder).onPressed,
          isNull,
        );
        expect(find.text('Finish the check to hand over'), findsOneWidget);

        // 4. Tick second checkbox -> button remains disabled
        await tester.tap(cutleryCheck);
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(footerButtonFinder).onPressed,
          isNull,
        );
        expect(find.text('Finish the check to hand over'), findsOneWidget);

        // 5. Tick third checkbox -> button enables and shows "Confirm handover"
        await tester.tap(packagingCheck);
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(footerButtonFinder).onPressed,
          isNotNull,
        );
        expect(find.text('Confirm handover'), findsOneWidget);

        // 6. Tap "Confirm handover"
        await tester.tap(footerButtonFinder);
        await tester.pumpAndSettle();

        // Verifies repo.handOverTicket was called
        expect(repo.handedOverTicketIds, contains('handover-test-ticket'));

        // Status dialog is closed and Success dialog appears
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);
        expect(find.byType(HandedOverSuccessDialog), findsOneWidget);
        expect(find.text('Handed over'), findsOneWidget);
        expect(find.textContaining('T-016 was handed over at'), findsOneWidget);
        expect(
          find.textContaining('It is no longer on the board.'),
          findsOneWidget,
        );

        // 7. Click "Back to board" -> dismisses success dialog
        final backButton = find.byKey(
          const ValueKey('handed-over-back-to-board-button'),
        );
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.byType(HandedOverSuccessDialog), findsNothing);
        // Handed over ticket is removed from the board
        expect(
          find.byKey(const ValueKey('kitchen-ticket-card-T-016')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Handover UI flow (Delivery ticket): renders 3-step stepper, photo evidence card, dynamic item count, and transitions button to "Add the photo to hand over"',
      (tester) async {
        final deliveryTicket = sampleKitchenBoardTickets
            .firstWhere((t) => t.data.ticketNumber == 'T-014')
            .copyWith(lane: KitchenBoardLane.ready, rawStatus: 'READY');

        final repo = _FakeKitchenBoardRepository(() async => [deliveryTicket]);

        await pumpBoard(tester, repository: repo, role: UserRole.kitchenHead);

        // 1. Click "Hand over" button on ticket card in Ready lane
        final handOverButton = find.widgetWithText(FilledButton, 'Hand over');
        expect(handOverButton, findsOneWidget);
        await tester.tap(handOverButton);
        await tester.pumpAndSettle();

        // 2. Dialog is opened
        final dialogFinder = find.byType(KitchenTicketStatusDialog);
        expect(dialogFinder, findsOneWidget);
        expect(
          find.descendant(of: dialogFinder, matching: find.text('T-014')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialogFinder, matching: find.text('HANDOVER')),
          findsOneWidget,
        );

        // 3. 3-step Stepper is rendered
        expect(find.byType(KitchenTicketHandoverStepper), findsOneWidget);
        expect(find.text('Check'), findsOneWidget);
        expect(find.text('Photo'), findsOneWidget);
        expect(find.text('Hand over'), findsWidgets);

        // 4. Dynamic item count label: "All 2 items match the ticket"
        expect(find.text('All 2 items match the ticket'), findsOneWidget);
        expect(
          find.text('Cutlery, napkins and condiments included'),
          findsOneWidget,
        );
        expect(find.text('Packaging sealed'), findsOneWidget);

        // 5. Photo evidence card is rendered
        expect(find.byType(KitchenTicketHandoverPhotoCard), findsOneWidget);
        expect(find.text('Photo evidence'), findsOneWidget);
        expect(
          find.text(
            'Sample evidence only. Real image upload and persistence are not verified.',
          ),
          findsOneWidget,
        );
        expect(find.text('Attached'), findsNothing);
        expect(
          find.byKey(
            const ValueKey('kitchen-ticket-handover-add-photo-button'),
          ),
          findsOneWidget,
        );

        // 6. Footer button initially disabled with "Finish the check to hand over"
        final footerButton = find.byKey(
          const ValueKey('kitchen-ticket-handover-confirm-button'),
        );
        expect(footerButton, findsOneWidget);
        expect(find.text('Finish the check to hand over'), findsOneWidget);
        expect(tester.widget<FilledButton>(footerButton).onPressed, isNull);

        // 7. Tick all 3 checkboxes
        await tester.tap(find.text('All 2 items match the ticket'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cutlery, napkins and condiments included'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Packaging sealed'));
        await tester.pumpAndSettle();

        // 8. With checklist complete but no photo attached -> button is still disabled,
        // and label changes to "Add the photo to hand over"
        expect(tester.widget<FilledButton>(footerButton).onPressed, isNull);
        expect(find.text('Add the photo to hand over'), findsOneWidget);

        // 9. Tapping "Attach photo" opens bottom sheet with Camera and Gallery options
        await tester.tap(
          find.byKey(
            const ValueKey('kitchen-ticket-handover-add-photo-button'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Take photo'), findsOneWidget);
        expect(find.text('Choose from gallery'), findsOneWidget);

        // Close bottom sheet
        await tester.tap(find.text('Take photo'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Handover UI flow (Delivery ticket): attaching photo enables Confirm handover and passes photos to repo.handOverTicket and opens success dialog',
      (tester) async {
        final deliveryTicket = sampleKitchenBoardTickets
            .firstWhere((t) => t.data.ticketNumber == 'T-014')
            .copyWith(lane: KitchenBoardLane.ready, rawStatus: 'READY');

        final repo = _FakeKitchenBoardRepository(() async => [deliveryTicket]);

        final validPngBytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        );

        await pumpBoard(
          tester,
          repository: repo,
          role: UserRole.kitchenHead,
          onPickImage: (source) async => XFile.fromData(
            validPngBytes,
            name: 'delivery_proof.png',
            path: 'delivery_proof.png',
            mimeType: 'image/png',
          ),
        );

        // 1. Click "Hand over" button on delivery ticket card
        final handOverButton = find.widgetWithText(FilledButton, 'Hand over');
        expect(handOverButton, findsOneWidget);
        await tester.tap(handOverButton);
        await tester.pumpAndSettle();

        // 2. Dialog is opened
        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);

        // 3. Tick all 3 checkboxes
        await tester.tap(find.text('All 2 items match the ticket'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cutlery, napkins and condiments included'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Packaging sealed'));
        await tester.pumpAndSettle();

        // Button disabled, prompting photo
        final footerButton = find.byKey(
          const ValueKey('kitchen-ticket-handover-confirm-button'),
        );
        expect(tester.widget<FilledButton>(footerButton).onPressed, isNull);
        expect(find.text('Add the photo to hand over'), findsOneWidget);

        // 4. Attach photo
        await tester.tap(
          find.byKey(
            const ValueKey('kitchen-ticket-handover-add-photo-button'),
          ),
        );
        await tester.pumpAndSettle();

        // Button now enabled with "Confirm handover"
        expect(find.text('Attached'), findsOneWidget);
        expect(tester.widget<FilledButton>(footerButton).onPressed, isNotNull);
        expect(find.text('Confirm handover'), findsOneWidget);

        // 5. Confirm handover
        await tester.tap(footerButton);
        await tester.pumpAndSettle();

        // Verifies repo.handOverTicket was called WITH the attached photo!
        expect(
          repo.handedOverTicketIds,
          contains(deliveryTicket.kitchenTicketId),
        );
        expect(
          repo.handedOverPhotos[deliveryTicket.kitchenTicketId],
          isNotNull,
        );
        expect(
          repo.handedOverPhotos[deliveryTicket.kitchenTicketId]!.first.name,
          'delivery_proof.png',
        );

        // Status dialog closed and HandedOverSuccessDialog opened
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);
        expect(find.byType(HandedOverSuccessDialog), findsOneWidget);
      },
    );

    testWidgets(
      'KitchenTicketHandoverView for delivery ticket: uploading photo enables Confirm handover, shows Attached badge and thumbnail, supports 5-photo maximum and removal',
      (tester) async {
        final deliveryTicket = sampleKitchenBoardTickets
            .firstWhere((t) => t.data.ticketNumber == 'T-014')
            .copyWith(lane: KitchenBoardLane.ready, rawStatus: 'READY');

        var handoverCalled = false;
        var pickCounter = 0;
        final validPngBytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: KkfcColors.canvas,
            ),
            home: Scaffold(
              body: KitchenTicketHandoverView(
                ticket: deliveryTicket,
                isActionLoading: false,
                onHandover: () => handoverCalled = true,
                onPickImage: (source) async {
                  pickCounter++;
                  return XFile.fromData(
                    validPngBytes,
                    name: 'photo_$pickCounter.png',
                    mimeType: 'image/png',
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final footerButton = find.byKey(
          const ValueKey('kitchen-ticket-handover-confirm-button'),
        );
        expect(tester.widget<FilledButton>(footerButton).onPressed, isNull);

        // 1. Tick all checkboxes
        await tester.tap(find.text('All 2 items match the ticket'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cutlery, napkins and condiments included'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Packaging sealed'));
        await tester.pumpAndSettle();

        // Checklist complete, no photos yet -> disabled "Add the photo to hand over"
        expect(tester.widget<FilledButton>(footerButton).onPressed, isNull);
        expect(find.text('Add the photo to hand over'), findsOneWidget);

        // 2. Add 1st photo
        await tester.tap(
          find.byKey(
            const ValueKey('kitchen-ticket-handover-add-photo-button'),
          ),
        );
        await tester.pumpAndSettle();

        // Photo attached!
        expect(find.text('Attached'), findsOneWidget);
        expect(find.text('1 of 5 photos attached'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('kitchen-ticket-handover-remove-photo-0')),
          findsOneWidget,
        );

        // Button is now enabled with "Confirm handover"
        expect(tester.widget<FilledButton>(footerButton).onPressed, isNotNull);
        expect(find.text('Confirm handover'), findsOneWidget);

        // 3. Remove photo -> reverts to disabled "Add the photo to hand over"
        await tester.tap(
          find.byKey(const ValueKey('kitchen-ticket-handover-remove-photo-0')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Attached'), findsNothing);
        expect(tester.widget<FilledButton>(footerButton).onPressed, isNull);
        expect(find.text('Add the photo to hand over'), findsOneWidget);

        // 4. Add 5 photos up to maximum limit
        for (var i = 0; i < 5; i++) {
          await tester.tap(
            find.byKey(
              const ValueKey('kitchen-ticket-handover-add-photo-button'),
            ),
          );
          await tester.pumpAndSettle();
        }

        expect(find.text('5 of 5 photos attached'), findsOneWidget);
        // Add more button is now hidden when max (5) photos are reached
        expect(
          find.byKey(
            const ValueKey('kitchen-ticket-handover-add-photo-button'),
          ),
          findsNothing,
        );

        // 5. Confirm handover can now be tapped
        expect(tester.widget<FilledButton>(footerButton).onPressed, isNotNull);
        await tester.tap(footerButton);
        await tester.pumpAndSettle();

        expect(handoverCalled, isTrue);
      },
    );

    test('automatically refreshes tickets when the user logs in or switches tokens', () async {
      var currentTickets = [sampleKitchenBoardTickets[0]];
      final repo = _FakeKitchenBoardRepository(() async => currentTickets);

      final container = ProviderContainer(
        overrides: [
          kitchenBoardRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      // 1. Initial build loads the first ticket set
      final initial = container.read(kitchenBoardProvider);
      expect(initial.isLoading, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.fetchCount, 1);
      expect(container.read(kitchenBoardProvider).tickets.length, 1);
      expect(
        container.read(kitchenBoardProvider).tickets.first.data.ticketNumber,
        'T-016',
      );

      // 2. Repository updates with new tickets
      currentTickets = sampleKitchenBoardTickets;

      // 3. User logs in (sessionTokenProvider receives a new token)
      container.read(sessionTokenProvider.notifier).setToken('new-user-token');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 4. Kitchen board automatically refreshed tickets
      expect(repo.fetchCount, 2);
      expect(container.read(kitchenBoardProvider).tickets.length, 3);

      // 5. User logs out: clears tickets
      container.read(sessionTokenProvider.notifier).setToken(null);
      expect(container.read(kitchenBoardProvider).tickets, isEmpty);

      // 6. Another user logs in: automatically refreshes tickets again
      container
          .read(sessionTokenProvider.notifier)
          .setToken('kitchen-head-token');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.fetchCount, 3);
      expect(container.read(kitchenBoardProvider).tickets.length, 3);
    });

    testWidgets(
      'KitchenBoardScreen automatically refreshes and displays new tickets when user logs in',
      (tester) async {
        var currentTickets = [sampleKitchenBoardTickets[0]]; // Only T-016
        final repo = _FakeKitchenBoardRepository(() async => currentTickets);

        final container = ProviderContainer(
          overrides: [
            kitchenBoardRepositoryProvider.overrideWithValue(repo),
            initialRoleProvider.overrideWithValue(UserRole.kitchenHead),
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: counterTheme,
              home: const KitchenBoardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('T-016'), findsOneWidget);
        expect(find.text('T-015'), findsNothing);
        expect(repo.fetchCount, 1);

        // Backend receives T-015 and T-014
        currentTickets = sampleKitchenBoardTickets;

        // User signs in / token is set
        container
            .read(sessionTokenProvider.notifier)
            .setToken('kitchen-staff-token');
        await tester.pumpAndSettle();

        // Screen automatically refreshed and now displays T-015 and T-014
        expect(repo.fetchCount, 2);
        expect(find.text('T-016'), findsOneWidget);
        expect(find.text('T-015'), findsOneWidget);
        expect(find.text('T-014'), findsOneWidget);
      },
    );

    testWidgets(
      'renders background canvas wave accents and header wave arcs on KitchenBoardScreen',
      (tester) async {
        final repo = _FakeKitchenBoardRepository(
          () async => sampleKitchenBoardTickets,
        );

        await pumpBoard(tester, repository: repo);

        // 1. Verifies the fluid background canvas waves from the design system are present
        expect(find.byType(KkfcCanvasWaves), findsOneWidget);

        final canvasWaves = find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is CanvasWavesPainter,
        );
        expect(canvasWaves, findsOneWidget);

        // 2. Verifies the navy header copper wave arcs are present
        final headerWaves = find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is HeaderWavesPainter,
        );
        expect(headerWaves, findsOneWidget);

        // 3. Verifies both phone and tablet layouts render background waves without overflow
        await pumpBoard(tester, repository: repo, size: const Size(390, 844));
        expect(find.byType(KkfcCanvasWaves), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'choreographs kitchen board entrance, ticket stagger, lane badge spring, and physical card press compression',
      (tester) async {
        var currentTickets = [sampleKitchenBoardTickets[0]]; // T-016 in Queued
        final repo = _FakeKitchenBoardRepository(() async => currentTickets);

        await pumpBoard(tester, repository: repo);

        // 1. Verify choreographed screen entrance FadeTransition & SlideTransition
        expect(find.byType(FadeTransition), findsWidgets);
        expect(find.byType(SlideTransition), findsWidgets);

        // 2. Verify KitchenTicketCard tactile physical compression (0.97 scale on pointer down)
        final cardFinder = find.byKey(
          const ValueKey('kitchen-ticket-card-T-016'),
        );
        expect(cardFinder, findsOneWidget);

        final scaleFinder = find.descendant(
          of: cardFinder,
          matching: find.byType(AnimatedScale),
        );
        expect(scaleFinder, findsOneWidget);
        expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1.0);

        final gesture = await tester.startGesture(tester.getCenter(cardFinder));
        await tester.pump();
        expect(
          tester.widget<AnimatedScale>(scaleFinder).scale,
          KkfcMotion.pressScale,
        );
        expect(
          tester.widget<AnimatedScale>(scaleFinder).duration,
          KkfcMotion.durPress,
        );

        await gesture.up();
        await tester.pump();
        expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1.0);
        expect(
          tester.widget<AnimatedScale>(scaleFinder).duration,
          KkfcMotion.durRelease,
        );
        await tester.pumpAndSettle();

        // 3. Verify Refresh button tactile physical compression
        final refreshFinder = find.byKey(
          const ValueKey('kitchen-board-refresh-button'),
        );
        final refreshGesture = await tester.startGesture(
          tester.getCenter(refreshFinder),
        );
        await tester.pump();
        await refreshGesture.up();
        await tester.pumpAndSettle();

        // 4. Verify lane header count badge spring transition when new tickets arrive
        expect(
          find.byKey(const ValueKey('lane-count-zero-preparing')),
          findsOneWidget,
        );
        currentTickets = sampleKitchenBoardTickets; // Adds T-015 in Preparing & T-014 in Ready
        await tester.tap(refreshFinder);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('lane-count-pill-preparing-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('lane-count-pill-ready-1')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Queued ticket popup renders Cancel ticket button below Acknowledge and opens static CancelKitchenTicketDialog (max 200 chars)',
      (tester) async {
        final repo = _FakeKitchenBoardRepository(
          () async => sampleKitchenBoardTickets,
        );

        await pumpBoard(tester, repository: repo);

        // 1. Ticket cards on the board do NOT show 'Cancel ticket' directly
        final queuedCard = find.byKey(
          const ValueKey('kitchen-ticket-card-T-016'),
        );
        expect(queuedCard, findsOneWidget);
        expect(find.text('Cancel ticket'), findsNothing);

        final cardAcknowledgeButton = find.descendant(
          of: queuedCard,
          matching: find.widgetWithText(FilledButton, 'Acknowledge'),
        );
        expect(cardAcknowledgeButton, findsOneWidget);

        // 2. Opening the queued ticket status popup shows 'Cancel ticket' below 'Acknowledge'
        await tester.tap(cardAcknowledgeButton);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        final dialogAckButton = find.byKey(
          const ValueKey('kitchen-ticket-dialog-action-button'),
        );
        final dialogCancelButton = find.byKey(
          const ValueKey('kitchen-ticket-dialog-cancel-ticket-button'),
        );
        expect(dialogAckButton, findsOneWidget);
        expect(dialogCancelButton, findsOneWidget);
        expect(
          find.descendant(
            of: dialogCancelButton,
            matching: find.text('Cancel ticket'),
          ),
          findsOneWidget,
        );

        final dialogAckRect = tester.getRect(dialogAckButton);
        final dialogCancelRect = tester.getRect(dialogCancelButton);
        expect(
          dialogCancelRect.top,
          greaterThanOrEqualTo(dialogAckRect.bottom),
        );

        // 3. Clicking 'Cancel ticket' inside the popup opens CancelKitchenTicketDialog
        await tester.tap(dialogCancelButton);
        await tester.pumpAndSettle();

        expect(find.byType(CancelKitchenTicketDialog), findsOneWidget);
        expect(find.text('Cancel ticket T-016'), findsOneWidget);
        expect(find.text('Cancellation reason'), findsOneWidget);
        expect(find.text('0/200'), findsOneWidget);

        final reasonFieldFinder = find.byKey(
          const ValueKey('cancel-ticket-reason-field'),
        );
        expect(reasonFieldFinder, findsOneWidget);
        expect(tester.widget<TextField>(reasonFieldFinder).maxLength, 200);

        final submitButtonFinder = find.byKey(
          const ValueKey('cancel-ticket-submit-button'),
        );
        expect(submitButtonFinder, findsOneWidget);
        expect(find.text('Submit'), findsOneWidget);

        // 4. Clicking Submit with empty reason displays validation banner
        await tester.tap(submitButtonFinder);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('cancel-ticket-error-banner')),
          findsOneWidget,
        );
        expect(
          find.text('Enter a cancellation reason (up to 200 characters).'),
          findsOneWidget,
        );
        expect(find.byType(CancelKitchenTicketDialog), findsOneWidget);

        // 5. Entering a reason updates character count and clicking Submit closes both popups and cancels ticket via API
        await tester.enterText(
          reasonFieldFinder,
          'Customer requested cancellation',
        );
        await tester.pumpAndSettle();
        expect(find.text('31/200'), findsOneWidget);

        await tester.tap(submitButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(CancelKitchenTicketDialog), findsNothing);
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);
        expect(repo.cancelledTickets.length, 1);
        expect(
          repo.cancelledTickets.first.reason,
          'Customer requested cancellation',
        );
        expect(
          repo.cancelledTickets.first.orderId,
          sampleKitchenBoardTickets.first.orderId,
        );
        // Cancelled ticket is removed from the board
        expect(
          find.byKey(const ValueKey('kitchen-ticket-card-T-016')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Cancel ticket button does NOT exist when user role is kitchen staff, but exists for allowed roles (kitchen head, supervisor, manager, superadmin)',
      (tester) async {
        final repo = _FakeKitchenBoardRepository(
          () async => sampleKitchenBoardTickets,
        );

        // 1. Kitchen Staff: Cancel ticket button must NOT exist in the queued popup
        await pumpBoard(tester, repository: repo, role: UserRole.kitchenStaff);

        final queuedCard = find.byKey(
          const ValueKey('kitchen-ticket-card-T-016'),
        );
        expect(queuedCard, findsOneWidget);

        final cardAckButton = find.descendant(
          of: queuedCard,
          matching: find.widgetWithText(FilledButton, 'Acknowledge'),
        );
        await tester.tap(cardAckButton);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey('kitchen-ticket-dialog-cancel-ticket-button'),
          ),
          findsNothing,
        );
        expect(find.text('Cancel ticket'), findsNothing);

        // Close popup
        await tester.tap(
          find.byKey(const ValueKey('kitchen-ticket-dialog-close-button')),
        );
        await tester.pumpAndSettle();

        // 2. Kitchen Head: Cancel ticket button MUST exist
        await pumpBoard(tester, repository: repo, role: UserRole.kitchenHead);

        await tester.tap(cardAckButton);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey('kitchen-ticket-dialog-cancel-ticket-button'),
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel ticket'), findsOneWidget);
      },
    );

    testWidgets(
      'Rework UI flow: card layout, Preparing lane priority, rework dialog with 200 char placeholder, and returning to QC displays rework note',
      (tester) async {
        final reworkTicket = sampleKitchenBoardTickets[1].copyWith(
          rawStatus: 'REWORKING',
          qcReturnedReason: 'Rice portion short; plate again',
          data: sampleKitchenBoardTickets[1].data.copyWith(
            status: KkfcStatus.reworking,
            qcReturnedReason: 'Rice portion short; plate again',
          ),
        );

        final normalPreparingTicket = sampleKitchenBoardTickets[1].copyWith(
          kitchenTicketId: '00000000-0000-4000-8000-000000000099',
          data: sampleKitchenBoardTickets[1].data.copyWith(
            ticketNumber: 'T-099',
            status: KkfcStatus.preparing,
          ),
        );

        // 1. Verify Lane Priority: rework tickets are always highest priority (at the top)
        final mixedState = KitchenBoardState(
          tickets: [normalPreparingTicket, reworkTicket],
        );
        final preparingLaneTickets = mixedState.ticketsForLane(
          KitchenBoardLane.preparing,
        );
        expect(preparingLaneTickets.first.data.ticketNumber, 'T-015');
        expect(preparingLaneTickets.last.data.ticketNumber, 'T-099');

        var currentTickets = [reworkTicket];
        final repo = _FakeKitchenBoardRepository(() async => currentTickets);

        await pumpBoard(tester, repository: repo);

        // 2. Ticket card in Preparing lane matches reference design
        final reworkCard = find.byKey(
          const ValueKey('kitchen-ticket-card-T-015'),
        );
        expect(reworkCard, findsOneWidget);

        // Rework pill badge
        expect(
          find.descendant(
            of: reworkCard,
            matching: find.byKey(const ValueKey('kitchen-ticket-rework-badge')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: reworkCard, matching: find.text('Rework')),
          findsOneWidget,
        );

        // QC returned callout box
        expect(
          find.descendant(
            of: reworkCard,
            matching: find.byKey(
              const ValueKey('kitchen-ticket-qc-returned-box'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: reworkCard,
            matching: find.textContaining(
              'QC returned: Rice portion short; plate again',
            ),
          ),
          findsOneWidget,
        );

        // Full width action button labeled "Open rework"
        final openReworkButton = find.descendant(
          of: reworkCard,
          matching: find.widgetWithText(FilledButton, 'Open rework'),
        );
        expect(openReworkButton, findsOneWidget);

        // 3. Clicking "Open rework" opens KitchenTicketStatusDialog with KitchenTicketReworkView
        await tester.tap(openReworkButton);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        expect(find.byType(KitchenTicketReworkView), findsOneWidget);

        // Header shows subtitle "REWORK", ticket number "T-015", and status badge "Rework"
        expect(find.text('REWORK'), findsOneWidget);
        expect(find.text('T-015'), findsAtLeast(1));

        // Card 1: Rework info and notes
        expect(find.text(' · returned from QC'), findsOneWidget);
        expect(find.text('Reason'), findsOneWidget);
        expect(find.text('Rice portion short; plate again'), findsAtLeast(1));
        expect(find.text('Rework notes (optional)'), findsOneWidget);

        // TextField has placeholder: "e.g. Replated with a full portion." and 200 char limit
        final notesFieldFinder = find.byKey(
          const ValueKey('rework-notes-input-field'),
        );
        expect(notesFieldFinder, findsOneWidget);
        final textFieldWidget = tester.widget<TextField>(notesFieldFinder);
        expect(textFieldWidget.maxLength, 200);
        expect(
          textFieldWidget.decoration?.hintText,
          'e.g. Replated with a full portion.',
        );

        // Card 2: Items on this ticket
        expect(find.text('Items on this ticket'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(KitchenTicketReworkView),
            matching: find.text("Aurelia's Chicken Inasal Pecho"),
          ),
          findsOneWidget,
        );

        // Footer button: "Rework done · return to QC"
        final reworkDoneButton = find.byKey(
          const ValueKey('rework-done-return-to-qc-button'),
        );
        expect(reworkDoneButton, findsOneWidget);
        expect(find.text('Rework done · return to QC'), findsOneWidget);

        // 4. Fill rework note and click "Rework done · return to QC"
        await tester.enterText(
          notesFieldFinder,
          'Replated with a full portion.',
        );
        await tester.pumpAndSettle();

        currentTickets = [
          reworkTicket.copyWith(
            rawStatus: 'FOR_CHECKING',
            lane: KitchenBoardLane.qcCheck,
            reworkNotes: 'Replated with a full portion.',
            data: reworkTicket.data.copyWith(
              status: KkfcStatus.checking,
              reworkNotes: 'Replated with a full portion.',
            ),
          ),
        ];

        await tester.tap(reworkDoneButton);
        await tester.pumpAndSettle();

        // Popup closed
        expect(find.byType(KitchenTicketStatusDialog), findsNothing);

        // 5. Ticket is now in QC check lane and displays rework note on the card
        final qcLaneCard = find.byKey(
          const ValueKey('kitchen-ticket-card-T-015'),
        );
        expect(qcLaneCard, findsOneWidget);
        expect(
          find.descendant(
            of: qcLaneCard,
            matching: find.byKey(
              const ValueKey('kitchen-ticket-rework-note-box'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: qcLaneCard,
            matching: find.textContaining(
              'Rework note: Replated with a full portion.',
            ),
          ),
          findsOneWidget,
        );

        // 6. Opening the QC modal displays the rework note banner
        final qcCardButton = find.descendant(
          of: qcLaneCard,
          matching: find.widgetWithText(FilledButton, 'QC check'),
        );
        await tester.tap(qcCardButton);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketStatusDialog), findsOneWidget);
        expect(
          find.byKey(const ValueKey('qc-dialog-rework-note-banner')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('qc-dialog-rework-note-banner')),
            matching: find.textContaining(
              'Rework note: Replated with a full portion.',
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'In rework state, fail reason displays directly under each item in KitchenTicketItemTile for multi-item tickets',
      (tester) async {
        final multiItemReworkTicket = sampleKitchenBoardTickets[1].copyWith(
          kitchenTicketId: 'rework-multi-item-ticket',
          rawStatus: 'REWORKING',
          qcReturnedReason: 'Rice portion short; plate again',
          data: sampleKitchenBoardTickets[1].data.copyWith(
            ticketNumber: 'T-077',
            status: KkfcStatus.reworking,
            qcReturnedReason: 'Rice portion short; plate again',
            items: const [
              KitchenTicketItem(
                quantity: 1,
                name: "Aurelia's Chicken Inasal Pecho",
                orderItemId: 'item-pecho-1',
                modifiers: ['Toasted Garlic Inasal Rice'],
                failReason: 'Rice portion short; plate again',
              ),
              KitchenTicketItem(
                quantity: 2,
                name: 'Calamansi Juice',
                orderItemId: 'item-juice-2',
                modifiers: ['Less Ice'],
                failReason: null,
              ),
            ],
          ),
        );

        final repo = _FakeKitchenBoardRepository(
          () async => [multiItemReworkTicket],
        );
        await pumpBoard(tester, repository: repo);

        final card = find.byKey(const ValueKey('kitchen-ticket-card-T-077'));
        expect(card, findsOneWidget);

        // 1. Rework badge at the top
        expect(
          find.descendant(
            of: card,
            matching: find.byKey(const ValueKey('kitchen-ticket-rework-badge')),
          ),
          findsOneWidget,
        );

        // 2. Failed item displays QC returned reason under it
        final pechoTile = find.ancestor(
          of: find.text("Aurelia's Chicken Inasal Pecho"),
          matching: find.byType(KitchenTicketItemTile),
        );
        expect(pechoTile, findsOneWidget);
        expect(
          find.descendant(
            of: pechoTile,
            matching: find.byKey(
              const ValueKey('kitchen-ticket-qc-returned-box'),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: pechoTile,
            matching: find.textContaining(
              'QC returned: Rice portion short; plate again',
            ),
          ),
          findsOneWidget,
        );

        // 3. Passed item does NOT display any QC returned box under it
        final juiceTile = find.ancestor(
          of: find.text('Calamansi Juice'),
          matching: find.byType(KitchenTicketItemTile),
        );
        expect(juiceTile, findsOneWidget);
        expect(
          find.descendant(
            of: juiceTile,
            matching: find.byKey(
              const ValueKey('kitchen-ticket-qc-returned-box'),
            ),
          ),
          findsNothing,
        );

        // 4. In the rework modal dialog, fail reason also appears under the item
        final openReworkButton = find.descendant(
          of: card,
          matching: find.widgetWithText(FilledButton, 'Open rework'),
        );
        await tester.tap(openReworkButton);
        await tester.pumpAndSettle();

        expect(find.byType(KitchenTicketReworkView), findsOneWidget);
        final reworkPechoTile = find.descendant(
          of: find.byType(KitchenTicketReworkView),
          matching: find.ancestor(
            of: find.text("Aurelia's Chicken Inasal Pecho"),
            matching: find.byType(KitchenTicketItemTile),
          ),
        );
        expect(reworkPechoTile, findsOneWidget);
        expect(
          find.descendant(
            of: reworkPechoTile,
            matching: find.textContaining(
              'QC returned: Rice portion short; plate again',
            ),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
