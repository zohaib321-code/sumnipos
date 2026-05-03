class ProductVariant {
  final int? id;
  final int? productId;
  final String name;
  final double price;
  final int stockQty;
  final bool trackStock;

  ProductVariant({
    this.id,
    this.productId,
    required this.name,
    required this.price,
    this.stockQty = 0,
    this.trackStock = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'price': price,
      'stock_qty': stockQty,
      'track_stock': trackStock ? 1 : 0,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'],
      productId: map['product_id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      stockQty: map['stock_qty'] ?? 0,
      trackStock: map['track_stock'] == 1,
    );
  }
}
