import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../services/cart_storage.dart';
import '../services/medusa_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.cartId,
    this.cartStorage,
    this.onCartUpdated,
    this.service,
  });

  final Product product;
  final String? cartId;
  final CartStorage? cartStorage;
  final ValueChanged<String>? onCartUpdated;
  final MedusaService? service;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  late final MedusaService _service;
  late final CartStorage _cartStorage;
  late Product _product;
  final Map<String, String> _selectedOptions = {};
  int _quantity = 1;
  String? _activeCartId;
  bool _isLoadingDetail = true;
  bool _isAdding = false;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MedusaService.instance;
    _cartStorage = widget.cartStorage ?? CartStorage.instance;
    _activeCartId = widget.cartId;
    _product = widget.product;
    _initializeOptions(_product);
    _loadProductDetail();
  }

  ProductVariant? get _selectedVariant {
    if (_product.options.isEmpty) {
      return _product.variants.isEmpty ? null : _product.variants.first;
    }
    return _product.variantForOptions(_selectedOptions);
  }

  void _initializeOptions(Product product) {
    _selectedOptions.clear();
    if (product.variants.isEmpty) return;

    final firstVariant = product.variants.first;
    for (final option in product.options) {
      final value = firstVariant.optionValues[option.id];
      if (value != null) _selectedOptions[option.id] = value;
    }
  }

  Future<void> _loadProductDetail({bool showProgress = false}) async {
    if (showProgress) {
      setState(() {
        _isLoadingDetail = true;
        _detailError = null;
      });
    }

    try {
      final product = await _service.getProductDetail(widget.product.id);
      if (!mounted) return;
      setState(() {
        _product = product;
        _isLoadingDetail = false;
        _detailError = null;
        _initializeOptions(product);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingDetail = false;
        _detailError = error.toString();
      });
    }
  }

  void _selectOption(ProductOption option, String value) {
    final selection = {..._selectedOptions, option.id: value};
    if (!_product.hasVariantForOptions(selection)) return;

    setState(() {
      _selectedOptions
        ..clear()
        ..addAll(selection);
      _quantity = 1;
    });
  }

  bool _isOptionValueAvailable(ProductOption option, String value) {
    return _product.hasVariantForOptions({
      ..._selectedOptions,
      option.id: value,
    });
  }

  Future<void> _handleAddToCart() async {
    final variant = _selectedVariant;
    if (variant == null ||
        variant.isAvailable != true ||
        _detailError != null) {
      return;
    }

    setState(() => _isAdding = true);
    try {
      var activeCartId = _activeCartId ?? '';
      var storageWarning = false;
      if (activeCartId.isEmpty) {
        activeCartId = await _service.createCart();
        _activeCartId = activeCartId;
        widget.onCartUpdated?.call(activeCartId);
        try {
          await _cartStorage.saveCartId(activeCartId);
        } catch (_) {
          storageWarning = true;
        }
      }

      await _service.addToCart(
        cartId: activeCartId,
        variantId: variant.id,
        quantity: _quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: storageWarning
                ? Colors.orange.shade800
                : Colors.green.shade700,
            content: Text(
              storageWarning
                  ? 'Đã thêm ${variant.title}. Không thể lưu giỏ hàng sau khi thoát app.'
                  : 'Đã thêm ${variant.title} vào giỏ hàng.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('$error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedVariant = _selectedVariant;
    final canAddToCart =
        !_isLoadingDetail &&
        _detailError == null &&
        selectedVariant?.isAvailable == true &&
        !_isAdding;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        title: const Text('Chi tiết sản phẩm'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildHeroImage(context),
          const SizedBox(height: 18),
          if (_isLoadingDetail) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 10),
            Text(
              'Đang cập nhật giá và tồn kho từ Medusa…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF777D8A),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_detailError != null) _buildDetailError(context),
          Text(
            _product.brand ?? 'Điện thoại',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _product.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF202533),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _selectedPriceLabel(selectedVariant),
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFFC24136),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (selectedVariant != null) ...[
            const SizedBox(height: 9),
            _buildStockStatus(context, selectedVariant),
          ],
          const SizedBox(height: 22),
          if (_product.options.isEmpty)
            _buildNoOptionsNotice(context)
          else
            ..._product.options.map(_buildOptionPicker),
          if (selectedVariant != null) ...[
            const SizedBox(height: 18),
            _buildQuantityPicker(context, selectedVariant),
          ],
          if (_product.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 20),
            _buildSectionTitle(context, 'Mô tả'),
            const SizedBox(height: 8),
            Text(
              _product.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF555B68),
                height: 1.55,
              ),
            ),
          ],
          if (_specificationRows.isNotEmpty) ...[
            const SizedBox(height: 22),
            _buildSectionTitle(context, 'Thông số kỹ thuật'),
            const SizedBox(height: 10),
            _buildSpecifications(context),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9EBF1))),
          ),
          child: SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: canAddToCart ? _handleAddToCart : null,
              icon: _isAdding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.shopping_bag_outlined),
              label: Text(
                _isAdding
                    ? 'Đang thêm…'
                    : selectedVariant?.isAvailable == false
                    ? 'Tạm hết hàng'
                    : 'Thêm vào giỏ hàng',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _selectedPriceLabel(ProductVariant? variant) {
    if (variant == null) return 'Chọn đủ cấu hình';
    final price = variant.price;
    if (price == null || price <= 0) return 'Liên hệ báo giá';
    return _currencyFormat.format(price);
  }

  Widget _buildHeroImage(BuildContext context) {
    final imageUrl =
        _product.thumbnail ??
        (_product.images.isEmpty ? null : _product.images.first);
    return Container(
      height: 270,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EBF1)),
      ),
      alignment: Alignment.center,
      child: imageUrl == null
          ? Icon(
              Icons.phone_iphone_rounded,
              size: 88,
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.35),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.phone_iphone_rounded,
                  size: 88,
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.35),
                ),
              ),
            ),
    );
  }

  Widget _buildDetailError(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFF9A6500)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chưa xác minh được giá và tồn kho mới nhất.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _detailError!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton.icon(
                  onPressed: () => _loadProductDetail(showProgress: true),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tải lại'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatus(BuildContext context, ProductVariant variant) {
    final Color color;
    final IconData icon;
    final String text;

    if (variant.isBackorder) {
      color = const Color(0xFF825B12);
      icon = Icons.schedule_outlined;
      text = 'Có thể đặt trước';
    } else if (variant.manageInventory == false) {
      color = const Color(0xFF23734D);
      icon = Icons.check_circle_outline;
      text = 'Có thể đặt hàng';
    } else if (variant.inventoryQuantity != null &&
        variant.inventoryQuantity! > 0) {
      color = const Color(0xFF23734D);
      icon = Icons.check_circle_outline;
      text = 'Còn ${variant.inventoryQuantity} sản phẩm';
    } else if (variant.isAvailable == false) {
      color = const Color(0xFF9A5360);
      icon = Icons.remove_circle_outline;
      text = 'Tạm hết hàng';
    } else {
      color = const Color(0xFF777D8A);
      icon = Icons.help_outline;
      text = 'Chưa xác minh tồn kho';
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildOptionPicker(ProductOption option) {
    final theme = Theme.of(context);
    final selectedValue = _selectedOptions[option.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFF303646),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: option.values.map((value) {
              final selected = selectedValue == value;
              final available = _isOptionValueAvailable(option, value);
              return ChoiceChip(
                label: Text(value),
                selected: selected,
                showCheckmark: false,
                onSelected: available
                    ? (_) => _selectOption(option, value)
                    : null,
                backgroundColor: Colors.white,
                selectedColor: theme.colorScheme.primaryContainer,
                side: BorderSide(
                  color: selected
                      ? theme.colorScheme.primary
                      : const Color(0xFFE2E5EC),
                ),
                labelStyle: TextStyle(
                  color: available
                      ? const Color(0xFF303646)
                      : const Color(0xFF9AA0AC),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityPicker(BuildContext context, ProductVariant variant) {
    final stockLimited =
        variant.manageInventory == true &&
        variant.allowBackorder != true &&
        variant.inventoryQuantity != null;
    final atMaximum = stockLimited && _quantity >= variant.inventoryQuantity!;

    return Row(
      children: [
        Text(
          'Số lượng',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Giảm số lượng',
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$_quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Tăng số lượng',
          onPressed: atMaximum ? null : () => setState(() => _quantity++),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: const Color(0xFF202533),
        fontWeight: FontWeight.w800,
      ),
    );
  }

  List<(String, String)> get _specificationRows {
    const labels = <String, String>{
      'screen': 'Màn hình',
      'chipset': 'Chip xử lý',
      'ram': 'RAM',
      'battery': 'Pin',
      'camera': 'Camera',
      'os': 'Hệ điều hành',
      'release_year': 'Năm ra mắt',
      'warranty': 'Bảo hành',
    };

    return labels.entries
        .map(
          (entry) => (
            entry.value,
            _product.specifications[entry.key]?.toString() ?? '',
          ),
        )
        .where((row) => row.$2.isNotEmpty)
        .toList();
  }

  Widget _buildSpecifications(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EBF1)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < _specificationRows.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      _specificationRows[index].$1,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFF777D8A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _specificationRows[index].$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF303646),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoOptionsNotice(BuildContext context) {
    return Text(
      'Sản phẩm chưa có tùy chọn phiên bản.',
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: const Color(0xFF777D8A)),
    );
  }
}
