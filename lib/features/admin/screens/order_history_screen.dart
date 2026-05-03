import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/services/printer_service.dart';
import '../../pos/providers/cart_provider.dart';
import '../../../models/order.dart' as model;
import '../widgets/admin_shell.dart';
import '../../../core/theme/app_theme.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<model.Order> _orders = [];
  bool _isLoading = true;
  model.Order? _selectedOrder;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await DatabaseHelper.instance.getOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
      // Auto-select first order
      if (_selectedOrder == null && orders.isNotEmpty) {
        _selectedOrder = orders.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Order History',
      pageSubtitle: 'View and manage past orders',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Order list ─────────────────────────────────────────
          Container(
            width: 380,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(right: BorderSide(color: AppTheme.outline)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppTheme.outline)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'ORDER HISTORY',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1.0,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadOrders,
                        icon: const Icon(Icons.refresh, size: 18),
                        color: AppTheme.textMuted,
                        tooltip: 'Refresh',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.receipt_long_outlined,
                                      size: 48, color: AppTheme.outline),
                                  SizedBox(height: 12),
                                  Text('No orders found',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: AppTheme.textMuted)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _orders.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final order = _orders[index];
                                final isSelected =
                                    _selectedOrder?.id == order.id;
                                return _OrderListTile(
                                  order: order,
                                  isSelected: isSelected,
                                  onTap: () => setState(
                                      () => _selectedOrder = order),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          // ── Right: Order detail pane ─────────────────────────────────
          Expanded(
            child: _selectedOrder == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.touch_app_outlined,
                            size: 56, color: AppTheme.outline),
                        SizedBox(height: 16),
                        Text('Select an order to view details',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppTheme.textMuted)),
                      ],
                    ),
                  )
                : _OrderDetailPane(
                    order: _selectedOrder!,
                    onStatusChanged: (order) async {
                      setState(() => _selectedOrder = order);
                      await _loadOrders();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Order list tile ──────────────────────────────────────────────────────────

class _OrderListTile extends StatelessWidget {
  final model.Order order;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrderListTile({
    required this.order,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = order.status == 'paid';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        color: isSelected
            ? AppTheme.primary.withOpacity(0.06)
            : Colors.transparent,
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 44,
              color: isPaid ? AppTheme.secondary : AppTheme.warning,
            ),
            const SizedBox(width: 12),
            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? AppTheme.secondary.withOpacity(0.08)
                              : AppTheme.warning.withOpacity(0.08),
                          border: Border.all(
                            color: isPaid
                                ? AppTheme.secondary.withOpacity(0.3)
                                : AppTheme.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          isPaid ? 'PAID' : 'UNPAID',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isPaid
                                ? AppTheme.secondary
                                : AppTheme.warning,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd · hh:mm a').format(order.dateTime),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rs. ${order.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color:
                    isPaid ? AppTheme.secondary : AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Order detail pane ────────────────────────────────────────────────────────

class _OrderDetailPane extends StatelessWidget {
  final model.Order order;
  final ValueChanged<model.Order?> onStatusChanged;

  const _OrderDetailPane({
    required this.order,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = order.status == 'paid';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detail header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          color: AppTheme.surface,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Order Details #${order.id}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        color:
                            isPaid ? AppTheme.secondary : AppTheme.warning,
                        child: Text(
                          order.status.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy – hh:mm a')
                        .format(order.dateTime),
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.textMuted),
                  ),
                  if (order.notes != null) ...[
                    const SizedBox(height: 4),
                    Text('Note: ${order.notes}',
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppTheme.onSurfaceVar,
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Items list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            itemCount: order.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          if (item.notes != null)
                            Text(
                              '↳ ${item.notes}',
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
                      'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
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
        // Total + actions
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.outline)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL AMOUNT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.textMuted,
                      )),
                  Text(
                    'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Kitchen slip
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => PrinterService.printKitchenReceipt(order),
                      icon: const Icon(Icons.restaurant, size: 16),
                      label: const Text('KITCHEN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.onSurfaceVar,
                        side: const BorderSide(color: AppTheme.outline),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Print
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => PrinterService.printCustomerReceipt(order),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('PRINT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.onSurfaceVar,
                        side: const BorderSide(color: AppTheme.outline),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                         final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('DELETE ORDER'),
                              content: Text('Delete Order #${order.id}? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pop(ctx, true), 
                                  child: const Text('DELETE')
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await DatabaseHelper.instance.deleteOrder(order.id!);
                            onStatusChanged(null);
                          }
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('DELETE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isPaid) ...[
                    // Pay & close
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await DatabaseHelper.instance
                              .updateOrderStatus(order.id!, 'paid');
                          final updated = await DatabaseHelper.instance
                              .getOrder(order.id!);
                          if (updated != null) {
                            PrinterService.printCustomerReceipt(updated);
                            onStatusChanged(updated);
                          }
                        },
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('PAY & CLOSE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
