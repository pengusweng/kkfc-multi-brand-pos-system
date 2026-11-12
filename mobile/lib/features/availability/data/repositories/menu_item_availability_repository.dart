import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';

/// Repository for updating menu item availability via `PATCH /api/menu-items/availability/:id`.
class MenuItemAvailabilityRepository {
  MenuItemAvailabilityRepository(this._dio);

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

  /// Sets menu item availability (`is_available`).
  ///
  /// Sends `{ "availability": availability }` to `PATCH /api/menu-items/availability/:id`.
  Future<void> updateAvailability({
    required String menuItemId,
    required bool availability,
  }) async {
    await _dio.patch<dynamic>(
      _endpoint('/menu-items/availability/$menuItemId'),
      data: {'availability': availability},
    );
  }
}

final menuItemAvailabilityRepositoryProvider =
    Provider<MenuItemAvailabilityRepository>((ref) {
      return MenuItemAvailabilityRepository(ref.watch(dioProvider));
    });
