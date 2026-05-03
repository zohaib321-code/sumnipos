import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/order.dart';
import '../../models/settings.dart';
import 'dart:developer' as dev;
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 16,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    dev.log('Upgrading database from $oldVersion to $newVersion');
    if (oldVersion < 2) {
      await _addColumnIfNotExists(db, 'products', 'is_active', 'INTEGER NOT NULL DEFAULT 1');
      await _addColumnIfNotExists(db, 'deals', 'is_active', 'INTEGER NOT NULL DEFAULT 1');
    }
    if (oldVersion < 4) {
      await _addColumnIfNotExists(db, 'order_items', 'product_name', 'TEXT');
    }
    if (oldVersion < 5) {
      await _addColumnIfNotExists(db, 'orders', 'status', 'TEXT NOT NULL DEFAULT "paid"');
      await _addColumnIfNotExists(db, 'orders', 'notes', 'TEXT');
      await _addColumnIfNotExists(db, 'order_items', 'notes', 'TEXT');
    }
    if (oldVersion < 6) {
      await _addColumnIfNotExists(db, 'categories', 'image_path', 'TEXT');
      await _addColumnIfNotExists(db, 'deals', 'image_path', 'TEXT');
    }
    if (oldVersion < 7) {
      await _addColumnIfNotExists(db, 'orders', 'subtotal', 'REAL DEFAULT 0.0');
      await _addColumnIfNotExists(db, 'orders', 'tax_amount', 'REAL DEFAULT 0.0');
      
      await db.execute('CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY, store_name TEXT, store_address TEXT, store_phone TEXT, tax_percentage REAL, footer_message TEXT)');
      await db.insert('settings', SystemSettings.defaultSettings().toMap());
    }
    if (oldVersion < 8) {
      await _addColumnIfNotExists(db, 'settings', 'custom_charges', 'TEXT');
    }
    if (oldVersion < 9) {
      await _addColumnIfNotExists(db, 'orders', 'charges', 'TEXT');
    }
    if (oldVersion < 10 || oldVersion < 13) {
      await db.execute('CREATE TABLE IF NOT EXISTS product_variants (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, name TEXT NOT NULL, price REAL NOT NULL, stock_qty INTEGER DEFAULT 0, track_stock INTEGER DEFAULT 0, FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE)');
      await db.execute('CREATE TABLE IF NOT EXISTS ingredients (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, stock_qty REAL, unit TEXT, reorder_level REAL)');
      await db.execute('CREATE TABLE IF NOT EXISTS product_recipes (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER, variant_id INTEGER, ingredient_id INTEGER, quantity REAL, FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE, FOREIGN KEY (ingredient_id) REFERENCES ingredients (id) ON DELETE CASCADE)');
    }
    if (oldVersion < 12) {
      await _addColumnIfNotExists(db, 'order_items', 'variant_id', 'INTEGER');
    }
    if (oldVersion < 14) {
      await _addColumnIfNotExists(db, 'deal_items', 'variant_id', 'INTEGER');
    }
    if (oldVersion < 15) {
      await _addColumnIfNotExists(db, 'settings', 'customer_printer', 'TEXT DEFAULT "internal"');
      await _addColumnIfNotExists(db, 'settings', 'kitchen_printer', 'TEXT DEFAULT "internal"');
    }
    if (oldVersion < 16) {
      await _addColumnIfNotExists(db, 'settings', 'header_items', 'TEXT');
      await _addColumnIfNotExists(db, 'settings', 'footer_items', 'TEXT');
      await _addColumnIfNotExists(db, 'settings', 'table_font_size', 'INTEGER DEFAULT 24');
      await _addColumnIfNotExists(db, 'settings', 'table_alignment', 'INTEGER DEFAULT 1');
    }
  }

  Future<void> _addColumnIfNotExists(Database db, String tableName, String columnName, String columnType) async {
    var tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
    if (!tableInfo.any((column) => column['name'] == columnName)) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, icon TEXT NOT NULL, image_path TEXT)');
    await db.execute('CREATE TABLE products (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price REAL NOT NULL, category_id INTEGER NOT NULL, stock_qty INTEGER NOT NULL, track_stock INTEGER NOT NULL, is_active INTEGER NOT NULL DEFAULT 1, image_path TEXT, FOREIGN KEY (category_id) REFERENCES categories (id))');
    await db.execute('CREATE TABLE deals (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price REAL NOT NULL, is_active INTEGER NOT NULL DEFAULT 1, image_path TEXT)');
    await db.execute('CREATE TABLE deal_items (id INTEGER PRIMARY KEY AUTOINCREMENT, deal_id INTEGER, product_id INTEGER, variant_id INTEGER, qty INTEGER, FOREIGN KEY (deal_id) REFERENCES deals (id), FOREIGN KEY (product_id) REFERENCES products (id))');
    await db.execute('CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, subtotal REAL DEFAULT 0.0, tax_amount REAL DEFAULT 0.0, charges TEXT, total REAL NOT NULL, created_at TEXT NOT NULL, status TEXT NOT NULL DEFAULT "paid", notes TEXT)');
    await db.execute('CREATE TABLE order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER, product_id INTEGER, variant_id INTEGER, product_name TEXT, qty INTEGER, price REAL NOT NULL, notes TEXT, FOREIGN KEY (order_id) REFERENCES orders (id), FOREIGN KEY (product_id) REFERENCES products (id))');
    await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, pin_code TEXT NOT NULL, role TEXT NOT NULL)');
    await db.execute('CREATE TABLE settings (id INTEGER PRIMARY KEY, store_name TEXT, store_address TEXT, store_phone TEXT, tax_percentage REAL, footer_message TEXT, custom_charges TEXT, customer_printer TEXT DEFAULT "internal", kitchen_printer TEXT DEFAULT "internal", header_items TEXT, footer_items TEXT, table_font_size INTEGER DEFAULT 24, table_alignment INTEGER DEFAULT 1)');
    await db.execute('CREATE TABLE product_variants (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, name TEXT NOT NULL, price REAL NOT NULL, stock_qty INTEGER NOT NULL, track_stock INTEGER NOT NULL, FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE ingredients (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, stock_qty REAL, unit TEXT, reorder_level REAL)');
    await db.execute('CREATE TABLE product_recipes (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER, variant_id INTEGER, ingredient_id INTEGER, quantity REAL, FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE, FOREIGN KEY (ingredient_id) REFERENCES ingredients (id) ON DELETE CASCADE)');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    await db.insert('users', {'name': 'Administrator', 'pin_code': '1234', 'role': 'admin'});
    await db.insert('users', {'name': 'Cashier 01', 'pin_code': '0000', 'role': 'cashier'});
    await db.insert('settings', SystemSettings.defaultSettings().toMap());
    
    // Categories
    int catBurgers = await db.insert('categories', {'name': 'Burgers', 'icon': 'lunch_dining'});
    int catSides = await db.insert('categories', {'name': 'Sides', 'icon': 'tapas'});
    int catBevs = await db.insert('categories', {'name': 'Beverages', 'icon': 'local_drink'});
    int catDesserts = await db.insert('categories', {'name': 'Desserts', 'icon': 'icecream'});

    // Ingredients
    int ingBun = await db.insert('ingredients', {'name': 'Burger Bun', 'stock_qty': 100, 'unit': 'pcs', 'reorder_level': 20});
    int ingBeef = await db.insert('ingredients', {'name': 'Beef Patty', 'stock_qty': 80, 'unit': 'pcs', 'reorder_level': 20});
    int ingChicken = await db.insert('ingredients', {'name': 'Chicken Fillet', 'stock_qty': 60, 'unit': 'pcs', 'reorder_level': 15});
    int ingPotatoes = await db.insert('ingredients', {'name': 'Potatoes', 'stock_qty': 50, 'unit': 'kg', 'reorder_level': 10});

    // Products (No Variants)
    int prodBeef = await db.insert('products', {'name': 'Smash Beef Burger', 'price': 750.0, 'category_id': catBurgers, 'stock_qty': 0, 'track_stock': 0, 'is_active': 1});
    int prodChicken = await db.insert('products', {'name': 'Crispy Chicken Burger', 'price': 650.0, 'category_id': catBurgers, 'stock_qty': 0, 'track_stock': 0, 'is_active': 1});
    int prodWater = await db.insert('products', {'name': 'Mineral Water', 'price': 100.0, 'category_id': catBevs, 'stock_qty': 200, 'track_stock': 1, 'is_active': 1});
    int prodBrownie = await db.insert('products', {'name': 'Chocolate Brownie', 'price': 300.0, 'category_id': catDesserts, 'stock_qty': 20, 'track_stock': 1, 'is_active': 1});

    // Recipes for No Variant Products
    await db.insert('product_recipes', {'product_id': prodBeef, 'ingredient_id': ingBun, 'quantity': 1.0});
    await db.insert('product_recipes', {'product_id': prodBeef, 'ingredient_id': ingBeef, 'quantity': 1.0});
    await db.insert('product_recipes', {'product_id': prodChicken, 'ingredient_id': ingBun, 'quantity': 1.0});
    await db.insert('product_recipes', {'product_id': prodChicken, 'ingredient_id': ingChicken, 'quantity': 1.0});

    // Products (With Variants)
    int prodFries = await db.insert('products', {'name': 'French Fries', 'price': 250.0, 'category_id': catSides, 'stock_qty': 0, 'track_stock': 0, 'is_active': 1});
    int varFriesS = await db.insert('product_variants', {'product_id': prodFries, 'name': 'Small', 'price': 200.0, 'stock_qty': 0, 'track_stock': 0});
    int varFriesM = await db.insert('product_variants', {'product_id': prodFries, 'name': 'Medium', 'price': 300.0, 'stock_qty': 0, 'track_stock': 0});
    int varFriesL = await db.insert('product_variants', {'product_id': prodFries, 'name': 'Large', 'price': 450.0, 'stock_qty': 0, 'track_stock': 0});
    
    await db.insert('product_recipes', {'product_id': prodFries, 'variant_id': varFriesS, 'ingredient_id': ingPotatoes, 'quantity': 0.15});
    await db.insert('product_recipes', {'product_id': prodFries, 'variant_id': varFriesM, 'ingredient_id': ingPotatoes, 'quantity': 0.25});
    await db.insert('product_recipes', {'product_id': prodFries, 'variant_id': varFriesL, 'ingredient_id': ingPotatoes, 'quantity': 0.40});

    int prodSoda = await db.insert('products', {'name': 'Fountain Soda', 'price': 150.0, 'category_id': catBevs, 'stock_qty': 0, 'track_stock': 0, 'is_active': 1});
    int varCola = await db.insert('product_variants', {'product_id': prodSoda, 'name': 'Cola', 'price': 150.0, 'stock_qty': 0, 'track_stock': 0});
    int varSprite = await db.insert('product_variants', {'product_id': prodSoda, 'name': 'Sprite', 'price': 150.0, 'stock_qty': 0, 'track_stock': 0});

    // Deals
    int dealCombo = await db.insert('deals', {'name': 'Smash Combo', 'price': 1050.0, 'is_active': 1});
    await db.insert('deal_items', {'deal_id': dealCombo, 'product_id': prodBeef, 'qty': 1});
    await db.insert('deal_items', {'deal_id': dealCombo, 'product_id': prodFries, 'variant_id': varFriesM, 'qty': 1});
    await db.insert('deal_items', {'deal_id': dealCombo, 'product_id': prodSoda, 'variant_id': varCola, 'qty': 1});

    int dealCouple = await db.insert('deals', {'name': 'Couple Goals', 'price': 1500.0, 'is_active': 1});
    await db.insert('deal_items', {'deal_id': dealCouple, 'product_id': prodChicken, 'qty': 2});
    await db.insert('deal_items', {'deal_id': dealCouple, 'product_id': prodFries, 'variant_id': varFriesS, 'qty': 2});
    await db.insert('deal_items', {'deal_id': dealCouple, 'product_id': prodSoda, 'variant_id': null, 'qty': 2}); // Variant null allows user choice
  }

  Future<SystemSettings> getSettings() async {
    final db = await instance.database;
    final maps = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    return maps.isNotEmpty ? SystemSettings.fromMap(maps.first) : SystemSettings.defaultSettings();
  }

  Future<void> updateSettings(SystemSettings settings) async {
    final db = await instance.database;
    await db.update('settings', settings.toMap(), where: 'id = ?', whereArgs: [1]);
  }

  Future<String> getUserPin(String role) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'role = ?', whereArgs: [role]);
    return maps.isNotEmpty ? maps.first['pin_code'].toString() : '';
  }

  Future<void> updateUserPin(String role, String pin) async {
    final db = await instance.database;
    await db.update('users', {'pin_code': pin}, where: 'role = ?', whereArgs: [role]);
  }

  Future<int> createOrder(Order order, List<OrderItem> items) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      int orderId;
      bool wasAlreadyPaid = false;
      
      if (order.id != null) {
        final existing = await txn.query('orders', where: 'id = ?', whereArgs: [order.id]);
        if (existing.isNotEmpty && existing.first['status'] == 'paid') wasAlreadyPaid = true;
        
        await txn.update('orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
        await txn.delete('order_items', where: 'order_id = ?', whereArgs: [order.id]);
        orderId = order.id!;
      } else {
        orderId = await txn.insert('orders', order.toMap());
      }
      
      for (var item in items) {
        await txn.insert('order_items', {...item.toMap(), 'order_id': orderId});
      }

      if (order.status == 'paid' && !wasAlreadyPaid) {
        await _performInventoryDeduction(txn, items);
      }
      return orderId;
    });
  }

  Future<void> _performInventoryDeduction(Transaction txn, List<OrderItem> items) async {
    for (var item in items) {
      if (item.productId <= 0) continue; 

      List<Map<String, dynamic>> recipes;
      if (item.variantId != null) {
        recipes = await txn.query(
          'product_recipes', 
          where: 'product_id = ? AND (variant_id = ? OR variant_id IS NULL)', 
          whereArgs: [item.productId, item.variantId]
        );
      } else {
        recipes = await txn.query(
          'product_recipes', 
          where: 'product_id = ? AND variant_id IS NULL', 
          whereArgs: [item.productId]
        );
      }
        
      for (var r in recipes) {
        final qtyToConsume = (r['quantity'] as num).toDouble() * item.quantity;
        await txn.execute(
          'UPDATE ingredients SET stock_qty = stock_qty - ? WHERE id = ?', 
          [qtyToConsume, r['ingredient_id']]
        );
      }

      if (item.variantId != null) {
        await txn.execute(
          'UPDATE product_variants SET stock_qty = stock_qty - ? WHERE id = ? AND track_stock = 1', 
          [item.quantity, item.variantId]
        );
      } else {
        await txn.execute(
          'UPDATE products SET stock_qty = stock_qty - ? WHERE id = ? AND track_stock = 1', 
          [item.quantity, item.productId]
        );
      }
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final existing = await txn.query('orders', where: 'id = ?', whereArgs: [orderId]);
      if (existing.isEmpty || existing.first['status'] == status) return;

      await txn.update('orders', {'status': status}, where: 'id = ?', whereArgs: [orderId]);
      
      if (status == 'paid') {
        final itemsData = await txn.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
        final items = itemsData.map((e) => OrderItem.fromMap(e)).toList();
        await _performInventoryDeduction(txn, items);
      }
    });
  }

  Future<void> deleteOrder(int orderId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
      await txn.delete('orders', where: 'id = ?', whereArgs: [orderId]);
    });
  }

  Future<List<Order>> getOrders({String? status}) async {
    final db = await instance.database;
    final result = status != null 
        ? await db.query('orders', where: 'status = ?', whereArgs: [status], orderBy: 'id DESC')
        : await db.query('orders', orderBy: 'id DESC');
    
    List<Order> orders = [];
    for (var row in result) {
      final items = (await db.query('order_items', where: 'order_id = ?', whereArgs: [row['id']]))
          .map((e) => OrderItem.fromMap(e)).toList();
      orders.add(Order.fromMap(row, items));
    }
    return orders;
  }

  Future<Order?> getOrder(int id) async {
    final db = await instance.database;
    final maps = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final items = (await db.query('order_items', where: 'order_id = ?', whereArgs: [id]))
        .map((e) => OrderItem.fromMap(e)).toList();
    return Order.fromMap(maps.first, items);
  }

  Future<void> wipeAndSeedEverything() async {
     final db = await instance.database;
     await db.transaction((txn) async {
       await txn.delete('orders'); await txn.delete('order_items'); await txn.delete('product_recipes');
       await txn.delete('deal_items'); await txn.delete('deals'); await txn.delete('product_variants');
       await txn.delete('products'); await txn.delete('categories'); await txn.delete('ingredients');
       await _seedData(txn as Database);
     });
  }
}
