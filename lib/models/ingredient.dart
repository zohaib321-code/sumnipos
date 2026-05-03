class Ingredient {
  final int? id;
  final String name;
  final double stockQty;
  final String unit; // e.g. units, kg, liters, packets
  final double reorderLevel;

  Ingredient({
    this.id,
    required this.name,
    required this.stockQty,
    required this.unit,
    this.reorderLevel = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stock_qty': stockQty,
      'unit': unit,
      'reorder_level': reorderLevel,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      name: map['name'] ?? '',
      stockQty: (map['stock_qty'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'units',
      reorderLevel: (map['reorder_level'] ?? 10.0).toDouble(),
    );
  }
}

class ProductRecipe {
  final int? id;
  final int productId;
  final int? variantId;
  final int ingredientId;
  final double quantity;

  ProductRecipe({
    this.id,
    required this.productId,
    this.variantId,
    required this.ingredientId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'variant_id': variantId,
      'ingredient_id': ingredientId,
      'quantity': quantity,
    };
  }

  factory ProductRecipe.fromMap(Map<String, dynamic> map) {
    return ProductRecipe(
      id: map['id'],
      productId: map['product_id'],
      variantId: map['variant_id'],
      ingredientId: map['ingredient_id'],
      quantity: (map['quantity'] ?? 1.0).toDouble(),
    );
  }
}
