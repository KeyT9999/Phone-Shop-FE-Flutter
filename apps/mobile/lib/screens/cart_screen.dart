import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/medusa_service.dart';

class CartScreen extends StatefulWidget {
  final String? cartId;

  const CartScreen({Key? key, this.cartId}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _cartData;
  String? _error;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    if (widget.cartId == null || widget.cartId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _cartData = null;
      });
      return;
    }

    try {
      final cart = await MedusaService.getCart(widget.cartId!);
      setState(() {
        _cartData = cart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = (_cartData?['items'] as List?) ?? [];
    final total = _cartData?['total'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng của bạn'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Lỗi: $_error'))
              : items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('Giỏ hàng đang trống', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tiếp tục xem điện thoại'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          leading: item['thumbnail'] != null
                              ? Image.network(item['thumbnail'], width: 50, height: 50, fit: BoxFit.cover)
                              : const Icon(Icons.phone_android, size: 40),
                          title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Phiên bản: ${item['variant_title'] ?? ''}\nSL: ${item['quantity']}'),
                          trailing: Text(
                            _currencyFormat.format(item['unit_price'] ?? 0),
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tổng thanh toán:'),
                        Text(
                          _currencyFormat.format(total),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tiến hành đặt hàng thành công!')),
                        );
                      },
                      child: const Text('Đặt hàng ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
