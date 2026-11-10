import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/models/brand_models.dart';

class BrandRepository {
  BrandRepository(this._dio);

  final Dio _dio;

  /// Fetches all active brands from the API.
  Future<List<AssignedBrand>> getAll({bool activeOnly = true}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/brands',
      queryParameters: {'page': 1, 'limit': 100, 'activeOnly': activeOnly},
    );
    final data = response.data?['data'];
    if (data is! List) {
      throw const FormatException('Invalid brands response.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(AssignedBrand.fromApiJson)
        .toList();
  }

  Future<AssignedBrand> getById(String brandId) async {
    final response = await _dio.get<Map<String, dynamic>>('/brands/$brandId');
    final brand = response.data;
    if (brand == null) {
      throw const FormatException('Invalid brand response.');
    }
    return AssignedBrand.fromApiJson(brand);
  }
}

final brandRepositoryProvider = Provider<BrandRepository>(
  (ref) => BrandRepository(ref.watch(dioProvider)),
);
