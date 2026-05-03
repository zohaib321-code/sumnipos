import 'package:flutter/material.dart';
import '../../../core/db/database_helper.dart';
import '../../../models/deal.dart';
import '../../../models/product.dart';
import '../../../models/product_variant.dart';

class DealProvider with ChangeNotifier {
  List<Deal> _deals = [];
  bool _isLoading = false;

  List<Deal> get deals => _deals;
  bool get isLoading => _isLoading;

  Future<void> loadDeals() async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> dealMaps = await db.query('deals');
    
    List<Deal> loadedDeals = [];
    for (var dealMap in dealMaps) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'deal_items',
        where: 'deal_id = ?',
        whereArgs: [dealMap['id']],
      );

      List<DealItem> items = [];
      for (var itemMap in itemMaps) {
        final List<Map<String, dynamic>> productMaps = await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [itemMap['product_id']],
        );
        
        Product? product;
        ProductVariant? variant;
        if (productMaps.isNotEmpty) {
          // Fetch variants so POS knows if prompt is required
          final List<Map<String, dynamic>> pvMaps = await db.query(
            'product_variants',
            where: 'product_id = ?',
            whereArgs: [productMaps.first['id']],
          );
          final pVariants = pvMaps.map((v) => ProductVariant.fromMap(v)).toList();
          product = Product.fromMap(productMaps.first, variants: pVariants);
          
          // Load variant if exists
          if (itemMap['variant_id'] != null) {
            final List<Map<String, dynamic>> variantMaps = await db.query(
              'product_variants',
              where: 'id = ?',
              whereArgs: [itemMap['variant_id']],
            );
            if (variantMaps.isNotEmpty) {
              variant = ProductVariant.fromMap(variantMaps.first);
            }
          }
        }

        items.add(DealItem(
          id: itemMap['id'],
          dealId: itemMap['deal_id'],
          productId: itemMap['product_id'],
          variantId: itemMap['variant_id'],
          qty: itemMap['qty'],
          product: product,
          variant: variant,
        ));
      }

      loadedDeals.add(Deal.fromMap(dealMap, items: items));
    }
    
    _deals = loadedDeals;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveDeal(Deal deal, List<DealItem> items) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      int dealId;
      if (deal.id == null) {
        dealId = await txn.insert('deals', deal.toMap());
      } else {
        dealId = deal.id!;
        await txn.update(
          'deals',
          deal.toMap(),
          where: 'id = ?',
          whereArgs: [dealId],
        );
        // Remove old items to replace them
        await txn.delete(
          'deal_items',
          where: 'deal_id = ?',
          whereArgs: [dealId],
        );
      }

      for (var item in items) {
        await txn.insert('deal_items', {
          'deal_id': dealId,
          'product_id': item.productId,
          'variant_id': item.variantId,
          'qty': item.qty,
        });
      }
    });
    await loadDeals();
  }

  Future<void> deleteDeal(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('deal_items', where: 'deal_id = ?', whereArgs: [id]);
      await txn.delete('deals', where: 'id = ?', whereArgs: [id]);
    });
    await loadDeals();
  }

  Future<void> toggleDealStatus(int id, bool isActive) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'deals',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadDeals();
  }

  List<Deal> getActiveDeals() {
    return _deals.where((d) => d.isActive).toList();
  }
}
