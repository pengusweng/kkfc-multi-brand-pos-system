import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';

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

  /// Advances a ticket's fulfillment stage on the backend.
  Future<void> advanceTicket(KitchenBoardTicket ticket) async {
    final id = ticket.kitchenTicketId;
    final actionPath = switch (ticket.rawStatus.toUpperCase()) {
      'QUEUED' => '/kitchen-fulfillment/$id/acknowledge',
      'ACKNOWLEDGED' => '/kitchen-fulfillment/$id/prepare',
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
