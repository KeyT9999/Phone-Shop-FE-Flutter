import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../services/cart_storage.dart';
import '../services/medusa_service.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.service});

  final MedusaService? service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _brands = ['Tất cả', 'Apple', 'Samsung', 'Xiaomi', 'OPPO'];

  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  late final MedusaService _service;
  late final CartStorage _cartStorage;
  late Future<List<Product>> _productsFuture;
  late Future<void> _cartIdRestoration;
  Timer? _searchDebounce;
  String _selectedBrand = 'Tất cả';
  String? _cartId;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MedusaService.instance;
    _cartStorage = CartStorage.instance;
    _cartIdRestoration = _restoreCartId();
    _productsFuture = _loadProducts();
  }

  Future<void> _restoreCartId() async {
    try {
      final cartId = await _cartStorage.readCartId();
      if (mounted) setState(() => _cartId = cartId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể khôi phục giỏ hàng: $error')),
      );
    }
  }

  Future<void> _openCart() async {
    await _cartIdRestoration;
    if (!mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cartId: _cartId,
          service: _service,
          storage: _cartStorage,
          onCartIdChanged: (id) {
            if (mounted) setState(() => _cartId = id);
          },
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(service: _service)),
    );
  }

  Future<List<Product>> _loadProducts() {
    return _service.getProducts(
      query: _searchController.text,
      brand: _selectedBrand == 'Tất cả' ? null : _selectedBrand,
    );
  }

  void _refreshProducts() {
    setState(() => _productsFuture = _loadProducts());
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _refreshProducts();
    });
  }

  Future<void> _refreshFromGesture() async {
    _refreshProducts();
    try {
      await _productsFuture;
    } catch (_) {
      // The FutureBuilder renders the request error with a retry action.
    }
  }

  void _selectBrand(String brand) {
    if (brand == _selectedBrand) return;
    _searchDebounce?.cancel();
    setState(() {
      _selectedBrand = brand;
      _productsFuture = _loadProducts();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.phone_iphone,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'DTC Phone Store',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tài khoản',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: _openProfile,
          ),
          IconButton(
            tooltip: 'Mở giỏ hàng',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: _openCart,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: _refreshFromGesture,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildCatalogHeader(context, snapshot),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildErrorState(context, snapshot.error),
                  )
                else if ((snapshot.data ?? const <Product>[]).isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  _buildProductGrid(context, snapshot.data!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCatalogHeader(
    BuildContext context,
    AsyncSnapshot<List<Product>> snapshot,
  ) {
    final theme = Theme.of(context);
    final products = snapshot.data;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CỬA HÀNG ĐIỆN THOẠI',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Tìm chiếc máy\nhợp với bạn.',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm tên điện thoại hoặc cấu hình',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa nội dung tìm kiếm',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE8EAF0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _brands.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final brand = _brands[index];
                final selected = _selectedBrand == brand;
                return ChoiceChip(
                  label: Text(brand),
                  selected: selected,
                  showCheckmark: false,
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary
                        : const Color(0xFFE5E7EB),
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF414655),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (_) => _selectBrand(brand),
                );
              },
            ),
          ),
          if (products != null &&
              snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) ...[
            const SizedBox(height: 13),
            Text(
              '${products.length} sản phẩm',
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF777D8A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = width >= 1000
              ? 4
              : width >= 650
              ? 3
              : 2;
          return SliverGrid.builder(
            itemCount: products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: width < 400 ? 0.69 : 0.74,
            ),
            itemBuilder: (context, index) =>
                _buildProductCard(context, products[index]),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE9EBF1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await _cartIdRestoration;
          if (!context.mounted) return;
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: product,
                cartId: _cartId,
                cartStorage: _cartStorage,
                service: _service,
                onCartUpdated: (id) {
                  if (mounted) setState(() => _cartId = id);
                },
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF7F8FB),
                alignment: Alignment.center,
                child: product.thumbnail == null
                    ? Icon(
                        Icons.phone_iphone_rounded,
                        size: 56,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
                      )
                    : Image.network(
                        product.thumbnail!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.phone_iphone_rounded,
                          size: 56,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.brand ?? 'Điện thoại',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF202533),
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.minPrice > 0
                              ? _currencyFormat.format(product.minPrice)
                              : 'Xem cấu hình',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: const Color(0xFFC24136),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${product.variants.length} phiên bản',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF888E9A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Color(0xFF9A5360),
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa tải được catalog',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF777D8A),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _refreshProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasSearch = _searchController.text.trim().isNotEmpty;
    final hasBrand = _selectedBrand != 'Tất cả';
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 50,
              color: Color(0xFF9AA0AC),
            ),
            const SizedBox(height: 14),
            Text(
              'Không tìm thấy điện thoại phù hợp',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch || hasBrand
                  ? 'Thử đổi từ khóa hoặc chọn thương hiệu khác.'
                  : 'Catalog hiện chưa có sản phẩm nào.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF777D8A)),
            ),
          ],
        ),
      ),
    );
  }
}
