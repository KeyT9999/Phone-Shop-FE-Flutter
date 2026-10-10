class PaymentProvider {
  const PaymentProvider({required this.id, this.isEnabled = true});

  final String id;
  final bool isEnabled;

  bool get isSystem => id == 'pp_system' || id.startsWith('pp_system_');

  String get label => isSystem ? 'Thanh toán khi nhận hàng (COD)' : id;

  factory PaymentProvider.fromJson(Map<String, dynamic> json) =>
      PaymentProvider(
        id: json['id']?.toString() ?? '',
        isEnabled: json['is_enabled'] != false,
      );
}
