import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../services/api_services/officer_api_service.dart';

class FishCatchReportScreen extends StatefulWidget {
  const FishCatchReportScreen({super.key});

  @override
  State<FishCatchReportScreen> createState() =>
      _FishCatchReportScreenState();
}

class _FishCatchReportScreenState extends State<FishCatchReportScreen> {
  final OfficersApiService _api = OfficersApiService();

  // Palette
  static const Color _primary = Color(0xFF1257C7);
  static const Color _primaryDark = Color(0xFF0F3D66); // deep navy (web)
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMid = Color(0xFF475569);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _chartBlue = Color(0xFF12B5CB); // matches web bars

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _groupBy = 'species';

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmt(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _api.fetchFishCatchReport(
      fromDate: _fmt(_fromDate),
      toDate: _fmt(_toDate),
      groupBy: _groupBy,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _items = OfficersApiService.extractList(res);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Failed to load report';
        _loading = false;
      });
    }
  }

  // ── Aggregations ────────────────────────────────────────
  double get _totalKg => _items.fold<double>(
      0, (s, e) => s + ((e['total_weight_kg'] as num?)?.toDouble() ?? 0));

  int get _totalQty => _items.fold<int>(
      0, (s, e) => s + ((e['total_quantity'] as num?)?.toInt() ?? 0));

  int get _totalVoyages => _items.fold<int>(
      0, (s, e) => s + ((e['voyage_count'] as num?)?.toInt() ?? 0));

  double _weightOf(Map<String, dynamic> e) =>
      (e['total_weight_kg'] as num?)?.toDouble() ?? 0;

  int _qtyOf(Map<String, dynamic> e) =>
      (e['total_quantity'] as num?)?.toInt() ?? 0;

  int _voyagesOf(Map<String, dynamic> e) =>
      (e['voyage_count'] as num?)?.toInt() ?? 0;

  String _labelOf(Map<String, dynamic> e) =>
      e['group_label']?.toString() ?? '—';

  /// Top N groups by weight for the chart.
  List<Map<String, dynamic>> get _chartItems {
    final copy = [..._items];
    copy.sort((a, b) => _weightOf(b).compareTo(_weightOf(a)));
    return copy.take(8).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Text(
            'Fish Catch Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: _primary,
        child: Column(
          children: [
            _filterCard(),
            _summaryRow(),
            const SizedBox(height: 4),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  // ── Filter Card (dates + group by + search + view chart) ─
  Widget _filterCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dateChip(
                  label: 'From date',
                  value: _fmt(_fromDate),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _fromDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) {
                      setState(() => _fromDate = d);
                      _load();
                    }
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: _textLight),
              ),
              Expanded(
                child: _dateChip(
                  label: 'To date',
                  value: _fmt(_toDate),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _toDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) {
                      setState(() => _toDate = d);
                      _load();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _groupByDropdown(),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDark,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _items.isEmpty ? null : _openChart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: BorderSide(color: _primary.withOpacity(0.4)),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.bar_chart_rounded, size: 18),
                  label: const Text(
                    'View Chart',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateChip({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _primary.withOpacity(0.04),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _primary.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: _primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupByDropdown() {
    return DropdownButtonFormField<String>(
      value: _groupBy,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'species', child: Text('Species')),
        DropdownMenuItem(value: 'port', child: Text('Port')),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() => _groupBy = v);
        _load();
      },
    );
  }

  // ── Summary Cards (Total catch + Voyages) ────────────────
  Widget _summaryRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              label: 'Total catch (kg)',
              value: _totalKg.toStringAsFixed(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
              label: 'Voyages',
              value: '$_totalVoyages',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _textMid,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _textDark,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────
  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('No catch data for this range.',
            style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _tableHeader(),
        const SizedBox(height: 6),
        ..._items.map(_tableRow),
      ],
    );
  }

  // ── Table Header (dark navy, matches web) ────────────────
  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 5,
            child: Text(
              'GROUP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'WEIGHT (KG)',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'QUANTITY',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'VOYAGES',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> e) {
    final label = _labelOf(e);
    final weight = _weightOf(e);
    final qty = _qtyOf(e);
    final voyages = _voyagesOf(e);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              weight.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$qty',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$voyages',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // VIEW CHART — bottom sheet with bar chart
  // ═══════════════════════════════════════════════════════════
  void _openChart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => _ChartSheet(
          controller: ctrl,
          items: _chartItems,
          totalKg: _totalKg,
          groupBy: _groupBy,
          chartBlue: _chartBlue,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CHART SHEET
// ═══════════════════════════════════════════════════════════════
class _ChartSheet extends StatelessWidget {
  final ScrollController controller;
  final List<Map<String, dynamic>> items;
  final double totalKg;
  final String groupBy;
  final Color chartBlue;

  const _ChartSheet({
    required this.controller,
    required this.items,
    required this.totalKg,
    required this.groupBy,
    required this.chartBlue,
  });

  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMid = Color(0xFF475569);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _primaryDark = Color(0xFF0F3D66);

  double _weightOf(Map<String, dynamic> e) =>
      (e['total_weight_kg'] as num?)?.toDouble() ?? 0;

  String _labelOf(Map<String, dynamic> e) =>
      e['group_label']?.toString() ?? '—';

  /// Short label for x-axis (first word or two).
  String _short(String s) {
    final words = s.split(' ');
    if (words.length <= 2) return s;
    return '${words[0]} ${words[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final maxKg = items.isEmpty
        ? 100.0
        : items
        .map(_weightOf)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final yMax = (maxKg * 1.2).ceilToDouble();

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Column(
        children: [
          // drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: _divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    color: _primaryDark, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catch by Group',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Grouped by ${groupBy[0].toUpperCase()}${groupBy.substring(1)}  •  Total ${totalKg.toStringAsFixed(2)} kg',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: _textMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _divider),
          // chart
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 20),
              children: [
                SizedBox(
                  height: 320,
                  child: BarChart(
                    BarChartData(
                      maxY: yMax,
                      minY: 0,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yMax / 4,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: _divider,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: yMax / 4,
                            getTitlesWidget: (v, meta) => Text(
                              v.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: _textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 54,
                            getTitlesWidget: (v, meta) {
                              final i = v.toInt();
                              if (i < 0 || i >= items.length) {
                                return const SizedBox.shrink();
                              }
                              final label = _short(_labelOf(items[i]));
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: SizedBox(
                                  width: 70,
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: _textMid,
                                      height: 1.15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => _primaryDark,
                          getTooltipItem:
                              (group, groupIndex, rod, rodIndex) {
                            final item = items[group.x.toInt()];
                            return BarTooltipItem(
                              '${_labelOf(item)}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                  '${rod.toY.toStringAsFixed(2)} kg',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      barGroups: List.generate(items.length, (i) {
                        final w = _weightOf(items[i]);
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: w,
                              color: chartBlue,
                              width: 22,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Data table below the chart
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'GROUP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'WEIGHT (KG)',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ...items.map((e) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _divider),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            _labelOf(e),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _weightOf(e).toStringAsFixed(2),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}