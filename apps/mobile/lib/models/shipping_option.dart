class ShippingOption {
  const ShippingOption({
    required this.id,
    required this.name,
    this.description,
    this.priceType = 'flat',
    this.amount,
    this.currencyCode,
    this.data = const {},
  });

  final String id;
  final String name;
  final String? description;
  final String priceType;
  final num? amount;
  final String? currencyCode;
  final Map<String, dynamic> data;

  bool get requiresCalculation => priceType == 'calculated';
  bool get hasPrice => amount != null;

  factory ShippingOption.fromJson(
    Map<String, dynamic> json, {
    String? preferredCurrencyCode,
  }) {
    final calculated = json['calculated_price'] is Map
        ? Map<String, dynamic>.from(json['calculated_price'] as Map)
        : const <String, dynamic>{};
    final provider = json['provider'] is Map
        ? Map<String, dynamic>.from(json['provider'] as Map)
        : const <String, dynamic>{};
    final type = json['type'] is Map
        ? Map<String, dynamic>.from(json['type'] as Map)
        : const <String, dynamic>{};
    final prices = json['prices'] is List
        ? (json['prices'] as List)
              .whereType<Map>()
              .map((price) => Map<String, dynamic>.from(price))
              .toList()
        : const <Map<String, dynamic>>[];
    Map<String, dynamic>? price;
    for (final candidate in prices) {
      if (candidate['currency_code']?.toString().toLowerCase() ==
          preferredCurrencyCode?.toLowerCase()) {
        price = candidate;
        break;
      }
    }
    price ??= prices.isEmpty ? null : prices.first;
    final rawData = json['data'];
    return ShippingOption(
      id: json['id']?.toString() ?? '',
      name:
          json['name']?.toString() ?? type['label']?.toString() ?? 'Giao hàng',
      description:
          json['description']?.toString() ?? type['description']?.toString(),
      priceType: json['price_type']?.toString() ?? 'flat',
      amount:
          _number(json['amount']) ??
          _number(calculated['calculated_amount']) ??
          _number(calculated['amount']) ??
          _number(price?['amount']),
      currencyCode:
          json['currency_code']?.toString() ??
          calculated['currency_code']?.toString() ??
          price?['currency_code']?.toString() ??
          preferredCurrencyCode ??
          provider['currency_code']?.toString(),
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
    );
  }

  ShippingOption copyWith({num? amount, String? currencyCode}) =>
      ShippingOption(
        id: id,
        name: name,
        description: description,
        priceType: priceType,
        amount: amount ?? this.amount,
        currencyCode: currencyCode ?? this.currencyCode,
        data: data,
      );

  static num? _number(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '');
}
