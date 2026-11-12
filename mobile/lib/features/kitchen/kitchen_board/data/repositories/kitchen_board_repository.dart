import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

class KitchenBoardException implements Exception {
  const KitchenBoardException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Repository for fetching and updating kitchen board tickets.
///
/// Primary endpoint: `GET /api/kitchen-ticket/today`.
class KitchenBoardRepository {
  KitchenBoardRepository(this._dio);

  final Dio _dio;

  String _endpoint(String pathWithoutApiPrefix) {
    final base = _dio.options.baseUrl.trim();
    final strippedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    if (strippedBase.endsWith('/api')) {
      return pathWithoutApiPrefix;
    }
    return '/api$pathWithoutApiPrefix';
  }

  /// Fetches today's kitchen tickets from `GET /api/kitchen-ticket/today`.
  Future<List<KitchenBoardTicket>> fetchTodaysTickets({DateTime? now}) async {
    try {
      final response = await _dio.get<Object?>(
        _endpoint('/kitchen-ticket/today'),
      );
      final body = response.data;
      final rawList = _extractTicketList(body);

      final referenceTime = now ?? DateTime.now();
      final tickets = <KitchenBoardTicket>[];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final parsed = KitchenBoardTicket.tryFromApiJson(
            item,
            now: referenceTime,
          );
          if (parsed != null) {
            tickets.add(parsed);
          }
        } else if (item is Map) {
          final parsed = KitchenBoardTicket.tryFromApiJson(
            Map<String, dynamic>.from(item),
            now: referenceTime,
          );
          if (parsed != null) {
            tickets.add(parsed);
          }
        }
      }
      return tickets;
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Assigns the given [preparerId] to the ticket via
  /// `PATCH /api/kitchen-ticket/{kitchenTicketId}/preparer`.
  ///
  /// Silently succeeds if the ticket is already assigned (409 Conflict).
  Future<void> assignPreparer(String kitchenTicketId, String preparerId) async {
    try {
      await _dio.patch<Object?>(
        _endpoint('/kitchen-ticket/$kitchenTicketId/preparer'),
        data: {'preparer_id': preparerId},
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) return;
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Acknowledges a queued kitchen ticket via
  /// `POST /api/kitchen-fulfillment/{kitchenTicketId}/acknowledge`.
  ///
  /// Optionally assigns [preparerId] so the acknowledging user is recorded
  /// as the ticket's preparer.
  Future<void> acknowledgeTicket(
    String kitchenTicketId, {
    String? preparerId,
  }) async {
    try {
      await _dio.post<Object?>(
        _endpoint('/kitchen-fulfillment/$kitchenTicketId/acknowledge'),
      );
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }

    if (preparerId != null && preparerId.isNotEmpty) {
      try {
        await assignPreparer(kitchenTicketId, preparerId);
      } catch (_) {
        // Non-blocking; prepareTicket will also ensure preparer is assigned.
      }
    }
  }

  /// Begins preparation on an acknowledged ticket via
  /// `POST /api/kitchen-fulfillment/{kitchenTicketId}/prepare`.
  ///
  /// If [preparerId] is supplied, claims preparer assignment first so the
  /// backend authorization check (`preparer_id === callerId`) passes.
  Future<void> prepareTicket(
    String kitchenTicketId, {
    String? preparerId,
  }) async {
    if (preparerId != null && preparerId.isNotEmpty) {
      try {
        await assignPreparer(kitchenTicketId, preparerId);
      } catch (_) {
        // Continue to prepare in case caller is already assigned.
      }
    }

    try {
      await _dio.post<Object?>(
        _endpoint('/kitchen-fulfillment/$kitchenTicketId/prepare'),
      );
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Sends a preparing or reworking ticket to QC check via
  /// `POST /api/kitchen-fulfillment/{kitchenTicketId}/for-checking`.
  ///
  /// If [preparerId] is supplied, ensures the caller is assigned as preparer
  /// so backend authorization (`preparer_id === callerId`) succeeds.
  Future<void> sendToQc(String kitchenTicketId, {String? preparerId}) async {
    if (preparerId != null && preparerId.isNotEmpty) {
      try {
        await assignPreparer(kitchenTicketId, preparerId);
      } catch (_) {
        // Continue in case already assigned to caller.
      }
    }

    try {
      await _dio.post<Object?>(
        _endpoint('/kitchen-fulfillment/$kitchenTicketId/for-checking'),
      );
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Claims checker assignment for a ticket via
  /// `PATCH /api/kitchen-ticket/{kitchenTicketId}/checker`.
  Future<void> assignChecker(String kitchenTicketId, String checkerId) async {
    try {
      await _dio.patch<Object?>(
        _endpoint('/kitchen-ticket/$kitchenTicketId/checker'),
        data: {'checker_id': checkerId},
      );
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Starts a QC check attempt for a ticket in `FOR_CHECKING` state via
  /// `POST /api/kitchen-fulfillment/{kitchenTicketId}/check`.
  /// Returns the created `qc_attempt_id` if available.
  Future<String?> checkTicket(
    String kitchenTicketId, {
    String? checkerId,
  }) async {
    if (checkerId != null && checkerId.isNotEmpty) {
      try {
        await assignChecker(kitchenTicketId, checkerId);
      } catch (_) {
        // Continue in case already assigned to caller.
      }
    }

    try {
      final response = await _dio.post<dynamic>(
        _endpoint('/kitchen-fulfillment/$kitchenTicketId/check'),
      );
      final data = response.data;
      if (data is Map) {
        final attempt = data['attempt'];
        if (attempt is Map && attempt['qc_attempt_id'] is String) {
          return attempt['qc_attempt_id'] as String;
        }
      }
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
    return null;
  }

  /// Fetches the latest in-progress QC attempt ID for a ticket via
  /// `GET /api/kitchen-qc/ticket/{kitchenTicketId}/latest`.
  /// Returns `null` if no attempt exists or if the latest attempt has already
  /// ended (`FAILED` or `PASSED`).
  Future<String?> fetchLatestQcAttemptId(String kitchenTicketId) async {
    try {
      final response = await _dio.get<dynamic>(
        _endpoint('/kitchen-qc/ticket/$kitchenTicketId/latest'),
      );
      final data = response.data;
      if (data is Map) {
        final status = (data['status'] as String?)?.toUpperCase();
        if (status != null && status != 'IN_PROGRESS') {
          return null;
        }
        if (data['qc_attempt_id'] is String) {
          return data['qc_attempt_id'] as String;
        }
      }
    } catch (_) {
      // Ignore lookup failure; caller can fall back to checking or ticket ID.
    }
    return null;
  }

  /// Passes a QC attempt via
  /// `POST /api/kitchen-fulfillment/qc-attempts/{attemptId}/pass`.
  Future<void> passQcAttempt(String attemptId) async {
    try {
      await _dio.post<Object?>(
        _endpoint('/kitchen-fulfillment/qc-attempts/$attemptId/pass'),
      );
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Resolves the QC attempt ID for a ticket and marks it passed.
  Future<void> passQcForTicket({
    required String kitchenTicketId,
    String? attemptId,
    String? checkerId,
  }) async {
    final inProgressAttemptId = await fetchLatestQcAttemptId(kitchenTicketId);

    var resolvedAttemptId = inProgressAttemptId;
    if (resolvedAttemptId == null || resolvedAttemptId.isEmpty) {
      resolvedAttemptId = await checkTicket(
        kitchenTicketId,
        checkerId: checkerId,
      );
    }
    resolvedAttemptId ??= attemptId ?? kitchenTicketId;

    await passQcAttempt(resolvedAttemptId);
  }

  /// Rejects a QC attempt via
  /// `POST /api/kitchen-fulfillment/qc-attempts/{attemptId}/reject`.
  Future<void> rejectQcAttempt(
    String attemptId, {
    required List<Map<String, dynamic>> rejections,
  }) async {
    try {
      await _dio.post<Object?>(
        _endpoint('/kitchen-fulfillment/qc-attempts/$attemptId/reject'),
        data: {'rejections': rejections},
      );
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Resolves the QC attempt ID for a ticket and marks it rejected,
  /// sending it back to preparing in rework state.
  Future<void> rejectQcForTicket({
    required String kitchenTicketId,
    required String reason,
    String? attemptId,
    String? checkerId,
    List<String>? orderItemIds,
    List<Map<String, dynamic>>? rejections,
  }) async {
    final inProgressAttemptId = await fetchLatestQcAttemptId(kitchenTicketId);

    var resolvedAttemptId = inProgressAttemptId;
    if (resolvedAttemptId == null || resolvedAttemptId.isEmpty) {
      resolvedAttemptId = await checkTicket(
        kitchenTicketId,
        checkerId: checkerId,
      );
    }
    resolvedAttemptId ??= attemptId ?? kitchenTicketId;

    var effectiveItemIds = orderItemIds
        ?.where((id) => id.trim().isNotEmpty)
        .toList();

    // If no orderItemIds were provided and rejections need resolution, query the ticket.
    final needsItemIds =
        effectiveItemIds == null ||
        effectiveItemIds.isEmpty ||
        (rejections != null &&
            rejections.any(
              (r) => (r['order_item_id'] as String?)?.trim().isEmpty ?? true,
            ));

    if (needsItemIds) {
      try {
        final res = await _dio.get<Object?>(
          _endpoint('/kitchen-ticket/$kitchenTicketId'),
        );
        final data = res.data;
        if (data is Map<String, dynamic>) {
          final parsedTicket = KitchenBoardTicket.tryFromApiJson(data);
          final fetchedIds = parsedTicket?.data.items
              .map((i) => i.orderItemId)
              .whereType<String>()
              .where((id) => id.trim().isNotEmpty)
              .toList();
          if (fetchedIds != null && fetchedIds.isNotEmpty) {
            effectiveItemIds = fetchedIds;
          }
        } else if (data is Map) {
          final parsedTicket = KitchenBoardTicket.tryFromApiJson(
            Map<String, dynamic>.from(data),
          );
          final fetchedIds = parsedTicket?.data.items
              .map((i) => i.orderItemId)
              .whereType<String>()
              .where((id) => id.trim().isNotEmpty)
              .toList();
          if (fetchedIds != null && fetchedIds.isNotEmpty) {
            effectiveItemIds = fetchedIds;
          }
        }
      } catch (_) {
        // Fall through to validation check below.
      }
    }

    final List<Map<String, dynamic>> finalRejections;
    if (rejections != null && rejections.isNotEmpty) {
      finalRejections = rejections.map((rej) {
        final map = Map<String, dynamic>.from(rej);
        final rawId = (map['order_item_id'] as String?)?.trim();
        if (rawId == null || rawId.isEmpty) {
          if (effectiveItemIds != null && effectiveItemIds.isNotEmpty) {
            map['order_item_id'] = effectiveItemIds.first;
          } else {
            map['order_item_id'] = kitchenTicketId;
          }
        }
        return map;
      }).toList();
    } else {
      if (effectiveItemIds == null || effectiveItemIds.isEmpty) {
        throw const KitchenBoardException(
          'Cannot fail QC: no valid order items found for this ticket.',
        );
      }

      finalRejections = effectiveItemIds
          .map(
            (id) => {
              'order_item_id': id,
              'portion_number': 1,
              'rejection_reason': 'INCOMPLETE',
              'description': reason,
            },
          )
          .toList();
    }

    await rejectQcAttempt(resolvedAttemptId, rejections: finalRejections);
  }

  /// Hands over a ready ticket via
  /// `POST /api/kitchen-fulfillment/{kitchenTicketId}/hand-over`.
  Future<void> handOverTicket(String kitchenTicketId) async {
    try {
      await _dio.post<Object?>(
        _endpoint('/kitchen-fulfillment/$kitchenTicketId/hand-over'),
      );
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Advances a ticket's fulfillment stage on the backend.
  Future<void> advanceTicket(
    KitchenBoardTicket ticket, {
    String? preparerId,
  }) async {
    final id = ticket.kitchenTicketId;
    final raw = ticket.rawStatus.toUpperCase();
    if (raw == 'QUEUED' || ticket.data.status == KkfcStatus.queued) {
      await acknowledgeTicket(id, preparerId: preparerId);
      return;
    }
    if (raw == 'ACKNOWLEDGED' ||
        ticket.data.status == KkfcStatus.acknowledged) {
      await prepareTicket(id, preparerId: preparerId);
      return;
    }

    final isPreparingOrReworking =
        raw == 'PREPARING' ||
        raw == 'REWORKING' ||
        ticket.data.status == KkfcStatus.preparing ||
        ticket.data.status == KkfcStatus.reworking;
    if (isPreparingOrReworking) {
      await sendToQc(id, preparerId: preparerId);
      return;
    }

    final isQcLane =
        raw == 'FOR_CHECKING' ||
        raw == 'CHECKING' ||
        ticket.data.status == KkfcStatus.checking ||
        ticket.lane == KitchenBoardLane.qcCheck;
    if (isQcLane) {
      await passQcForTicket(
        kitchenTicketId: id,
        attemptId: ticket.qcAttemptId,
        checkerId: preparerId,
      );
      return;
    }

    final actionPath = switch (raw) {
      'READY' => '/kitchen-fulfillment/$id/hand-over',
      _ => null,
    };
    if (actionPath == null) return;

    try {
      await _dio.post<Object?>(_endpoint(actionPath));
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Cancels an order and its associated kitchen ticket via
  /// `POST /api/kitchen-fulfillment/brands/{brandId}/orders/{orderId}/cancel`.
  Future<void> cancelTicket({
    required String brandId,
    required String orderId,
    required String reason,
  }) async {
    try {
      await _dio.post<Object?>(
        _endpoint(
          '/kitchen-fulfillment/brands/$brandId/orders/$orderId/cancel',
        ),
        data: {'cancellation_reason': reason.trim()},
      );
    } on DioException catch (error) {
      throw KitchenBoardException(
        _errorMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Fetches an order by [brandId] and [orderId] via
  /// `GET /api/brands/{brandId}/orders/{orderId}`.
  Future<Map<String, dynamic>?> fetchOrder({
    required String brandId,
    required String orderId,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        _endpoint('/brands/$brandId/orders/$orderId'),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {
      // Fallback: return null if order fetch fails or unauthorized
    }
    return null;
  }

  List<Object?> _extractTicketList(Object? body) {
    if (body is List) {
      return body;
    }
    if (body is Map) {
      final tickets = body['kitchenTickets'] ?? body['data'] ?? body['tickets'];
      if (tickets is List) {
        return tickets;
      }
    }
    throw const FormatException('Invalid kitchen-ticket/today response.');
  }

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    if (error.response == null) {
      return 'Unable to reach the server. Check your connection and try again.';
    }
    return switch (error.response?.statusCode) {
      401 => 'Your session expired. Sign in again.',
      403 => 'You do not have permission to view kitchen tickets.',
      _ => 'Failed to load kitchen tickets.',
    };
  }
}

final kitchenBoardRepositoryProvider = Provider<KitchenBoardRepository>((ref) {
  return KitchenBoardRepository(ref.watch(dioProvider));
});
