import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../../core/services/printer_service.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/theme/app_theme.dart';

class CheckoutSummaryDialog extends StatefulWidget {
  const CheckoutSummaryDialog({super.key});

  @override
  State<CheckoutSummaryDialog> createState() => _CheckoutSummaryDialogState();
}

class _CheckoutSummaryDialogState extends State<CheckoutSummaryDialog> {
  final _orderNotesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _orderNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              children: [
                const Text(
                  'ORDER SUMMARY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 1.0,
                    color: AppTheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.08),
                                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    '${item.quantity}x',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                      if (item.notes != null)
                                        Text(
                                          'Note: ${item.notes}',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Rs. ${item.total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 360,
                      decoration: const BoxDecoration(
                        color: AppTheme.surface,
                        border: Border(left: BorderSide(color: AppTheme.outline)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: Text('TOTALS', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppTheme.textMuted)),
                          ),
                          _TotalLine(label: 'Subtotal', amount: cart.subtotal),
                          if (cart.taxAmount > 0)
                            _TotalLine(label: 'GST/Tax (${cart.settings.taxPercentage}%)', amount: cart.taxAmount),
                          ...cart.customChargesCalculated.map((c) => _TotalLine(label: c.name.toUpperCase(), amount: c.amount)),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                                Text('Rs. ${cart.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: TextField(
                              controller: _orderNotesController,
                              decoration: const InputDecoration(hintText: 'Order notes (optional)', prefixIcon: Icon(Icons.note_add_outlined, size: 18)),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.outline))),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: _isProcessing ? null : () => _processCheckout(context, 'unpaid'),
                                    style: OutlinedButton.styleFrom(
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                      side: const BorderSide(color: AppTheme.outline),
                                    ),
                                    child: const Text('SAVE UNPAID', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: _isProcessing ? null : () => _processCheckout(context, 'paid'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                      elevation: 0,
                                    ),
                                    child: _isProcessing 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('PAID', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processCheckout(BuildContext context, String status) async {
    setState(() => _isProcessing = true);
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    try {
      final orderId = await cart.checkout(
        status: status,
        orderNotes: _orderNotesController.text.isEmpty ? null : _orderNotesController.text,
      );

      if (orderId != null && context.mounted) {
        // Refresh products
        try {
          Provider.of<ProductProvider>(context, listen: false).loadProducts();
        } catch (e) {
          debugPrint("Provider error: $e");
        }

        final order = await DatabaseHelper.instance.getOrder(orderId);
        if (order != null && context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              contentPadding: EdgeInsets.zero,
              title: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(status == 'paid' ? 'ORDER PAID' : 'ORDER SAVED'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Order #${order.id} processed successfully.', style: const TextStyle(fontSize: 13)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt, size: 20),
                    title: const Text('Customer Receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () => PrinterService.printCustomerReceipt(order),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restaurant, size: 20),
                    title: const Text('Kitchen Ticket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () => PrinterService.printKitchenReceipt(order),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Divider(height: 1),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w800)),
                )
              ],
            ),
          );
        }
        if (context.mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final double amount;
  const _TotalLine({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Text('Rs. ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
