import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/category.dart';
import '../../products/providers/category_provider.dart';
import '../widgets/admin_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/icon_mapping.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  Category? _editing; // null = "add new" mode
  bool _panelOpen = false;

  final List<Map<String, dynamic>> _availableIcons = const [
    {'name': 'Fast Food',  'icon': Icons.fastfood,        'key': 'fastfood'},
    {'name': 'Drinks',     'icon': Icons.local_drink,      'key': 'local_drink'},
    {'name': 'Ice Cream',  'icon': Icons.icecream,         'key': 'icecream'},
    {'name': 'Cake',       'icon': Icons.cake,             'key': 'cake'},
    {'name': 'Pizza',      'icon': Icons.local_pizza,      'key': 'local_pizza'},
    {'name': 'Dining',     'icon': Icons.dinner_dining,    'key': 'dinner_dining'},
    {'name': 'Offer',      'icon': Icons.local_offer,      'key': 'local_offer'},
    {'name': 'Restaurant', 'icon': Icons.restaurant,       'key': 'restaurant'},
    {'name': 'Bakery',     'icon': Icons.bakery_dining,    'key': 'bakery_dining'},
    {'name': 'Coffee',     'icon': Icons.coffee,           'key': 'coffee'},
  ];

  // Panel form state
  final _nameController = TextEditingController();
  String _selectedIconKey = 'fastfood';
  String? _imagePath;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openPanel({Category? category}) {
    setState(() {
      _editing = category;
      _panelOpen = true;
      _nameController.text = category?.name ?? '';
      _selectedIconKey = category?.icon ?? 'fastfood';
      _imagePath = category?.imagePath;
    });
  }

  void _closePanel() => setState(() => _panelOpen = false);

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imagePath = image.path);
  }

  void _save(CategoryProvider provider) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final cat = Category(
      id: _editing?.id,
      name: name,
      icon: _selectedIconKey,
      imagePath: _imagePath,
    );
    if (_editing == null) {
      provider.addCategory(cat);
    } else {
      provider.updateCategory(cat);
    }
    _closePanel();
  }

  void _confirmDelete(BuildContext context, Category category,
      CategoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4))),
        title: Text('Delete "${category.name}"?',
            style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        content: const Text(
            'Products in this category will remain but may lose their association.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppTheme.onSurfaceVar)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.deleteCategory(category.id!);
              Navigator.pop(ctx);
              if (_editing?.id == category.id) _closePanel();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Category Management',
      pageSubtitle: 'Define and organize product groups',
      child: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: List + header ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page header row
                    Container(
                      color: AppTheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          const Text('CATEGORY INVENTORY', 
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _openPanel(),
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('CREATE CATEGORY'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              elevation: 0,
                              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // List
                    Expanded(
                      child: provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : provider.categories.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.category_outlined,
                                          size: 64, color: AppTheme.outline),
                                      const SizedBox(height: 16),
                                      const Text('No categories yet.',
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: AppTheme.textMuted)),
                                      const SizedBox(height: 12),
                                      TextButton(
                                          onPressed: () => _openPanel(),
                                          child: const Text(
                                              'Create First Category')),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 16, 24, 16),
                                  itemCount: provider.categories.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final cat = provider.categories[index];
                                    final isSelected =
                                        _editing?.id == cat.id && _panelOpen;
                                    return _CategoryRow(
                                      category: cat,
                                      isSelected: isSelected,
                                      availableIcons: _availableIcons,
                                      onEdit: () => _openPanel(category: cat),
                                      onDelete: () => _confirmDelete(
                                          context, cat, provider),
                                    );
                                  },
                                ),
                    ),
                    // Footer stats
                    Container(
                      color: AppTheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        children: [
                          _StatChip(
                              label: 'TOTAL CATEGORIES',
                              value: provider.categories.length.toString()
                                  .padLeft(2, '0')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Right: Inline Edit/Add Panel ─────────────────────────────
              if (_panelOpen)
                Container(
                  width: 320,
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(left: BorderSide(color: AppTheme.outline)),
                  ),
                  child: _EditPanel(
                    isEditing: _editing != null,
                    nameController: _nameController,
                    selectedIconKey: _selectedIconKey,
                    imagePath: _imagePath,
                    availableIcons: _availableIcons,
                    onIconSelected: (key) =>
                        setState(() => _selectedIconKey = key),
                    onPickImage: _pickImage,
                    onClearImage: () => setState(() => _imagePath = null),
                    onCancel: _closePanel,
                    onSave: () => _save(provider),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Category list row ────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final List<Map<String, dynamic>> availableIcons;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.category,
    required this.isSelected,
    required this.availableIcons,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary.withOpacity(0.04)
            : AppTheme.surface,
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              border: Border.all(color: AppTheme.outline),
            ),
            child: category.imagePath != null
                ? _CategoryImage(path: category.imagePath!)
                : Icon(
                    IconMapping.getIcon(category.icon),
                    color: AppTheme.primary,
                    size: 26,
                  ),
          ),
          // Name
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          // Actions
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppTheme.primary,
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppTheme.error,
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  final String path;
  const _CategoryImage({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}

// ─── Inline Edit Panel ────────────────────────────────────────────────────────

class _EditPanel extends StatelessWidget {
  final bool isEditing;
  final TextEditingController nameController;
  final String selectedIconKey;
  final String? imagePath;
  final List<Map<String, dynamic>> availableIcons;
  final ValueChanged<String> onIconSelected;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _EditPanel({
    required this.isEditing,
    required this.nameController,
    required this.selectedIconKey,
    required this.imagePath,
    required this.availableIcons,
    required this.onIconSelected,
    required this.onPickImage,
    required this.onClearImage,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.outline)),
          ),
          child: Row(
            children: [
              Text(
                isEditing ? 'EDIT CATEGORY' : 'ADD CATEGORY',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: AppTheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppTheme.textMuted,
                onPressed: onCancel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelLabel('NAME'),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Beverages',
                  ),
                ),
                const SizedBox(height: 24),
                const _PanelLabel('ICON SELECTION'),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: availableIcons.length,
                  itemBuilder: (context, i) {
                    final item = availableIcons[i];
                    final isSelected =
                        selectedIconKey == item['key'] && imagePath == null;
                    return GestureDetector(
                      onTap: () {
                        onIconSelected(item['key']);
                        onClearImage();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.surface,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item['icon'],
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['name'],
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const _PanelLabel('CATEGORY IMAGE (OPTIONAL)'),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      border: Border.all(
                        color: AppTheme.outline,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: imagePath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              _CategoryImage(path: imagePath!),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: onClearImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    color: Colors.black54,
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.cloud_upload_outlined,
                                  size: 32, color: AppTheme.textMuted),
                              SizedBox(height: 6),
                              Text('TAP TO UPLOAD IMAGE',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bottom action bar
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.outline)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.onSurfaceVar,
                    side: const BorderSide(color: AppTheme.outline),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('CANCEL',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.onSurface,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('SAVE',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelLabel extends StatelessWidget {
  final String text;
  const _PanelLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppTheme.textMuted,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppTheme.textMuted)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary)),
        ],
      ),
    );
  }
}
