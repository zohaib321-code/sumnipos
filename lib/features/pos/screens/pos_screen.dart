import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/product_grid.dart';
import '../widgets/cart_sidebar.dart';
import '../widgets/global_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/pin_dialog.dart';
import '../../admin/screens/admin_home.dart';
import '../../admin/screens/order_history_screen.dart';
import '../../products/providers/category_provider.dart';
import '../../../core/services/cash_drawer_service.dart';
import '../../../models/drawer_log.dart';
import 'package:sunmi_pos/core/theme/app_theme.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  dynamic selectedCategoryId;

  void _handleAdminAccess() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isAdmin) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim1, anim2) => const AdminHomeScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        onSuccess: () {
          if (authProvider.isAdmin) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, anim1, anim2) => const AdminHomeScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Access Denied: Admin role required')),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmOpenDrawer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('OPEN CASH DRAWER?', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        content: const Text('This will open the cash drawer and log the action. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            child: const Text('OPEN DRAWER', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await CashDrawerService.open(reason: DrawerLog.reasonManual);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Cash drawer opened' : 'Drawer signal sent (no drawer connected?)'),
        backgroundColor: ok ? AppTheme.primary : AppTheme.textMuted,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewOrderHistory() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const OrderHistoryScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── Consistant Top Header ──────────────────────────────────
          GlobalHeader(
            title: 'Velocity POS',
            subtitle: 'Point of Sale',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.point_of_sale, color: AppTheme.textMuted),
                  onPressed: _confirmOpenDrawer,
                  tooltip: 'Open Cash Drawer',
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                  onPressed: _handleAdminAccess,
                  tooltip: 'Admin Access',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppTheme.error),
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                  tooltip: 'Logout Session',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: Row(
              children: [
                // ── Left Side Categories & Deals (Scrollable) ──────────
                Container(
                  width: 160,
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(right: BorderSide(color: AppTheme.outline)),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: _VerticalCategoryList(
                          selectedId: selectedCategoryId,
                          onChanged: (id) => setState(() => selectedCategoryId = id),
                        ),
                      ),
                      const Divider(height: 1),
                      // Orders Button at bottom
                      _SideButton(
                        label: 'ORDERS',
                        icon: Icons.history,
                        onTap: _viewOrderHistory,
                      ),
                    ],
                  ),
                ),
                
                // ── Main Content Area (Product Grid) ──────────────────
                Expanded(
                  flex: 8,
                  child: ProductGrid(
                    categoryId: selectedCategoryId,
                  ),
                ),
                
                // ── Right Sidebar (Cart) ─────────────────────────────
                const VerticalDivider(width: 1),
                const Expanded(
                  flex: 4,
                  child: CartSidebar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalCategoryList extends StatelessWidget {
  final dynamic selectedId;
  final Function(dynamic) onChanged;

  const _VerticalCategoryList({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length + 2,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        dynamic id;
        String name;
        IconData icon;
        
        if (index == 0) {
          id = null;
          name = 'ALL ITEMS';
          icon = Icons.grid_view_rounded;
        } else if (index == 1) {
          id = 'deals';
          name = 'DEALS';
          icon = Icons.local_offer;
        } else {
          final cat = categories[index - 2];
          id = cat.id;
          name = cat.name.toUpperCase();
          icon = Icons.fastfood_outlined;
        }

        final isSelected = selectedId == id;
        
        return InkWell(
          onTap: () => onChanged(id),
          child: Container(
            height: 52, // Reduced from 72
            padding: const EdgeInsets.symmetric(horizontal: 14), // Slightly reduced from 16
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary.withOpacity(0.05) : null,
              border: isSelected 
                ? const Border(left: BorderSide(color: AppTheme.primary, width: 4))
                : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SideButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textMuted),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
