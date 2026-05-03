import 'package:flutter/material.dart';
import '../../../core/db/database_helper.dart';
import '../../../models/category.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    
    _categories = maps.map((map) => Category.fromMap(map)).toList();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('categories', category.toMap());
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadCategories();
  }
}
