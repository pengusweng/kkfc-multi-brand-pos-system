/// Represents an active order draft created or confirmed via the orders API.
class OrderDraft {
  const OrderDraft({
    required this.orderId,
    required this.orderCode,
    required this.orderNumber,
    required this.brandId,
    required this.channel,
    required this.status,
    this.tableReference,
    this.ticketNumber,
    this.paymentMethod,
    this.paymentStatus,
    this.rawResponse = const {},
  });

  final String orderId;
  final String orderCode;
  final int orderNumber;
  final String brandId;
  final String channel;
  final String status;
  final String? tableReference;
  final String? ticketNumber;
  final String? paymentMethod;
  final String? paymentStatus;
  final Map<String, dynamic> rawResponse;

  factory OrderDraft.fromJson(Map<String, dynamic> json) {
    final ticketObj = json['kitchen_tickets_order'];
    String? ticket;
    if (ticketObj is Map<String, dynamic>) {
      ticket = ticketObj['ticket_number'] as String?;
    }

    return OrderDraft(
      orderId: (json['order_id'] as String?) ?? '',
      orderCode: (json['order_code'] as String?) ?? '',
      orderNumber: (json['order_number'] as int?) ?? 0,
      brandId: (json['brand_id'] as String?) ?? '',
      channel: (json['order_channel'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'DRAFT',
      tableReference: json['table_reference'] as String?,
      ticketNumber: ticket,
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String?,
      rawResponse: json,
    );
  }

  OrderDraft copyWith({
    String? orderId,
    String? orderCode,
    int? orderNumber,
    String? brandId,
    String? channel,
    String? status,
    String? tableReference,
    String? ticketNumber,
    String? paymentMethod,
    String? paymentStatus,
    Map<String, dynamic>? rawResponse,
  }) {
    return OrderDraft(
      orderId: orderId ?? this.orderId,
      orderCode: orderCode ?? this.orderCode,
      orderNumber: orderNumber ?? this.orderNumber,
      brandId: brandId ?? this.brandId,
      channel: channel ?? this.channel,
      status: status ?? this.status,
      tableReference: tableReference ?? this.tableReference,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }
}
