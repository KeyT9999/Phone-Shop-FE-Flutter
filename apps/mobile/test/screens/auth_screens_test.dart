import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/customer.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/screens/register_screen.dart';
import 'package:mobile/services/medusa_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('opens account from Home and signs in then out', (tester) async {
    final service = _FakeAuthService();

    await tester.pumpWidget(MaterialApp(home: HomeScreen(service: service)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'mai@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(service.loginCount, 1);
    expect(find.text('Mai Nguyen'), findsNWidgets(2));
    expect(find.text('mai@example.com'), findsNWidgets(2));

    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(service.logoutCount, 1);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('registration validates required fields and password match', (
    tester,
  ) async {
    final service = _FakeAuthService();

    await tester.pumpWidget(
      MaterialApp(home: RegisterScreen(service: service)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên.'), findsOneWidget);
    expect(service.registerCount, 0);

    await tester.enterText(find.byKey(const Key('register-first-name')), 'Mai');
    await tester.enterText(
      find.byKey(const Key('register-last-name')),
      'Nguyen',
    );
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'mai@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password')),
      'different123',
    );
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);
    expect(service.registerCount, 0);
  });

  testWidgets(
    'registers from Profile and returns with the customer signed in',
    (tester) async {
      final service = _FakeAuthService();

      await tester.pumpWidget(
        MaterialApp(home: ProfileScreen(service: service)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Tạo tài khoản'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('register-first-name')),
        'Mai',
      );
      await tester.enterText(
        find.byKey(const Key('register-last-name')),
        'Nguyen',
      );
      await tester.enterText(
        find.byKey(const Key('register-email')),
        'mai@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register-confirm-password')),
        'password123',
      );
      await tester.ensureVisible(find.byKey(const Key('register-submit')));
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();

      expect(service.registerCount, 1);
      expect(find.text('Mai Nguyen'), findsNWidgets(2));
    },
  );

  testWidgets('shows login errors and keeps the form available', (
    tester,
  ) async {
    final service = _FakeAuthService(failLogin: true);

    await tester.pumpWidget(MaterialApp(home: LoginScreen(service: service)));
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'mai@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });
}

class _FakeAuthService extends MedusaService {
  _FakeAuthService({this.failLogin = false})
    : super(
        client: MockClient((_) async => http.Response('{}', 500)),
        apiBaseUrl: 'http://localhost:9000',
        publishableApiKeyOverride: 'pk_test',
      );

  bool failLogin;
  int loginCount = 0;
  int registerCount = 0;
  int logoutCount = 0;
  Customer? currentCustomer;

  @override
  Future<List<Product>> getProducts({String? query, String? brand}) async =>
      const [];

  @override
  Future<Customer?> getCurrentCustomer() async => currentCustomer;

  @override
  Future<Customer> loginCustomer({
    required String email,
    required String password,
  }) async {
    loginCount++;
    if (failLogin) {
      throw const MedusaApiException('Email hoặc mật khẩu không đúng.');
    }
    currentCustomer = _customer;
    return _customer;
  }

  @override
  Future<Customer> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    registerCount++;
    currentCustomer = _customer;
    return _customer;
  }

  @override
  Future<void> logoutCustomer() async {
    logoutCount++;
    currentCustomer = null;
  }
}

const _customer = Customer(
  id: 'cus_1',
  email: 'mai@example.com',
  firstName: 'Mai',
  lastName: 'Nguyen',
);
