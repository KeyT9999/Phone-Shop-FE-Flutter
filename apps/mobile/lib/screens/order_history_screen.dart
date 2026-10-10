import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer_order.dart';
import '../services/medusa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key, required this.service});

  final MedusaService service;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const _pageSize = 20;
  List<CustomerOrder> _orders = const [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders(reset: true);
  }

  Future<void> _loadOrders({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }
    try {
      final offset = reset ? 0 : _orders.length;
      final orders = await widget.service.getCustomerOrders(
        offset: offset,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _orders = reset ? orders : [..._orders, ...orders];
        _hasMore = orders.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Đơn hàng của tôi'),
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          onPressed: _isLoading ? null : () => _loadOrders(reset: true),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _isLoading
        ? const AppStateView(
            title: 'Đang tải đơn hàng',
            icon: Icons.receipt_long_outlined,
            isLoading: true,
          )
        : _error != null && _orders.isEmpty
        ? _errorState()
        : _orders.isEmpty
        ? _emptyState()
        : RefreshIndicator(
            onRefresh: () => _loadOrders(reset: true),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _orders.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == _orders.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _isLoadingMore
                          ? const CircularProgressIndicator()
                          : OutlinedButton(
                              onPressed: () => _loadOrders(),
                              child: const Text('Tải thêm'),
                            ),
                    ),
                  );
                }
                return _orderCard(_orders[index]);
              },
            ),
          ),
  );

  Widget _orderCard(CustomerOrder order) {
    final currency = order.currencyCode.toUpperCase();
    final money = NumberFormat.currency(
      locale: 'vi_VN',
      name: currency,
      decimalDigits: currency == 'VND' ? 0 : null,
    );
    final date = order.createdAt == null
        ? 'Ngày đặt hàng chưa có'
        : DateFormat(
            'dd/MM/yyyy HH:mm',
            'vi_VN',
          ).format(order.createdAt!.toLocal());
    final status = _statusLabel(order.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.number,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _StatusTag(label: status),
                ],
              ),
              const SizedBox(height: 6),
              Text(date, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Text('${order.items.length} sản phẩm'),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Expanded(child: Text('Tổng từ Medusa')),
                  Text(
                    money.format(order.total ?? 0),
                    style: const TextStyle(
                      color: AppColors.price,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState() => AppStateView(
    title: 'Chưa tải được đơn hàng',
    description: _error,
    icon: Icons.cloud_off_outlined,
    actionLabel: 'Thử lại',
    onAction: () => _loadOrders(reset: true),
  );

  Widget _emptyState() => RefreshIndicator(
    onRefresh: () => _loadOrders(reset: true),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: const [
        SizedBox(height: 90),
        Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.textMuted),
        SizedBox(height: 14),
        Text(
          'Chưa có đơn hàng',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        Text(
          'Đơn hàng đã đặt sẽ xuất hiện tại đây.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
      ],
    ),
  );

  String _statusLabel(String? value) => switch (value) {
    'pending' => 'Đang xử lý',
    'completed' => 'Hoàn tất',
    'archived' => 'Đã lưu trữ',
    'canceled' => 'Đã hủy',
    _ => value ?? 'Chưa xác định',
  };
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
