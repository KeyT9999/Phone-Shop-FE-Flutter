import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/product.dart';

class MedusaService {
  // Tự động nhận diện nền tảng:
  // - Android Emulator: dùng 10.0.2.2:9000
  // - Web / Windows Desktop / iOS Simulator: dùng localhost:9000
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:9000';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:9000';
      }
    } catch (_) {}
    return 'http://localhost:9000';
  }

  static const String apiKey = 'pk_8cea8ea6cc78d5ccfa84448ef86abeb0e3ecfdcb3f5b57636dabd8f58cf73167';

  static Map<String, String> get _headers => {
    'x-publishable-api-key': apiKey,
    'Content-Type': 'application/json',
  };

  // 1. Lấy danh sách sản phẩm
  static Future<List<Product>> getProducts({String? query}) async {
    String endpoint = '$baseUrl/store/products';
    if (query != null && query.isNotEmpty) {
      endpoint += '?q=${Uri.encodeComponent(query)}';
    }

    final response = await http.get(Uri.parse(endpoint), headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List productsJson = data['products'] ?? [];
      return productsJson.map((p) => Product.fromJson(p)).toList();
    } else {
      throw Exception('Không thể tải sản phẩm (Code: ${response.statusCode})');
    }
  }

  // 2. Chi tiết 1 sản phẩm
  static Future<Product> getProductDetail(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/store/products/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data['product']);
    } else {
      throw Exception('Không thể tải chi tiết máy: ${response.statusCode}');
    }
  }

  // 3. Khởi tạo giỏ hàng mới
  static Future<String> createCart() async {
    final response = await http.post(
      Uri.parse('$baseUrl/store/carts'),
      headers: _headers,
      body: jsonEncode({}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['cart']['id'];
    } else {
      throw Exception('Lỗi tạo giỏ hàng: ${response.statusCode}');
    }
  }

  // 4. Thêm sản phẩm vào giỏ hàng
  static Future<Map<String, dynamic>> addToCart({
    required String cartId,
    required String variantId,
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/store/carts/$cartId/line-items'),
      headers: _headers,
      body: jsonEncode({
        'variant_id': variantId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi thêm giỏ hàng: ${response.body}');
    }
  }

  // 5. Lấy thông tin giỏ hàng hiện tại
  static Future<Map<String, dynamic>> getCart(String cartId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/store/carts/$cartId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['cart'];
    } else {
      throw Exception('Lỗi lấy giỏ hàng: ${response.statusCode}');
    }
  }
}
