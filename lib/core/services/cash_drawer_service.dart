import '../../models/drawer_log.dart';
import '../db/database_helper.dart';
import 'printer_service.dart';

class CashDrawerService {
  static Future<bool> open({
    required String reason,
    int? orderId,
  }) async {
    final ok = await PrinterService.openCashDrawer();
    await DatabaseHelper.instance.insertDrawerLog(
      DrawerLog(
        timestamp: DateTime.now(),
        reason: reason,
        orderId: orderId,
      ),
    );
    return ok;
  }
}
