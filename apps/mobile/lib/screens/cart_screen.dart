import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/cart_storage.dart';
import '../services/medusa_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    this.cartId,
    this.service,
    this.storage,
    this.onCartIdChanged,
  });

  final String? cartId;
  final MedusaService? service;
  final CartStorage? storage;
  final ValueChanged<String?>? onCartIdChanged;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final MedusaService _service;
  late final CartStorage _storage;
  late String? _cartId;

  Map<String, dynamic>? _cartData;
  final Set<String> _busyItemIds = {};
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> get _items {
    final items = _cartData?['items'];
    if (items is! List) return const [];
    return items.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  String get _currencyCode =>
      _cartData?['currency_code']?.toString().toUpperCase() ?? 'VND';

  NumberFormat get _currencyFormat => NumberFormat.currency(
    locale: 'vi_VN',
    name: _currencyCode,
    decimalDigits: _currencyCode == 'VND' ? 0 : null,
  );

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MedusaService.instance;
    _storage = widget.storage ?? CartStorage.instance;
    _cartId = widget.cartId;
    _loadCart();
  }

  Future<void> _loadCart() async {
    final cartId = _cartId;
    if (cartId == null || cartId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = null;
        _cartData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cart = await _service.getCart(cartId);
      if (!mounted) return;
      setState(() {
        _cartData = cart;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _changeQuantity(
    Map<String, dynamic> item,
    int adjustment,
  ) async {
    final cartId = _cartId;
    final itemId = item['id']?.toString();
    final currentQuantity = _integer(item['quantity']);
    if (cartId == null || itemId == null || itemId.isEmpty) return;
    if (_busyItemIds.contains(itemId)) return;

    setState(() => _busyItemIds.add(itemId));
    try {
      final updatedCart = currentQuantity + adjustment < 1
          ? await _service.removeCartItem(cartId: cartId, itemId: itemId)
          : await _service.updateCartItemQuantity(
              cartId: cartId,
              itemId: itemId,
              quantity: currentQuantity + adjustment,
            );
      if (mounted) setState(() => _cartData = updatedCart);
    } catch (error) {
      if (mounted) _showMessage('Không thể cập nhật giỏ hàng: $error');
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(itemId));
    }
  }

  Future<void> _removeItem(Map<String, dynamic> item) async {
    final cartId = _cartId;
    final itemId = item['id']?.toString();
    if (cartId == null || itemId == null || itemId.isEmpty) return;
    if (_busyItemIds.contains(itemId)) return;

    setState(() => _busyItemIds.add(itemId));
    try {
      final updatedCart = await _service.removeCartItem(
        cartId: cartId,
        itemId: itemId,
      );
      if (mounted) setState(() => _cartData = updatedCart);
    } catch (error) {
      if (mounted) _showMessage('Không thể xóa sản phẩm: $error');
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(itemId));
    }
  }

  Future<void> _forgetCart() async {
    try {
      await _storage.clearCartId();
    } catch (error) {
      if (mounted) _showMessage('Không thể xóa mã giỏ đã lưu: $error');
      return;
    }
    widget.onCartIdChanged?.call(null);
    if (!mounted) return;
    setState(() {
      _cartId = null;
      _cartData = null;
      _error = null;
      _isLoading = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        title: const Text('Giỏ hàng'),
        actions: [
          if (_cartId != null && !_isLoading && _error == null)
            IconButton(
              tooltip: 'Tải lại giỏ hàng',
              onPressed: _loadCart,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState(context)
          : _items.isEmpty
          ? _buildEmptyState(context)
          : _buildItemsList(context),
      bottomNavigationBar: !_isLoading && _error == null && _items.isNotEmpty
          ? _buildTotals(context)
          : null,
    );
  }

  Widget _buildItemsList(BuildContext context) {
    final items = _items;
    return RefreshIndicator(
      onRefresh: _loadCart,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildCartItem(context, items[index]),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final itemId = item['id']?.toString() ?? '';
    final quantity = _integer(item['quantity']);
    final busy = _busyItemIds.contains(itemId);
    final thumbnail = item['thumbnail']?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EBF1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: thumbnail == null || thumbnail.isEmpty
                ? Icon(
                    Icons.phone_iphone_rounded,
                    size: 34,
                    color: theme.colorScheme.primary.withValues(alpha: 0.45),
                  )
                : Image.network(
                    thumbnail,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.phone_iphone_rounded,
                      size: 34,
                      color: theme.colorScheme.primary.withValues(alpha: 0.45),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['title']?.toString() ?? 'Sản phẩm',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Xóa ${item['title'] ?? 'sản phẩm'}',
                      visualDensity: VisualDensity.compact,
                      onPressed: busy ? null : () => _removeItem(item),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: const Color(0xFF777D8A),
                    ),
                  ],
                ),
                if (item['variant_title']?.toString().isNotEmpty == true)
                  Text(
                    item['variant_title'].toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF777D8A),
                    ),
                  ),
                const SizedBox(height: 5),
                Text(
                  _currencyFormat.format(_amount(item['unit_price'])),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFFC24136),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _quantityButton(
                      tooltip: 'Giảm số lượng',
                      icon: Icons.remove,
                      onPressed: busy ? null : () => _changeQuantity(item, -1),
                    ),
                    SizedBox(
                      width: 34,
                      child: busy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '$quantity',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    _quantityButton(
                      tooltip: 'Tăng số lượng',
                      icon: Icons.add,
                      onPressed: busy ? null : () => _changeQuantity(item, 1),
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

  Widget _quantityButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }

  Widget _buildTotals(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = _cartData?['subtotal'];
    final discount = _cartData?['discount_total'];
    final shipping = _cartData?['shipping_total'];
    final total = _cartData?['total'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9EBF1))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtotal != null)
              _totalRow('Tạm tính', _currencyFormat.format(_amount(subtotal))),
            if (_amount(discount) > 0)
              _totalRow(
                'Ưu đãi',
                '-${_currencyFormat.format(_amount(discount))}',
                valueColor: const Color(0xFF23734D),
              ),
            if (_amount(shipping) > 0)
              _totalRow(
                'Vận chuyển',
                _currencyFormat.format(_amount(shipping)),
              ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng từ Medusa',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _currencyFormat.format(_amount(total)),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFC24136),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Thanh toán sẽ được bổ sung ở phase tiếp theo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF777D8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF777D8A)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF303646),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _loadCart,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Giỏ hàng đang trống',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thêm một chiếc điện thoại bạn thích để xem tổng tiền tại đây.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF777D8A),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tiếp tục xem điện thoại'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 54,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa tải được giỏ hàng',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF777D8A),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadCart,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
            TextButton(
              onPressed: _forgetCart,
              child: const Text('Xóa mã giỏ đã lưu trên thiết bị'),
            ),
          ],
        ),
      ),
    );
  }

  int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  num _amount(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
}
