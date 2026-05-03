import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../models/product_variant.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sunmi_pos/features/products/providers/product_provider.dart';
import 'package:sunmi_pos/features/products/providers/category_provider.dart';
import 'package:sunmi_pos/models/product.dart';
import 'package:sunmi_pos/features/admin/widgets/admin_shell.dart';
import 'package:sunmi_pos/features/products/providers/ingredient_provider.dart';
import 'package:sunmi_pos/models/ingredient.dart';
import 'package:sunmi_pos/core/theme/app_theme.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  dynamic _filterCategoryId;
  bool _panelOpen = false;
  Product? _editingProduct;

  // Form Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  bool _trackStock = false;
  String? _imagePath;
  int? _selectedCatId;
  List<ProductVariant> _variants = [];
  
  // Recipe mapping: null key = base product, int key = temporary variant index or ID
  List<ProductRecipe> _baseRecipe = [];
  Map<int, List<ProductRecipe>> _variantRecipes = {}; // Index in _variants list -> Recipe

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _openPanel({Product? product}) {
    setState(() {
      _editingProduct = product;
      _panelOpen = true;
      if (product != null) {
        _nameController.text = product.name;
        _priceController.text = product.price.toString();
        _stockController.text = product.stockQty.toString();
        _trackStock = product.trackStock;
        _imagePath = product.imagePath;
        _selectedCatId = product.categoryId;
        _variants = List.from(product.variants);
        
        // Load Recipes
        _loadRecipes(product);
      } else {
        _nameController.clear();
        _priceController.clear();
        _stockController.text = '0';
        _trackStock = false;
        _imagePath = null;
        _selectedCatId = null;
        _variants = [];
        _baseRecipe = [];
        _variantRecipes = {};
      }
    });
  }

  Future<void> _loadRecipes(Product product) async {
    final ingProvider = context.read<IngredientProvider>();
    final base = await ingProvider.getRecipe(product.id!);
    setState(() {
      _baseRecipe = base;
      _variantRecipes = {};
    });
    
    // Load for variants
    for (int i = 0; i < product.variants.length; i++) {
        final v = product.variants[i];
        if (v.id != null) {
            final vRecipe = await ingProvider.getRecipe(product.id!, variantId: v.id);
            setState(() {
                _variantRecipes[i] = vRecipe;
            });
        }
    }
  }

  void _closePanel() => setState(() => _panelOpen = false);

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // PERSIST IMAGE: Copy to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(image.path);
      final String localPath = path.join(appDir.path, 'product_images');
      
      // Ensure directory exists
      final directory = Directory(localPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String finalPath = path.join(localPath, fileName);
      final File savedImage = await File(image.path).copy(finalPath);
      
      setState(() => _imagePath = savedImage.path);
    }
  }

  void _save(ProductProvider provider) {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final stock = int.tryParse(_stockController.text) ?? 0;

    if (name.isEmpty || _selectedCatId == null) return;

    final p = Product(
      id: _editingProduct?.id,
      name: name,
      price: price,
      categoryId: _selectedCatId!,
      trackStock: _trackStock,
      stockQty: stock,
      imagePath: _imagePath,
      variants: _variants,
    );

    if (_editingProduct == null) {
      provider.addProduct(p).then((newId) {
        if (newId != null) _saveAllRecipes(newId);
      });
    } else {
      provider.updateProduct(p);
      _saveAllRecipes(p.id!);
    }
    _closePanel();
  }

  void _saveAllRecipes(int productId) {
    final ingProvider = context.read<IngredientProvider>();
    
    // Update base product recipe
    final baseWithId = _baseRecipe.map((r) => ProductRecipe(
      productId: productId,
      ingredientId: r.ingredientId,
      quantity: r.quantity,
    )).toList();
    ingProvider.saveRecipe(productId, null, baseWithId);

    // Note: Since we don't easily know the new variant IDs here for NEW products,
    // this part is tricky. For now, we assume existing variants.
    // In a real production app, we'd wait for variants to be saved and get their IDs.
    // For this prototype, we'll save recipes for variants that have an ID.
    _variantRecipes.forEach((index, recipes) {
       if (index < _variants.length) {
         final v = _variants[index];
         if (v.id != null) {
            final vWithId = recipes.map((r) => ProductRecipe(
                productId: productId,
                variantId: v.id,
                ingredientId: r.ingredientId,
                quantity: r.quantity,
            )).toList();
            ingProvider.saveRecipe(productId, v.id, vWithId);
         }
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: _panelOpen ? (_editingProduct == null ? 'NEW PRODUCT' : 'EDIT PRODUCT') : 'PRODUCT CATALOG',
      pageSubtitle: _panelOpen ? 'Define details, variants and recipes' : 'Manage your full product list and pricing',
      child: Consumer2<ProductProvider, CategoryProvider>(
        builder: (context, prodProvider, catProvider, _) {
          if (_panelOpen) {
            return _EditPanel(
              isEditing: _editingProduct != null,
              nameController: _nameController,
              priceController: _priceController,
              stockController: _stockController,
              trackStock: _trackStock,
              onTrackStockChanged: (v) => setState(() => _trackStock = v),
              imagePath: _imagePath,
              onPickImage: _pickImage,
              onClearImage: () => setState(() => _imagePath = null),
              categories: catProvider.categories,
              selectedCatId: _selectedCatId,
              onCatChanged: (id) => setState(() => _selectedCatId = id),
              onCancel: _closePanel,
              variants: _variants,
              onAddVariant: (v) => setState(() => _variants.add(v)),
              onRemoveVariant: (v) => setState(() => _variants.remove(v)),
              baseRecipe: _baseRecipe,
              variantRecipes: _variantRecipes,
              onUpdateRecipe: (index, recipe) {
                setState(() {
                  if (index == null) {
                    _baseRecipe = recipe;
                  } else {
                    _variantRecipes[index] = recipe;
                  }
                });
              },
              onSave: () => _save(prodProvider),
            );
          }

          final filtered = prodProvider.products.where((p) {
            return _filterCategoryId == null || p.categoryId == _filterCategoryId;
          }).toList();

          return Row(
            children: [
              // Left Category Panel
              Container(
                width: 160,
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(right: BorderSide(color: AppTheme.outline)),
                ),
                child: ListView(
                  children: [
                    _SideItem(
                      label: 'ALL ITEMS',
                      icon: Icons.all_out_rounded,
                      selected: _filterCategoryId == null,
                      onTap: () => setState(() => _filterCategoryId = null),
                    ),
                    ...catProvider.categories.map((c) => _SideItem(
                      label: c.name.toUpperCase(),
                      icon: Icons.folder_open_outlined,
                      selected: _filterCategoryId == c.id,
                      onTap: () => setState(() => _filterCategoryId = c.id),
                    )),
                  ],
                ),
              ),
              
              // Right Grid Area
              Expanded(
                child: Column(
                  children: [
                    _BuildHeader(
                      onAdd: () => _openPanel(),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty 
                        ? const Center(child: Text('No products found', style: TextStyle(color: AppTheme.textMuted)))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _ProductCard(
                              product: filtered[index],
                              onEdit: () => _openPanel(product: filtered[index]),
                              onDelete: () => _confirmDelete(context, filtered[index], prodProvider),
                            ),
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

  void _confirmDelete(BuildContext context, Product p, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${p.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.deleteProduct(p.id!);
              Navigator.pop(ctx);
            },
            child: const Text('DELETE', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _BuildHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const _BuildHeader({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Text('CATALOG BROWSER', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('CREATE PRODUCT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SideItem({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.05) : Colors.transparent,
          border: Border(left: BorderSide(color: selected ? AppTheme.primary : Colors.transparent, width: 4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? AppTheme.primary : AppTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected ? AppTheme.primary : AppTheme.onSurfaceVar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                if (product.imagePath != null)
                  Positioned.fill(child: Image.file(File(product.imagePath!), fit: BoxFit.cover))
                else
                  const Center(child: Icon(Icons.restaurant, size: 24, color: AppTheme.outline)),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    children: [
                      _CircleAction(icon: Icons.edit_outlined, color: AppTheme.onSurface, onTap: onEdit),
                      const SizedBox(width: 4),
                      _CircleAction(icon: Icons.delete_outline, color: AppTheme.error, onTap: onDelete),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RS. ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    if (product.variants.isNotEmpty)
                      const Icon(Icons.layers_outlined, size: 14, color: AppTheme.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, border: Border.all(color: AppTheme.outline)),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _EditPanel extends StatelessWidget {
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController stockController;
  final bool trackStock;
  final ValueChanged<bool> onTrackStockChanged;
  final String? imagePath;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final List<dynamic> categories;
  final int? selectedCatId;
  final ValueChanged<int?> onCatChanged;
  final List<ProductVariant> variants;
  final ValueChanged<ProductVariant> onAddVariant;
  final ValueChanged<ProductVariant> onRemoveVariant;
  final List<ProductRecipe> baseRecipe;
  final Map<int, List<ProductRecipe>> variantRecipes;
  final Function(int?, List<ProductRecipe>) onUpdateRecipe;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _EditPanel({
    required this.isEditing,
    required this.nameController,
    required this.priceController,
    required this.stockController,
    required this.trackStock,
    required this.onTrackStockChanged,
    required this.imagePath,
    required this.onPickImage,
    required this.onClearImage,
    required this.categories,
    required this.selectedCatId,
    required this.onCatChanged,
    required this.variants,
    required this.onAddVariant,
    required this.onRemoveVariant,
    required this.baseRecipe,
    required this.variantRecipes,
    required this.onUpdateRecipe,
    required this.onCancel,
    required this.onSave,
  });

  String _RecipeSummaryText({bool variants = false, int? variantIndex}) {
    final recipes = variantIndex != null ? variantRecipes[variantIndex] : baseRecipe;
    if (recipes == null || recipes.isEmpty) return 'LINK INGREDIENTS';
    return '${recipes.length} INGREDIENTS LINKED';
  }

  void _showRecipeBuilder(BuildContext context, int? variantIndex) {
    final ingProvider = context.read<IngredientProvider>();
    final currentRecipe = variantIndex != null 
        ? List<ProductRecipe>.from(variantRecipes[variantIndex] ?? []) 
        : List<ProductRecipe>.from(baseRecipe);

    showDialog(
      context: context,
      builder: (ctx) => _RecipeBuilderDialog(
        ingredients: ingProvider.ingredients,
        initialRecipe: currentRecipe,
        onSave: (newRecipe) => onUpdateRecipe(variantIndex, newRecipe),
      ),
    );
  }


  void _showAddVariantDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    bool trackStock = false;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('ADD VARIANT'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Variant Name (e.g. Small)')),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, decoration: const InputDecoration(hintText: 'Price'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Track Stock', style: TextStyle(fontSize: 12)),
                value: trackStock,
                onChanged: (v) => setLocalState(() => trackStock = v),
              ),
              if (trackStock)
                TextField(controller: stockCtrl, decoration: const InputDecoration(hintText: 'Current Stock'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                final stock = int.tryParse(stockCtrl.text) ?? 0;
                if (name.isNotEmpty) {
                  onAddVariant(ProductVariant(name: name, price: price, stockQty: stock, trackStock: trackStock));
                }
                Navigator.pop(ctx);
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          // Sticky Top Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.outline)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditing ? 'EDITING PRODUCT' : 'NEW PRODUCT', 
                         style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0, color: AppTheme.textMuted)),
                    Text(nameController.text.isEmpty ? 'Untitled' : nameController.text.toUpperCase(), 
                         style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
                const Spacer(),
                TextButton(onPressed: onCancel, child: const Text('DISCARD')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary, 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Details & Variants
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            _Section(
                              title: 'BASIC INFORMATION',
                              child: Column(
                                children: [
                                  _FormField(label: 'PRODUCT NAME', controller: nameController),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('CATEGORY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 0.5)),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              decoration: BoxDecoration(
                                                color: AppTheme.background,
                                                border: Border.all(color: AppTheme.outline),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<int>(
                                                  isExpanded: true,
                                                  value: selectedCatId,
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.onSurface),
                                                  items: categories.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name.toUpperCase()))).toList(),
                                                  onChanged: onCatChanged,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(child: _FormField(label: 'BASE PRICE', controller: priceController, keyboard: TextInputType.number)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _Section(
                              title: 'VARIANTS & PRICING',
                              action: TextButton.icon(
                                onPressed: () => _showAddVariantDialog(context),
                                icon: const Icon(Icons.add_circle, size: 18),
                                label: const Text('ADD VARIANT'),
                              ),
                              child: variants.isEmpty
                                  ? const Center(child: Text('Add sizes or versions of this product', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic)))
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: variants.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final v = variants[index];
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppTheme.background,
                                            border: Border.all(color: AppTheme.outline),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(v.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                                    Text('RS. ${v.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 11)),
                                                  ],
                                                ),
                                              ),
                                              TextButton.icon(
                                                onPressed: () => _showRecipeBuilder(context, index),
                                                icon: const Icon(Icons.hub_outlined, size: 16),
                                                label: Text(_RecipeSummaryText(variantIndex: index), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                                style: TextButton.styleFrom(foregroundColor: AppTheme.onSurface),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20), onPressed: () => onRemoveVariant(v)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 40),
                      
                      // RIGHT COLUMN: Media & Recipe
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                             _Section(
                              title: 'MEDIA',
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: onPickImage,
                                    child: Container(
                                      height: 180,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: AppTheme.background,
                                        border: Border.all(color: AppTheme.outline, style: BorderStyle.none),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: imagePath != null
                                          ? Stack(
                                              children: [
                                                Positioned.fill(child: Image.file(File(imagePath!), fit: BoxFit.cover)),
                                                Positioned(top: 8, right: 8, child: _CircleAction(icon: Icons.close, color: AppTheme.error, onTap: onClearImage)),
                                              ],
                                            )
                                          : const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.image_search_outlined, size: 40, color: AppTheme.outline),
                                                SizedBox(height: 12),
                                                Text('DRAG AND DROP OR CLICK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _Section(
                              title: 'INVENTORY & RECIPE',
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('TRACK INVENTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                    value: trackStock,
                                    onChanged: onTrackStockChanged,
                                  ),
                                  if (trackStock)
                                    _FormField(label: 'INITIAL STOCK', controller: stockController, keyboard: TextInputType.number),
                                  
                                  const Divider(height: 48),
                                  
                                  const Text('BASE PRODUCT FORMULA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 0.5)),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showRecipeBuilder(context, null),
                                      icon: const Icon(Icons.hub_outlined, size: 18),
                                      label: Text(_RecipeSummaryText()),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        side: const BorderSide(color: AppTheme.secondary),
                                        foregroundColor: AppTheme.secondary,
                                      ),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboard;
  const _FormField({required this.label, required this.controller, this.keyboard = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            border: Border.all(color: AppTheme.outline),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _Section({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.outline.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.outline.withOpacity(0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppTheme.textMuted)),
                if (action != null) action!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _RecipeBuilderDialog extends StatefulWidget {
  final List<Ingredient> ingredients;
  final List<ProductRecipe> initialRecipe;
  final Function(List<ProductRecipe>) onSave;

  const _RecipeBuilderDialog({
    required this.ingredients,
    required this.initialRecipe,
    required this.onSave,
  });

  @override
  State<_RecipeBuilderDialog> createState() => _RecipeBuilderDialogState();
}

class _RecipeBuilderDialogState extends State<_RecipeBuilderDialog> {
  late List<ProductRecipe> _localRecipe;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localRecipe = List.from(widget.initialRecipe);
  }

  @override
  Widget build(BuildContext context) {
    final filteredIngredients = widget.ingredients.where((ing) => 
      ing.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 1000,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: AppTheme.onSurface,
              child: Row(
                children: [
                  const Icon(Icons.hub_outlined, color: Colors.white, size: 24),
                  const SizedBox(width: 16),
                  const Text('LINK RAW MATERIALS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
            ),
            
            Expanded(
              child: Row(
                children: [
                  // Left Pane: Search & Selection
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppTheme.outline))),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'SEARCH INGREDIENTS...',
                                prefixIcon: Icon(Icons.search),
                                isDense: true,
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredIngredients.length,
                              itemBuilder: (context, index) {
                                final ing = filteredIngredients[index];
                                final isAdded = _localRecipe.any((r) => r.ingredientId == ing.id);
                                return ListTile(
                                  dense: true,
                                  title: Text(ing.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
                                  subtitle: Text('ID: ${ing.id} | Unit: ${ing.unit}', style: const TextStyle(fontSize: 10)),
                                  trailing: isAdded 
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : const Icon(Icons.add_circle_outline),
                                  onTap: () {
                                    if (!isAdded) {
                                      setState(() {
                                        _localRecipe.add(ProductRecipe(productId: 0, ingredientId: ing.id!, quantity: 1.0));
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Right Pane: Active Recipe
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: AppTheme.background,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('RECIPE COMPOSITION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.textMuted)),
                          ),
                          Expanded(
                            child: _localRecipe.isEmpty 
                              ? const Center(child: Text('No ingredients linked yet', style: TextStyle(fontStyle: FontStyle.italic)))
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: _localRecipe.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final recipe = _localRecipe[index];
                                    final ing = widget.ingredients.firstWhere((i) => i.id == recipe.ingredientId, orElse: () => Ingredient(name: 'Unknown', stockQty: 0.0, unit: ''));
                                    
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.outline)),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(ing.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                                Text(ing.unit, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              _QtyBtn(icon: Icons.remove, onTap: () {
                                                final step = (ing.unit.toLowerCase() == 'pcs' || ing.unit.toLowerCase() == 'units') ? 1.0 : 0.1;
                                                if (recipe.quantity >= step) {
                                                  setState(() => _localRecipe[index] = ProductRecipe(productId: 0, ingredientId: recipe.ingredientId, quantity: recipe.quantity - step));
                                                }
                                              }),
                                              Container(
                                                width: 80,
                                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                                child: TextField(
                                                  textAlign: TextAlign.center,
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                                  controller: TextEditingController(text: recipe.quantity.toStringAsFixed((ing.unit.toLowerCase() == 'pcs' || ing.unit.toLowerCase() == 'units') ? 0 : 2)),
                                                  onChanged: (v) {
                                                    final val = double.tryParse(v) ?? 0.0;
                                                    _localRecipe[index] = ProductRecipe(productId: 0, ingredientId: recipe.ingredientId, quantity: val);
                                                  },
                                                ),
                                              ),
                                              _QtyBtn(icon: Icons.add, onTap: () {
                                                final step = (ing.unit.toLowerCase() == 'pcs' || ing.unit.toLowerCase() == 'units') ? 1.0 : 0.1;
                                                setState(() => _localRecipe[index] = ProductRecipe(productId: 0, ingredientId: recipe.ingredientId, quantity: recipe.quantity + step));
                                              }),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                                            onPressed: () => setState(() => _localRecipe.removeAt(index)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          ),
                          // Save Section
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.outline))),
                            child: Row(
                              children: [
                                Text('${_localRecipe.length} Items Selected', style: const TextStyle(fontWeight: FontWeight.w800)),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () {
                                    widget.onSave(_localRecipe);
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                  ),
                                  child: const Text('CONFIRM RECIPE', style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.outline), shape: BoxShape.circle),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
