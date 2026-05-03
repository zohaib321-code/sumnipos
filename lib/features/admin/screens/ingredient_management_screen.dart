import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/admin_shell.dart';
import '../../products/providers/ingredient_provider.dart';
import '../../../models/ingredient.dart';
import '../../../core/theme/app_theme.dart';

class IngredientManagementScreen extends StatefulWidget {
  const IngredientManagementScreen({super.key});

  @override
  State<IngredientManagementScreen> createState() => _IngredientManagementScreenState();
}

class _IngredientManagementScreenState extends State<IngredientManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IngredientProvider>();

    return AdminShell(
      pageTitle: 'RAW MATERIALS',
      pageSubtitle: 'Manage your kitchen ingredients and stock levels',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: AppTheme.surface,
            child: Row(
              children: [
                const Text(
                  'INGREDIENTS LIST',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: AppTheme.textMuted,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showIngredientDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('ADD INGREDIENT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.ingredients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.outline),
                            SizedBox(height: 16),
                            Text('No ingredients found', style: TextStyle(fontFamily: 'Inter', color: AppTheme.textMuted)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: provider.ingredients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ingredient = provider.ingredients[index];
                          return _IngredientCard(ingredient: ingredient);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showIngredientDialog(BuildContext context, [Ingredient? ingredient]) {
    final nameController = TextEditingController(text: ingredient?.name);
    final stockController = TextEditingController(text: ingredient?.stockQty.toString());
    String selectedUnit = ingredient?.unit ?? 'kg';
    final reorderController = TextEditingController(text: ingredient?.reorderLevel.toString() ?? '10');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: Text(ingredient == null ? 'ADD INGREDIENT' : 'EDIT INGREDIENT', 
                     style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(isDense: true),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INITIAL STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                        TextField(
                          controller: stockController,
                          decoration: const InputDecoration(isDense: true),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('UNIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: selectedUnit,
                          items: ['kg', 'ltr', 'pcs', 'g', 'ml', 'packets'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (val) => setLocalState(() => selectedUnit = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('ALERT LEVEL (Low Stock Warning)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
              TextField(
                controller: reorderController,
                decoration: const InputDecoration(isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.onSurface, foregroundColor: Colors.white),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newIngredient = Ingredient(
                    id: ingredient?.id,
                    name: nameController.text,
                    stockQty: double.tryParse(stockController.text) ?? 0.0,
                    unit: selectedUnit,
                    reorderLevel: double.tryParse(reorderController.text) ?? 10.0,
                  );
                  
                  if (ingredient == null) {
                    context.read<IngredientProvider>().addIngredient(newIngredient);
                  } else {
                    context.read<IngredientProvider>().updateIngredient(newIngredient);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('SAVE MATERIAL', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final Ingredient ingredient;

  const _IngredientCard({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final isLow = ingredient.stockQty <= ingredient.reorderLevel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: isLow ? AppTheme.warning.withOpacity(0.5) : AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: isLow ? AppTheme.warning.withOpacity(0.1) : AppTheme.background,
            child: Icon(Icons.egg_outlined, color: isLow ? AppTheme.warning : AppTheme.textMuted),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name.toUpperCase(),
                  style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unit: ${ingredient.unit}',
                  style: const TextStyle(fontFamily: 'Inter', color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${ingredient.stockQty.toStringAsFixed(1)} ${ingredient.unit}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isLow ? AppTheme.error : AppTheme.onSurface,
                ),
              ),
              if (isLow)
                const Text(
                  'LOW STOCK',
                  style: TextStyle(fontFamily: 'Inter', color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.w900),
                ),
            ],
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _editIngredient(context),
            color: AppTheme.textMuted,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => context.read<IngredientProvider>().deleteIngredient(ingredient.id!),
            color: AppTheme.error.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  void _editIngredient(BuildContext context) {
    // This is a bit lazy, better to move dialog to a separate widget or handle better
    final state = context.findAncestorStateOfType<_IngredientManagementScreenState>();
    state?._showIngredientDialog(context, ingredient);
  }
}
