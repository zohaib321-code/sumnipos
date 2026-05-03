import 'product_variant.dart';

class Product {
  final int? id;
  final String name;
  final double price;
  final int categoryId;
  final int stockQty;
  final bool trackStock;
  final bool isActive;
  final String? imagePath;
  final List<ProductVariant>? _variants;

  List<ProductVariant> get variants => _variants ?? const [];

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.stockQty = 0,
    this.trackStock = false,
    this.isActive = true,
    this.imagePath,
    List<ProductVariant>? variants,
  }) : _variants = variants;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category_id': categoryId,
      'stock_qty': stockQty,
      'track_stock': trackStock ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'image_path': imagePath,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, {List<ProductVariant>? variants}) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      categoryId: map['category_id'],
      stockQty: map['stock_qty'],
      trackStock: map['track_stock'] == 1,
      isActive: map['is_active'] == 1,
      imagePath: map['image_path'],
      variants: variants ?? const [],
    );
  }
}
