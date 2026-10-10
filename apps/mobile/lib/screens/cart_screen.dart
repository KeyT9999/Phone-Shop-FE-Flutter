import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/cart_storage.dart';
import '../services/medusa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    this.cartId,
    this.service,
    this.storage,
    this.cartRevision = 0,
    this.onCartIdChanged,
    this.onContinueShopping,
  });

  final String? cartId;
  final MedusaService? service;
  final CartStorage? storage;
  final int cartRevision;
  final ValueChanged<String?>? onCartIdChanged;
  final VoidCallback? onContinueShopping;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final MedusaService _service;
  late final CartStorage _storage;
  late String? _cartId;

  Map<String, dynamic>? _cartData;
  final Set<String> _busyItemIds = {};
  String? _formatterCurrencyCode;
  NumberFormat? _currencyFormatter;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> get _items {
    final items = _cartData?['items'];
    if (items is! List) return const [];
    return items.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  String get _currencyCode =>
      _cartData?['currency_code']?.toString().toUpperCase() ?? 'VND';

  NumberFormat get _currencyFormat {
    final currencyCode = _currencyCode;
    if (_currencyFormatter == null || _formatterCurrencyCode != currencyCode) {
      _formatterCurrencyCode = currencyCode;
      _currencyFormatter = NumberFormat.currency(
        locale: 'vi_VN',
        name: currencyCode,
        decimalDigits: currencyCode == 'VND' ? 0 : null,
      );
    }
    return _currencyFormatter!;
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MedusaService.instance;
    _storage = widget.storage ?? CartStorage.instance;
    _cartId = widget.cartId;
    _loadCart();
    _restoreCartId();
  }

  @override
  void didUpdateWidget(covariant CartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cartId != widget.cartId && widget.cartId != _cartId) {
      _cartId = widget.cartId;
      _loadCart();
    } else if (oldWidget.cartRevision != widget.cartRevision) {
      _loadCart();
    }
  }

  Future<void> _restoreCartId() async {
    if (_cartId != null) return;
    try {
      final cartId = await _storage.readCartId();
      if (!mounted || _cartId != null || cartId == null) return;
      setState(() => _cartId = cartId);
      await _loadCart();
    } catch (_) {
      // The empty state remains usable if local storage is unavailable.
    }
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

  Future<void> _openCheckout() async {
    final cartId = _cartId;
    if (cartId == null || cartId.isEmpty) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cartId: cartId,
          service: _service,
          storage: _storage,
          onCartIdChanged: (id) {
            widget.onCartIdChanged?.call(id);
            if (mounted) setState(() => _cartId = id);
          },
        ),
      ),
    );
    if (mounted) await _loadCart();
  }

  void _continueShopping() {
    if (widget.onContinueShopping != null) {
      widget.onContinueShopping!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
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
          ? const AppStateView(
              title: 'Đang tải giỏ hàng',
              icon: Icons.shopping_bag_outlined,
              isLoading: true,
            )
          : _error != null
          ? _buildErrorState(context)
          : items.isEmpty
          ? _buildEmptyState(context)
          : _buildItemsList(context, items),
      bottomNavigationBar: !_isLoading && _error == null && items.isNotEmpty
          ? _buildTotals(context)
          : null,
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
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

    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.imageSurface,
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
                      onPressed: busy ? null : () => _removeItem(item),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                if (item['variant_title']?.toString().isNotEmpty == true)
                  Text(
                    item['variant_title'].toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                const SizedBox(height: 5),
                Text(
                  _currencyFormat.format(_amount(item['unit_price'])),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.price,
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
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
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
                valueColor: AppColors.success,
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
                    color: AppColors.price,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppPrimaryAction(
              onPressed: _openCheckout,
              icon: Icons.arrow_forward_rounded,
              label: 'Tiếp tục thanh toán',
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
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Giỏ hàng đang trống',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Thêm một chiếc điện thoại bạn thích để xem tổng tiền tại đây.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textMuted, height: 1.45),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.tonal(
                  onPressed: _continueShopping,
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
    return Column(
      children: [
        Expanded(
          child: AppStateView(
            title: 'Chưa tải được giỏ hàng',
            description: _error,
            icon: Icons.cloud_off_outlined,
            actionLabel: 'Thử lại',
            onAction: _loadCart,
          ),
        ),
        TextButton(
          onPressed: _forgetCart,
          child: const Text('Xóa mã giỏ đã lưu trên thiết bị'),
        ),
      ],
    );
  }

  int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  num _amount(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
}
