import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/deal.dart';
import '../../../models/product.dart';
import '../../../models/product_variant.dart';
import '../../deals/providers/deal_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../products/providers/category_provider.dart';
import '../widgets/admin_shell.dart';
import '../../../core/theme/app_theme.dart';

class DealFormScreen extends StatefulWidget {
  final Deal? editingDeal;
  const DealFormScreen({super.key, this.editingDeal});

  @override
  State<DealFormScreen> createState() => _DealFormScreenState();
}

class _DealFormScreenState extends State<DealFormScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  List<DealItem> _selectedItems = [];
  bool _isActive = true;
  String? _imagePath;
  int? _filterCatId;

  @override
  void initState() {
    super.initState();
    if (widget.editingDeal != null) {
      _nameController.text = widget.editingDeal!.name;
      _priceController.text = widget.editingDeal!.price.toStringAsFixed(0);
      _selectedItems = List.from(widget.editingDeal!.items);
      _isActive = widget.editingDeal!.isActive;
      _imagePath = widget.editingDeal!.imagePath;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imagePath = pickedFile.path);
    }
  }

  void _addItemToDeal(Product p, ProductVariant? v) {
    setState(() {
      _selectedItems.add(DealItem(
        dealId: widget.editingDeal?.id ?? 0,
        productId: p.id!,
        variantId: v?.id,
        qty: 1,
        product: p,
        variant: v,
      ));
    });
  }

  void _adjustQty(int index, int delta) {
    setState(() {
      final item = _selectedItems[index];
      final newQty = item.qty + delta;
      if (newQty <= 0) {
        _selectedItems.removeAt(index);
      } else {
        _selectedItems[index] = DealItem(
          dealId: item.dealId,
          productId: item.productId,
          variantId: item.variantId,
          qty: newQty,
          product: item.product,
          variant: item.variant,
        );
      }
    });
  }

  double get _regularPrice => _selectedItems.fold(0.0, (sum, i) => sum + (i.variant?.price ?? i.product?.price ?? 0) * i.qty);

  void _saveDeal() {
    if (_nameController.text.isEmpty || _selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name and select items')));
      return;
    }

    final provider = context.read<DealProvider>();
    final deal = Deal(
      id: widget.editingDeal?.id,
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      isActive: _isActive,
      imagePath: _imagePath,
    );
    provider.saveDeal(deal, _selectedItems);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: widget.editingDeal == null ? 'CREATE NEW DEAL' : 'EDIT DEAL',
      pageSubtitle: 'Configure bundle contents and pricing',
      child: Consumer2<ProductProvider, CategoryProvider>(
        builder: (context, prodProvider, catProvider, _) {
          final products = prodProvider.products.where((p) => _filterCatId == null || p.categoryId == _filterCatId).toList();

          return Row(
            children: [
              // 1. Vertical Category List (Left)
              Container(
                width: 160,
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(right: BorderSide(color: AppTheme.outline)),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _VerticalCatTile(
                      label: 'ALL ITEMS',
                      selected: _filterCatId == null,
                      onTap: () => setState(() => _filterCatId = null),
                      icon: Icons.grid_view_rounded,
                    ),
                    const Divider(height: 1),
                    ...catProvider.categories.map((c) => _VerticalCatTile(
                      label: c.name.toUpperCase(),
                      selected: _filterCatId == c.id,
                      onTap: () => setState(() => _filterCatId = c.id),
                      icon: Icons.fastfood_outlined,
                    )),
                  ],
                ),
              ),
              
              // 2. Product Grid (Middle)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.80,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final p = products[index];
                          return _ProductTile(product: p, onTap: () => _handleProductSelect(p));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Configuration Panel
              Container(
                width: 400,
                decoration: const BoxDecoration(color: AppTheme.surface, border: Border(left: BorderSide(color: AppTheme.outline))),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ImagePickerSection(imagePath: _imagePath, onPick: _pickImage),
                            const SizedBox(height: 24),
                            _ConfigLabel(label: 'DEAL NAME'),
                            TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'e.g. Family Feast')),
                            const SizedBox(height: 24),
                            _ConfigLabel(label: 'BUNDLE ITEMS'),
                            const SizedBox(height: 12),
                            if (_selectedItems.isEmpty)
                              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Click products on the left to add', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted))))
                            else
                              ...List.generate(_selectedItems.length, (i) => _BundleItemTile(item: _selectedItems[i], onAdjust: (d) => _adjustQty(i, d))),
                            const Divider(height: 48),
                            _PriceSection(regularPrice: _regularPrice, priceController: _priceController),
                            const SizedBox(height: 24),
                            SwitchListTile(
                              title: const Text('ACTIVE ON MENU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _saveDeal,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: Text(widget.editingDeal == null ? 'CREATE DEAL' : 'UPDATE DEAL', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleProductSelect(Product product) {
    if (product.variants.isEmpty) {
      _addItemToDeal(product, null);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text('CHOOSE FOR ${product.name.toUpperCase()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('BASE PRODUCT'), onTap: () { _addItemToDeal(product, null); Navigator.pop(ctx); }),
              const Divider(),
              ...product.variants.map((v) => ListTile(title: Text(v.name), trailing: Text('Rs. ${v.price.toStringAsFixed(0)}'), onTap: () { _addItemToDeal(product, v); Navigator.pop(ctx); })),
            ],
          ),
        ),
      );
    }
  }
}

