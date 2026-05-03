import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/deal.dart';
import '../../deals/providers/deal_provider.dart';
import '../widgets/admin_shell.dart';
import '../../../core/theme/app_theme.dart';
import 'deal_form_screen.dart';

class DealManagementScreen extends StatelessWidget {
  const DealManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'PROMOTIONS & DEALS',
      pageSubtitle: 'Configure item bundles, combos and special offers',
      child: Consumer<DealProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Reduced height
                color: AppTheme.surface,
                child: Row(
                  children: [
                    _CompactStat(label: 'TOTAL DEALS', value: provider.deals.length.toString()),
                    const SizedBox(width: 24),
                    _CompactStat(label: 'ACTIVE', value: provider.deals.where((d) => d.isActive).length.toString(), color: AppTheme.secondary),
                    const Spacer(),
                    SizedBox(
                      height: 40, // Reduced from 52
                      width: 180, // Reduced from 220
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DealFormScreen())),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('NEW DEAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Grid
              Expanded(
                child: provider.deals.isEmpty
                    ? const Center(child: Text('No deals created yet', style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: provider.deals.length,
                        itemBuilder: (context, index) {
                          final deal = provider.deals[index];
                          return _DealCard(
                            deal: deal,
                            onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DealFormScreen(editingDeal: deal))),
                            onDelete: () => _confirmDelete(context, provider, deal),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, DealProvider provider, Deal deal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('DELETE "${deal.name.toUpperCase()}"?', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        content: const Text('This will permanently remove this bundle from your catalog. This action cannot be undone.', style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () { provider.deleteDeal(deal.id!); Navigator.pop(ctx); },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('DELETE PERMANENTLY'),
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _CompactStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _DealCard extends StatelessWidget {
  final Deal deal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DealCard({required this.deal, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (deal.imagePath != null)
                  Image.file(File(deal.imagePath!), fit: BoxFit.cover)
                else
                  const Center(child: Icon(Icons.local_offer_outlined, size: 32, color: AppTheme.outline)),
                if (!deal.isActive)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: Text('DISABLED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    color: AppTheme.primary,
                    child: Text('Rs. ${deal.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deal.name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Text('${deal.items.length} PRODUCTS INCLUDED', style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                        child: const Text('EDIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
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
