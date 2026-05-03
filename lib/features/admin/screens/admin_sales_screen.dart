import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/services/printer_service.dart';
import '../../../models/order.dart' as model;
import '../widgets/admin_shell.dart';
import '../../../core/theme/app_theme.dart';

class AdminSalesScreen extends StatefulWidget {
  const AdminSalesScreen({super.key});

  @override
  State<AdminSalesScreen> createState() => _AdminSalesScreenState();
}

class _AdminSalesScreenState extends State<AdminSalesScreen> {
  List<model.Order> _allOrders = [];
  List<model.Order> _filteredOrders = [];
  bool _isLoading = true;
  model.Order? _selectedOrder;
  final TextEditingController _searchController = TextEditingController();

  DateTimeRange? _dateRange;
  
  double _totalRevenue = 0.0;
  int _totalOrders = 0;
  List<MapEntry<String, int>> _topItems = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _filterOrders();
    }
  }

  void _clearDateRange() {
    setState(() {
      _dateRange = null;
    });
    _filterOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await DatabaseHelper.instance.getOrders();
    // Sort orders from newest to oldest
    orders.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    _allOrders = orders;
    _filterOrders();
    setState(() => _isLoading = false);
  }

  void _filterOrders() {
    final query = _searchController.text.trim().toLowerCase();
    
    // Filter list
    final filtered = _allOrders.where((order) {
      // Apply date filter
      if (_dateRange != null) {
        // A date range typically starts at 00:00 of start date, and we want to include until 23:59:59 of end date.
        final start = _dateRange!.start;
        // set end to the very end of the day
        final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59);
        
        if (order.dateTime.isBefore(start) || order.dateTime.isAfter(end)) {
          return false;
        }
      }
      
      // Apply query filter
      if (query.isNotEmpty) {
        if (!order.id.toString().contains(query) && !order.status.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Compute stats based on the filtered list
    double revenue = 0.0;
    int orderCount = 0;
    Map<String, int> productCounts = {};

    for (var o in filtered) {
      if (o.status == 'paid') {
        revenue += o.totalAmount;
        orderCount++;
        for (var item in o.items) {
          productCounts[item.productName] = (productCounts[item.productName] ?? 0) + item.quantity;
        }
      }
    }

    final sortedItems = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final topItems = sortedItems.take(3).toList(); // Show top 3

    if (_selectedOrder != null) {
      // Check if selected still exists in filtered
      if (!filtered.any((o) => o.id == _selectedOrder!.id)) {
        _selectedOrder = null;
      }
    }
    if (_selectedOrder == null && filtered.isNotEmpty) {
      _selectedOrder = filtered.first;
    }

    setState(() {
      _filteredOrders = filtered;
      _totalRevenue = revenue;
      _totalOrders = orderCount;
      _topItems = topItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Format date string for the range
    String dateRangeStr = 'ALL TIME';
    if (_dateRange != null) {
      final start = DateFormat('MMM dd, yyyy').format(_dateRange!.start);
      final end = DateFormat('MMM dd, yyyy').format(_dateRange!.end);
      dateRangeStr = (start == end) ? start : '$start – $end';
    }

    return AdminShell(
      pageTitle: 'Sales Reports & Analytics',
      pageSubtitle: 'View searchable order logs, stats, and revenue',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Search & Order list ─────────────────────────────────────────
          Container(
            width: 420,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(right: BorderSide(color: AppTheme.outline)),
            ),
            child: Column(
              children: [
                // Global Stats Header
                Container(
                  color: AppTheme.primary.withOpacity(0.04),
                  child: Column(
                    children: [
                      // Date range selector row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.outline)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: AppTheme.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  dateRangeStr,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (_dateRange != null)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: _clearDateRange,
                                    tooltip: 'Clear Date Filter',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    color: AppTheme.error,
                                  ),
                                if (_dateRange != null)
                                  const SizedBox(width: 8),
                                InkWell(
                                  onTap: _pickDateRange,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.outline),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      color: Colors.white,
                                    ),
                                    child: const Text('FILTER DATES', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TOTAL PAID ORDERS', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                                  const SizedBox(height: 4),
                                  Text('$_totalOrders', style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppTheme.outline),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TOTAL REVENUE', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                                  const SizedBox(height: 4),
                                  Text('Rs. ${_totalRevenue.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 20, color: AppTheme.secondary, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.outline)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Order ID or Status...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.search_off,
                                      size: 48, color: AppTheme.outline),
                                  SizedBox(height: 12),
                                  Text('No matching records found',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: AppTheme.textMuted)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredOrders.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final order = _filteredOrders[index];
                                final isSelected =
                                    _selectedOrder?.id == order.id;
                                return _SalesListTile(
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
                        Icon(Icons.plagiarism_outlined,
                            size: 56, color: AppTheme.outline),
                        SizedBox(height: 16),
                        Text('Select a record to view details',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppTheme.textMuted)),
                      ],
                    ),
                  )
                : _SalesDetailPane(
                    order: _selectedOrder!,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Order list tile ──────────────────────────────────────────────────────────

class _SalesListTile extends StatelessWidget {
  final model.Order order;
  final bool isSelected;
  final VoidCallback onTap;

  const _SalesListTile({
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
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
                    DateFormat('MMM dd, hh:mm a').format(order.dateTime),
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

// ─── Order detail pane (Read only) ────────────────────────────────────────────────────────

class _SalesDetailPane extends StatelessWidget {
  final model.Order order;

  const _SalesDetailPane({
    required this.order,
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
                        'Report: Order #${order.id}',
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
                        decoration: BoxDecoration(
                          color: isPaid ? AppTheme.secondary : AppTheme.warning,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
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
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
        // Total + Print Record action
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
                  const Text('TOTAL AMOUNT RECORDED',
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
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => PrinterService.printCustomerReceipt(order),
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('RE-PRINT RECORD'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.onSurface,
                        side: const BorderSide(color: AppTheme.outline),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radius)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
