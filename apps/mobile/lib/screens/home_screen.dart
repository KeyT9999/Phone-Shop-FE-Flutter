import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/medusa_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  String? _cartId;
  String _selectedBrand = 'Tất cả';
  final List<String> _brands = ['Tất cả', 'iPhone', 'Samsung', 'Xiaomi', 'OPPO'];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts([String? query]) {
    setState(() {
      _productsFuture = MedusaService.getProducts(query: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.phone_iphone, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(
              'DTC Phone Store',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('•'),
              child: Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(cartId: _cartId),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchProducts(_searchController.text),
        child: Column(
          children: [
            // Thanh tìm kiếm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm điện thoại (iPhone 15, S24...)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _fetchProducts();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onSubmitted: (value) => _fetchProducts(value),
              ),
            ),

            // Danh mục thương hiệu dạng Chip
            SizedBox(
              height: 45,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _brands.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final brand = _brands[index];
                  final isSelected = _selectedBrand == brand;
                  return ChoiceChip(
                    label: Text(brand),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primaryContainer,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedBrand = brand);
                        _fetchProducts(brand == 'Tất cả' ? null : brand);
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Lưới sản phẩm điện thoại
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off, size: 60, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text('Lỗi kết nối Backend Medusa:', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _fetchProducts(),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final products = snapshot.data ?? [];

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Chưa tìm thấy điện thoại nào phù hợp'),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final price = product.minPrice;

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  product: product,
                                  cartId: _cartId,
                                  onCartUpdated: (id) => setState(() => _cartId = id),
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ảnh máy
                              Expanded(
                                flex: 6,
                                child: Container(
                                  width: double.infinity,
                                  color: Colors.grey.shade50,
                                  child: product.thumbnail != null
                                      ? Image.network(
                                          product.thumbnail!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.phone_android, size: 50, color: Colors.grey),
                                        )
                                      : const Icon(Icons.phone_android, size: 50, color: Colors.grey),
                                ),
                              ),

                              // Tên & Giá
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        product.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            price > 0 ? _currencyFormat.format(price) : 'Liên hệ',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${product.variants.length} phiên bản',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
