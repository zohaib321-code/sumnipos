import 'package:flutter/material.dart';
import '../../../core/db/database_helper.dart';
import '../../../models/settings.dart';
import '../widgets/admin_shell.dart';
import '../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../pos/providers/cart_provider.dart';
import '../../../core/services/printer_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _footerController;
  List<CustomCharge> _customCharges = [];
  List<ReceiptItem> _headerItems = [];
  List<ReceiptItem> _footerItems = [];
  int _tableFontSize = 24;
  int _tableAlignment = 1;
  int _storeNameSize = 36;
  bool _storeNameBold = true;
  int _storeAddressSize = 22;
  bool _storeAddressBold = false;
  int _storePhoneSize = 22;
  bool _storePhoneBold = false;
  String _customerPrinter = 'internal|default|Internal Sunmi Printer';
  String _kitchenPrinter = 'internal|default|Internal Sunmi Printer';
  bool _isLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getSettings();
    setState(() {
      _nameController = TextEditingController(text: settings.storeName)..addListener(_rebuild);
      _addressController = TextEditingController(text: settings.storeAddress)..addListener(_rebuild);
      _phoneController = TextEditingController(text: settings.storePhone)..addListener(_rebuild);
      _footerController = TextEditingController(text: settings.footerMessage)..addListener(_rebuild);
      _customerPrinter = settings.customerPrinter;
      _kitchenPrinter = settings.kitchenPrinter;
      _customCharges = List.from(settings.customCharges);
      _headerItems = List.from(settings.headerItems);
      _footerItems = List.from(settings.footerItems);
      _tableFontSize = settings.tableFontSize;
      _tableAlignment = settings.tableAlignment;
      _storeNameSize = settings.storeNameSize;
      _storeNameBold = settings.storeNameBold;
      _storeAddressSize = settings.storeAddressSize;
      _storeAddressBold = settings.storeAddressBold;
      _storePhoneSize = settings.storePhoneSize;
      _storePhoneBold = settings.storePhoneBold;
      _isLoading = false;
    });
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    
    final settings = SystemSettings(
      storeName: _nameController.text,
      storeAddress: _addressController.text,
      storePhone: _phoneController.text,
      taxPercentage: 0.0, 
      footerMessage: _footerController.text,
      customCharges: _customCharges,
      customerPrinter: _customerPrinter,
      kitchenPrinter: _kitchenPrinter,
      footerItems: _footerItems,
      tableFontSize: _tableFontSize,
      tableAlignment: _tableAlignment,
      storeNameSize: _storeNameSize,
      storeNameBold: _storeNameBold,
      storeAddressSize: _storeAddressSize,
      storeAddressBold: _storeAddressBold,
      storePhoneSize: _storePhoneSize,
      storePhoneBold: _storePhoneBold,
    );
    await DatabaseHelper.instance.updateSettings(settings);
    if (mounted) context.read<CartProvider>().refreshSettings();
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully'), backgroundColor: AppTheme.secondary, behavior: SnackBarBehavior.floating, width: 300),
      );
    }
  }

  void _showPrinterPicker(bool isKitchen) async {
    showDialog(
      context: context,
      builder: (context) => _PrinterDiscoveryDialog(
        onSelected: (device) {
          setState(() {
            if (isKitchen) {
              _kitchenPrinter = device.toString();
            } else {
              _customerPrinter = device.toString();
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return AdminShell(pageTitle: 'Settings', pageSubtitle: '', child: const Center(child: CircularProgressIndicator()));

    return AdminShell(
      pageTitle: 'SYSTEM SETTINGS',
      pageSubtitle: 'Configure your store environment',
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'STORE IDENTITY', icon: Icons.store_outlined),
                    const SizedBox(height: 12),
                    _SettingsGroup(
                      children: [
                        _SimpleSettingRow(
                          label: 'RESTAURANT NAME', 
                          controller: _nameController, 
                          size: _storeNameSize,
                          isBold: _storeNameBold,
                          onSizeChanged: (v) => setState(() => _storeNameSize = v),
                          onBoldToggle: (v) => setState(() => _storeNameBold = v),
                        ),
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        _SimpleSettingRow(
                          label: 'ADDRESS DETAIL', 
                          controller: _addressController, 
                          size: _storeAddressSize,
                          isBold: _storeAddressBold,
                          onSizeChanged: (v) => setState(() => _storeAddressSize = v),
                          onBoldToggle: (v) => setState(() => _storeAddressBold = v),
                        ),
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        _SimpleSettingRow(
                          label: 'CONTACT / PHONE', 
                          controller: _phoneController, 
                          size: _storePhoneSize,
                          isBold: _storePhoneBold,
                          onSizeChanged: (v) => setState(() => _storePhoneSize = v),
                          onBoldToggle: (v) => setState(() => _storePhoneBold = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _SectionTitle(title: 'PRINTERS & ROUTING', icon: Icons.print_outlined),
                    const SizedBox(height: 12),
                    _SettingsGroup(
                      children: [
                        _PrinterRow(
                          label: 'Customer Bill',
                          device: PrinterDevice.fromString(_customerPrinter),
                          onTap: () => _showPrinterPicker(false),
                        ),
                        const Divider(height: 1),
                        _PrinterRow(
                          label: 'Kitchen Slip',
                          device: PrinterDevice.fromString(_kitchenPrinter),
                          onTap: () => _showPrinterPicker(true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(title: 'TAXES & DISCOUNTS', icon: Icons.receipt_long_outlined),
                        TextButton.icon(
                          onPressed: _addCustomCharge,
                          icon: const Icon(Icons.add_circle, size: 16),
                          label: const Text('ADD NEW CHARGE/TAX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SettingsGroup(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_customCharges.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text('NO CHARGES DEFINED.', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(_customCharges.length, (i) {
                            final c = _customCharges[i];
                            return _ChargeCard(
                              charge: c,
                              onToggle: (v) => setState(() {
                                _customCharges[i] = CustomCharge(name: c.name, value: c.value, type: c.type, isActive: v);
                              }),
                              onDelete: () => setState(() => _customCharges.removeAt(i)),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _SectionTitle(title: 'RECEIPT CUSTOMIZATION', icon: Icons.receipt_outlined),
                    const SizedBox(height: 12),
                    _SettingsGroup(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Text('ORDER SUMMARY TABLE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.primary))),
                            const Text('Font Size:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: _tableFontSize,
                              isDense: true,
                              underline: const SizedBox(),
                              items: [20, 24, 28, 32].map((e) => DropdownMenuItem(value: e, child: Text(e.toString(), style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (v) => setState(() => _tableFontSize = v!),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('HEADER ITEMS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.primary)),
                            TextButton.icon(
                              onPressed: () => _addReceiptItem(true),
                              icon: const Icon(Icons.add_circle_outline, size: 16),
                              label: const Text('ADD HEADER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_headerItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Using default store info (Name, Address, Phone). Add items to override.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.textMuted)),
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_headerItems.length, (i) {
                            return _ReceiptItemCard(
                              item: _headerItems[i],
                              onDelete: () => setState(() => _headerItems.removeAt(i)),
                            );
                          }),
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('FOOTER ITEMS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.primary)),
                            TextButton.icon(
                              onPressed: () => _addReceiptItem(false),
                              icon: const Icon(Icons.add_circle_outline, size: 16),
                              label: const Text('ADD FOOTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_footerItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Using default "Thank You" message.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.textMuted)),
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_footerItems.length, (i) {
                            return _ReceiptItemCard(
                              item: _footerItems[i],
                              onDelete: () => setState(() => _footerItems.removeAt(i)),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _SectionTitle(title: 'SECURITY & DATA', icon: Icons.lock_outline),
                    const SizedBox(height: 12),
                    _SettingsGroup(
                      children: [
                        _PinChangeRow(role: 'admin', label: 'Admin Terminal PIN'),
                        _PinChangeRow(role: 'cashier', label: 'Cashier Login PIN'),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          title: const Text('Wipe & Reseed Database', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.error)),
                          subtitle: const Text('Deletes all data and inserts a complete fast-food menu', style: TextStyle(fontSize: 11)),
                          trailing: OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('WARNING'),
                                  content: const Text('This will delete EVERYTHING (all orders, products, deals) and insert new seed data. Are you sure?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
                                      onPressed: () => Navigator.pop(ctx, true), 
                                      child: const Text('WIPE & RESEED')
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                setState(() => _isLoading = true);
                                await DatabaseHelper.instance.wipeAndSeedEverything();
                                await _loadSettings();
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database reseeded successfully!')));
                                }
                              }
                            },
                            child: const Text('EXECUTE'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
          
          Container(
            width: 360,
            decoration: const BoxDecoration(color: AppTheme.surfaceVariant, border: Border(left: BorderSide(color: AppTheme.outline))),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('LIVE RECEIPT PREVIEW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2, color: AppTheme.textMuted)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: _ReceiptPreview(
                        storeName: _nameController.text,
                        address: _addressController.text,
                        phone: _phoneController.text,
                        charges: _customCharges,
                        headerItems: _headerItems,
                        footerItems: _footerItems,
                        tableFontSize: _tableFontSize,
                        tableAlignment: _tableAlignment,
                        storeNameSize: _storeNameSize,
                        storeNameBold: _storeNameBold,
                        storeAddressSize: _storeAddressSize,
                        storeAddressBold: _storeAddressBold,
                        storePhoneSize: _storePhoneSize,
                        storePhoneBold: _storePhoneBold,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.outline))),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => PrinterService.printTestReceipt(
                            storeName: _nameController.text,
                            address: _addressController.text,
                            phone: _phoneController.text,
                            charges: _customCharges,
                            headerItems: _headerItems,
                            footerItems: _footerItems,
                            tableFontSize: _tableFontSize,
                            tableAlignment: _tableAlignment,
                          ),
                          icon: const Icon(Icons.print, size: 20),
                          label: const Text('TEST PRINT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                          icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save, size: 20),
                          label: const Text('SAVE SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addReceiptItem(bool isHeader) {
    final textCtrl = TextEditingController();
    int fontSize = 20;
    int alignment = 1;
    bool isBold = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isHeader ? 'ADD HEADER ITEM' : 'ADD FOOTER ITEM', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: textCtrl, decoration: const InputDecoration(labelText: 'TEXT')),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Size:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: fontSize,
                    items: [16, 18, 20, 22, 24, 28, 32, 36].map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                    onChanged: (v) => setDialogState(() => fontSize = v!),
                  ),
                  const Spacer(),
                  const Text('Bold:'),
                  Checkbox(value: isBold, onChanged: (v) => setDialogState(() => isBold = v!)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Alignment:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Icon(Icons.align_horizontal_left, size: 16),
                      selected: alignment == 0,
                      onSelected: (s) => setDialogState(() => alignment = 0),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ChoiceChip(
                      label: const Icon(Icons.align_horizontal_center, size: 16),
                      selected: alignment == 1,
                      onSelected: (s) => setDialogState(() => alignment = 1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ChoiceChip(
                      label: const Icon(Icons.align_horizontal_right, size: 16),
                      selected: alignment == 2,
                      onSelected: (s) => setDialogState(() => alignment = 2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final newItem = ReceiptItem(text: textCtrl.text, fontSize: fontSize, alignment: alignment, isBold: isBold);
                  if (isHeader) {
                    _headerItems.add(newItem);
                  } else {
                    _footerItems.add(newItem);
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  void _addCustomCharge() {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    ChargeType selectedType = ChargeType.percentage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('NEW CHARGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'NAME')),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('PERCENT %'),
                      selected: selectedType == ChargeType.percentage,
                      onSelected: (s) => setDialogState(() => selectedType = ChargeType.percentage),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('FIXED Rs'),
                      selected: selectedType == ChargeType.flat,
                      onSelected: (s) => setDialogState(() => selectedType = ChargeType.flat),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                ],
              ),
              TextField(controller: valueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'VALUE')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                setState(() => _customCharges.add(CustomCharge(name: nameCtrl.text, value: double.tryParse(valueCtrl.text) ?? 0, type: selectedType)));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrinterDiscoveryDialog extends StatefulWidget {
  final Function(PrinterDevice) onSelected;
  const _PrinterDiscoveryDialog({required this.onSelected});

  @override
  State<_PrinterDiscoveryDialog> createState() => _PrinterDiscoveryDialogState();
}

class _PrinterDiscoveryDialogState extends State<_PrinterDiscoveryDialog> {
  List<PrinterDevice> _devices = [];
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => _isScanning = true);
    final devices = await PrinterService.discoverPrinters();
    setState(() {
      _devices = devices;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('AVAILABLE PRINTERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          if (!_isScanning) IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _scan),
        ],
      ),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _isScanning
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Scanning local network...')]))
            : _devices.isEmpty
                ? const Center(child: Text('No printers found'))
                : ListView.separated(
                    itemCount: _devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final d = _devices[index];
                      return ListTile(
                        leading: Icon(d.type == PrinterType.internal ? Icons.tablet_android : Icons.print),
                        title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(d.address, style: const TextStyle(fontSize: 11)),
                        onTap: () {
                          widget.onSelected(d);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _PrinterRow extends StatelessWidget {
  final String label;
  final PrinterDevice device;
  final VoidCallback onTap;
  const _PrinterRow({required this.label, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
      subtitle: Text(device.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
      trailing: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary.withOpacity(0.1), foregroundColor: AppTheme.primary, elevation: 0, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
        child: const Text('SELECT PRINTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _ReceiptItemCard extends StatelessWidget {
  final ReceiptItem item;
  final VoidCallback onDelete;
  const _ReceiptItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal, fontSize: 11))),
              IconButton(icon: const Icon(Icons.close, size: 14, color: AppTheme.error), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          Text('Size: ${item.fontSize} | Align: ${item.alignment == 0 ? 'Left' : item.alignment == 1 ? 'Center' : 'Right'}', style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _ChargeCard extends StatelessWidget {
  final CustomCharge charge;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  const _ChargeCard({required this.charge, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final val = charge.type == ChargeType.percentage ? '${charge.value}%' : 'Rs. ${charge.value.toStringAsFixed(0)}';
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: charge.isActive ? Colors.white : AppTheme.background, border: Border.all(color: AppTheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(charge.name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10))),
              Switch.adaptive(value: charge.isActive, onChanged: onToggle, activeColor: AppTheme.primary),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              IconButton(icon: const Icon(Icons.close, size: 14, color: AppTheme.error), onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinChangeRow extends StatefulWidget {
  final String role;
  final String label;
  const _PinChangeRow({required this.role, required this.label});

  @override
  State<_PinChangeRow> createState() => _PinChangeRowState();
}

class _PinChangeRowState extends State<_PinChangeRow> {
  final _ctrl = TextEditingController();
  bool _editing = false;
  @override
  void initState() { super.initState(); _loadPin(); }
  Future<void> _loadPin() async {
    final pin = await DatabaseHelper.instance.getUserPin(widget.role);
    setState(() => _ctrl.text = pin);
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
          Expanded(child: TextFormField(controller: _ctrl, enabled: _editing, obscureText: !_editing, maxLength: 4, decoration: const InputDecoration(isDense: true, counterText: ''))),
          const SizedBox(width: 12),
          TextButton(onPressed: () async {
            if (_editing) {
              await DatabaseHelper.instance.updateUserPin(widget.role, _ctrl.text);
              setState(() => _editing = false);
            } else { setState(() => _editing = true); }
          }, child: Text(_editing ? 'SAVE' : 'CHANGE')),
        ],
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  final String storeName;
  final String address;
  final String phone;
  final List<CustomCharge> charges;
  final List<ReceiptItem> headerItems;
  final int tableFontSize;
  final int tableAlignment;
  final int storeNameSize;
  final bool storeNameBold;
  final int storeAddressSize;
  final bool storeAddressBold;
  final int storePhoneSize;
  final bool storePhoneBold;

  const _ReceiptPreview({
    required this.storeName,
    required this.address,
    required this.phone,
    required this.charges,
    required this.headerItems,
    required this.footerItems,
    required this.tableFontSize,
    required this.tableAlignment,
    required this.storeNameSize,
    required this.storeNameBold,
    required this.storeAddressSize,
    required this.storeAddressBold,
    required this.storePhoneSize,
    required this.storePhoneBold,
  });
  
  @override
  Widget build(BuildContext context) {
    const subtotal = 1400.0;
    double totalCharges = 0;
    List<Widget> chargeWidgets = [];
    
    for (var c in charges.where((e) => e.isActive)) {
      final isPercent = c.type == ChargeType.percentage;
      final val = isPercent ? (subtotal * c.value / 100) : c.value;
      final label = isPercent ? '${c.name.toUpperCase()} (${c.value}%)' : c.name.toUpperCase();
      totalCharges += val;
      chargeWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: tableFontSize * 0.4)),
              Text(val.toStringAsFixed(0), style: TextStyle(fontSize: tableFontSize * 0.4)),
            ],
          ),
        ),
      );
    }

    const divider = Text(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: TextStyle(color: AppTheme.outline, letterSpacing: -1, fontWeight: FontWeight.bold),
    );

    TextAlign getTextAlign(int align) {
      if (align == 0) return TextAlign.left;
      if (align == 2) return TextAlign.right;
      return TextAlign.center;
    }

    return Container(
      width: 280,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerItems.isEmpty) ...[
            Text(storeName.isEmpty ? 'STORE NAME' : storeName.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontWeight: storeNameBold ? FontWeight.w900 : FontWeight.normal, fontSize: storeNameSize * 0.4, height: 1.2)),
            if (address.isNotEmpty) Text(address, textAlign: TextAlign.center, style: TextStyle(fontSize: storeAddressSize * 0.45, fontWeight: storeAddressBold ? FontWeight.bold : FontWeight.normal, color: AppTheme.textMuted)),
            if (phone.isNotEmpty) Text('TEL: $phone', textAlign: TextAlign.center, style: TextStyle(fontSize: storePhoneSize * 0.45, fontWeight: storePhoneBold ? FontWeight.bold : FontWeight.normal, color: AppTheme.textMuted)),
          ] else
            ...headerItems.map((item) => Text(
              item.text,
              textAlign: getTextAlign(item.alignment),
              style: TextStyle(
                fontSize: item.fontSize * 0.4,
                fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
              ),
            )),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: divider,
          ),
          Row(
            mainAxisAlignment: tableAlignment == 0 ? MainAxisAlignment.start : tableAlignment == 2 ? MainAxisAlignment.end : MainAxisAlignment.center,
            children: [
               Container(
                 width: 200,
                 child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('QTY  ITEM', style: TextStyle(fontSize: tableFontSize * 0.4, fontWeight: FontWeight.bold)),
                      Text('PRICE', style: TextStyle(fontSize: tableFontSize * 0.4, fontWeight: FontWeight.bold)),
                    ],
                 ),
               ),
            ],
          ),
          const SizedBox(height: 8),
          _ReceiptItemRow(qty: 2, name: 'MINERAL WATER', price: 100, fontSize: tableFontSize * 0.4, alignment: tableAlignment),
          _ReceiptItemRow(qty: 1, name: 'BEEF BURGER', price: 450, fontSize: tableFontSize * 0.4, alignment: tableAlignment),
          _ReceiptItemRow(qty: 1, name: 'SMASH COMBO (DEAL)', price: 850, fontSize: tableFontSize * 0.4, alignment: tableAlignment),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: divider,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SUBTOTAL', style: TextStyle(fontSize: tableFontSize * 0.4)),
              Text(subtotal.toStringAsFixed(0), style: TextStyle(fontSize: tableFontSize * 0.4)),
            ],
          ),
          ...chargeWidgets,
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              Text('Rs. ${(subtotal + totalCharges).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: divider,
          ),
          if (footerItems.isEmpty)
            const Text('THANK YOU!', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2))
          else
            ...footerItems.map((item) => Text(
              item.text,
              textAlign: getTextAlign(item.alignment),
              style: TextStyle(
                fontSize: item.fontSize * 0.4,
                fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
              ),
            )),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: divider,
          ),
          const Text('Developed by Arcade Developers', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const Text('and Marketing: 03135734950', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _ReceiptItemRow extends StatelessWidget {
  final int qty;
  final String name;
  final double price;
  final double fontSize;
  final int alignment;

  const _ReceiptItemRow({
    required this.qty,
    required this.name,
    required this.price,
    required this.fontSize,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: alignment == 0 ? MainAxisAlignment.start : alignment == 2 ? MainAxisAlignment.end : MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('$qty x $name', style: TextStyle(fontSize: fontSize))),
                Text(price.toStringAsFixed(0), style: TextStyle(fontSize: fontSize)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 18, color: AppTheme.textMuted), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: AppTheme.textMuted))]);
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  const _SettingsGroup({required this.children, this.padding});
  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.outline)), child: Column(children: children));
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _EditRow({required this.label, required this.controller, required this.hint, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
          Expanded(child: TextFormField(controller: controller, maxLines: maxLines, decoration: InputDecoration(hintText: hint, isDense: true))),
        ],
      ),
    );
  }
}

class _SimpleSettingRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int size;
  final bool isBold;
  final ValueChanged<int> onSizeChanged;
  final ValueChanged<bool> onBoldToggle;

  const _SimpleSettingRow({
    required this.label,
    required this.controller,
    required this.size,
    required this.isBold,
    required this.onSizeChanged,
    required this.onBoldToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    hintText: 'Enter detail...',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Size Control
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepButton(icon: Icons.remove, onTap: () => onSizeChanged(size - 2)),
                    SizedBox(width: 32, child: Text(size.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    _StepButton(icon: Icons.add, onTap: () => onSizeChanged(size + 2)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Bold Toggle
              InkWell(
                onTap: () => onBoldToggle(!isBold),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isBold ? AppTheme.primary : AppTheme.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('B', style: TextStyle(color: isBold ? Colors.white : AppTheme.onSurface, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 14, color: AppTheme.primary),
      ),
    );
  }
}
