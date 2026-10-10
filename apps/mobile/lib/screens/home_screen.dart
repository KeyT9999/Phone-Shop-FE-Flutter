import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../services/cart_storage.dart';
import '../services/medusa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.service,
    this.storage,
    this.onOpenCart,
    this.onOpenProfile,
    this.onCartIdChanged,
    this.onCartContentsChanged,
  });

  final MedusaService? service;
  final CartStorage? storage;
  final VoidCallback? onOpenCart;
  final VoidCallback? onOpenProfile;
  final ValueChanged<String?>? onCartIdChanged;
  final ValueChanged<String>? onCartContentsChanged;

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
    _cartStorage = widget.storage ?? CartStorage.instance;
    _cartIdRestoration = _restoreCartId();
    _productsFuture = _loadProducts();
  }

  Future<void> _restoreCartId() async {
    try {
      final cartId = await _cartStorage.readCartId();
      if (mounted) {
        setState(() => _cartId = cartId);
        widget.onCartIdChanged?.call(cartId);
      }
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
    if (widget.onOpenCart != null) {
      widget.onOpenCart!();
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cartId: _cartId,
          service: _service,
          storage: _cartStorage,
          onCartIdChanged: (id) {
            if (mounted) setState(() => _cartId = id);
            widget.onCartIdChanged?.call(id);
          },
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    if (widget.onOpenProfile != null) {
      widget.onOpenProfile!();
      return;
    }
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
    setState(() {
      _productsFuture = _loadProducts();
    });
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
      appBar: AppBar(
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
        actions: widget.onOpenCart == null && widget.onOpenProfile == null
            ? [
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
              ]
            : null,
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: _buildCatalogHeader(context, snapshot),
                    ),
                  ),
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
    final products = snapshot.data;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPageHeading(
            eyebrow: 'Cửa hàng điện thoại',
            title: 'Tìm chiếc máy hợp với bạn.',
            subtitle: 'Khám phá theo thương hiệu, chọn phiên bản phù hợp.',
          ),
          const SizedBox(height: AppSpacing.lg),
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
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
                  selectedColor: AppColors.primarySoft,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textMuted,
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
            const SizedBox(height: AppSpacing.lg),
            AppSectionHeading(
              title: 'Điện thoại',
              subtitle: '${products.length} sản phẩm',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final horizontalInset = math.max(16.0, (width - 1320) / 2);
        final columns = width >= 1120
            ? 4
            : width >= 760
            ? 3
            : 2;
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalInset, 4, horizontalInset, 28),
          sliver: SliverGrid.builder(
            itemCount: products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              childAspectRatio: width < 400 ? 0.68 : 0.76,
            ),
            itemBuilder: (context, index) =>
                _buildProductCard(context, products[index]),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
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
                  final onCartContentsChanged = widget.onCartContentsChanged;
                  if (onCartContentsChanged != null) {
                    onCartContentsChanged(id);
                  } else {
                    widget.onCartIdChanged?.call(id);
                  }
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
                color: AppColors.imageSurface,
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
                            color: AppColors.text,
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
                            color: AppColors.price,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${product.variants.length} phiên bản',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
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
    return AppStateView(
      title: 'Chưa tải được catalog',
      description: '$error',
      icon: Icons.wifi_off_rounded,
      actionLabel: 'Thử lại',
      onAction: _refreshProducts,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasSearch = _searchController.text.trim().isNotEmpty;
    final hasBrand = _selectedBrand != 'Tất cả';
    return AppStateView(
      title: 'Không tìm thấy điện thoại phù hợp',
      description: hasSearch || hasBrand
          ? 'Thử đổi từ khóa hoặc chọn thương hiệu khác.'
          : 'Catalog hiện chưa có sản phẩm nào.',
      icon: Icons.search_off_rounded,
    );
  }
}
