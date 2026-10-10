import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/customer.dart';
import 'package:mobile/models/customer_order.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/screens/cart_screen.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/product_detail_screen.dart';
import 'package:mobile/navigation/store_shell.dart';
import 'package:mobile/services/cart_storage.dart';
import 'package:mobile/services/medusa_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late InMemorySharedPreferencesAsync preferencesPlatform;

  setUp(() {
    preferencesPlatform = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = preferencesPlatform;
  });

  testWidgets('shows Medusa line items and server totals', (tester) async {
    final service = _FakeCartService();

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cartId: 'cart_1',
          service: service,
          storage: CartStorage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Galaxy S26'), findsOneWidget);
    expect(find.text('256 GB · Đen'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Tổng từ Medusa'), findsOneWidget);
    expect(find.textContaining('2.000.000'), findsNWidgets(2));
    expect(find.text('Tiếp tục thanh toán'), findsOneWidget);
    expect(
      find.text('Thanh toán sẽ được bổ sung ở phase tiếp theo.'),
      findsNothing,
    );
  });

  testWidgets('updates quantity and uses the new server total', (tester) async {
    final service = _FakeCartService();

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cartId: 'cart_1',
          service: service,
          storage: CartStorage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tăng số lượng'));
    await tester.pumpAndSettle();

    expect(service.lastUpdatedQuantity, 3);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('3.000.000'), findsNWidgets(2));
  });

  testWidgets('removes the last item when quantity is reduced to zero', (
    tester,
  ) async {
    final service = _FakeCartService(quantity: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cartId: 'cart_1',
          service: service,
          storage: CartStorage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Giảm số lượng'));
    await tester.pumpAndSettle();

    expect(service.removeCount, 1);
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
  });

  testWidgets('retries a failed cart request', (tester) async {
    final service = _FakeCartService(failReads: true);

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cartId: 'cart_1',
          service: service,
          storage: CartStorage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa tải được giỏ hàng'), findsOneWidget);

    service.failReads = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Galaxy S26'), findsOneWidget);
  });

  testWidgets('forgets the saved cart reference after a load error', (
    tester,
  ) async {
    final service = _FakeCartService(failReads: true);
    final storage = CartStorage();
    await storage.saveCartId('cart_1');
    String? reportedCartId = 'cart_1';

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          cartId: 'cart_1',
          service: service,
          storage: storage,
          onCartIdChanged: (id) => reportedCartId = id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa mã giỏ đã lưu trên thiết bị'));
    await tester.pumpAndSettle();

    expect(await storage.readCartId(), isNull);
    expect(reportedCartId, isNull);
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
  });

  testWidgets('creates and persists one cart, then reuses its ID', (
    tester,
  ) async {
    final service = _FakeCartService();
    final storage = CartStorage();
    String? notifiedCartId;
    const product = Product(
      id: 'prod_1',
      title: 'Galaxy S26',
      images: [],
      variants: [
        ProductVariant(
          id: 'variant_1',
          title: '256 GB · Đen',
          price: 1000000,
          manageInventory: false,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          product: product,
          service: service,
          cartStorage: storage,
          onCartUpdated: (id) => notifiedCartId = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addButton = find.widgetWithText(FilledButton, 'Thêm vào giỏ hàng');
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(service.createCartCount, 1);
    expect(service.addToCartCount, 2);
    expect(service.lastAddedCartId, 'cart_1');
    expect(await storage.readCartId(), 'cart_1');
    expect(notifiedCartId, 'cart_1');
  });

  testWidgets('restores the saved cart ID before opening the cart', (
    tester,
  ) async {
    final storage = CartStorage();
    await storage.saveCartId('cart_restored');
    final service = _FakeCartService();

    await tester.pumpWidget(MaterialApp(home: HomeScreen(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mở giỏ hàng'));
    await tester.pumpAndSettle();

    expect(service.lastRetrievedCartId, 'cart_restored');
    expect(find.text('Galaxy S26'), findsOneWidget);
  });

  testWidgets('refreshes the shell cart after adding a product', (
    tester,
  ) async {
    final service = _FakeCartService(listProduct: true);
    final storage = CartStorage();
    await storage.clearCartId();

    await tester.pumpWidget(
      MaterialApp(
        home: StoreShell(service: service, storage: storage),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Galaxy S26').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galaxy S26').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm vào giỏ hàng'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Giỏ hàng'),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.lastRetrievedCartId, 'cart_1');
    expect(find.text('Galaxy S26'), findsOneWidget);
    expect(find.text('Tổng từ Medusa'), findsOneWidget);
  });
}

class _FakeCartService extends MedusaService {
  _FakeCartService({
    this.quantity = 2,
    this.failReads = false,
    this.listProduct = false,
  }) : super(
         client: MockClient((_) async => http.Response('{}', 500)),
         apiBaseUrl: 'http://localhost:9000',
         publishableApiKeyOverride: 'pk_test',
       );

  int? quantity;
  bool failReads;
  bool listProduct;
  int? lastUpdatedQuantity;
  int removeCount = 0;
  int createCartCount = 0;
  int addToCartCount = 0;
  String? lastAddedCartId;
  String? lastRetrievedCartId;

  @override
  Future<List<Product>> getProducts({String? query, String? brand}) async =>
      listProduct ? [_product()] : const [];

  @override
  Future<List<CustomerOrder>> getCustomerOrders({
    int offset = 0,
    int limit = 20,
  }) async => const [];

  @override
  Future<Customer?> getCurrentCustomer() async => null;

  Product _product() => const Product(
    id: 'prod_1',
    title: 'Galaxy S26',
    images: [],
    variants: [
      ProductVariant(
        id: 'variant_1',
        title: '256 GB · Đen',
        price: 1000000,
        manageInventory: false,
      ),
    ],
  );

  @override
  Future<Product> getProductDetail(String id) async => const Product(
    id: 'prod_1',
    title: 'Galaxy S26',
    images: [],
    variants: [
      ProductVariant(
        id: 'variant_1',
        title: '256 GB · Đen',
        price: 1000000,
        manageInventory: false,
      ),
    ],
  );

  @override
  Future<String> createCart() async {
    createCartCount++;
    return 'cart_1';
  }

  @override
  Future<Map<String, dynamic>> addToCart({
    required String cartId,
    required String variantId,
    int quantity = 1,
  }) async {
    addToCartCount++;
    lastAddedCartId = cartId;
    return _cart();
  }

  Map<String, dynamic> _cart() => {
    'id': 'cart_1',
    'currency_code': 'vnd',
    'items': quantity == null
        ? <Map<String, dynamic>>[]
        : [
            {
              'id': 'item_1',
              'title': 'Galaxy S26',
              'variant_title': '256 GB · Đen',
              'thumbnail': null,
              'quantity': quantity,
              'unit_price': 1000000,
            },
          ],
    'subtotal': (quantity ?? 0) * 1000000,
    'discount_total': 0,
    'shipping_total': 0,
    'total': (quantity ?? 0) * 1000000,
  };

  @override
  Future<Map<String, dynamic>> getCart(String cartId) async {
    lastRetrievedCartId = cartId;
    if (failReads) {
      throw const MedusaApiException('Backend tạm thời không khả dụng.');
    }
    return _cart();
  }

  @override
  Future<Map<String, dynamic>> updateCartItemQuantity({
    required String cartId,
    required String itemId,
    required int quantity,
  }) async {
    lastUpdatedQuantity = quantity;
    this.quantity = quantity;
    return _cart();
  }

  @override
  Future<Map<String, dynamic>> removeCartItem({
    required String cartId,
    required String itemId,
  }) async {
    removeCount++;
    quantity = null;
    return _cart();
  }
}
