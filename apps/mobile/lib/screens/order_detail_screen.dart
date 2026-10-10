import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer_order.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final currency = order.currencyCode.toUpperCase();
    final money = NumberFormat.currency(
      locale: 'vi_VN',
      name: currency,
      decimalDigits: currency == 'VND' ? 0 : null,
    );
    final address = order.shippingAddress ?? const <String, dynamic>{};
    final name = [address['first_name'], address['last_name']]
        .whereType<Object>()
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .join(' ');
    final locality =
        [address['address_1'], address['address_2'], address['city']]
            .whereType<Object>()
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .join(', ');
    final created = order.createdAt == null
        ? null
        : DateFormat(
            'dd/MM/yyyy HH:mm',
            'vi_VN',
          ).format(order.createdAt!.toLocal());
    return Scaffold(
      appBar: AppBar(title: Text('Đơn ${order.number}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          _card(
            'Trạng thái đơn hàng',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label(order.status)),
                if (order.paymentStatus != null) ...[
                  const SizedBox(height: 6),
                  Text('Thanh toán: ${_label(order.paymentStatus)}'),
                ],
                if (order.fulfillmentStatus != null) ...[
                  const SizedBox(height: 6),
                  Text('Giao hàng: ${_label(order.fulfillmentStatus)}'),
                ],
                if (created != null) ...[
                  const SizedBox(height: 6),
                  Text('Ngày đặt: $created'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            'Sản phẩm',
            Column(
              children: [
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['title'] ?? 'Sản phẩm'} × ${item['quantity'] ?? 1}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          money.format(
                            _amount(item['total'] ?? item['subtotal']),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (order.items.isEmpty)
                  const Text('Thông tin sản phẩm không có trong phản hồi.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            'Địa chỉ giao hàng',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                if (address['phone'] != null) Text(address['phone'].toString()),
                if (locality.isNotEmpty)
                  Text(locality, style: const TextStyle(height: 1.4)),
                if (name.isEmpty && locality.isEmpty)
                  const Text('Không có trong phản hồi đơn hàng.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            'Tổng tiền',
            Column(
              children: [
                _totalRow('Tạm tính', order.subtotal, money),
                _totalRow('Vận chuyển', order.shippingTotal, money),
                if ((order.discountTotal ?? 0) > 0)
                  _totalRow(
                    'Ưu đãi',
                    order.discountTotal,
                    money,
                    negative: true,
                  ),
                const Divider(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tổng từ Medusa',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      money.format(order.total ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, Widget child) => AppSurface(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const Divider(height: 18),
        child,
      ],
    ),
  );

  Widget _totalRow(
    String label,
    num? amount,
    NumberFormat money, {
    bool negative = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        Text('${negative ? '-' : ''}${money.format(amount ?? 0)}'),
      ],
    ),
  );

  String _label(String? value) {
    if (value == null || value.isEmpty) return 'Chưa xác định';
    return value[0].toUpperCase() + value.substring(1).replaceAll('_', ' ');
  }

  num _amount(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
}
