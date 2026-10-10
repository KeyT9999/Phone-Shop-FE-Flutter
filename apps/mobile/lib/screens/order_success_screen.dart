import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer_order.dart';
import '../services/medusa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'order_detail_screen.dart';
import 'order_history_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.order,
    required this.service,
    this.storageNotice,
  });

  final CustomerOrder order;
  final MedusaService service;
  final String? storageNotice;

  @override
  Widget build(BuildContext context) {
    final currency = order.currencyCode.toUpperCase();
    final money = NumberFormat.currency(
      locale: 'vi_VN',
      name: currency,
      decimalDigits: currency == 'VND' ? 0 : null,
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Đặt hàng'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: AppSurface(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.successSurface,
                    child: Icon(
                      Icons.check_rounded,
                      size: 38,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Đã gửi đơn hàng',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Mã đơn ${order.number}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    money.format(order.total ?? 0),
                    style: const TextStyle(
                      color: AppColors.price,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Thanh toán khi nhận hàng (COD). Trạng thái đơn và thanh toán hiển thị theo dữ liệu Medusa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, height: 1.4),
                  ),
                  if (storageNotice != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      storageNotice!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.warning),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pushReplacement<void, void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      ),
                      child: const Text('Xem đơn hàng'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushAndRemoveUntil<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderHistoryScreen(service: service),
                      ),
                      (route) => route.isFirst,
                    ),
                    child: const Text('Lịch sử đơn hàng'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
