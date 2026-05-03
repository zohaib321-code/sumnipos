import '../../models/order.dart';

class PrinterService {
  static Future<void> init() async {
    print("Printer Service: Initialized (Stub/Windows)");
  }

  static Future<void> printReceipt(Order order) async {
    print("--- RECEIPT STUB ---");
    print("Order ID: ${order.id}");
    print("Total: \$${order.totalAmount.toStringAsFixed(2)}");
    for (var item in order.items) {
      print("${item.productName} x${item.quantity}");
    }
    print("--- END RECEIPT ---");
  }
}
