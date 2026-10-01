import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/customer.dart';
import 'package:mobile/services/auth_storage.dart';
import 'package:mobile/services/medusa_service.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('logs in and retrieves the authenticated customer', () async {
    final requests = <http.Request>[];
    final storage = AuthStorage();
    final service = _service(storage, (request) async {
      requests.add(request);
      if (request.url.path == '/auth/customer/emailpass') {
        return http.Response(jsonEncode({'token': 'jwt-customer-token'}), 200);
      }
      return http.Response(jsonEncode({'customer': _customerJson()}), 200);
    });

    final customer = await service.loginCustomer(
      email: 'mai@example.com',
      password: 'correct-horse',
    );

    expect(customer, isA<Customer>());
    expect(customer.fullName, 'Mai Nguyen');
    expect(await storage.readToken(), 'jwt-customer-token');
    expect(requests[0].method, 'POST');
    expect(requests[0].url.path, '/auth/customer/emailpass');
    expect(jsonDecode(requests[0].body), {
      'email': 'mai@example.com',
      'password': 'correct-horse',
    });
    expect(requests[1].url.path, '/store/customers/me');
    expect(requests[1].headers['authorization'], 'Bearer jwt-customer-token');
  });

  test(
    'registers, creates customer, then logs in for an actor token',
    () async {
      final requests = <http.Request>[];
      final storage = AuthStorage();
      final service = _service(storage, (request) async {
        requests.add(request);
        if (request.url.path == '/auth/customer/emailpass/register') {
          return http.Response(
            jsonEncode({'token': 'jwt-registration-token'}),
            200,
          );
        }
        if (request.url.path == '/store/customers') {
          return http.Response(jsonEncode({'customer': _customerJson()}), 200);
        }
        if (request.url.path == '/auth/customer/emailpass') {
          return http.Response(jsonEncode({'token': 'jwt-actor-token'}), 200);
        }
        return http.Response(jsonEncode({'customer': _customerJson()}), 200);
      });

      final customer = await service.registerCustomer(
        firstName: 'Mai',
        lastName: 'Nguyen',
        email: 'mai@example.com',
        password: 'correct-horse',
      );

      expect(customer.id, 'cus_1');
      expect(await storage.readToken(), 'jwt-actor-token');
      expect(requests.map((request) => request.url.path), [
        '/auth/customer/emailpass/register',
        '/store/customers',
        '/auth/customer/emailpass',
        '/store/customers/me',
      ]);
      expect(jsonDecode(requests[0].body), {
        'email': 'mai@example.com',
        'password': 'correct-horse',
      });
      expect(
        requests[1].headers['authorization'],
        'Bearer jwt-registration-token',
      );
      expect(jsonDecode(requests[1].body), {
        'first_name': 'Mai',
        'last_name': 'Nguyen',
        'email': 'mai@example.com',
      });
      expect(jsonDecode(requests[2].body), {
        'email': 'mai@example.com',
        'password': 'correct-horse',
      });
      expect(requests[3].headers['authorization'], 'Bearer jwt-actor-token');
    },
  );

  test('returns unauthenticated and clears an expired JWT', () async {
    final storage = AuthStorage();
    await storage.saveToken('expired-token');
    final service = _service(
      storage,
      (request) async =>
          http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
    );

    final customer = await service.getCurrentCustomer();

    expect(customer, isNull);
    expect(await storage.readToken(), isNull);
  });

  test('logs out by clearing the persisted JWT', () async {
    final storage = AuthStorage();
    await storage.saveToken('jwt-customer-token');
    final service = _service(storage, (_) async => http.Response('{}', 500));

    await service.logoutCustomer();

    expect(await storage.readToken(), isNull);
  });
}

MedusaService _service(
  AuthStorage storage,
  Future<http.Response> Function(http.Request) handler,
) => MedusaService(
  client: MockClient(handler),
  apiBaseUrl: 'http://localhost:9000',
  publishableApiKeyOverride: 'pk_test',
  authStorage: storage,
);

Map<String, dynamic> _customerJson() => {
  'id': 'cus_1',
  'email': 'mai@example.com',
  'first_name': 'Mai',
  'last_name': 'Nguyen',
  'phone': '+84901234567',
};
