import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/customer.dart';
import 'package:mobile/models/customer_address.dart';
import 'package:mobile/services/auth_storage.dart';
import 'package:mobile/services/medusa_service.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'associates authenticated customer before updating cart addresses',
    () async {
      final storage = AuthStorage();
      await storage.saveToken('customer-token');
      final requests = <http.Request>[];
      final service = MedusaService(
        apiBaseUrl: 'http://localhost:9000',
        publishableApiKeyOverride: 'pk_test',
        authStorage: storage,
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/store/carts/cart_1/customer') {
            return _jsonResponse({
              'cart': {'id': 'cart_1'},
            });
          }
          return _jsonResponse({
            'cart': {
              'id': 'cart_1',
              'shipping_address': {'city': 'Hà Nội'},
              'billing_address': {'city': 'Hà Nội'},
            },
          });
        }),
      );

      final cart = await service.attachCustomerAddressToCart(
        cartId: 'cart_1',
        customer: const Customer(id: 'cus_1', email: 'mai@example.com'),
        address: const CustomerAddress(
          firstName: 'Mai',
          lastName: 'Nguyen',
          phone: '0912345678',
          province: 'Hà Nội',
          district: 'Ba Đình',
          ward: 'Phúc Xá',
          addressLine: '12 phố An Xá',
        ),
      );

      expect(cart['id'], 'cart_1');
      expect(requests, hasLength(2));
      expect(requests.first.method, 'POST');
      expect(requests.first.url.path, '/store/carts/cart_1/customer');
      expect(requests.first.body, isEmpty);
      expect(requests.last.method, 'POST');
      expect(requests.last.url.path, '/store/carts/cart_1');
      final update = jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(update['email'], 'mai@example.com');
      expect(update.containsKey('customer_id'), isFalse);
      expect(update['shipping_address']['country_code'], 'vn');
      expect(update['billing_address']['country_code'], 'vn');
      for (final request in requests) {
        expect(request.headers['authorization'], 'Bearer customer-token');
        expect(request.headers['x-publishable-api-key'], 'pk_test');
      }
    },
  );
}

http.Response _jsonResponse(Map<String, dynamic> body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
