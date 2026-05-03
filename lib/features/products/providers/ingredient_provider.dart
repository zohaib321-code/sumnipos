import 'package:flutter/material.dart';
import '../../../core/db/database_helper.dart';
import '../../../models/ingredient.dart';

class IngredientProvider with ChangeNotifier {
  List<Ingredient> _ingredients = [];
  bool _isLoading = false;

  List<Ingredient> get ingredients => _ingredients;
  bool get isLoading => _isLoading;

  IngredientProvider() {
    loadIngredients();
  }

  Future<void> loadIngredients() async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('ingredients', orderBy: 'name ASC');

    _ingredients = maps.map((m) => Ingredient.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addIngredient(Ingredient ingredient) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('ingredients', ingredient.toMap());
    await loadIngredients();
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'ingredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
    await loadIngredients();
  }

  Future<void> deleteIngredient(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('ingredients', where: 'id = ?', whereArgs: [id]);
    await loadIngredients();
  }

  // Recipe Methods
  Future<List<ProductRecipe>> getRecipe(int productId, {int? variantId}) async {
    final db = await DatabaseHelper.instance.database;
    
    String whereClause = 'product_id = ?';
    List<dynamic> args = [productId];
    
    if (variantId != null) {
      whereClause += ' AND variant_id = ?';
      args.add(variantId);
    } else {
      whereClause += ' AND variant_id IS NULL';
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'product_recipes',
      where: whereClause,
      whereArgs: args,
    );
    return maps.map((m) => ProductRecipe.fromMap(m)).toList();
  }

  Future<void> saveRecipe(int productId, int? variantId, List<ProductRecipe> recipes) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Clear old recipe for this product/variant
      if (variantId != null) {
        await txn.delete('product_recipes', where: 'product_id = ? AND variant_id = ?', whereArgs: [productId, variantId]);
      } else {
        await txn.delete('product_recipes', where: 'product_id = ? AND variant_id IS NULL', whereArgs: [productId]);
      }

      // Insert new ones
      for (var r in recipes) {
        await txn.insert('product_recipes', r.toMap());
      }
    });
  }
}
