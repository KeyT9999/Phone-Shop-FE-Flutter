import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/cart_storage.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('persists a cart ID and clears only the cart ID', () async {
    final storage = CartStorage();

    expect(await storage.readCartId(), isNull);

    await storage.saveCartId('cart_123');
    expect(await storage.readCartId(), 'cart_123');

    await storage.clearCartId();
    expect(await storage.readCartId(), isNull);
  });

  test('treats an empty saved cart ID as missing', () async {
    final storage = CartStorage();

    await storage.saveCartId('');

    expect(await storage.readCartId(), isNull);
  });
}
