import 'package:flutter/material.dart';
import '../../../core/db/database_helper.dart';

enum UserRole { admin, cashier, none }

class AuthProvider with ChangeNotifier {
  UserRole _role = UserRole.none;
  String? _userName;

  UserRole get role => _role;
  String? get userName => _userName;
  bool get isAdmin => _role == UserRole.admin;

  Future<bool> login(String pin) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'pin_code = ?',
      whereArgs: [pin],
    );

    if (maps.isNotEmpty) {
      final user = maps.first;
      _userName = user['name'];
      _role = user['role'] == 'admin' ? UserRole.admin : UserRole.cashier;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _role = UserRole.none;
    _userName = null;
    notifyListeners();
  }
}
