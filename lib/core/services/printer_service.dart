import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../models/settings.dart';
import '../db/database_helper.dart';

enum PrinterType { internal, network, usb }

class PrinterDevice {
  final String name;
  final String address;
  final PrinterType type;

  PrinterDevice({required this.name, required this.address, required this.type});

  @override
  String toString() => '${type.name}|$address|$name';

  factory PrinterDevice.fromString(String str) {
    final parts = str.split('|');
    if (parts.length < 3) return PrinterDevice(name: 'Internal', address: 'default', type: PrinterType.internal);
    return PrinterDevice(
      type: PrinterType.values.firstWhere((e) => e.name == parts[0], orElse: () => PrinterType.internal),
      address: parts[1],
      name: parts[2],
    );
  }
}

class PrinterService {
  static const MethodChannel _channel = MethodChannel('sunmi_printer');

  static Future<void> init() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('BIND_PRINTER_SERVICE');
      } catch (e) {
        debugPrint("Sunmi Bind Error: $e");
      }
    }
  }

  /// Discovers available printers on the network and local system
  static Future<List<PrinterDevice>> discoverPrinters() async {
    List<PrinterDevice> devices = [];

    // 1. Add Internal Sunmi Printer
    devices.add(PrinterDevice(name: "Internal Sunmi Printer", address: "internal", type: PrinterType.internal));

    // 2. Network Discovery (Scan port 9100 on common subnets)
    if (!kIsWeb) {
      // Get local IP to determine subnet
      String subnet = "192.168.1";
      try {
        for (var interface in await NetworkInterface.list()) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              final parts = addr.address.split('.');
              if (parts.length == 4) {
                subnet = "${parts[0]}.${parts[1]}.${parts[2]}";
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Subnet detection error: $e");
      }

      // Scan in parallel for speed
      final List<Future<void>> scans = [];
      for (int i = 1; i < 255; i++) {
        final String ip = "$subnet.$i";
        scans.add(
          Socket.connect(ip, 9100, timeout: const Duration(milliseconds: 700))
              .then((socket) {
            devices.add(PrinterDevice(name: "Network Printer ($ip)", address: ip, type: PrinterType.network));
            socket.destroy();
          }).catchError((_) {
            // Ignore connection errors
          }),
        );
      }
      await Future.wait(scans);
    }

    return devices;
  }

  static Future<void> printKitchenReceipt(Order order) async {
    final settings = await DatabaseHelper.instance.getSettings();
    final device = PrinterDevice.fromString(settings.kitchenPrinter);
    
    if (device.type == PrinterType.internal) {
      await _printSunmi(order, isKitchen: true);
    } else if (device.type == PrinterType.network) {
      await _printNetwork(order, device.address, isKitchen: true);
    }
  }

  static Future<void> printCustomerReceipt(Order order) async {
    final settings = await DatabaseHelper.instance.getSettings();
    final device = PrinterDevice.fromString(settings.customerPrinter);

    if (device.type == PrinterType.internal) {
      await _printSunmi(order, isKitchen: false);
    } else if (device.type == PrinterType.network) {
      await _printNetwork(order, device.address, isKitchen: false);
    }
  }

  static Future<void> printTestReceipt({
    required String storeName,
    required String address,
    required String phone,
    required List<CustomCharge> charges,
    required List<ReceiptItem> headerItems,
    required List<ReceiptItem> footerItems,
    required int tableFontSize,
    required int tableAlignment,
  }) async {
    final settings = await DatabaseHelper.instance.getSettings();
    final device = PrinterDevice.fromString(settings.customerPrinter);

    if (device.type == PrinterType.internal) {
      try {
        await _channel.invokeMethod('INIT_PRINTER');
        
        // Header
        if (headerItems.isNotEmpty) {
          for (var item in headerItems) {
            await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': item.alignment});
            await _channel.invokeMethod('PRINT_TEXT', {'text': '${item.text}\n', 'size': item.fontSize, 'bold': item.isBold});
          }
        } else {
          await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 1});
          await _channel.invokeMethod('PRINT_TEXT', {'text': '${storeName.toUpperCase()}\n', 'size': 36, 'bold': true});
        }
        
        await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 1});
        await _channel.invokeMethod('PRINT_TEXT', {'text': '--- TEST PRINT ---\n', 'size': 20});
        
        // Table
        final tableWidth = _getCharsPerLine(tableFontSize);
        await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 0});
        await _channel.invokeMethod('PRINT_TEXT', {
          'text': _formatLine('QTY ITEM', 'PRICE', width: tableWidth) + '\n', 
          'size': tableFontSize, 
          'bold': true
        });
        await _channel.invokeMethod('PRINT_TEXT', {'text': '--------------------------------\n', 'size': 20});
        await _channel.invokeMethod('PRINT_TEXT', {'text': _formatLine('1 x TEST ITEM', '100', width: tableWidth) + '\n', 'size': tableFontSize});
        
        // Footer
        await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 1});
        await _channel.invokeMethod('PRINT_TEXT', {'text': '--------------------------------\n', 'size': 20});
        
        if (footerItems.isNotEmpty) {
          for (var item in footerItems) {
            await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': item.alignment});
            await _channel.invokeMethod('PRINT_TEXT', {'text': '${item.text}\n', 'size': item.fontSize, 'bold': item.isBold});
          }
        } else {
          await _channel.invokeMethod('PRINT_TEXT', {'text': 'THANK YOU!\n', 'size': 28, 'bold': true});
        }

        await _channel.invokeMethod('LINE_WRAP', {'lines': 4});
        await _channel.invokeMethod('CUT_PAPER');
      } catch (e) {
         debugPrint("Sunmi Print Error: $e");
      }
    } else if (device.type == PrinterType.network) {
      try {
        final socket = await Socket.connect(device.address, 9100, timeout: const Duration(seconds: 2));
        socket.add([0x1B, 0x40]);
        socket.add(utf8.encode("\n\nTEST PRINT\nStore: $storeName\n\n\n\n"));
        socket.add([0x1D, 0x56, 0x41, 0x00]);
        await socket.flush();
        socket.destroy();
      } catch (e) {
        debugPrint("Network Print Error: $e");
      }
    }
  }

  static Future<void> _printNetwork(Order order, String ip, {required bool isKitchen}) async {
    try {
      final settings = await DatabaseHelper.instance.getSettings();
      final formatter = DateFormat('yyyy-MM-dd HH:mm');
      const String divider = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
      final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 2));
      
      socket.add([0x1B, 0x40]); 
      socket.add([0x1B, 0x61, 0x01]);

      if (!isKitchen) {
        if (settings.storeName.isNotEmpty) {
          socket.add(settings.storeNameBold ? [0x1B, 0x21, 0x38] : [0x1B, 0x21, 0x30]);
          socket.add(utf8.encode("${settings.storeName.toUpperCase()}\n"));
        }
        if (settings.storeAddress.isNotEmpty) {
          socket.add(settings.storeAddressBold ? [0x1B, 0x21, 0x08] : [0x1B, 0x21, 0x00]);
          socket.add(utf8.encode("${settings.storeAddress}\n"));
        }
        if (settings.storePhone.isNotEmpty) {
          socket.add(settings.storePhoneBold ? [0x1B, 0x21, 0x08] : [0x1B, 0x21, 0x00]);
          socket.add(utf8.encode("TEL: ${settings.storePhone}\n"));
        }
        socket.add(utf8.encode(divider));
      }

      socket.add([0x1B, 0x21, 0x08]);
      socket.add(utf8.encode(isKitchen ? "KITCHEN ORDER\n" : "CUSTOMER RECEIPT\n"));
      socket.add([0x1B, 0x21, 0x00]);
      socket.add(utf8.encode("Order: #${order.id}\n"));
      socket.add(utf8.encode("Date: ${formatter.format(order.dateTime)}\n"));
      
      socket.add([0x1B, 0x61, 0x00]);
      socket.add(utf8.encode(divider));

      final width = _getCharsPerLine(24);
      if (!isKitchen) {
        socket.add(utf8.encode(_formatLine('QTY  ITEM', 'PRICE', width: width) + '\n'));
      } else {
        socket.add(utf8.encode("QTY  ITEM\n"));
      }

      for (var item in order.items) {
         if (isKitchen) {
           socket.add([0x1B, 0x21, 0x08]);
           socket.add(utf8.encode("${item.quantity} x ${item.productName}\n"));
           socket.add([0x1B, 0x21, 0x00]);
           if (item.notes != null && item.notes!.isNotEmpty) {
              socket.add(utf8.encode("   * Note: ${item.notes}\n"));
           }
         } else {
            String name = item.productName;
            String price = item.price.toStringAsFixed(0);
            String qtyLine = '${item.quantity} x ';
            int maxName = width - qtyLine.length - price.length - 2;
            
            if (name.length > maxName) {
              socket.add(utf8.encode(qtyLine + name.substring(0, maxName) + '\n'));
              socket.add(utf8.encode(_formatLine('  ' + name.substring(maxName), price, width: width) + '\n'));
            } else {
              socket.add(utf8.encode(_formatLine(qtyLine + name, price, width: width) + '\n'));
            }
         }
      }

      if (!isKitchen) {
        socket.add([0x1B, 0x61, 0x01]);
        socket.add(utf8.encode(divider));
        socket.add([0x1B, 0x61, 0x00]);
        socket.add(utf8.encode(_formatLine('SUBTOTAL', order.subtotal.toStringAsFixed(0), width: width) + '\n'));
        for (var charge in order.charges) {
           String label = charge.percentage > 0 
               ? '${charge.name.toUpperCase()} (${charge.percentage.toStringAsFixed(0)}%)'
               : charge.name.toUpperCase();
           socket.add(utf8.encode(_formatLine(label, charge.amount.toStringAsFixed(0), width: width) + '\n'));
        }
        socket.add(utf8.encode(divider));
        socket.add([0x1B, 0x21, 0x10]);
        socket.add(utf8.encode(_formatLine('TOTAL', 'Rs. ${order.totalAmount.toStringAsFixed(0)}', width: _getCharsPerLine(32)) + '\n'));
        socket.add([0x1B, 0x21, 0x00]);
        socket.add([0x1B, 0x61, 0x01]);
        socket.add(utf8.encode(divider));
        if (settings.footerMessage.isNotEmpty) {
          socket.add(utf8.encode("${settings.footerMessage}\n"));
        }
        socket.add(utf8.encode("THANK YOU!\n"));
        socket.add(utf8.encode("Developed by Arcade Developers\n"));
        socket.add(utf8.encode("and Marketing: 03135734950\n"));
      }

      socket.add(utf8.encode("\n\n\n\n"));
      socket.add([0x1D, 0x56, 0x41, 0x00]);
      await socket.flush();
      socket.destroy();
    } catch (e) {
      debugPrint("Network Print Error: $e");
    }
  }

  static int _getCharsPerLine(int fontSize) {
    if (fontSize >= 36) return 16;
    if (fontSize >= 32) return 20;
    if (fontSize >= 28) return 24;
    if (fontSize >= 24) return 32;
    return 32;
  }

  static String _formatLine(String left, dynamic right, {int width = 32}) {
    String rightStr = right.toString();
    int spaces = width - left.length - rightStr.length;
    if (spaces < 1) return left + " " + rightStr;
    return left + (' ' * spaces) + rightStr;
  }

  static Future<void> _printSunmi(Order order, {required bool isKitchen}) async {
    try {
      final settings = await DatabaseHelper.instance.getSettings();
      final formatter = DateFormat('yyyy-MM-dd HH:mm');
      const String divider = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

      await _channel.invokeMethod('INIT_PRINTER');
      
      if (!isKitchen) {
        if (settings.headerItems.isNotEmpty) {
          for (var item in settings.headerItems) {
            await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': item.alignment});
            await _channel.invokeMethod('PRINT_TEXT', {
              'text': '${item.text}\n', 
              'size': item.fontSize,
              'bold': item.isBold
            });
          }
        } else {
          await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 1});
          if (settings.storeName.isNotEmpty) {
            await _channel.invokeMethod('PRINT_TEXT', {
              'text': '${settings.storeName.toUpperCase()}\n', 
              'size': settings.storeNameSize, 
              'bold': settings.storeNameBold
            });
          }
          if (settings.storeAddress.isNotEmpty) {
            await _channel.invokeMethod('PRINT_TEXT', {
              'text': '${settings.storeAddress}\n', 
              'size': settings.storeAddressSize,
              'bold': settings.storeAddressBold
            });
          }
          if (settings.storePhone.isNotEmpty) {
            await _channel.invokeMethod('PRINT_TEXT', {
              'text': 'TEL: ${settings.storePhone}\n', 
              'size': settings.storePhoneSize,
              'bold': settings.storePhoneBold
            });
          }
        }
        await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 1});
        await _channel.invokeMethod('PRINT_TEXT', {'text': '$divider\n', 'size': 20});
      }

      await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 1});
      await _channel.invokeMethod('PRINT_TEXT', {
        'text': isKitchen ? 'KITCHEN ORDER\n' : 'CUSTOMER RECEIPT\n', 
        'size': 32,
        'bold': true
      });
      await _channel.invokeMethod('PRINT_TEXT', {'text': 'Order: #${order.id}\n', 'size': 24});
      await _channel.invokeMethod('PRINT_TEXT', {'text': 'Date: ${formatter.format(order.dateTime)}\n', 'size': 24});
      
      await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 0});
      await _channel.invokeMethod('PRINT_TEXT', {'text': '$divider\n', 'size': 20});

      final int tableWidth = _getCharsPerLine(settings.tableFontSize);
      if (!isKitchen) {
        await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': settings.tableAlignment});
        await _channel.invokeMethod('PRINT_TEXT', {
          'text': _formatLine('QTY  ITEM', 'PRICE', width: tableWidth) + '\n', 
          'size': settings.tableFontSize,
          'bold': true
        });
      } else {
        await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 0});
        await _channel.invokeMethod('PRINT_TEXT', {'text': 'QTY  ITEM\n', 'size': 28, 'bold': true});
      }
      
      for (var item in order.items) {
        if (isKitchen) {
          await _channel.invokeMethod('PRINT_TEXT', {'text': '${item.quantity} x ${item.productName}\n', 'size': 32, 'bold': true});
          if (item.notes != null && item.notes!.isNotEmpty) {
             await _channel.invokeMethod('PRINT_TEXT', {'text': '   * Note: ${item.notes}\n', 'size': 24});
          }
        } else {
           String qtyPrefix = '${item.quantity} x ';
           String name = item.productName;
           String price = item.price.toStringAsFixed(0);
           
           int reservedForPrice = price.length + 2; 
           int firstLineMax = tableWidth - qtyPrefix.length - reservedForPrice;
           
           if (name.length <= firstLineMax) {
             await _channel.invokeMethod('PRINT_TEXT', {
               'text': _formatLine(qtyPrefix + name, price, width: tableWidth) + '\n', 
               'size': settings.tableFontSize
             });
           } else {
             String firstLineName = name.substring(0, firstLineMax);
             String remainingName = name.substring(firstLineMax);
             
             await _channel.invokeMethod('PRINT_TEXT', {
               'text': qtyPrefix + firstLineName + '\n', 
               'size': settings.tableFontSize
             });
             
             await _channel.invokeMethod('PRINT_TEXT', {
               'text': _formatLine('  ' + remainingName, price, width: tableWidth) + '\n', 
               'size': settings.tableFontSize
             });
           }
        }
      }

      if (!isKitchen) {
        await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 1});
        await _channel.invokeMethod('PRINT_TEXT', {'text': '$divider\n', 'size': 20});
        
        await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 0});
        await _channel.invokeMethod('PRINT_TEXT', {
          'text': _formatLine('SUBTOTAL', order.subtotal.toStringAsFixed(0), width: tableWidth) + '\n', 
          'size': settings.tableFontSize
        });
        
        for (var charge in order.charges) {
           String label = charge.percentage > 0 
               ? '${charge.name.toUpperCase()} (${charge.percentage.toStringAsFixed(0)}%)'
               : charge.name.toUpperCase();
           await _channel.invokeMethod('PRINT_TEXT', {
             'text': _formatLine(label, charge.amount.toStringAsFixed(0), width: tableWidth) + '\n', 
             'size': settings.tableFontSize
           });
        }
        
        await _channel.invokeMethod('PRINT_TEXT', {'text': '$divider\n', 'size': 20});
        
        int totalWidth = _getCharsPerLine(36);
        await _channel.invokeMethod('PRINT_TEXT', {
          'text': _formatLine('TOTAL', 'Rs. ${order.totalAmount.toStringAsFixed(0)}', width: totalWidth) + '\n', 
          'size': 36,
          'bold': true
        });
        
        await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 1});
        await _channel.invokeMethod('PRINT_TEXT', {'text': '$divider\n', 'size': 20});
        
        if (settings.footerItems.isNotEmpty) {
          for (var item in settings.footerItems) {
            await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': item.alignment});
            await _channel.invokeMethod('PRINT_TEXT', {
              'text': '${item.text}\n', 
              'size': item.fontSize,
              'bold': item.isBold
            });
          }
        } else {
          // Default Footer
          if (settings.footerMessage.isNotEmpty) {
            await _channel.invokeMethod('PRINT_TEXT', {'text': '${settings.footerMessage}\n', 'size': 22});
          }
          await _channel.invokeMethod('PRINT_TEXT', {'text': 'THANK YOU!\n', 'size': 28, 'bold': true});
        }

        // --- FINAL ARCADE BRANDING ---
        await _channel.invokeMethod('SET_ALIGNMENT', {'alignment': 1});
        await _channel.invokeMethod('PRINT_TEXT', {'text': '$divider\n', 'size': 20});
        await _channel.invokeMethod('PRINT_TEXT', {'text': 'Developed by Arcade Developers\n', 'size': 18});
        await _channel.invokeMethod('PRINT_TEXT', {'text': 'and Marketing: 03135734950\n', 'size': 18});
      }

      await _channel.invokeMethod('LINE_WRAP', {'lines': 4});
      await _channel.invokeMethod('CUT_PAPER');
    } catch (e) {
       debugPrint("Sunmi Print Error: $e");
    }
  }

}
