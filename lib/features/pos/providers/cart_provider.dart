import 'package:flutter/material.dart';
import '../../../core/db/database_helper.dart';
import '../../../models/product.dart';
import '../../../models/product_variant.dart';
import '../../../models/order.dart';
import '../../../models/deal.dart';
import '../../../models/settings.dart';

class CartItem {
  final Product? product;
  final ProductVariant? variant;
  final Deal? deal;
  final Map<int, ProductVariant> selectedDealVariants; // dealItemId -> Variant
  int quantity;
  String? notes;

  CartItem({
    this.product,
    this.variant,
    this.deal,
    this.selectedDealVariants = const {},
    this.quantity = 1,
    this.notes,
  }) : assert(product != null || deal != null);

  double get price => variant?.price ?? product?.price ?? deal?.price ?? 0;
  String get name => variant != null ? '${product!.name} (${variant!.name})' : (product?.name ?? deal?.name ?? 'Unknown');
  String get id {
    if (variant != null) return '${product!.id}_v${variant!.id}';
    if (deal != null) {
      if (selectedDealVariants.isEmpty) return 'deal_${deal!.id}';
      final variantKeys = selectedDealVariants.keys.toList()..sort();
      final variantString = variantKeys.map((k) => '${k}:${selectedDealVariants[k]!.id}').join('_');
      return 'deal_${deal!.id}_$variantString';
    }
    return product!.id.toString();
  }
  String? get imagePath => product?.imagePath ?? deal?.imagePath;

  double get total => price * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  int? _editingOrderId;
  SystemSettings _settings = SystemSettings.defaultSettings();

  List<CartItem> get items => List.unmodifiable(_items);
  int? get editingOrderId => _editingOrderId;
  SystemSettings get settings => _settings;

  CartProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await DatabaseHelper.instance.getSettings();
    notifyListeners();
  }

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  double get taxAmount {
    return subtotal * (_settings.taxPercentage / 100);
  }

  List<OrderCharge> get customChargesCalculated {
    return _settings.customCharges.where((c) => c.isActive).map((charge) {
      double amount = 0;
      if (charge.type == ChargeType.percentage) {
        amount = subtotal * (charge.value / 100);
      } else {
        amount = charge.value;
      }
      return OrderCharge(
        name: charge.name,
        percentage: charge.type == ChargeType.percentage ? charge.value : 0,
        amount: amount,
      );
    }).toList();
  }

  double get chargesTotal {
    return customChargesCalculated.fold(0, (sum, item) => sum + item.amount);
  }

  double get totalAmount {
    return subtotal + taxAmount + chargesTotal;
  }

  void addToCart(Product product, {ProductVariant? variant}) {
    if (product.trackStock && product.stockQty <= 0) return;

    final itemId = variant != null ? '${product.id}_v${variant.id}' : product.id.toString();
    final index = _items.indexWhere((item) => item.id == itemId && item.notes == null);
    
    if (index >= 0) {
      if (product.trackStock && _items[index].quantity >= product.stockQty) return;
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product, variant: variant));
    }
    notifyListeners();
  }

  void addDealToCart(Deal deal, {Map<int, ProductVariant> selections = const {}}) {
    final tempItem = CartItem(deal: deal, selectedDealVariants: selections);
    final index = _items.indexWhere((item) => item.id == tempItem.id && item.notes == null);
    
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(tempItem);
    }
    notifyListeners();
  }

  void updateQuantity(String id, int delta) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateItemNotes(int index, String? notes) {
    if (index >= 0 && index < _items.length) {
      _items[index].notes = notes;
      notifyListeners();
    }
  }

  Future<void> loadOrderForEditing(Order order) async {
    clearCart();
    _editingOrderId = order.id;
    
    final db = await DatabaseHelper.instance.database;
    
    for (var item in order.items) {
      // Logic for regular products
      if (item.productId != -1 && !item.productName.contains('↳')) {
        final List<Map<String, dynamic>> maps = await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        
        Product? prod;
        if (maps.isNotEmpty) {
          prod = Product.fromMap(maps.first);
        } else {
          prod = Product(id: item.productId, name: item.productName, price: item.price, categoryId: 0, stockQty: 999, trackStock: false);
        }

        ProductVariant? variant;
        if (item.variantId != null) {
          final vMaps = await db.query('product_variants', where: 'id = ?', whereArgs: [item.variantId]);
          if (vMaps.isNotEmpty) variant = ProductVariant.fromMap(vMaps.first);
        }

        _items.add(CartItem(
          product: prod,
          variant: variant,
          quantity: item.quantity,
          notes: item.notes,
        ));
      } 
      // Logic for Deals
      else if (item.productId == -1 && !item.productName.contains('↳')) {
        final List<Map<String, dynamic>> maps = await db.query(
          'deals',
          where: 'name = ?',
          whereArgs: [item.productName],
        );

        if (maps.isNotEmpty) {
          // Re-load the deal structure with its items so stock can be deducted correctly on re-save
          final dealId = maps.first['id'];
          final dealItemsData = await db.query('deal_items', where: 'deal_id = ?', whereArgs: [dealId]);
          
          List<DealItem> dealItems = [];
          for (var di in dealItemsData) {
            final pMaps = await db.query('products', where: 'id = ?', whereArgs: [di['product_id']]);
            Product? p; if (pMaps.isNotEmpty) p = Product.fromMap(pMaps.first);
            dealItems.add(DealItem.fromMap(di, product: p));
          }

          _items.add(CartItem(
            deal: Deal.fromMap(maps.first, items: dealItems),
            quantity: item.quantity,
            notes: item.notes,
          ));
        }
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _editingOrderId = null;
    notifyListeners();
  }

  Future<void> refreshSettings() async {
    await _loadSettings();
  }

  Future<int?> checkout({required String status, String? orderNotes}) async {
    if (_items.isEmpty) return null;

    try {
      final order = Order(
        id: _editingOrderId,
        subtotal: subtotal,
        taxAmount: taxAmount,
        charges: customChargesCalculated,
        totalAmount: totalAmount,
        dateTime: DateTime.now(),
        status: status,
        notes: orderNotes,
      );

      List<OrderItem> orderItems = [];
      for (var cartItem in _items) {
        if (cartItem.product != null) {
          orderItems.add(OrderItem(
            orderId: 0,
            productId: cartItem.product!.id!,
            variantId: cartItem.variant?.id,
            productName: cartItem.name,
            quantity: cartItem.quantity,
            price: cartItem.price,
            notes: cartItem.notes,
          ));
        } else if (cartItem.deal != null) {
          // Main Deal Header
          orderItems.add(OrderItem(
            orderId: 0,
            productId: -1,
            productName: cartItem.deal!.name,
            quantity: cartItem.quantity,
            price: cartItem.deal!.price,
            notes: cartItem.notes,
          ));
          
          // Deal Components (to deduct stock)
          if (cartItem.deal!.items.isNotEmpty) {
            for (var dealItem in cartItem.deal!.items) {
              final selectedVariant = cartItem.selectedDealVariants[dealItem.id];
              final finalVariantId = selectedVariant?.id ?? dealItem.variantId;
              final variantLabel = selectedVariant != null ? " (${selectedVariant.name})" : "";

              orderItems.add(OrderItem(
                orderId: 0,
                productId: dealItem.productId,
                variantId: finalVariantId,
                productName: '  ↳ ${dealItem.product?.name ?? "Item"}$variantLabel',
                quantity: dealItem.qty * cartItem.quantity,
                price: 0,
              ));
            }
          }
        }
      }

      int orderId = await DatabaseHelper.instance.createOrder(order, orderItems);
      
      clearCart();
      return orderId;
    } catch (e) {
      debugPrint('Checkout error: $e');
      rethrow;
    }
  }
}
