// lib/officer/screens/citings_summary_screen.dart

import 'package:flutter/material.dart';
import '../../../../services/api_services/officer_api_service.dart';
import 'citings_details_sheet.dart';

class CitingsSummaryScreen extends StatefulWidget {
  const CitingsSummaryScreen({super.key});

  @override
  State<CitingsSummaryScreen> createState() => _CitingsSummaryScreenState();
}

class _CitingsSummaryScreenState extends State<CitingsSummaryScreen> {
  final OfficersApiService _api = OfficersApiService();
  final _searchCtrl = TextEditingController();

  // Palette
  static const Color _primary = Color(0xFF1257C7);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMid = Color(0xFF475569);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _warning = Color(0xFFD97706);
  static const Color _info = Color(0xFF0891B2);

  // Data
  List<Map<String, dynamic>> _rawItems = [];
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _loadingCounts = false;
  String? _error;

  int _page = 1;
  final int _limit = 50;

  // Filters
  String? _typeFilter;
  late DateTime _fromDate;
  late DateTime _toDate;

  // Counts
  int _allCount = 0;
  final Map<String, int> _typeCounts = {};
  final Set<String> _discoveredTypes = {};

  // ═══════════════════════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate = now;
    _fromDate = now.subtract(const Duration(days: 30));
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // DATE HELPERS
  // ═══════════════════════════════════════════════════════════
  String? _fmt(DateTime? d) {
    if (d == null) return null;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  DateTime? _citingDate(Map<String, dynamic> v) {
    // ✅ Try the columns the API most likely filters on first,
    //    then fall back to creation timestamps.
    final candidates = [
      v['citing_datetime'],
      v['citing_date'],
      v['sighted_at'],
      v['reported_at'],
      v['created_at'],
      v['created_date'],
    ];
    for (final raw in candidates) {
      if (raw == null) continue;
      final s = raw.toString().trim();
      if (s.isEmpty) continue;
      try {
        return DateTime.parse(s.replaceFirst(' ', 'T')).toLocal();
      } catch (_) {
        try {
          final parts = s.split(' ').first.split('-');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        } catch (_) {}
      }
    }
    return null;
  }

  bool _inDateRange(DateTime? d) {
    if (d == null) return false;
    final from = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
    final to = DateTime(_toDate.year, _toDate.month, _toDate.day)
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    return !d.isBefore(from) && !d.isAfter(to);
  }

  // ═══════════════════════════════════════════════════════════
  // LOCAL FILTER (search + type only — dates handled by _bootstrap)
  // ═══════════════════════════════════════════════════════════
  void _applyLocalFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = _rawItems.where((v) {
      if (!_inDateRange(_citingDate(v))) return false;
      if (_typeFilter != null && _typeOf(v) != _typeFilter) return false;

      if (q.isNotEmpty) {
        final haystack = [
          v['citing_ref_no'],
          v['reference_no'],
          v['boat_reg_no'],
          v['boat_name'],
          v['reported_by_name'],
          v['citing_type'],
          v['illegal_activity_type'],
          v['remarks'],
          v['citing_status'],
          v['photo_path'],
          v['latitude'],
          v['longitude'],
        ]
            .where((e) => e != null)
            .map((e) => e.toString().toLowerCase())
            .join(' ');
        if (!haystack.contains(q)) return false;
      }

      return true;
    }).toList();

    setState(() {
      _items = filtered;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // BOOTSTRAP — fetches for the CURRENT _fromDate / _toDate
  // ═══════════════════════════════════════════════════════════
  Future<void> _bootstrap() async {
    // ✅ Clear stale data so old rows don't linger while a
    //    new fetch is in flight (or if it fails).
    setState(() {
      _loading = true;
      _loadingCounts = true;
      _error = null;
      _rawItems = [];
      _items = [];
      _allCount = 0;
      _typeCounts.clear();
      _discoveredTypes.clear();
      _page = 1;
    });

    final allItems = <Map<String, dynamic>>[];
    int page = 1;
    int? serverTotal;
    bool hasMore = true;
    const pageSize = 100;

    while (hasMore && page <= 200) {
      final res = await _api.fetchCitings(
        fromDate: _fmt(_fromDate),
        toDate: _fmt(_toDate),
        page: page,
        limit: pageSize,
      );

      if (!mounted) return;

      if (res['success'] != true) {
        if (page == 1) {
          setState(() {
            _error = res['message']?.toString() ?? 'Failed to load Citings';
            _loading = false;
            _loadingCounts = false;
          });
          return;
        }
        break;
      }

      final list = OfficersApiService.extractList(res);
      final meta = OfficersApiService.extractPagination(res);
      serverTotal = meta['total'] ?? serverTotal;

      allItems.addAll(list);

      if (list.isEmpty) {
        hasMore = false;
      } else if (list.length < pageSize) {
        hasMore = false;
      } else {
        if (serverTotal != null && allItems.length >= serverTotal) {
          hasMore = false;
        } else {
          page++;
        }
      }
    }

    final discovered = <String>{};
    final counts = <String, int>{};
    for (final v in allItems) {
      final t = _typeOf(v);
      if (t.isEmpty || t == 'UNKNOWN') continue;
      discovered.add(t);
      counts[t] = (counts[t] ?? 0) + 1;
    }

    if (!mounted) return;

    setState(() {
      _allCount = allItems.length;
      _rawItems = allItems;
      _typeCounts
        ..clear()
        ..addAll(counts);
      _discoveredTypes
        ..clear()
        ..addAll(discovered);
      _loading = false;
      _loadingCounts = false;
    });

    _applyLocalFilters();
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  String _typeOf(Map<String, dynamic> v) {
    final t = v['citing_type'];
    if (t == null) return 'UNKNOWN';
    final s = t.toString().trim().toUpperCase();
    return s.isEmpty ? 'UNKNOWN' : s;
  }

  Color _typeColor(String t) {
    switch (t.toUpperCase()) {
      case 'ILLEGAL_ACTIVITY':
        return _danger;
      case 'OTHER_STATE_BOAT':
        return _warning;
      case 'FOREIGN_BOAT':
        return const Color(0xFF7C3AED);
      case 'BANNED_SPECIES':
        return const Color(0xFF0891B2);
      case 'POLLUTION':
        return const Color(0xFF16A34A);
      case 'OTHER':
        return _textMid;
      default:
        return _textMid;
    }
  }

  IconData _typeIcon(String t) {
    switch (t.toUpperCase()) {
      case 'ILLEGAL_ACTIVITY':
        return Icons.gavel_rounded;
      case 'OTHER_STATE_BOAT':
        return Icons.directions_boat_rounded;
      case 'FOREIGN_BOAT':
        return Icons.public_rounded;
      case 'BANNED_SPECIES':
        return Icons.block_rounded;
      case 'POLLUTION':
        return Icons.water_drop_rounded;
      case 'OTHER':
        return Icons.info_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  List<String> get _visibleTypes {
    final list = _discoveredTypes.toList();
    list.sort();
    return list;
  }

  /// Tile counts respect the current search AND the current date range.
  int _liveCount(String? t) {
    final q = _searchCtrl.text.trim().toLowerCase();

    bool matchesSearch(Map<String, dynamic> v) {
      if (q.isEmpty) return true;
      final haystack = [
        v['citing_ref_no'],
        v['reference_no'],
        v['boat_reg_no'],
        v['boat_name'],
        v['reported_by_name'],
        v['citing_type'],
        v['illegal_activity_type'],
        v['remarks'],
        v['citing_status'],
        v['photo_path'],
        v['latitude'],
        v['longitude'],
      ]
          .where((e) => e != null)
          .map((e) => e.toString().toLowerCase())
          .join(' ');
      return haystack.contains(q);
    }

    final dateFiltered =
    _rawItems.where((v) => _inDateRange(_citingDate(v))).toList();

    if (t == null) {
      return dateFiltered.where(matchesSearch).length;
    }

    return dateFiltered
        .where((v) => _typeOf(v) == t && matchesSearch(v))
        .length;
  }

  String _pretty(String s) {
    return s
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _prettyDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso.replaceFirst(' ', 'T')).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final d = dt.day.toString().padLeft(2, '0');
      final m = months[dt.month - 1];
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$d $m · $hh:$mm';
    } catch (_) {
      return iso.length >= 16 ? iso.substring(0, 16) : iso;
    }
  }

  int _i(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Citings',
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
            onPressed: _bootstrap,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _bootstrap,
        color: _primary,
        child: Column(
          children: [
            _dateRow(),
            _searchBar(),
            _typeSquares(),
            const Divider(height: 1, color: _divider),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _dateRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _dateChip(
              label: 'From',
              value: _fmt(_fromDate) ?? '—',
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _fromDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d == null) return;
                setState(() {
                  _fromDate = d;
                  _typeFilter = null;
                });
                // ✅ RE-FETCH from the server with the new range.
                await _bootstrap();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dateChip(
              label: 'To',
              value: _fmt(_toDate) ?? '—',
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _toDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d == null) return;
                setState(() {
                  _toDate = d;
                  _typeFilter = null;
                });
                // ✅ RE-FETCH from the server with the new range.
                await _bootstrap();
              },
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Reset to last 30 days',
            child: Material(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final now = DateTime.now();
                  setState(() {
                    _toDate = now;
                    _fromDate = now.subtract(const Duration(days: 30));
                    _typeFilter = null;
                  });
                  // ✅ RE-FETCH after reset too.
                  await _bootstrap();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: _primary),
                ),
              ),
            ),
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
      color: _primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _primary.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: _primary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
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

  Widget _searchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => _applyLocalFilters(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search ref / boat / reporter / type...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              _searchCtrl.clear();
              _applyLocalFilters();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _typeSquares() {
    final types = _visibleTypes;

    if (types.isEmpty && _loading) {
      return const SizedBox(height: 96);
    }

    final tiles = <Widget>[];

    tiles.add(
      _typeSquare(
        label: 'All',
        count: _liveCount(null),
        icon: Icons.apps_rounded,
        color: _primary,
        selected: _typeFilter == null,
        loading: _loadingCounts,
        onTap: () {
          if (_typeFilter == null) return;
          setState(() => _typeFilter = null);
          _applyLocalFilters();
        },
      ),
    );

    for (final t in types) {
      tiles.add(const SizedBox(width: 10));
      tiles.add(
        _typeSquare(
          label: _pretty(t),
          count: _liveCount(t),
          icon: _typeIcon(t),
          color: _typeColor(t),
          selected: _typeFilter == t,
          loading: _loadingCounts,
          onTap: () {
            setState(() => _typeFilter = _typeFilter == t ? null : t);
            _applyLocalFilters();
          },
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: tiles,
        ),
      ),
    );
  }

  Widget _typeSquare({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool selected,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? color.withOpacity(0.12) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : _divider,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 26,
                    width: 26,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: color),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 20,
                child: loading
                    ? Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                )
                    : Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              onPressed: _bootstrap,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final items = _items;

    if (items.isEmpty) {
      return const Center(
        child: Text('No citings found.',
            style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _citingTile(items[i]),
    );
  }

  Widget _citingTile(Map<String, dynamic> v) {
    final ref = v['citing_ref_no']?.toString() ?? '—';
    final intRef = v['reference_no']?.toString() ?? '';
    final boatReg = v['boat_reg_no']?.toString() ?? '';
    final reportedBy = v['reported_by_name']?.toString() ?? '';
    final type = _typeOf(v);
    final typeColor = _typeColor(type);
    final dt = _prettyDate(v['citing_datetime']?.toString());
    final remarks = v['remarks']?.toString() ?? '';
    final illegalType = v['illegal_activity_type']?.toString() ?? '';
    final sightedCount = _i(v['sighted_boat_count']);
    final status = v['citing_status']?.toString() ?? 'REPORTED';
    final lat = (v['latitude'] as num?)?.toDouble();
    final lng = (v['longitude'] as num?)?.toDouble();

    final hasLocation =
        lat != null && lng != null && lat != 0 && lng != 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetails(v),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ref,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _pretty(type),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.directions_boat_rounded,
                      size: 14, color: _primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      boatReg.isEmpty ? '—' : boatReg,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (reportedBy.isNotEmpty)
                    Text(
                      'by $reportedBy',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textLight,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 13, color: _textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dt,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _textMid,
                      ),
                    ),
                  ),
                ],
              ),
              if (intRef.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.tag_rounded,
                        size: 13, color: _textLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        intRef,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1, color: _divider),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _miniStat(
                    icon: Icons.directions_boat_filled_rounded,
                    label: 'Sighted',
                    value: '$sightedCount',
                    color: _info,
                  ),
                  if (illegalType.isNotEmpty && illegalType != 'null')
                    _miniStat(
                      icon: Icons.warning_amber_rounded,
                      label: 'Activity',
                      value: _pretty(illegalType),
                      color: _warning,
                    ),
                  _miniStat(
                    icon: Icons.verified_rounded,
                    label: 'Status',
                    value: _pretty(status),
                    color: _success,
                  ),
                  if (hasLocation)
                    _miniStat(
                      icon: Icons.location_on_rounded,
                      label: '',
                      value:
                      '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}',
                      color: _danger,
                    ),
                ],
              ),
              if (remarks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes_rounded,
                          size: 13, color: _textMid),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          remarks,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _textMid,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openDetails(v),
                  style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 15),
                  label: const Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        if (label.isNotEmpty)
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

  void _openDetails(Map<String, dynamic> v) {
    final citingId = _i(v['citing_id']);
    if (citingId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid citing ID'),
          backgroundColor: _danger,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, ctrl) {
            return CitingDetailsSheet(
              citingId: citingId,
              initial: v,
              controller: ctrl,
            );
          },
        );
      },
    );
  }
}