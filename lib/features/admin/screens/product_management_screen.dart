import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunmi_pos/features/products/providers/product_provider.dart';
import 'package:sunmi_pos/features/products/providers/category_provider.dart';
import 'package:sunmi_pos/models/product.dart';
import 'package:sunmi_pos/features/admin/widgets/admin_shell.dart';
import 'package:sunmi_pos/features/products/providers/ingredient_provider.dart';
import 'package:sunmi_pos/core/theme/app_theme.dart';
import 'package:sunmi_pos/models/product_variant.dart';
import 'package:sunmi_pos/models/ingredient.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  dynamic _filterCategoryId;
  bool _panelOpen = false;
  Product? _targetProduct;
  ProductVariant? _targetVariant;
  Ingredient? _targetIngredient;
  bool _showIngredients = false;
  final _stockController = TextEditingController();

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  void _openInventoryPanel(Product? product, {ProductVariant? variant, Ingredient? ingredient}) {
    setState(() {
      _targetProduct = product;
      _targetVariant = variant;
      _targetIngredient = ingredient;
      _panelOpen = true;
      _stockController.text = (ingredient?.stockQty ?? variant?.stockQty ?? product?.stockQty ?? 0).toString();
    });
  }

  void _closePanel() => setState(() => _panelOpen = false);

  void _updateStock(ProductProvider prodProvider, IngredientProvider ingProvider) {
    final newQty = double.tryParse(_stockController.text) ?? 0.0;
    
    if (_targetIngredient != null) {
      final updated = Ingredient(
        id: _targetIngredient!.id,
        name: _targetIngredient!.name,
        stockQty: newQty,
        unit: _targetIngredient!.unit,
        reorderLevel: _targetIngredient!.reorderLevel,
      );
      ingProvider.updateIngredient(updated);
    } else if (_targetProduct != null) {
      final intQty = newQty.toInt();
      if (_targetVariant != null) {
        final updatedVariants = _targetProduct!.variants.map((v) {
          if (v.id == _targetVariant!.id && v.name == _targetVariant!.name) {
            return ProductVariant(
              id: v.id,
              productId: v.productId,
              name: v.name,
              price: v.price,
              trackStock: true,
              stockQty: intQty,
            );
          }
          return v;
        }).toList();

        final updatedProd = Product(
          id: _targetProduct!.id,
          name: _targetProduct!.name,
          price: _targetProduct!.price,
          categoryId: _targetProduct!.categoryId,
          trackStock: _targetProduct!.trackStock,
          stockQty: _targetProduct!.stockQty,
          imagePath: _targetProduct!.imagePath,
          isActive: _targetProduct!.isActive,
          variants: updatedVariants,
        );
        prodProvider.updateProduct(updatedProd);
      } else {
        final updated = Product(
          id: _targetProduct!.id,
          name: _targetProduct!.name,
          price: _targetProduct!.price,
          categoryId: _targetProduct!.categoryId,
          trackStock: true,
          stockQty: intQty,
          imagePath: _targetProduct!.imagePath,
          isActive: _targetProduct!.isActive,
          variants: _targetProduct!.variants,
        );
        prodProvider.updateProduct(updated);
      }
    }
    _closePanel();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'INVENTORY TRACKING',
      pageSubtitle: 'Monitor and adjust stock levels for all traceable items',
      child: Consumer2<ProductProvider, IngredientProvider>(
        builder: (context, prodProvider, ingProvider, _) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Unified Header
                    Container(
                      color: AppTheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        children: [
                          _buildToggleButton('MENU ITEMS', !_showIngredients, () => setState(() => _showIngredients = false)),
                          const SizedBox(width: 8),
                          _buildToggleButton('RAW MATERIALS', _showIngredients, () => setState(() => _showIngredients = true)),
                          const Spacer(),
                          if (!_showIngredients)
                            _buildCategoryFilter(context),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Content
                    Expanded(
                      child: _showIngredients
                          ? _buildIngredientList(ingProvider)
                          : _buildProductList(prodProvider),
                    ),
                  ],
                ),
              ),
              if (_panelOpen)
                _StockAdjustPanel(
                  productName: _targetIngredient?.name ?? _targetProduct?.name ?? '',
                  variantName: _targetVariant?.name,
                  unitName: _targetIngredient?.unit ?? 'UNITS',
                  controller: _stockController,
                  onCancel: _closePanel,
                  onSave: () => _updateStock(prodProvider, ingProvider),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggleButton(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? AppTheme.onSurface : AppTheme.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: active ? Colors.white : AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final catProvider = context.read<CategoryProvider>();
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border.all(color: AppTheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: _filterCategoryId,
          dropdownColor: AppTheme.surface,
          hint: const Text('FILTER CATEGORY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
          items: [
            const DropdownMenuItem(value: null, child: Text('ALL CATEGORIES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800))),
            ...catProvider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)))),
          ],
          onChanged: (id) => setState(() => _filterCategoryId = id),
        ),
      ),
    );
  }

  Widget _buildProductList(ProductProvider prodProvider) {
    final List<Map<String, dynamic>> items = [];
    for (final p in prodProvider.products) {
      if (_filterCategoryId != null && p.categoryId != _filterCategoryId) continue;
      if (p.trackStock) items.add({'product': p, 'variant': null});
      for (final v in p.variants) {
        if (v.trackStock) items.add({'product': p, 'variant': v});
      }
    }

    if (items.isEmpty) return const _EmptyState(msg: 'No menu items with tracking enabled');

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _InventoryRow(
          name: item['variant'] != null ? '${item['product'].name} (${item['variant'].name})' : item['product'].name,
          stock: (item['variant']?.stockQty ?? item['product'].stockQty).toDouble(),
          unit: 'UNITS',
          lowThreshold: 10,
          onAdjust: () => _openInventoryPanel(item['product'], variant: item['variant']),
        );
      },
    );
  }

  Widget _buildIngredientList(IngredientProvider ingProvider) {
    if (ingProvider.ingredients.isEmpty) return const _EmptyState(msg: 'No raw materials found');

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: ingProvider.ingredients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ing = ingProvider.ingredients[index];
        return _InventoryRow(
          name: ing.name.toUpperCase(),
          stock: ing.stockQty,
          unit: ing.unit.toUpperCase(),
          lowThreshold: ing.reorderLevel,
          onAdjust: () => _openInventoryPanel(null, ingredient: ing),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(msg, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)));
  }
}

