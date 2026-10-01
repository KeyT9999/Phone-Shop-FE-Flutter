import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/medusa_service.dart';

void main() {
  test('creates the cart with the Vietnam region', () async {
    final requests = <http.Request>[];
    final service = MedusaService(
      apiBaseUrl: 'http://localhost:9000',
      publishableApiKeyOverride: 'pk_test',
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/store/regions') {
          return http.Response(
            jsonEncode({
              'regions': [
                {
                  'id': 'reg_vietnam',
                  'currency_code': 'vnd',
                  'countries': [
                    {'iso_2': 'vn'},
                  ],
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'cart': {'id': 'cart_1'},
          }),
          201,
        );
      }),
    );

    final cartId = await service.createCart();

    expect(cartId, 'cart_1');
    expect(requests, hasLength(2));
    expect(requests.first.url.path, '/store/regions');
    expect(requests.last.method, 'POST');
    expect(requests.last.url.path, '/store/carts');
    expect(jsonDecode(requests.last.body), {'region_id': 'reg_vietnam'});
  });

  test(
    'adds, updates, removes, and retrieves a cart from Medusa responses',
    () async {
      final requests = <http.Request>[];
      final service = MedusaService(
        apiBaseUrl: 'http://localhost:9000',
        publishableApiKeyOverride: 'pk_test',
        client: MockClient((request) async {
          requests.add(request);
          final cart = {
            'id': 'cart_1',
            'currency_code': 'vnd',
            'items': [
              {'id': 'item_1', 'quantity': 3},
            ],
            'subtotal': 3000000,
            'total': 3000000,
          };
          if (request.method == 'DELETE') {
            return http.Response(jsonEncode({'parent': cart}), 200);
          }
          return http.Response(jsonEncode({'cart': cart}), 200);
        }),
      );

      final added = await service.addToCart(
        cartId: 'cart_1',
        variantId: 'variant_1',
        quantity: 3,
      );
      final updated = await service.updateCartItemQuantity(
        cartId: 'cart_1',
        itemId: 'item_1',
        quantity: 3,
      );
      final removed = await service.removeCartItem(
        cartId: 'cart_1',
        itemId: 'item_1',
      );
      final retrieved = await service.getCart('cart_1');

      expect(added['total'], 3000000);
      expect(updated['items'], isA<List>());
      expect(removed['id'], 'cart_1');
      expect(retrieved['currency_code'], 'vnd');
      expect(requests.map((request) => request.method), [
        'POST',
        'POST',
        'DELETE',
        'GET',
      ]);
      expect(requests[0].url.path, '/store/carts/cart_1/line-items');
      expect(jsonDecode(requests[0].body), {
        'variant_id': 'variant_1',
        'quantity': 3,
      });
      expect(requests[1].url.path, '/store/carts/cart_1/line-items/item_1');
      expect(jsonDecode(requests[1].body), {'quantity': 3});
      expect(requests[2].url.path, '/store/carts/cart_1/line-items/item_1');
      expect(requests[3].url.path, '/store/carts/cart_1');
      for (final request in requests) {
        expect(request.url.queryParameters['fields'], contains('+items.*'));
        expect(request.headers['x-publishable-api-key'], 'pk_test');
      }
    },
  );

  test(
    'rejects a zero or negative quantity before requesting Medusa',
    () async {
      var requestCount = 0;
      final service = MedusaService(
        publishableApiKeyOverride: 'pk_test',
        client: MockClient((_) async {
          requestCount++;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        service.updateCartItemQuantity(
          cartId: 'cart_1',
          itemId: 'item_1',
          quantity: 0,
        ),
        throwsA(isA<MedusaApiException>()),
      );
      expect(requestCount, 0);
    },
  );
}
