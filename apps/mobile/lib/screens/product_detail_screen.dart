import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/medusa_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String? cartId;
  final Function(String)? onCartUpdated;

  const ProductDetailScreen({
    Key? key,
    required this.product,
    this.cartId,
    this.onCartUpdated,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isAdding = false;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
  }

  Future<void> _handleAddToCart() async {
    if (_selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phiên bản máy')),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      String activeCartId = widget.cartId ?? '';
      if (activeCartId.isEmpty) {
        activeCartId = await MedusaService.createCart();
        if (widget.onCartUpdated != null) {
          widget.onCartUpdated!(activeCartId);
        }
      }

      await MedusaService.addToCart(
        cartId: activeCartId,
        variantId: _selectedVariant!.id,
        quantity: _quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text('Đã thêm ${_selectedVariant!.title} vào giỏ hàng!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Lỗi: $e'),
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
    final price = _selectedVariant?.price ?? widget.product.minPrice;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            Container(
              height: 280,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: widget.product.thumbnail != null
                  ? Image.network(
                      widget.product.thumbnail!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.phone_android, size: 80, color: Colors.grey),
                    )
                  : const Icon(Icons.phone_android, size: 80, color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên & Giá
                  Text(
                    widget.product.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price > 0 ? _currencyFormat.format(price) : 'Liên hệ báo giá',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // Chọn phiên bản / màu sắc / dung lượng
                  Text(
                    'Chọn phiên bản & màu sắc:',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.product.variants.map((v) {
                      final isSelected = _selectedVariant?.id == v.id;
                      return ChoiceChip(
                        label: Text(v.title),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primaryContainer,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedVariant = v);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Số lượng
                  Row(
                    children: [
                      Text('Số lượng:', style: theme.textTheme.titleMedium),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Text('$_quantity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // Mô tả sản phẩm
                  Text(
                    'Mô tả sản phẩm:',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description ?? 'Sản phẩm chính hãng, bảo hành 12 tháng toàn quốc.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isAdding ? null : _handleAddToCart,
                  icon: _isAdding
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.add_shopping_cart),
                  label: Text(_isAdding ? 'Đang thêm...' : 'Thêm vào giỏ hàng', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
