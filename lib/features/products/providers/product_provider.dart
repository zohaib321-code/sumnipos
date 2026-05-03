import 'package:flutter/material.dart';
import '../../../core/db/database_helper.dart';
import '../../../models/product.dart';
import '../../../models/product_variant.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> productMaps = await db.query('products');
    
    final List<Product> loadedProducts = [];
    for (final pMap in productMaps) {
      final List<Map<String, dynamic>> variantMaps = await db.query(
        'product_variants',
        where: 'product_id = ?',
        whereArgs: [pMap['id']],
      );
      final variants = variantMaps.map((vMap) => ProductVariant.fromMap(vMap)).toList();
      loadedProducts.add(Product.fromMap(pMap, variants: variants));
    }
    
    _products = loadedProducts;
    _isLoading = false;
    notifyListeners();
  }

  Future<int?> addProduct(Product product) async {
    final db = await DatabaseHelper.instance.database;
    int? productId;
    await db.transaction((txn) async {
      productId = await txn.insert('products', product.toMap());
      for (final variant in product.variants) {
        await txn.insert('product_variants', {
          ...variant.toMap(),
          'product_id': productId,
        });
      }
    });
    await loadProducts();
    return productId;
  }

  Future<void> updateProduct(Product product) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
      // Simple sync: delete all and re-add
      await txn.delete('product_variants', where: 'product_id = ?', whereArgs: [product.id]);
      for (final variant in product.variants) {
        await txn.insert('product_variants', {
          ...variant.toMap(),
          'product_id': product.id,
        });
      }
    });
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadProducts();
  }

  Future<void> toggleProductStatus(int id, bool isActive) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'products',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadProducts();
  }

  List<Product> getProductsByCategory(int? categoryId) {
    // Only show active products for the POS screen
    return _products.where((p) => p.isActive && (categoryId == null || p.categoryId == categoryId)).toList();
  }
}
