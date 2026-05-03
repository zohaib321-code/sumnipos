import 'dart:convert';

class OrderCharge {
  final String name;
  final double percentage;
  final double amount;

  OrderCharge({
    required this.name,
    required this.percentage,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'percentage': percentage,
      'amount': amount,
    };
  }

  factory OrderCharge.fromMap(Map<String, dynamic> map) {
    return OrderCharge(
      name: map['name'] ?? '',
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }
}

class Order {
  final int? id;
  final double subtotal;
  final double taxAmount;
  final List<OrderCharge> charges;
  final double totalAmount;
  final DateTime dateTime;
  final List<OrderItem> items;
  final String status; // 'paid' or 'unpaid'
  final String? notes;

  Order({
    this.id,
    required this.subtotal,
    required this.taxAmount,
    this.charges = const [],
    required this.totalAmount,
    required this.dateTime,
    this.items = const [],
    this.status = 'paid',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'charges': jsonEncode(charges.map((e) => e.toMap()).toList()),
      'total': totalAmount,
      'created_at': dateTime.toIso8601String(),
      'status': status,
      'notes': notes,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Order.fromMap(Map<String, dynamic> map, [List<OrderItem> items = const []]) {
    List<OrderCharge> charges = [];
    if (map['charges'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(map['charges']);
        charges = decoded.map((e) => OrderCharge.fromMap(e)).toList();
      } catch (e) {
        print("Error decoding order charges: $e");
      }
    }

    return Order(
      id: map['id'],
      subtotal: (map['subtotal'] ?? map['total'] ?? 0.0).toDouble(),
      taxAmount: (map['tax_amount'] ?? 0.0).toDouble(),
      charges: charges,
      totalAmount: (map['total'] as num).toDouble(),
      dateTime: DateTime.parse(map['created_at']),
      items: items,
      status: map['status'] ?? 'paid',
      notes: map['notes'],
    );
  }

  Order copyWith({
    int? id,
    double? subtotal,
    double? taxAmount,
    List<OrderCharge>? charges,
    double? totalAmount,
    DateTime? dateTime,
    List<OrderItem>? items,
    String? status,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      charges: charges ?? this.charges,
      totalAmount: totalAmount ?? this.totalAmount,
      dateTime: dateTime ?? this.dateTime,
      items: items ?? this.items,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final String productName;
  final int? variantId;
  final int quantity;
  final double price;
  final String? notes;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    this.variantId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'order_id': orderId,
      'product_id': productId,
      'variant_id': variantId ?? -1,
      'product_name': productName,
      'qty': quantity,
      'price': price,
      'notes': notes,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'] ?? 0,
      productId: map['product_id'] ?? 0,
      variantId: (map['variant_id'] == -1) ? null : map['variant_id'],
      productName: map['product_name'] ?? 'Product',
      quantity: map['qty'] ?? 0,
      price: (map['price'] as num).toDouble(),
      notes: map['notes'],
    );
  }
}
