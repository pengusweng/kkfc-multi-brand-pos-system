import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
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
  Future<void> assignPreparer(
    String kitchenTicketId,
    String preparerId,
  ) async {
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
    if (raw == 'ACKNOWLEDGED' || ticket.data.status == KkfcStatus.acknowledged) {
      await prepareTicket(id, preparerId: preparerId);
      return;
    }

    final actionPath = switch (raw) {
      'PREPARING' || 'REWORKING' => '/kitchen-fulfillment/$id/for-checking',
      'FOR_CHECKING' => '/kitchen-fulfillment/$id/check',
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
