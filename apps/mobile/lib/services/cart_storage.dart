import 'package:shared_preferences/shared_preferences.dart';

class CartStorage {
  CartStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static final CartStorage instance = CartStorage();
  static const _cartIdKey = 'dtc_medusa_cart_id_v1';

  final SharedPreferencesAsync _preferences;

  Future<String?> readCartId() async {
    final cartId = await _preferences.getString(_cartIdKey);
    if (cartId == null || cartId.isEmpty) return null;
    return cartId;
  }

  Future<void> saveCartId(String cartId) =>
      _preferences.setString(_cartIdKey, cartId);

  Future<void> clearCartId() => _preferences.remove(_cartIdKey);
}
