class DrawerLog {
  final int? id;
  final DateTime timestamp;
  final String reason;
  final int? orderId;

  static const String reasonManual = 'manual';
  static const String reasonSalePaid = 'sale_paid';
  static const String reasonTest = 'test';

  DrawerLog({
    this.id,
    required this.timestamp,
    required this.reason,
    this.orderId,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
        'order_id': orderId,
      };

  factory DrawerLog.fromMap(Map<String, dynamic> map) => DrawerLog(
        id: map['id'] as int?,
        timestamp: DateTime.parse(map['timestamp'] as String),
        reason: map['reason'] as String,
        orderId: map['order_id'] as int?,
      );
}
