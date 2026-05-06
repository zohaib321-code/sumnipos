import 'dart:convert';

enum ChargeType { percentage, flat }

class CustomCharge {
  final String name;
  final double value;
  final ChargeType type;
  final bool isActive;

  CustomCharge({
    required this.name,
    required this.value,
    this.type = ChargeType.percentage,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
      'type': type.name,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory CustomCharge.fromMap(Map<String, dynamic> map) {
    return CustomCharge(
      name: map['name'] ?? '',
      value: (map['value'] ?? map['percentage'] ?? 0.0).toDouble(),
      type: map['type'] == 'flat' ? ChargeType.flat : ChargeType.percentage,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }
}

class ReceiptItem {
  final String text;
  final int fontSize;
  final int alignment; // 0: Left, 1: Center, 2: Right
  final bool isBold;

  ReceiptItem({
    required this.text,
    this.fontSize = 20,
    this.alignment = 1,
    this.isBold = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'fontSize': fontSize,
      'alignment': alignment,
      'isBold': isBold,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      text: map['text'] ?? '',
      fontSize: map['fontSize'] ?? 20,
      alignment: map['alignment'] ?? 1,
      isBold: map['isBold'] ?? false,
    );
  }
}

class SystemSettings {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final double taxPercentage;
  final String footerMessage;
  final List<CustomCharge> customCharges;

  // Printer Settings
  final String
  customerPrinter; // e.g., "internal", "network:192.168.1.100", "usb:DeviceName"
  final String kitchenPrinter;

  // Customizable Receipt Settings
  final List<ReceiptItem> headerItems;
  final List<ReceiptItem> footerItems;
  final int tableFontSize;
  final int tableAlignment; // 0: Left, 1: Center, 2: Right

  // Header settings
  final int storeNameSize;
  final bool storeNameBold;
  final int storeAddressSize;
  final bool storeAddressBold;
  final int storePhoneSize;
  final bool storePhoneBold;

  SystemSettings({
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.taxPercentage,
    required this.footerMessage,
    this.customCharges = const [],
    this.customerPrinter = 'internal',
    this.kitchenPrinter = 'internal',
    this.headerItems = const [],
    this.footerItems = const [],
    this.tableFontSize = 20,
    this.tableAlignment = 1,
    this.storeNameSize = 36,
    this.storeNameBold = true,
    this.storeAddressSize = 22,
    this.storeAddressBold = false,
    this.storePhoneSize = 22,
    this.storePhoneBold = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'store_name': storeName,
      'store_address': storeAddress,
      'store_phone': storePhone,
      'tax_percentage': taxPercentage,
      'footer_message': footerMessage,
      'custom_charges': jsonEncode(
        customCharges.map((e) => e.toMap()).toList(),
      ),
      'customer_printer': customerPrinter,
      'kitchen_printer': kitchenPrinter,
      'header_items': jsonEncode(headerItems.map((e) => e.toMap()).toList()),
      'footer_items': jsonEncode(footerItems.map((e) => e.toMap()).toList()),
      'table_font_size': tableFontSize,
      'table_alignment': tableAlignment,
      'store_name_size': storeNameSize,
      'store_name_bold': storeNameBold ? 1 : 0,
      'store_address_size': storeAddressSize,
      'store_address_bold': storeAddressBold ? 1 : 0,
      'store_phone_size': storePhoneSize,
      'store_phone_bold': storePhoneBold ? 1 : 0,
    };
  }

  factory SystemSettings.fromMap(Map<String, dynamic> map) {
    List<CustomCharge> charges = [];
    if (map['custom_charges'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(map['custom_charges']);
        charges = decoded.map((e) => CustomCharge.fromMap(e)).toList();
      } catch (e) {
        print("Error decoding custom charges: $e");
      }
    }

    List<ReceiptItem> headers = [];
    if (map['header_items'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(map['header_items']);
        headers = decoded.map((e) => ReceiptItem.fromMap(e)).toList();
      } catch (e) {}
    }

    List<ReceiptItem> footers = [];
    if (map['footer_items'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(map['footer_items']);
        footers = decoded.map((e) => ReceiptItem.fromMap(e)).toList();
        if (footers.length == 1 &&
            footers.first.text.trim().toUpperCase() == 'THANK YOU!') {
          footers = [];
        }
      } catch (e) {}
    }

    return SystemSettings(
      storeName: map['store_name'] ?? 'SUNMI POS PKR',
      storeAddress: map['store_address'] ?? 'Karachi, Pakistan',
      storePhone: map['store_phone'] ?? '',
      taxPercentage: map['tax_percentage']?.toDouble() ?? 0.0,
      footerMessage: map['footer_message'] ?? '',
      customCharges: charges,
      customerPrinter: map['customer_printer'] ?? 'internal',
      kitchenPrinter: map['kitchen_printer'] ?? 'internal',
      headerItems: headers,
      footerItems: footers,
      tableFontSize: map['table_font_size'] ?? 20,
      tableAlignment: map['table_alignment'] ?? 1,
      storeNameSize: map['store_name_size'] ?? 36,
      storeNameBold: (map['store_name_bold'] ?? 1) == 1,
      storeAddressSize: map['store_address_size'] ?? 22,
      storeAddressBold: (map['store_address_bold'] ?? 0) == 1,
      storePhoneSize: map['store_phone_size'] ?? 22,
      storePhoneBold: (map['store_phone_bold'] ?? 0) == 1,
    );
  }

  factory SystemSettings.defaultSettings() {
    return SystemSettings(
      storeName: 'SUNMI POS PKR',
      storeAddress: 'Karachi, Pakistan',
      storePhone: '',
      taxPercentage: 0.0,
      footerMessage: '',
      customCharges: [],
      customerPrinter: 'internal',
      kitchenPrinter: 'internal',
      headerItems: [],
      footerItems: [],
      tableFontSize: 24,
      tableAlignment: 1,
      storeNameSize: 36,
      storeNameBold: true,
      storeAddressSize: 22,
      storeAddressBold: false,
      storePhoneSize: 22,
      storePhoneBold: false,
    );
  }

  SystemSettings copyWith({
    String? storeName,
    String? storeAddress,
    String? storePhone,
    double? taxPercentage,
    String? footerMessage,
    List<CustomCharge>? customCharges,
    String? customerPrinter,
    String? kitchenPrinter,
    List<ReceiptItem>? headerItems,
    List<ReceiptItem>? footerItems,
    int? tableFontSize,
    int? tableAlignment,
    int? storeNameSize,
    bool? storeNameBold,
    int? storeAddressSize,
    bool? storeAddressBold,
    int? storePhoneSize,
    bool? storePhoneBold,
  }) {
    return SystemSettings(
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      footerMessage: footerMessage ?? this.footerMessage,
      customCharges: customCharges ?? this.customCharges,
      customerPrinter: customerPrinter ?? this.customerPrinter,
      kitchenPrinter: kitchenPrinter ?? this.kitchenPrinter,
      headerItems: headerItems ?? this.headerItems,
      footerItems: footerItems ?? this.footerItems,
      tableFontSize: tableFontSize ?? this.tableFontSize,
      tableAlignment: tableAlignment ?? this.tableAlignment,
      storeNameSize: storeNameSize ?? this.storeNameSize,
      storeNameBold: storeNameBold ?? this.storeNameBold,
      storeAddressSize: storeAddressSize ?? this.storeAddressSize,
      storeAddressBold: storeAddressBold ?? this.storeAddressBold,
      storePhoneSize: storePhoneSize ?? this.storePhoneSize,
      storePhoneBold: storePhoneBold ?? this.storePhoneBold,
    );
  }
}
