import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../services/cart_storage.dart';
import '../services/medusa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';

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
  int _imageIndex = 0;
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
        widget.onCartUpdated?.call(activeCartId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: storageWarning
                ? AppColors.warning
                : AppColors.success,
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
            backgroundColor: AppColors.error,
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
      appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
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
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_detailError != null) _buildDetailError(context),
          AppPageHeading(
            eyebrow: _product.brand ?? 'Điện thoại',
            title: _product.title,
          ),
          const SizedBox(height: 9),
          Text(
            _selectedPriceLabel(selectedVariant),
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.price,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (selectedVariant != null) ...[
            const SizedBox(height: 9),
            _buildStockStatus(context, selectedVariant),
          ],
          const SizedBox(height: AppSpacing.xl),
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
            const AppSectionHeading(title: 'Mô tả'),
            const SizedBox(height: 8),
            Text(
              _product.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.55,
              ),
            ),
          ],
          if (_specificationRows.isNotEmpty) ...[
            const SizedBox(height: 22),
            const AppSectionHeading(title: 'Thông số kỹ thuật'),
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
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
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
    final images = _productImages;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: PageView.builder(
                itemCount: images.isEmpty ? 1 : images.length,
                onPageChanged: (index) => setState(() => _imageIndex = index),
                itemBuilder: (context, index) {
                  if (images.isEmpty) {
                    return const _ProductImagePlaceholder(size: 88);
                  }
                  return ColoredBox(
                    color: AppColors.imageSurface,
                    child: Image.network(
                      images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const _ProductImagePlaceholder(size: 88),
                    ),
                  );
                },
              ),
            ),
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < images.length; index++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: index == _imageIndex ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: index == _imageIndex
                              ? AppColors.primary
                              : AppColors.textMuted.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> get _productImages {
    final images = <String>[];
    final thumbnail = _product.thumbnail?.trim();
    if (thumbnail != null && thumbnail.isNotEmpty) images.add(thumbnail);
    for (final image in _product.images) {
      final url = image.trim();
      if (url.isNotEmpty && !images.contains(url)) images.add(url);
    }
    return images;
  }

  Widget _buildDetailError(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
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
      color = AppColors.warning;
      icon = Icons.schedule_outlined;
      text = 'Có thể đặt trước';
    } else if (variant.manageInventory == false) {
      color = AppColors.success;
      icon = Icons.check_circle_outline;
      text = 'Có thể đặt hàng';
    } else if (variant.inventoryQuantity != null &&
        variant.inventoryQuantity! > 0) {
      color = AppColors.success;
      icon = Icons.check_circle_outline;
      text = 'Còn ${variant.inventoryQuantity} sản phẩm';
    } else if (variant.isAvailable == false) {
      color = AppColors.error;
      icon = Icons.remove_circle_outline;
      text = 'Tạm hết hàng';
    } else {
      color = AppColors.textMuted;
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
              color: AppColors.text,
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
                selectedColor: AppColors.primarySoft,
                side: BorderSide(
                  color: selected
                      ? theme.colorScheme.primary
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  color: available ? AppColors.text : AppColors.textMuted,
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
    return AppSurface(
      padding: EdgeInsets.zero,
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
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _specificationRows[index].$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text,
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
          ?.copyWith(color: AppColors.textMuted),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.imageSurface,
    child: Center(
      child: Icon(
        Icons.phone_iphone_rounded,
        size: size,
        color: AppColors.primary.withValues(alpha: 0.35),
      ),
    ),
  );
}
