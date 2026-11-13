import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

/// Generates an RFC 4122 v4 UUID for idempotent order creation requests.
String generateOrderId([Random? random]) {
  final rng = random ?? _secureOrFallbackRandom();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx

  String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).join();
  return '${h.substring(0, 8)}-'
      '${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-'
      '${h.substring(20, 32)}';
}

Random _secureOrFallbackRandom() {
  try {
    return Random.secure();
  } catch (_) {
    return Random();
  }
}

/// Shared request serialization keeps retry identity aligned with the API payload.
Map<String, dynamic> buildCreateOrderPayload({
  required MenuChannel channel,
  required List<CartLine> lines,
  String? reference,
  String? merchantStoreReference,
  String? notes,
}) {
  final trimmedReference = reference?.trim() ?? '';
  final trimmedStore = merchantStoreReference?.trim() ?? '';
  final trimmedNotes = notes?.trim() ?? '';

  return <String, dynamic>{
    'order_channel': channel.apiValue,
    if (channel == MenuChannel.dineIn && trimmedReference.isNotEmpty)
      'table_reference': trimmedReference,
    if (channel.isPlatform && trimmedStore.isNotEmpty)
      'merchant_store_reference': trimmedStore,
    if (channel.isPlatform && trimmedReference.isNotEmpty)
      'external_order_reference': trimmedReference,
    if (channel == MenuChannel.takeaway && trimmedReference.isNotEmpty)
      'notes': trimmedNotes.isEmpty
          ? trimmedReference
          : '$trimmedReference · $trimmedNotes',
    if (channel != MenuChannel.takeaway && trimmedNotes.isNotEmpty)
      'notes': trimmedNotes,
    'lines': [
      for (final line in lines)
        {
          'menu_item_id': line.item.id,
          'quantity': line.quantity,
          if (line.selectedModifierIds.isNotEmpty)
            'modifier_ids': line.selectedModifierIds,
        },
    ],
  };
}

class OrderEntryRepository {
  OrderEntryRepository(this._dio);

  final Dio _dio;

  /// Sends a new order to `POST /brands/:brandId/orders`.
  Future<Map<String, dynamic>> createOrder({
    required String brandId,
    required String orderId,
    required MenuChannel channel,
    required List<CartLine> lines,
    String? reference,
    String? merchantStoreReference,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'order_id': orderId,
      ...buildCreateOrderPayload(
        channel: channel,
        lines: lines,
        reference: reference,
        merchantStoreReference: merchantStoreReference,
        notes: notes,
      ),
    };

    final response = await _dio.post<Map<String, dynamic>>(
      '/brands/$brandId/orders',
      data: payload,
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('Invalid create order response.');
    }
    return body;
  }

  /// Verifies an existing draft order at `POST /brands/:brandId/orders/:orderId/verify`.
  Future<Map<String, dynamic>> verifyOrder({
    required String brandId,
    required String orderId,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentReference,
  }) async {
    final payload = <String, dynamic>{};
    if (paymentMethod != null) payload['payment_method'] = paymentMethod;
    if (paymentStatus != null) payload['payment_status'] = paymentStatus;
    if (paymentReference != null) {
      payload['payment_reference'] = paymentReference;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/brands/$brandId/orders/$orderId/verify',
      data: payload,
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('Invalid verify order response.');
    }
    return body;
  }

  /// Confirms an existing draft order at `POST /brands/:brandId/orders/:orderId/confirm`.
  Future<Map<String, dynamic>> confirmOrder({
    required String brandId,
    required String orderId,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentReference,
  }) async {
    final payload = <String, dynamic>{};
    if (paymentMethod != null) payload['payment_method'] = paymentMethod;
    if (paymentStatus != null) payload['payment_status'] = paymentStatus;
    if (paymentReference != null) {
      payload['payment_reference'] = paymentReference;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/brands/$brandId/orders/$orderId/confirm',
      data: payload,
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('Invalid confirm order response.');
    }
    return body;
  }

  /// Cancels an unconfirmed draft order at `POST /brands/:brandId/orders/:orderId/cancel`.
  Future<Map<String, dynamic>> cancelDraftOrder({
    required String brandId,
    required String orderId,
    required String cancellationReason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/brands/$brandId/orders/$orderId/cancel',
      data: {'cancellation_reason': cancellationReason},
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('Invalid cancel draft order response.');
    }
    return body;
  }
}

final orderEntryRepositoryProvider = Provider<OrderEntryRepository>(
  (ref) => OrderEntryRepository(ref.watch(dioProvider)),
);
