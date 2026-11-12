import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/features/availability/data/repositories/menu_item_availability_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final Future<ResponseBody> Function(String? body) respond;
  RequestOptions? lastRequest;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    String? body;
    if (requestStream != null) {
      final buffer = <int>[];
      await for (final chunk in requestStream) {
        buffer.addAll(chunk);
      }
      body = utf8.decode(buffer);
    }

    lastRequest = options;
    lastBody = body;
    return respond(body);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('MenuItemAvailabilityRepository', () {
    test('sends PATCH /api/menu-items/availability/:id with { availability: false }', () async {
      late _FakeAdapter adapter;
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      adapter = _FakeAdapter((body) async {
        return ResponseBody.fromString(
          jsonEncode({'menu_item_id': 'item-1', 'is_available': false}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      dio.httpClientAdapter = adapter;

      final repository = MenuItemAvailabilityRepository(dio);
      await repository.updateAvailability(
        menuItemId: 'item-1',
        availability: false,
      );

      expect(adapter.lastRequest?.method, 'PATCH');
      expect(
        adapter.lastRequest?.uri.path,
        '/api/menu-items/availability/item-1',
      );
      final decodedBody = jsonDecode(adapter.lastBody ?? '{}');
      expect(decodedBody, {'availability': false});
    });

    test('sends PATCH /api/menu-items/availability/:id with { availability: true }', () async {
      late _FakeAdapter adapter;
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      adapter = _FakeAdapter((body) async {
        return ResponseBody.fromString(
          jsonEncode({'menu_item_id': 'item-2', 'is_available': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      dio.httpClientAdapter = adapter;

      final repository = MenuItemAvailabilityRepository(dio);
      await repository.updateAvailability(
        menuItemId: 'item-2',
        availability: true,
      );

      expect(adapter.lastRequest?.method, 'PATCH');
      expect(
        adapter.lastRequest?.uri.path,
        '/api/menu-items/availability/item-2',
      );
      final decodedBody = jsonDecode(adapter.lastBody ?? '{}');
      expect(decodedBody, {'availability': true});
    });

    test('propagates error when API call fails', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      dio.httpClientAdapter = _FakeAdapter((body) async {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Conflict'}),
          409,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final repository = MenuItemAvailabilityRepository(dio);
      expect(
        () => repository.updateAvailability(
          menuItemId: 'item-1',
          availability: false,
        ),
        throwsA(isA<DioException>()),
      );
    });
  });
}
