class ProductOption {
  final String id;
  final String title;
  final List<String> values;

  const ProductOption({
    required this.id,
    required this.title,
    required this.values,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    final values = (json['values'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => value['value']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();

    return ProductOption(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      values: values,
    );
  }
}

class ProductVariant {
  final String id;
  final String title;
  final String? sku;
  final num? price;
  final String? currencyCode;
  final Map<String, String> optionValues;
  final int? inventoryQuantity;
  final bool? manageInventory;
  final bool? allowBackorder;

  const ProductVariant({
    required this.id,
    required this.title,
    this.sku,
    this.price,
    this.currencyCode,
    this.optionValues = const {},
    this.inventoryQuantity,
    this.manageInventory,
    this.allowBackorder,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final calculatedPrice = _asMap(json['calculated_price']);
    final options = <String, String>{};

    for (final rawOption in json['options'] as List? ?? const []) {
      final option = _asMap(rawOption);
      final optionId =
          option['option_id']?.toString() ??
          _asMap(option['option'])['id']?.toString();
      final value = option['value']?.toString();
      if (optionId != null && value != null) {
        options[optionId] = value;
      }
    }

    return ProductVariant(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      sku: json['sku']?.toString(),
      price: _asNum(calculatedPrice['calculated_amount']),
      currencyCode: calculatedPrice['currency_code']?.toString(),
      optionValues: options,
      inventoryQuantity: _asInt(json['inventory_quantity']),
      manageInventory: json['manage_inventory'] as bool?,
      allowBackorder: json['allow_backorder'] as bool?,
    );
  }

  /// `null` means the API didn't return enough information to verify stock.
  bool? get isAvailable {
    if (manageInventory == false) return true;
    if (inventoryQuantity == null) return null;
    if (inventoryQuantity! > 0) return true;
    return allowBackorder == true;
  }

  bool get isBackorder =>
      manageInventory == true &&
      inventoryQuantity == 0 &&
      allowBackorder == true;
}

class Product {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? thumbnail;
  final List<String> images;
  final String? brand;
  final Map<String, dynamic> specifications;
  final List<ProductOption> options;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.thumbnail,
    required this.images,
    this.brand,
    this.specifications = const {},
    this.options = const [],
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final metadata = _asMap(json['metadata']);
    final images = (json['images'] as List? ?? const [])
        .whereType<Map>()
        .map((image) => image['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
    final thumbnail = json['thumbnail']?.toString();
    if (images.isEmpty && thumbnail != null && thumbnail.isNotEmpty) {
      images.add(thumbnail);
    }

    return Product(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Điện thoại',
      subtitle: json['subtitle']?.toString(),
      description: json['description']?.toString(),
      thumbnail: thumbnail,
      images: images,
      brand: metadata['brand']?.toString() ?? json['subtitle']?.toString(),
      specifications: metadata,
      options: (json['options'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (option) =>
                ProductOption.fromJson(Map<String, dynamic>.from(option)),
          )
          .where((option) => option.id.isNotEmpty && option.title.isNotEmpty)
          .toList(),
      variants: (json['variants'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (variant) =>
                ProductVariant.fromJson(Map<String, dynamic>.from(variant)),
          )
          .toList(),
    );
  }

  num get minPrice {
    final prices = variants
        .map((variant) => variant.price)
        .whereType<num>()
        .toList();
    if (prices.isEmpty) return 0;
    return prices.reduce((current, next) => current < next ? current : next);
  }

  ProductVariant? variantForOptions(Map<String, String> selectedOptions) {
    if (options.isEmpty || selectedOptions.length != options.length) {
      return null;
    }

    for (final option in options) {
      if (!selectedOptions.containsKey(option.id)) return null;
    }

    for (final variant in variants) {
      final matches = options.every(
        (option) =>
            variant.optionValues[option.id] == selectedOptions[option.id],
      );
      if (matches) return variant;
    }
    return null;
  }

  bool hasVariantForOptions(Map<String, String> selectedOptions) {
    return variants.any(
      (variant) => selectedOptions.entries.every(
        (entry) => variant.optionValues[entry.key] == entry.value,
      ),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

num? _asNum(Object? value) => value is num ? value : num.tryParse('$value');

int? _asInt(Object? value) => value is int ? value : int.tryParse('$value');