class _VerticalCatTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  const _VerticalCatTile({required this.label, required this.selected, required this.onTap, required this.icon});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.05) : null,
          border: selected ? const Border(left: BorderSide(color: AppTheme.primary, width: 4)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? AppTheme.primary : AppTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: selected ? AppTheme.primary : AppTheme.textMuted))),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductTile({required this.product, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppTheme.outline)),
        child: Column(
          children: [
            Expanded(child: product.imagePath != null ? Image.file(File(product.imagePath!), fit: BoxFit.cover, width: double.infinity) : const Icon(Icons.restaurant, color: AppTheme.outline)),
            Padding(padding: const EdgeInsets.all(8), child: Text(product.name.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, height: 1.1))),
          ],
        ),
      ),
    );
  }
}

class _BundleItemTile extends StatelessWidget {
  final DealItem item;
  final Function(int) onAdjust;
  const _BundleItemTile({required this.item, required this.onAdjust});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.background, border: Border.all(color: AppTheme.outline)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.product?.name ?? "UNKNOWN"} ${item.variant != null ? "(${item.variant!.name})" : ""}'.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                Text('Rs. ${(item.variant?.price ?? item.product?.price ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.remove, size: 14), onPressed: () => onAdjust(-1)),
          Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.w900)),
          IconButton(icon: const Icon(Icons.add, size: 14), onPressed: () => onAdjust(1)),
        ],
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPick;
  const _ImagePickerSection({this.imagePath, required this.onPick});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DEAL IMAGE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(color: AppTheme.background, border: Border.all(color: AppTheme.outline, style: BorderStyle.values[1])),
            child: imagePath != null 
              ? Image.file(File(imagePath!), fit: BoxFit.cover)
              : const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_a_photo_outlined, color: AppTheme.textMuted), SizedBox(height: 8), Text('TAP TO ADD IMAGE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted))])),
          ),
        ),
      ],
    );
  }
}

class _ConfigLabel extends StatelessWidget {
  final String label;
  const _ConfigLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted)));
}

class _PriceSection extends StatelessWidget {
  final double regularPrice;
  final TextEditingController priceController;
  const _PriceSection({required this.regularPrice, required this.priceController});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('SUBTOTAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted)), Text('Rs. ${regularPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))])),
        const Icon(Icons.arrow_forward, color: AppTheme.textMuted, size: 16),
        const SizedBox(width: 24),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('DEAL PRICE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primary)), TextField(controller: priceController, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)))]))
      ],
    );
  }
}
