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
    debugPrint('[Auth] Login requested with ${pin.length} digits.');
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'pin_code = ?',
      whereArgs: [pin],
    );
    debugPrint('[Auth] Matching users found: ${maps.length}.');

    if (maps.isNotEmpty) {
      final user = maps.first;
      _userName = user['name'];
      _role = user['role'] == 'admin' ? UserRole.admin : UserRole.cashier;
      debugPrint('[Auth] Logged in as $_role.');
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
