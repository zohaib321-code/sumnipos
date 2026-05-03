import 'product.dart';
import 'product_variant.dart';

class Deal {
  final int? id;
  final String name;
  final double price;
  final bool isActive;
  final String? imagePath;
  final List<DealItem> items;

  Deal({
    this.id,
    required this.name,
    required this.price,
    this.isActive = true,
    this.imagePath,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'is_active': isActive ? 1 : 0,
      'image_path': imagePath,
    };
  }

  factory Deal.fromMap(Map<String, dynamic> map, {List<DealItem> items = const []}) {
    return Deal(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      isActive: map['is_active'] == 1,
      imagePath: map['image_path'],
      items: items,
    );
  }
}

class DealItem {
  final int? id;
  final int dealId;
  final int productId;
  final int? variantId; 
  final int qty;
  final Product? product; 
  final ProductVariant? variant; 

  DealItem({
    this.id,
    required this.dealId,
    required this.productId,
    this.variantId,
    required this.qty,
    this.product,
    this.variant,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deal_id': dealId,
      'product_id': productId,
      'variant_id': variantId ?? -1,
      'qty': qty,
    };
  }

  factory DealItem.fromMap(Map<String, dynamic> map, {Product? product, ProductVariant? variant}) {
    return DealItem(
      id: map['id'],
      dealId: map['deal_id'],
      productId: map['product_id'],
      variantId: (map['variant_id'] == -1) ? null : map['variant_id'],
      qty: map['qty'],
      product: product,
      variant: variant,
    );
  }
}
