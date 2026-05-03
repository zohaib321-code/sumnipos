import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_summary_dialog.dart';
import '../../../core/theme/app_theme.dart';

class CartSidebar extends StatelessWidget {
  const CartSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(left: BorderSide(color: AppTheme.outline)),
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT ORDER',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    if (cart.editingOrderId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Editing Order #${cart.editingOrderId}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppTheme.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                if (cart.items.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                    onPressed: () => cart.clearCart(),
                    color: AppTheme.textMuted,
                    tooltip: 'Clear Cart',
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // ── Cart Items List ──────────────────────────────────────────
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shopping_basket_outlined, size: 48, color: AppTheme.outline),
                        SizedBox(height: 16),
                        Text('CART IS EMPTY', 
                             style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppTheme.outline, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartItemRow(item: item, index: index);
                    },
                  ),
          ),
          
          // ── Bottom Summary ───────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.outline)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const Divider(height: 24),
                // ── Subtotal Line ──
                _SummaryRow(label: 'SUBTOTAL', value: cart.subtotal),
                // ── Tax Line ──
                if (cart.taxAmount > 0)
                  _SummaryRow(label: 'TAX (${cart.settings.taxPercentage}%)', value: cart.taxAmount),
                // ── Custom Charges ──
                ...cart.customChargesCalculated.map((c) => _SummaryRow(
                  label: c.name.toUpperCase(),
                  value: c.amount,
                )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      'Rs. ${cart.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56, // Reduced from 80px
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty ? null : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => const CheckoutSummaryDialog(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                    ),
                    child: Text(
                      cart.editingOrderId != null ? 'UPDATE ORDER' : 'PROCESS ORDER',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final dynamic item;
  final int index;

  const _CartItemRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [

              // Name & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Price
              Text(
                'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          if (item.notes != null && item.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Text(
                '↳ ${item.notes}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppTheme.secondary,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          if (item.deal != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.deal!.items.map<Widget>((di) {
                  // Get specific variant for this deal item if selected
                  final selectedVariant = item.selectedDealVariants[di.id];
                  // If not in selections, maybe it was pre-defined in the deal item (di.variant)
                  final variantName = selectedVariant?.name ?? di.variant?.name;
                  
                  return Text(
                    variantName != null 
                      ? '• ${di.qty}x ${di.product?.name} ($variantName)'
                      : '• ${di.qty}x ${di.product?.name ?? "..."}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
            
          const SizedBox(height: 8),
          // Actions bar
          Row(
            children: [
              const Spacer(),
              // Note button
              _ActionButton(
                icon: Icons.note_add_outlined,
                onTap: () => _showNoteDialog(context, cart, index, item.notes),
                color: item.notes != null ? AppTheme.secondary : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              // Quantity controls
                _QuantityControl(
                  qty: item.quantity,
                  onMinus: () {
                    if (item.quantity > 1) {
                      cart.updateQuantity(item.id, -1);
                    } else {
                      cart.removeItem(item.id);
                    }
                  },
                  onPlus: () => cart.updateQuantity(item.id, 1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, CartProvider cart, int index, String? currentNote) {
    final controller = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
        title: const Text('Add Note', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Special instructions...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              cart.updateItemNotes(index, controller.text.isEmpty ? null : controller.text);
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QuantityControl({required this.qty, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SubControl(
            icon: qty > 1 ? Icons.remove : Icons.delete_outline,
            onTap: onMinus,
            color: qty > 1 ? AppTheme.onSurface : AppTheme.error,
          ),
          Container(width: 1, height: 36, color: AppTheme.outline),
          Container(
            width: 36,
            alignment: Alignment.center,
            color: AppTheme.surfaceVariant,
            child: Text(
              '$qty',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primary),
            ),
          ),
          Container(width: 1, height: 36, color: AppTheme.outline),
          _SubControl(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _SubControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _SubControl({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, color: color ?? AppTheme.onSurface, size: 16),
      ),
    );
  }
}
class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          Text('Rs. ${value.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
