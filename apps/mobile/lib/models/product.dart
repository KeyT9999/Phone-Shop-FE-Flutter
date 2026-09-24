class ProductVariant {
  final String id;
  final String title;
  final String? sku;
  final num? price;
  final List<dynamic>? options;

  ProductVariant({
    required this.id,
    required this.title,
    this.sku,
    this.price,
    this.options,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    num? extractedPrice;
    if (json['calculated_price'] != null && json['calculated_price']['calculated_amount'] != null) {
      extractedPrice = json['calculated_price']['calculated_amount'];
    } else if (json['prices'] != null && (json['prices'] as List).isNotEmpty) {
      extractedPrice = json['prices'][0]['amount'];
    }

    return ProductVariant(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      sku: json['sku'],
      price: extractedPrice,
      options: json['options'],
    );
  }
}

class Product {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? thumbnail;
  final List<String> images;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.thumbnail,
    required this.images,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final imageList = <String>[];
    if (json['images'] != null) {
      for (var img in json['images']) {
        if (img is Map && img['url'] != null) {
          imageList.add(img['url']);
        }
      }
    }
    if (imageList.isEmpty && json['thumbnail'] != null) {
      imageList.add(json['thumbnail']);
    }

    final variantList = <ProductVariant>[];
    if (json['variants'] != null) {
      for (var v in json['variants']) {
        variantList.add(ProductVariant.fromJson(v));
      }
    }

    return Product(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Điện thoại',
      subtitle: json['subtitle'],
      description: json['description'],
      thumbnail: json['thumbnail'],
      images: imageList,
      variants: variantList,
    );
  }

  num get minPrice {
    if (variants.isEmpty) return 0;
    num min = double.infinity;
    for (var v in variants) {
      if (v.price != null && v.price! < min) {
        min = v.price!;
      }
    }
    return min == double.infinity ? 0 : min;
  }
}
