import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../products/providers/category_provider.dart';
import '../../../utils/icon_mapping.dart';

class CategorySidebar extends StatelessWidget {
  final dynamic selectedCategoryId;
  final Function(dynamic) onCategorySelected;
  final VoidCallback onAdminAccess;

  const CategorySidebar({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onAdminAccess,
  });

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    return Container(
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onLongPress: onAdminAccess,
                  child: const Text(
                    'CATEGORIES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // Subtle admin access point
                GestureDetector(
                  onDoubleTap: onAdminAccess,
                  child: Icon(Icons.lock_outline, size: 14, color: Colors.grey[300]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: categories.length + 2,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = selectedCategoryId == null;
                  return _CategoryTile(
                    name: 'ALL',
                    icon: Icons.grid_view,
                    isSelected: isSelected,
                    onTap: () => onCategorySelected(null),
                  );
                }
                
                if (index == 1) {
                  final isSelected = selectedCategoryId == 'deals';
                  return _CategoryTile(
                    name: 'DEALS',
                    icon: Icons.local_offer,
                    isSelected: isSelected,
                    onTap: () => onCategorySelected('deals'),
                  );
                }

                final category = categories[index - 2];
                final isSelected = selectedCategoryId == category.id;

                return _CategoryTile(
                  name: category.name.toUpperCase(),
                  icon: IconMapping.getIcon(category.icon),
                  isSelected: isSelected,
                  onTap: () => onCategorySelected(category.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 80, // Reduced height for touch-friendly but compact
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.blue[700],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