class _InventoryRow extends StatelessWidget {
  final String name;
  final double stock;
  final String unit;
  final double lowThreshold;
  final VoidCallback onAdjust;

  const _InventoryRow({
    required this.name,
    required this.stock,
    required this.unit,
    required this.lowThreshold,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = stock <= lowThreshold;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.outline.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(
                  isLow ? 'LOW STOCK' : 'IN STOCK',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: isLow ? AppTheme.error : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stock.toStringAsFixed(unit == 'UNITS' ? 0 : 2),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isLow ? AppTheme.error : AppTheme.onSurface,
                  ),
                ),
                Text(unit, style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            onPressed: onAdjust,
            icon: const Icon(Icons.edit_note, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: AppTheme.onSurface,
          ),
        ],
      ),
    );
  }
}

class _StockAdjustPanel extends StatelessWidget {
  final String productName;
  final String? variantName;
  final String unitName;
  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _StockAdjustPanel({
    required this.productName,
    this.variantName,
    required this.unitName,
    required this.controller,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(left: BorderSide(color: AppTheme.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ADJUST STOCK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Text(productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (variantName != null)
              Text(variantName!.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            const SizedBox(height: 32),
            const Text('NEW QUANTITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                child: const Text('UPDATE STOCK', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('CANCEL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
