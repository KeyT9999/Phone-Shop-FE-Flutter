import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/customer.dart';
import 'package:mobile/models/customer_order.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/navigation/store_shell.dart';
import 'package:mobile/services/cart_storage.dart';
import 'package:mobile/services/medusa_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('switches between all four store destinations', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StoreShell(service: _EmptyStoreService(), storage: CartStorage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(_selectedTab(tester), 0);
    await _tapDestination(tester, 'Giỏ hàng');
    expect(_selectedTab(tester), 1);

    await _tapDestination(tester, 'Đơn hàng');
    expect(_selectedTab(tester), 2);
    expect(find.text('Đơn hàng của tôi'), findsOneWidget);

    await _tapDestination(tester, 'Tài khoản');
    expect(_selectedTab(tester), 3);
    expect(find.text('Quản lý tài khoản'), findsOneWidget);

    await _tapDestination(tester, 'Khám phá');
    expect(_selectedTab(tester), 0);
    expect(find.text('Tìm chiếc máy hợp với bạn.'), findsOneWidget);
  });
}

int _selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Future<void> _tapDestination(WidgetTester tester, String label) async {
  final navigation = find.byType(NavigationBar);
  await tester.tap(find.descendant(of: navigation, matching: find.text(label)));
  await tester.pumpAndSettle();
}

class _EmptyStoreService extends MedusaService {
  _EmptyStoreService()
    : super(
        client: MockClient((_) async => http.Response('{}', 500)),
        apiBaseUrl: 'http://localhost:9000',
        publishableApiKeyOverride: 'pk_test',
      );

  @override
  Future<List<Product>> getProducts({String? query, String? brand}) async =>
      const [];

  @override
  Future<List<CustomerOrder>> getCustomerOrders({
    int offset = 0,
    int limit = 20,
  }) async => const [];

  @override
  Future<Customer?> getCurrentCustomer() async => null;
}
