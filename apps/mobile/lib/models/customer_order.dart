class CustomerOrder {
  const CustomerOrder({
    required this.id,
    this.displayId,
    this.status,
    this.paymentStatus,
    this.fulfillmentStatus,
    this.currencyCode = 'vnd',
    this.total,
    this.subtotal,
    this.shippingTotal,
    this.discountTotal,
    this.createdAt,
    this.items = const [],
    this.shippingAddress,
    this.shippingMethods = const [],
  });

  final String id;
  final int? displayId;
  final String? status;
  final String? paymentStatus;
  final String? fulfillmentStatus;
  final String currencyCode;
  final num? total;
  final num? subtotal;
  final num? shippingTotal;
  final num? discountTotal;
  final DateTime? createdAt;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? shippingAddress;
  final List<Map<String, dynamic>> shippingMethods;

  String get number => displayId == null ? id : '#$displayId';

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final address = json['shipping_address'];
    final rawItems = json['items'];
    final rawMethods = json['shipping_methods'];
    return CustomerOrder(
      id: json['id']?.toString() ?? '',
      displayId: _int(json['display_id']),
      status: json['status']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      fulfillmentStatus: json['fulfillment_status']?.toString(),
      currencyCode: json['currency_code']?.toString() ?? 'vnd',
      total: _number(json['total']),
      subtotal: _number(json['subtotal']),
      shippingTotal: _number(json['shipping_total']),
      discountTotal: _number(json['discount_total']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : const [],
      shippingAddress: address is Map
          ? Map<String, dynamic>.from(address)
          : null,
      shippingMethods: rawMethods is List
          ? rawMethods
                .whereType<Map>()
                .map((method) => Map<String, dynamic>.from(method))
                .toList()
          : const [],
    );
  }

  static int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static num? _number(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '');
}
