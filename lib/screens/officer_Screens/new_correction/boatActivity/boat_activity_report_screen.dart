import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../services/api_services/officer_api_service.dart';

class BoatActivityReportScreen extends StatefulWidget {
  const BoatActivityReportScreen({super.key});

  @override
  State<BoatActivityReportScreen> createState() =>
      _BoatActivityReportScreenState();
}

class _BoatActivityReportScreenState
    extends State<BoatActivityReportScreen> {
  final OfficersApiService _api = OfficersApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  // Palette
  static const Color _primary = Color(0xFF1257C7);
  static const Color _primaryDark = Color(0xFF0F3D66);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMid = Color(0xFF475569);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _chartBlue = Color(0xFF12B5CB);

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  String _sortBy = 'catch';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

    final res = await _api.fetchBoatActivity(
      fromDate: _fmt(_fromDate),
      toDate: _fmt(_toDate),
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

  List<Map<String, dynamic>> get _visibleItems {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = _items;

    if (q.isNotEmpty) {
      list = list.where((b) {
        final name = (b['boat_name'] ?? '').toString().toLowerCase();
        final reg = (b['boat_reg_no'] ?? '').toString().toLowerCase();
        final owner = (b['owner_name'] ?? '').toString().toLowerCase();
        return name.contains(q) || reg.contains(q) || owner.contains(q);
      }).toList();
    }

    final copy = [...list];
    switch (_sortBy) {
      case 'voyages':
        copy.sort((a, b) => ((b['voyage_count'] as num?)?.toInt() ?? 0)
            .compareTo((a['voyage_count'] as num?)?.toInt() ?? 0));
        break;
      case 'sea_days':
        copy.sort((a, b) => ((b['sea_days'] as num?)?.toDouble() ?? 0)
            .compareTo((a['sea_days'] as num?)?.toDouble() ?? 0));
        break;
      case 'name':
        copy.sort((a, b) => (a['boat_name'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo((b['boat_name'] ?? '').toString().toLowerCase()));
        break;
      case 'catch':
      default:
        copy.sort((a, b) => ((b['total_catch_kg'] as num?)?.toDouble() ?? 0)
            .compareTo((a['total_catch_kg'] as num?)?.toDouble() ?? 0));
    }
    return copy;
  }

  int get _totalVoyages => _items.fold<int>(
      0, (s, e) => s + ((e['voyage_count'] as num?)?.toInt() ?? 0));

  int get _totalDepartures => _items.fold<int>(
      0, (s, e) => s + ((e['departures'] as num?)?.toInt() ?? 0));

  double get _totalSeaDays => _items.fold<double>(
      0, (s, e) => s + ((e['sea_days'] as num?)?.toDouble() ?? 0));

  double get _totalCatchKg => _items.fold<double>(
      0, (s, e) => s + ((e['total_catch_kg'] as num?)?.toDouble() ?? 0));

  List<Map<String, dynamic>> get _chartItems {
    final copy = [..._items];
    copy.sort((a, b) => ((b['total_catch_kg'] as num?)?.toDouble() ?? 0)
        .compareTo((a['total_catch_kg'] as num?)?.toDouble() ?? 0));
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
            'Boat Activity',
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _filterCard(),
            _summaryRow(),
            const Divider(height: 1, color: _divider),
            _bodyContent(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Filter Card ─────────────────────────────────────────
  Widget _filterCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Date row ──
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
          const SizedBox(height: 12),

          // ── Search field ──
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search boat / reg / owner...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
              ),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _primary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Sort + Chart row (side by side, same height) ──
          Row(
            children: [
              // Sort dropdown — 60% width
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more_rounded,
                        size: 20, color: _primary),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: _primary.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 12, right: 8),
                        child: Icon(Icons.sort_rounded,
                            size: 18, color: _primary),
                      ),
                      prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: _primary.withOpacity(0.25)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: _primary.withOpacity(0.25)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _primary, width: 1.4),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'catch',
                        child: Text('Catch'),
                      ),
                      DropdownMenuItem(
                        value: 'voyages',
                        child: Text('Voyages'),
                      ),
                      DropdownMenuItem(
                        value: 'sea_days',
                        child: Text('Sea days'),
                      ),
                      DropdownMenuItem(
                        value: 'name',
                        child: Text('Name'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _sortBy = v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Chart button — 40% width, same height
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _items.isEmpty ? null : _openChart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _divider,
                      disabledForegroundColor: _textLight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.bar_chart_rounded, size: 18),
                    label: const Text(
                      'Chart',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
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

  // ── Summary cards ───────────────────────────────────────
  Widget _summaryRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  label: 'Total catch (kg)',
                  value: _totalCatchKg.toStringAsFixed(2),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  label: 'Boats',
                  value: '${_items.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  label: 'Sea days',
                  value: _totalSeaDays.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  label: 'Departures',
                  value: '$_totalDepartures',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textMid,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
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
  Widget _bodyContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final items = _visibleItems;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Center(
          child: Text(
            _items.isEmpty
                ? 'No boat activity in this range.'
                : 'No boats match your search.',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _boatTile(items[i]),
          ],
        ],
      ),
    );
  }

  // ── Boat tile ───────────────────────────────────────────
  Widget _boatTile(Map<String, dynamic> b) {
    final name = b['boat_name']?.toString() ?? '—';
    final reg = b['boat_reg_no']?.toString() ?? '';
    final owner = b['owner_name']?.toString() ?? '';
    final voyages = (b['voyage_count'] as num?)?.toInt() ?? 0;
    final departures = (b['departures'] as num?)?.toInt() ?? 0;
    final completed = (b['completed'] as num?)?.toInt() ?? 0;
    final seaDays = (b['sea_days'] as num?)?.toDouble() ?? 0;
    final catchKg = (b['total_catch_kg'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.directions_boat_rounded,
                    color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reg.isEmpty ? owner : '$reg · $owner',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${catchKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _statBadge(Icons.sailing_rounded, 'Voyages',
                  '$voyages', _primary),
              _statBadge(Icons.flight_takeoff_rounded, 'Departures',
                  '$departures', const Color(0xFF0891B2)),
              _statBadge(Icons.check_circle_rounded, 'Completed',
                  '$completed', const Color(0xFF059669)),
              _statBadge(Icons.waves_rounded, 'Sea days',
                  seaDays.toStringAsFixed(2), const Color(0xFF7C3AED)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(
      IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          '$label ',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _textLight,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // VIEW CHART
  // ═══════════════════════════════════════════════════════════
  void _openChart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => _BoatChartSheet(
          controller: ctrl,
          items: _chartItems,
          totalKg: _totalCatchKg,
          chartBlue: _chartBlue,
        ),
      ),
    );
  }
}
// CHART SHEET — Vertical bars, boat names straight below each bar
// ═══════════════════════════════════════════════════════════════
class _BoatChartSheet extends StatelessWidget {
  final ScrollController controller;
  final List<Map<String, dynamic>> items;
  final double totalKg;
  final Color chartBlue;

  const _BoatChartSheet({
    required this.controller,
    required this.items,
    required this.totalKg,
    required this.chartBlue,
  });

  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMid = Color(0xFF475569);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _primaryDark = Color(0xFF0F3D66);

  double _catchOf(Map<String, dynamic> e) =>
      (e['total_catch_kg'] as num?)?.toDouble() ?? 0;

  String _nameOf(Map<String, dynamic> e) =>
      e['boat_name']?.toString() ?? '—';

  /// Short, readable label — first word only so names never wrap.
  String _short(String s) {
    final t = s.trim();
    if (t.isEmpty) return '—';
    final first = t.split(RegExp(r'\s+')).first;
    if (first.length <= 12) return first;
    return '${first.substring(0, 11)}…';
  }

  @override
  Widget build(BuildContext context) {
    // Sort DESC (largest first) so bars go left → right by size.
    final sorted = [...items]
      ..sort((a, b) => _catchOf(b).compareTo(_catchOf(a)));

    final maxKg = sorted.isEmpty
        ? 10.0
        : sorted.map(_catchOf).fold<double>(0, (a, b) => a > b ? a : b);
    final step = _niceStep(maxKg);
    final yMax = ((maxKg / step).ceil() * step).toDouble().clamp(
      step,
      double.infinity,
    );

    // Width per bar so labels don't overlap.
    final barAreaWidth = (sorted.length * 56.0).clamp(280.0, 900.0);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: _divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
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
                        'Top Boats by Catch',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total ${totalKg.toStringAsFixed(2)} kg across ${items.length} boats',
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

          // Body
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // ── Chart: scroll horizontally if many boats ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: barAreaWidth,
                    height: 320,
                    child: BarChart(
                      BarChartData(
                        maxY: yMax,
                        minY: 0,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: step,
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
                          // Y-axis: numeric values (0, 1, 2, 3, 4, 5…)
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: step,
                              getTitlesWidget: (v, meta) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: _textLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // X-axis: boat names straight (no rotation)
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 46,
                              getTitlesWidget: (v, meta) {
                                final i = v.toInt();
                                if (i < 0 || i >= sorted.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _short(_nameOf(sorted[i])),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _textMid,
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                              final item = sorted[group.x.toInt()];
                              return BarTooltipItem(
                                '${_nameOf(item)}\n',
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
                        barGroups: List.generate(sorted.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: _catchOf(sorted[i]),
                                color: chartBlue,
                                width: 22,
                                borderRadius:
                                const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Data table (unchanged) ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'BOAT',
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
                          'CATCH (KG)',
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
                ...sorted.map((e) {
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
                            _nameOf(e),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _catchOf(e).toStringAsFixed(2),
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

  /// Nice y-axis step (1 / 2 / 5 / 10 / 20 / 50 …).
  double _niceStep(double maxKg) {
    if (maxKg <= 5) return 1;
    if (maxKg <= 10) return 2;
    if (maxKg <= 25) return 5;
    if (maxKg <= 50) return 10;
    if (maxKg <= 100) return 20;
    if (maxKg <= 250) return 50;
    if (maxKg <= 500) return 100;
    return 200;
  }
}