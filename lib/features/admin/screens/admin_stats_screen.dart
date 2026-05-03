import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/db/database_helper.dart';
import '../../../models/order.dart' as model;
import '../widgets/admin_shell.dart';
import '../../../core/theme/app_theme.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  List<model.Order> _allOrders = [];
  bool _isLoading = true;
  DateTimeRange? _dateRange;

  // Stats
  double _totalRevenue = 0.0;
  int _totalOrders = 0;
  int _paidOrders = 0;
  int _unpaidOrders = 0;
  double _averageOrderValue = 0.0;
  List<MapEntry<String, int>> _topItems = [];
  List<MapEntry<String, double>> _topRevenueItems = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await DatabaseHelper.instance.getOrders();
    _allOrders = orders;
    _calculateStats();
    setState(() => _isLoading = false);
  }

  void _calculateStats() {
    // 1. Filter by date if active
    final filtered = _allOrders.where((order) {
      if (_dateRange != null) {
        final start = _dateRange!.start;
        final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59);
        if (order.dateTime.isBefore(start) || order.dateTime.isAfter(end)) return false;
      }
      return true;
    }).toList();

    // 2. Calculations
    double revenue = 0.0;
    int paid = 0;
    int unpaid = 0;
    Map<String, int> productCounts = {};
    Map<String, double> productRevenue = {};

    for (var o in filtered) {
      if (o.status == 'paid') {
        revenue += o.totalAmount;
        paid++;
        for (var item in o.items) {
          productCounts[item.productName] = (productCounts[item.productName] ?? 0) + item.quantity;
          productRevenue[item.productName] = (productRevenue[item.productName] ?? 0.0) + (item.quantity * item.price);
        }
      } else {
        unpaid++;
      }
    }

    final topItemsSorted = productCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topRevenueSorted = productRevenue.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _totalOrders = filtered.length;
      _paidOrders = paid;
      _unpaidOrders = unpaid;
      _totalRevenue = revenue;
      _averageOrderValue = paid > 0 ? revenue / paid : 0.0;
      _topItems = topItemsSorted.take(10).toList(); // top 10 by volume
      _topRevenueItems = topRevenueSorted.take(10).toList(); // top 10 by revenue
    });
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
      setState(() => _dateRange = picked);
      _calculateStats();
    }
  }

  void _clearDateRange() {
    setState(() => _dateRange = null);
    _calculateStats();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AdministratorShell(child: const Center(child: CircularProgressIndicator()));
    }

    String dateRangeStr = 'ALL TIME';
    if (_dateRange != null) {
      final start = DateFormat('MMM dd, yyyy').format(_dateRange!.start);
      final end = DateFormat('MMM dd, yyyy').format(_dateRange!.end);
      dateRangeStr = (start == end) ? start : '$start – $end';
    }

    return AdministratorShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Filter Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.outline)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppTheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ANALYTICS DASHBOARD', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        Text('Report Range: $dateRangeStr', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_dateRange != null)
                      TextButton.icon(
                        onPressed: _clearDateRange,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('CLEAR FILTER'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range, size: 16),
                      label: const Text('SELECT DATE RANGE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dash Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Cards
                  Row(
                    children: [
                      Expanded(child: _KpiCard(title: 'GROSS REVENUE', value: 'Rs. ${_totalRevenue.toStringAsFixed(0)}', icon: Icons.payments_outlined, color: AppTheme.secondary)),
                      const SizedBox(width: 16),
                      Expanded(child: _KpiCard(title: 'PAID ORDERS', value: '$_paidOrders', icon: Icons.receipt_long, color: AppTheme.primary)),
                      const SizedBox(width: 16),
                      Expanded(child: _KpiCard(title: 'UNPAID/OPEN ORDERS', value: '$_unpaidOrders', icon: Icons.pending_actions, color: AppTheme.warning)),
                      const SizedBox(width: 16),
                      Expanded(child: _KpiCard(title: 'AVG ORDER VALUE', value: 'Rs. ${_averageOrderValue.toStringAsFixed(0)}', icon: Icons.trending_up, color: Colors.indigo)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Charts / Lists
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Items (Volume)
                      Expanded(
                        child: _StatWidgetContainer(
                          title: 'TOP 10 ITEMS (BY VOLUME)',
                          child: _topItems.isEmpty
                            ? const Padding(padding: EdgeInsets.all(24), child: Text('No data found for this period.', style: TextStyle(color: AppTheme.textMuted)))
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _topItems.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final item = _topItems[i];
                                  return ListTile(
                                    leading: CircleAvatar(backgroundColor: AppTheme.primary.withOpacity(0.1), radius: 14, child: Text('${i+1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary))),
                                    title: Text(item.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    trailing: Text('${item.value} units', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  );
                                },
                              ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Top Items (Revenue)
                      Expanded(
                        child: _StatWidgetContainer(
                          title: 'TOP 10 ITEMS (BY REVENUE)',
                          child: _topRevenueItems.isEmpty
                            ? const Padding(padding: EdgeInsets.all(24), child: Text('No data found for this period.', style: TextStyle(color: AppTheme.textMuted)))
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _topRevenueItems.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final item = _topRevenueItems[i];
                                  return ListTile(
                                    leading: CircleAvatar(backgroundColor: AppTheme.secondary.withOpacity(0.1), radius: 14, child: Text('${i+1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary))),
                                    title: Text(item.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    trailing: Text('Rs. ${item.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                                  );
                                },
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _StatWidgetContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatWidgetContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceVariant,
              border: Border(bottom: BorderSide(color: AppTheme.outline)),
            ),
            child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
          child,
        ],
      ),
    );
  }
}

class AdministratorShell extends StatelessWidget {
  final Widget child;
  const AdministratorShell({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Business Analytics',
      pageSubtitle: 'Detailed statistical reports of store operations',
      child: child,
    );
  }
}
