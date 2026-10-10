import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/customer.dart';
import '../models/customer_address.dart';
import '../models/customer_order.dart';
import '../models/payment_provider.dart';
import '../models/product.dart';
import '../models/shipping_option.dart';
import 'auth_storage.dart';

class MedusaService {
  MedusaService({
    http.Client? client,
    this.apiBaseUrl,
    this.publishableApiKeyOverride,
    AuthStorage? authStorage,
  }) : _client = client ?? http.Client(),
       _authStorage = authStorage ?? AuthStorage.instance;

  static final MedusaService instance = MedusaService();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'MEDUSA_BASE_URL',
  );
  static const String _configuredPublishableApiKey = String.fromEnvironment(
    'MEDUSA_PUBLISHABLE_KEY',
  );

  static const String _productFields =
      '*variants.calculated_price,id,title,subtitle,description,thumbnail,'
      'metadata,*images,*options,*options.values,*variants,*variants.options,'
      '+variants.inventory_quantity';
  static const String _cartFields =
      '+items.*,+shipping_address.*,+billing_address.*,+shipping_methods.*,'
      '+region_id,+email,+currency_code,+subtotal,+discount_total,'
      '+shipping_total,+total';

  final http.Client _client;
  final AuthStorage _authStorage;
  final String? apiBaseUrl;
  final String? publishableApiKeyOverride;
  Future<_StoreRegion>? _vietnamRegionFuture;

  String get baseUrl {
    final configured = (apiBaseUrl ?? _configuredBaseUrl).trim();
    if (configured.isNotEmpty) return _removeTrailingSlash(configured);

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:9000';
    }
    return 'http://localhost:9000';
  }

  String get publishableApiKey =>
      (publishableApiKeyOverride ?? _configuredPublishableApiKey).trim();

  Map<String, String> get _headers {
    if (publishableApiKey.isEmpty) {
      throw const MedusaApiException(
        'Thiếu MEDUSA_PUBLISHABLE_KEY. Hãy truyền publishable key khi chạy ứng dụng.',
      );
    }

    return {
      'x-publishable-api-key': publishableApiKey,
      'Content-Type': 'application/json',
    };
  }

  Future<List<Product>> getProducts({String? query, String? brand}) async {
    final region = await _getVietnamRegion();
    final normalizedQuery = query?.trim();
    final normalizedBrand = brand?.trim();
    late final List<Product> products;

    if (normalizedQuery?.isNotEmpty ?? false) {
      final productIds = await _searchProductIds(query: normalizedQuery!);
      if (productIds.isEmpty) return const [];

      final data = await _getJson(
        _uri(
          '/store/products',
          queryParameters: {
            'limit': '${productIds.length}',
            'region_id': region.id,
            'fields': _productFields,
          },
          arrayParameters: {'id[]': productIds},
        ),
      );
      final productsById = {
        for (final product in _readProducts(data['products']))
          product.id: product,
      };
      products = productIds
          .map((id) => productsById[id])
          .whereType<Product>()
          .toList();
    } else {
      final data = await _getJson(
        _uri(
          '/store/products',
          queryParameters: {
            'limit': '100',
            'region_id': region.id,
            'fields': _productFields,
          },
        ),
      );
      products = _readProducts(data['products']);
    }

    final normalizedBrandFilter = normalizedBrand?.toLowerCase();
    return products.where((product) {
      final brand = product.specifications['brand'];
      if (brand is! String || brand.trim().isEmpty) return false;
      return normalizedBrandFilter?.isNotEmpty != true ||
          brand.trim().toLowerCase() == normalizedBrandFilter;
    }).toList();
  }

  Future<Product> getProductDetail(String id) async {
    final region = await _getVietnamRegion();
    final data = await _getJson(
      _uri(
        '/store/products/${Uri.encodeComponent(id)}',
        queryParameters: {'region_id': region.id, 'fields': _productFields},
      ),
    );
    final rawProduct = data['product'];
    if (rawProduct is! Map) {
      throw const MedusaApiException('Medusa không trả về thông tin sản phẩm.');
    }
    return Product.fromJson(Map<String, dynamic>.from(rawProduct));
  }

  Future<List<String>> _searchProductIds({required String query}) async {
    final response = await _send(
      http.post(
        _uri('/store/search'),
        headers: _headers,
        body: jsonEncode({
          'entity': 'product',
          'fields': ['id'],
          'filters': {'q': query},
          'pagination': {'skip': 0, 'take': 100},
        }),
      ),
    );
    final data = _decodeJson(response);
    final results = data['results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      return const [];
    }

    final hits = (results.first as Map)['hits'];
    if (hits is! List) return const [];

    final ids = <String>[];
    for (final rawHit in hits) {
      if (rawHit is! Map) continue;
      final document = rawHit['document'];
      final id = document is Map
          ? document['id']?.toString()
          : rawHit['id']?.toString();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    return ids;
  }

  Future<_StoreRegion> _getVietnamRegion() async {
    final cached = _vietnamRegionFuture;
    if (cached != null) return cached;

    final request = _fetchVietnamRegion();
    _vietnamRegionFuture = request;
    try {
      return await request;
    } catch (_) {
      if (identical(_vietnamRegionFuture, request)) {
        _vietnamRegionFuture = null;
      }
      rethrow;
    }
  }

  Future<_StoreRegion> _fetchVietnamRegion() async {
    final data = await _getJson(
      _uri(
        '/store/regions',
        queryParameters: {
          'limit': '100',
          'fields': 'id,name,currency_code,*countries',
        },
      ),
    );
    final regions = data['regions'];
    if (regions is List) {
      for (final rawRegion in regions) {
        if (rawRegion is! Map) continue;
        final region = Map<String, dynamic>.from(rawRegion);
        final currencyCode = region['currency_code']?.toString().toLowerCase();
        if (currencyCode != 'vnd') continue;

        final countries = region['countries'];
        final countryCodes = countries is List
            ? countries
                  .whereType<Map>()
                  .map((country) => country['iso_2']?.toString().toLowerCase())
                  .whereType<String>()
                  .toList()
            : const <String>[];
        if (!countryCodes.contains('vn')) continue;

        final id = region['id']?.toString();
        if (id != null && id.isNotEmpty) {
          return _StoreRegion(id: id, currencyCode: currencyCode!);
        }
      }
    }

    throw const MedusaApiException(
      'Không tìm thấy region Vietnam/VND trong Medusa. Kiểm tra cấu hình backend trước khi tải catalog.',
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _send(_client.get(uri, headers: _headers));
    return _decodeJson(response);
  }

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      final response = await request.timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorBody = _tryDecodeMap(response.body);
        final message = errorBody?['message']?.toString();
        throw MedusaApiException(
          message?.isNotEmpty == true
              ? 'Medusa ${response.statusCode}: $message'
              : 'Yêu cầu Medusa thất bại (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      return response;
    } on TimeoutException {
      throw const MedusaApiException(
        'Kết nối Medusa quá thời gian chờ. Hãy thử lại.',
      );
    } on http.ClientException {
      throw const MedusaApiException(
        'Không kết nối được Medusa. Kiểm tra backend và địa chỉ MEDUSA_BASE_URL.',
      );
    } on SocketException {
      throw const MedusaApiException(
        'Không kết nối được Medusa. Kiểm tra backend và địa chỉ MEDUSA_BASE_URL.',
      );
    }
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    final data = _tryDecodeMap(response.body);
    if (data == null) {
      throw const MedusaApiException('Medusa trả về dữ liệu không hợp lệ.');
    }
    return data;
  }

  Uri _uri(
    String path, {
    Map<String, String> queryParameters = const {},
    Map<String, List<String>> arrayParameters = const {},
  }) {
    final parameters = <String, List<String>>{
      for (final entry in queryParameters.entries) entry.key: [entry.value],
      ...arrayParameters,
    };
    return Uri.parse('$baseUrl$path').replace(queryParameters: parameters);
  }

  List<Product> _readProducts(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((product) => Product.fromJson(Map<String, dynamic>.from(product)))
        .toList();
  }

  Map<String, dynamic>? _tryDecodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
    return null;
  }

  static String _removeTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Future<String> createCart() async {
    final region = await _getVietnamRegion();
    final response = await _send(
      _client.post(
        _uri('/store/carts'),
        headers: _headers,
        body: jsonEncode({'region_id': region.id}),
      ),
    );
    final cart = _decodeJson(response)['cart'];
    if (cart is Map && cart['id'] != null) return cart['id'].toString();
    throw const MedusaApiException('Medusa không trả về giỏ hàng hợp lệ.');
  }

  Future<Map<String, dynamic>> addToCart({
    required String cartId,
    required String variantId,
    int quantity = 1,
  }) async {
    final response = await _send(
      _client.post(
        _uri(
          '/store/carts/${Uri.encodeComponent(cartId)}/line-items',
          queryParameters: {'fields': _cartFields},
        ),
        headers: _headers,
        body: jsonEncode({'variant_id': variantId, 'quantity': quantity}),
      ),
    );
    return _readCart(_decodeJson(response));
  }

  Future<Map<String, dynamic>> updateCartItemQuantity({
    required String cartId,
    required String itemId,
    required int quantity,
  }) async {
    if (quantity < 1) {
      throw const MedusaApiException('Số lượng phải lớn hơn 0.');
    }

    final response = await _send(
      _client.post(
        _uri(
          '/store/carts/${Uri.encodeComponent(cartId)}/line-items/${Uri.encodeComponent(itemId)}',
          queryParameters: {'fields': _cartFields},
        ),
        headers: _headers,
        body: jsonEncode({'quantity': quantity}),
      ),
    );
    return _readCart(_decodeJson(response));
  }

  Future<Map<String, dynamic>> removeCartItem({
    required String cartId,
    required String itemId,
  }) async {
    final response = await _send(
      _client.delete(
        _uri(
          '/store/carts/${Uri.encodeComponent(cartId)}/line-items/${Uri.encodeComponent(itemId)}',
          queryParameters: {'fields': _cartFields},
        ),
        headers: _headers,
      ),
    );
    return _readCart(_decodeJson(response), allowParent: true);
  }

  Future<Map<String, dynamic>> getCart(String cartId) async {
    final response = await _send(
      _client.get(
        _uri(
          '/store/carts/${Uri.encodeComponent(cartId)}',
          queryParameters: {'fields': _cartFields},
        ),
        headers: _headers,
      ),
    );
    return _readCart(_decodeJson(response));
  }

  Future<Map<String, dynamic>> attachCustomerAddressToCart({
    required String cartId,
    required Customer customer,
    required CustomerAddress address,
  }) async {
    if (customer.id.isEmpty || customer.email.isEmpty) {
      throw const MedusaApiException('Hồ sơ khách hàng chưa hợp lệ.');
    }
    return _withCustomerAuth((token) async {
      await _send(
        _client.post(
          _uri('/store/carts/${Uri.encodeComponent(cartId)}/customer'),
          headers: _authenticatedHeaders(token),
        ),
      );

      final response = await _send(
        _client.post(
          _uri(
            '/store/carts/${Uri.encodeComponent(cartId)}',
            queryParameters: {'fields': _cartFields},
          ),
          headers: _authenticatedHeaders(token),
          body: jsonEncode({
            'email': customer.email,
            'shipping_address': address.toCartAddressJson(),
            'billing_address': address.toCartAddressJson(),
          }),
        ),
      );
      return _readCart(_decodeJson(response));
    });
  }

  Future<List<CustomerAddress>> getCustomerAddresses() async {
    return _withCustomerAuth((token) async {
      final response = await _send(
        _client.get(
          _uri('/store/customers/me/addresses'),
          headers: _authenticatedHeaders(token),
        ),
      );
      final addresses = _decodeJson(response)['addresses'];
      if (addresses is! List) return const [];
      return addresses
          .whereType<Map>()
          .map(
            (address) =>
                CustomerAddress.fromJson(Map<String, dynamic>.from(address)),
          )
          .toList();
    });
  }

  Future<CustomerAddress> createCustomerAddress(CustomerAddress address) async {
    return _withCustomerAuth((token) async {
      final existing = await _listCustomerAddresses(token);
      final existingIds = existing
          .map((item) => item.id)
          .whereType<String>()
          .toSet();
      late final http.Response response;
      try {
        response = await _send(
          _client.post(
            _uri('/store/customers/me/addresses'),
            headers: _authenticatedHeaders(token),
            body: jsonEncode(address.toMedusaJson()),
          ),
        );
      } on MedusaApiException {
        // A timed-out create may still have succeeded on the server. Check the
        // authenticated address list before allowing a retry to create a copy.
        try {
          final refreshed = await _listCustomerAddresses(token);
          for (final saved in refreshed.reversed) {
            if (_sameAddress(saved, address)) return saved;
          }
        } catch (_) {
          // Keep the original create failure as the actionable error.
        }
        rethrow;
      }
      final customer = _decodeJson(response)['customer'];
      final returned = customer is Map && customer['addresses'] is List
          ? (customer['addresses'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      CustomerAddress.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <CustomerAddress>[];
      final created = returned.where(
        (item) => item.id != null && !existingIds.contains(item.id),
      );
      if (created.isNotEmpty) return created.last;

      final refreshed = await _listCustomerAddresses(token);
      final newlyCreated = refreshed.where(
        (item) => item.id != null && !existingIds.contains(item.id),
      );
      if (newlyCreated.isNotEmpty) return newlyCreated.last;
      throw const MedusaApiException(
        'Địa chỉ đã gửi lên nhưng không nhận được mã địa chỉ từ Medusa.',
      );
    });
  }

  Future<CustomerAddress> updateCustomerAddress(CustomerAddress address) async {
    final id = address.id;
    if (id == null || id.isEmpty) {
      throw const MedusaApiException('Địa chỉ cần cập nhật chưa có mã.');
    }
    return _withCustomerAuth((token) async {
      final response = await _send(
        _client.post(
          _uri('/store/customers/me/addresses/${Uri.encodeComponent(id)}'),
          headers: _authenticatedHeaders(token),
          body: jsonEncode(address.toMedusaJson()),
        ),
      );
      final customer = _decodeJson(response)['customer'];
      if (customer is Map && customer['addresses'] is List) {
        for (final rawAddress in customer['addresses'] as List) {
          if (rawAddress is Map && rawAddress['id']?.toString() == id) {
            return CustomerAddress.fromJson(
              Map<String, dynamic>.from(rawAddress),
            );
          }
        }
      }
      final refreshed = await _listCustomerAddresses(token);
      for (final item in refreshed) {
        if (item.id == id) return item;
      }
      throw const MedusaApiException(
        'Không tải lại được địa chỉ vừa cập nhật.',
      );
    });
  }

  Future<void> deleteCustomerAddress(String addressId) async {
    await _withCustomerAuth((token) async {
      await _send(
        _client.delete(
          _uri(
            '/store/customers/me/addresses/${Uri.encodeComponent(addressId)}',
          ),
          headers: _authenticatedHeaders(token),
        ),
      );
    });
  }

  Future<List<ShippingOption>> getShippingOptions(
    String cartId, {
    String? currencyCode,
  }) async {
    final response = await _send(
      _client.get(
        _uri(
          '/store/shipping-options',
          queryParameters: {
            'cart_id': cartId,
            'fields':
                'id,name,price_type,+data,+type.label,+type.description,'
                '+provider.id,+provider.is_enabled,'
                '+prices.amount,+prices.currency_code,+calculated_price.calculated_amount',
          },
        ),
        headers: _headers,
      ),
    );
    final rawOptions = _decodeJson(response)['shipping_options'];
    if (rawOptions is! List) return const [];
    final options = rawOptions
        .whereType<Map>()
        .map(
          (item) => ShippingOption.fromJson(
            Map<String, dynamic>.from(item),
            preferredCurrencyCode: currencyCode,
          ),
        )
        .toList();
    return Future.wait(
      options.map((option) async {
        if (!option.requiresCalculation) return option;
        final calculated = await _calculateShippingOption(cartId, option);
        if (!calculated.hasPrice) {
          throw MedusaApiException(
            'Medusa chưa trả giá cho phương thức ${option.name}.',
          );
        }
        return calculated;
      }),
    );
  }

  Future<ShippingOption> _calculateShippingOption(
    String cartId,
    ShippingOption option,
  ) async {
    final response = await _send(
      _client.post(
        _uri(
          '/store/shipping-options/${Uri.encodeComponent(option.id)}/calculate',
        ),
        headers: _headers,
        body: jsonEncode({'cart_id': cartId, 'data': option.data}),
      ),
    );
    final rawOption = _decodeJson(response)['shipping_option'];
    if (rawOption is! Map) {
      throw const MedusaApiException(
        'Medusa không trả về giá của phương thức giao hàng.',
      );
    }
    return ShippingOption.fromJson(Map<String, dynamic>.from(rawOption));
  }

  Future<Map<String, dynamic>> addShippingMethod({
    required String cartId,
    required ShippingOption option,
  }) async {
    final response = await _send(
      _client.post(
        _uri(
          '/store/carts/${Uri.encodeComponent(cartId)}/shipping-methods',
          queryParameters: {'fields': _cartFields},
        ),
        headers: _headers,
        body: jsonEncode({'option_id': option.id, 'data': option.data}),
      ),
    );
    _readCart(_decodeJson(response));
    return getCart(cartId);
  }

  Future<List<PaymentProvider>> getPaymentProviders(String regionId) async {
    final response = await _send(
      _client.get(
        _uri(
          '/store/payment-providers',
          queryParameters: {'region_id': regionId, 'limit': '100'},
        ),
        headers: _headers,
      ),
    );
    final rawProviders = _decodeJson(response)['payment_providers'];
    if (rawProviders is! List) return const [];
    return rawProviders
        .whereType<Map>()
        .map(
          (item) => PaymentProvider.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((provider) => provider.id.isNotEmpty && provider.isEnabled)
        .toList();
  }

  Future<String> createPaymentCollection(String cartId) async {
    return _withCustomerAuth((token) async {
      final response = await _send(
        _client.post(
          _uri('/store/payment-collections'),
          headers: _authenticatedHeaders(token),
          body: jsonEncode({'cart_id': cartId}),
        ),
      );
      final collection = _decodeJson(response)['payment_collection'];
      final id = collection is Map ? collection['id']?.toString() : null;
      if (id == null || id.isEmpty) {
        throw const MedusaApiException(
          'Medusa không trả về payment collection hợp lệ.',
        );
      }
      return id;
    });
  }

  Future<void> createPaymentSession({
    required String collectionId,
    required String providerId,
  }) async {
    await _withCustomerAuth((token) async {
      await _send(
        _client.post(
          _uri(
            '/store/payment-collections/${Uri.encodeComponent(collectionId)}/payment-sessions',
          ),
          headers: _authenticatedHeaders(token),
          body: jsonEncode({'provider_id': providerId, 'data': {}}),
        ),
      );
    });
  }

  Future<Map<String, dynamic>> completeCart(String cartId) async {
    return _withCustomerAuth((token) async {
      final response = await _send(
        _client.post(
          _uri(
            '/store/carts/${Uri.encodeComponent(cartId)}/complete',
            queryParameters: {'fields': '+payment_status,+fulfillment_status'},
          ),
          headers: _authenticatedHeaders(token),
          body: jsonEncode({}),
        ),
      );
      return _decodeJson(response);
    });
  }

  Future<List<CustomerOrder>> getCustomerOrders({
    int offset = 0,
    int limit = 20,
  }) async {
    return _withCustomerAuth((token) async {
      final response = await _send(
        _client.get(
          _uri(
            '/store/orders',
            queryParameters: {
              'offset': '$offset',
              'limit': '$limit',
              'fields':
                  'id,display_id,status,payment_status,fulfillment_status,'
                  'currency_code,total,subtotal,shipping_total,discount_total,created_at,'
                  '+items.*,+shipping_address.*,+shipping_methods.*',
            },
          ),
          headers: _authenticatedHeaders(token),
        ),
      );
      final rawOrders = _decodeJson(response)['orders'];
      if (rawOrders is! List) return const [];
      return rawOrders
          .whereType<Map>()
          .map(
            (item) => CustomerOrder.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    });
  }

  Future<T> _withCustomerAuth<T>(
    Future<T> Function(String token) action,
  ) async {
    final token = await _authStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const MedusaApiException(
        'Vui lòng đăng nhập để dùng thông tin tài khoản.',
        statusCode: 401,
      );
    }
    try {
      return await action(token);
    } on MedusaApiException catch (error) {
      if (error.statusCode == 401) await _authStorage.clearToken();
      rethrow;
    }
  }

  Future<List<CustomerAddress>> _listCustomerAddresses(String token) async {
    final response = await _send(
      _client.get(
        _uri('/store/customers/me/addresses'),
        headers: _authenticatedHeaders(token),
      ),
    );
    final rawAddresses = _decodeJson(response)['addresses'];
    if (rawAddresses is! List) return const [];
    return rawAddresses
        .whereType<Map>()
        .map(
          (item) => CustomerAddress.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  bool _sameAddress(CustomerAddress first, CustomerAddress second) =>
      first.addressName.trim().toLowerCase() ==
          second.addressName.trim().toLowerCase() &&
      first.normalizedPhone == second.normalizedPhone &&
      first.firstName.trim().toLowerCase() ==
          second.firstName.trim().toLowerCase() &&
      first.lastName.trim().toLowerCase() ==
          second.lastName.trim().toLowerCase() &&
      first.province.trim().toLowerCase() ==
          second.province.trim().toLowerCase() &&
      first.district.trim().toLowerCase() ==
          second.district.trim().toLowerCase() &&
      first.ward.trim().toLowerCase() == second.ward.trim().toLowerCase() &&
      first.addressLine.trim().toLowerCase() ==
          second.addressLine.trim().toLowerCase() &&
      first.postalCode.trim() == second.postalCode.trim() &&
      first.isDefaultShipping == second.isDefaultShipping &&
      first.isDefaultBilling == second.isDefaultBilling;

  Future<Customer> loginCustomer({
    required String email,
    required String password,
  }) async {
    final token = await _requestCustomerToken(
      '/auth/customer/emailpass',
      email: email,
      password: password,
    );
    await _authStorage.saveToken(token);

    final customer = await getCurrentCustomer();
    if (customer == null) {
      throw const MedusaApiException(
        'Đăng nhập thành công nhưng chưa tải được hồ sơ khách hàng.',
      );
    }
    return customer;
  }

  Future<Customer> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final registrationToken = await _requestCustomerToken(
      '/auth/customer/emailpass/register',
      email: email,
      password: password,
    );
    final response = await _send(
      _client.post(
        _uri('/store/customers'),
        headers: _authenticatedHeaders(registrationToken),
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
        }),
      ),
    );
    _readCustomer(_decodeJson(response));

    final customerToken = await _requestCustomerToken(
      '/auth/customer/emailpass',
      email: email,
      password: password,
    );
    await _authStorage.saveToken(customerToken);

    final customer = await getCurrentCustomer();
    if (customer == null) {
      throw const MedusaApiException(
        'Tài khoản đã tạo nhưng chưa tải được hồ sơ khách hàng.',
      );
    }
    return customer;
  }

  Future<Customer?> getCurrentCustomer() async {
    final token = await _authStorage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _send(
        _client.get(
          _uri('/store/customers/me'),
          headers: _authenticatedHeaders(token),
        ),
      );
      return _readCustomer(_decodeJson(response));
    } on MedusaApiException catch (error) {
      if (error.statusCode == 401) {
        await _authStorage.clearToken();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logoutCustomer() => _authStorage.clearToken();

  Future<String> _requestCustomerToken(
    String path, {
    required String email,
    required String password,
  }) async {
    final response = await _send(
      _client.post(
        _uri(path),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    final token = _decodeJson(response)['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const MedusaApiException(
        'Medusa không trả về access token khách hàng hợp lệ.',
      );
    }
    return token;
  }

  Map<String, String> _authenticatedHeaders(String token) => {
    ..._headers,
    'authorization': 'Bearer $token',
  };

  Customer _readCustomer(Map<String, dynamic> data) {
    final customer = data['customer'];
    if (customer is Map) {
      final parsed = Customer.fromJson(Map<String, dynamic>.from(customer));
      if (parsed.id.isNotEmpty && parsed.email.isNotEmpty) return parsed;
    }
    throw const MedusaApiException(
      'Medusa không trả về hồ sơ khách hàng hợp lệ.',
    );
  }

  Map<String, dynamic> _readCart(
    Map<String, dynamic> data, {
    bool allowParent = false,
  }) {
    final cart = data['cart'] ?? (allowParent ? data['parent'] : null);
    if (cart is Map) return Map<String, dynamic>.from(cart);
    throw const MedusaApiException('Medusa không trả về giỏ hàng hợp lệ.');
  }
}

class MedusaApiException implements Exception {
  const MedusaApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class _StoreRegion {
  const _StoreRegion({required this.id, required this.currencyCode});

  final String id;
  final String currencyCode;
}
