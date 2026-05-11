import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';
import './product_catalog_screen.dart';
import './category_management_screen.dart';
import './product_management_screen.dart';
import './deal_management_screen.dart';
import './admin_sales_screen.dart';
import './system_settings_screen.dart';
import './ingredient_management_screen.dart';
import './admin_stats_screen.dart';
import './drawer_log_screen.dart';
import 'package:sunmi_pos/core/theme/app_theme.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'DASHBOARD',
      pageSubtitle: 'Select a module to manage your POS system',
      showBackButton: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONTROL PANEL',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 2.0,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5, // 5 cards per row
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0, // Keeping them square
              children: [
                _AdminBox(
                  title: 'PRODUCT CATALOG',
                  subtitle: 'Menu View',
                  icon: Icons.restaurant_menu,
                  color: AppTheme.primary,
                  onTap: () => _nav(context, const ProductCatalogScreen()),
                ),
                _AdminBox(
                  title: 'DEAL BUNDLES',
                  subtitle: 'Promotions',
                  icon: Icons.local_offer,
                  color: AppTheme.warning,
                  onTap: () => _nav(context, const DealManagementScreen()),
                ),
                _AdminBox(
                  title: 'CATEGORIES',
                  subtitle: 'Organization',
                  icon: Icons.grid_view_rounded,
                  color: AppTheme.secondary,
                  onTap: () => _nav(context, const CategoryManagementScreen()),
                ),
                _AdminBox(
                  title: 'INVENTORY',
                  subtitle: 'Stock Levels',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.blueGrey,
                  onTap: () => _nav(context, const ProductManagementScreen()),
                ),
                _AdminBox(
                  title: 'RECIPES & RAW',
                  subtitle: 'Ingredients',
                  icon: Icons.rebase_edit,
                  color: Colors.teal,
                  onTap: () => _nav(context, const IngredientManagementScreen()),
                ),
                _AdminBox(
                  title: 'ORDERS',
                  subtitle: 'History',
                  icon: Icons.history,
                  color: Colors.indigo,
                  onTap: () => _nav(context, const AdminSalesScreen()),
                ),
                _AdminBox(
                  title: 'SYSTEM',
                  subtitle: 'Settings',
                  icon: Icons.settings_outlined,
                  color: Colors.blueAccent,
                  onTap: () => _nav(context, const SystemSettingsScreen()),
                ),
                _AdminBox(
                  title: 'ANALYTICS',
                  subtitle: 'Statistics',
                  icon: Icons.analytics_outlined,
                  color: Colors.deepOrange,
                  onTap: () => _nav(context, const AdminStatsScreen()),
                ),
                _AdminBox(
                  title: 'CASH DRAWER',
                  subtitle: 'Open Log',
                  icon: Icons.point_of_sale,
                  color: AppTheme.warning,
                  onTap: () => _nav(context, const DrawerLogScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

class _AdminBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminBox({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 9,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
