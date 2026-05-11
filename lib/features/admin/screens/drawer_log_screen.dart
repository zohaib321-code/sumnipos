import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_shell.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/drawer_log.dart';

class DrawerLogScreen extends StatefulWidget {
  const DrawerLogScreen({super.key});

  @override
  State<DrawerLogScreen> createState() => _DrawerLogScreenState();
}

class _DrawerLogScreenState extends State<DrawerLogScreen> {
  List<DrawerLog> _logs = [];
  bool _loading = true;
  String _reasonFilter = 'all';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await DatabaseHelper.instance.getDrawerLogs(
      from: _dateRange?.start,
      to: _dateRange?.end == null
          ? null
          : DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59),
      reason: _reasonFilter == 'all' ? null : _reasonFilter,
    );
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      _dateRange = picked;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('yyyy-MM-dd  HH:mm:ss');

    return AdminShell(
      pageTitle: 'CASH DRAWER LOG',
      pageSubtitle: 'All drawer open events',
      child: Column(
        children: [
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(
              children: [
                _filterChip('All', 'all'),
                const SizedBox(width: 8),
                _filterChip('Manual', DrawerLog.reasonManual),
                const SizedBox(width: 8),
                _filterChip('Sale Paid', DrawerLog.reasonSalePaid),
                const SizedBox(width: 8),
                _filterChip('Test', DrawerLog.reasonTest),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _dateRange == null
                        ? 'ALL DATES'
                        : '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d').format(_dateRange!.end)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.6),
                  ),
                ),
                if (_dateRange != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      _dateRange = null;
                      _load();
                    },
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Clear date range',
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No drawer events for this filter.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final log = _logs[i];
                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                _reasonBadge(log.reason),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        timeFormat.format(log.timestamp),
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                      if (log.orderId != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Order #${log.orderId}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '#${log.id}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _reasonFilter == value;
    return InkWell(
      onTap: () {
        setState(() => _reasonFilter = value);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.outline),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: selected ? Colors.white : AppTheme.onSurfaceVar,
          ),
        ),
      ),
    );
  }

  Widget _reasonBadge(String reason) {
    Color color;
    String label;
    IconData icon;
    switch (reason) {
      case DrawerLog.reasonSalePaid:
        color = AppTheme.primary;
        label = 'SALE PAID';
        icon = Icons.point_of_sale;
        break;
      case DrawerLog.reasonTest:
        color = Colors.blueGrey;
        label = 'TEST';
        icon = Icons.science_outlined;
        break;
      case DrawerLog.reasonManual:
      default:
        color = AppTheme.warning;
        label = 'MANUAL';
        icon = Icons.pan_tool_alt_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
