import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'features/pos/providers/cart_provider.dart';
import 'features/products/providers/category_provider.dart';
import 'features/products/providers/product_provider.dart';
import 'features/deals/providers/deal_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/pos/screens/pos_screen.dart';
import 'core/services/printer_service.dart';
import 'features/products/providers/ingredient_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/db/database_helper.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Windows/Linux
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize Sunmi Printer (Only on Android)
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await PrinterService.init();
    } catch (e) {
      debugPrint('Printer initialization failed: $e');
    }
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadCategories()),
        ChangeNotifierProvider(create: (_) => ProductProvider()..loadProducts()),
        ChangeNotifierProvider(create: (_) => DealProvider()..loadDeals()),
        ChangeNotifierProvider(create: (_) => IngredientProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velocity POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.role == UserRole.none) {
            return const LoginScreen();
          }
          return const PosScreen();
        },
      ),
    );
  }
}
