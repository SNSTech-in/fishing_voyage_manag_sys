import 'package:flutter/material.dart';
import '../../../../services/api_services/officer_api_service.dart';
import 'voyage_details_screen.dart';

class VoyagesSummaryScreen extends StatefulWidget {
  const VoyagesSummaryScreen({super.key});

  @override
  State<VoyagesSummaryScreen> createState() => _VoyagesSummaryScreenState();
}

class _VoyagesSummaryScreenState extends State<VoyagesSummaryScreen> {
  final OfficersApiService _api = OfficersApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  // ═══════════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════════
  static const Color _primary = Color(0xFF1257C7);
  static const Color _primaryDark = Color(0xFF07347F);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMid = Color(0xFF475569);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _warning = Color(0xFFD97706);
  static const Color _info = Color(0xFF0891B2);

  // ═══════════════════════════════════════════════════════════
  // DATA
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> _items = [];

  bool _loading = true;
  bool _loadingCounts = false;
  String? _error;

  String? _statusFilter;
  late DateTime _fromDate;
  late DateTime _toDate;

  // ═══════════════════════════════════════════════════════════
  // FULL DATASET (unfiltered)
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> _allVoyages = [];

  // Fixed totals — never change on filter click
  int _allCount = 0;
  final Map<String, int> _statusCounts = {};
  Set<String> _discoveredStatuses = {};

  // ═══════════════════════════════════════════════════════════
  // PAGINATION
  // ═══════════════════════════════════════════════════════════
  static const int _limit = 50;

  // ═══════════════════════════════════════════════════════════
  // STATUS ORDER
  // ═══════════════════════════════════════════════════════════
  static const List<String> _preferredOrder = [
    'ONGOING',
    'AT SEA',
    'OVERDUE',
    'NOT_DEPARTED',
    'NOT STARTED',
    'UPCOMING',
    'COMPLETED',
    'CANCELLED',
  ];

  // ═══════════════════════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    // ✅ ONLY CHANGE: From is fixed to 1 Aug 2026; To is today.
    _fromDate = DateTime(2026, 8, 1);
    _toDate = DateTime.now();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // SAFE INT
  // ═══════════════════════════════════════════════════════════
  int _intValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  // ═══════════════════════════════════════════════════════════
  // SAFE DOUBLE
  // ═══════════════════════════════════════════════════════════
  double _doubleValue(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS  (prefer derived_status so OVERDUE and ONGOING
  //          become two distinct buckets)
  // ═══════════════════════════════════════════════════════════
  String _statusOf(Map<String, dynamic> v) {
    // 1️⃣ Business state wins when the backend provides it.
    final derived = v['derived_status']?.toString().trim();
    if (derived != null && derived.isNotEmpty) {
      return derived.toUpperCase();
    }

    // 2️⃣ Fall back to the raw trip lifecycle.
    final trip = v['trip_status']?.toString().trim();
    if (trip != null && trip.isNotEmpty) {
      return trip.toUpperCase();
    }

    // 3️⃣ Last resort — generic status field.
    final generic = v['status']?.toString().trim();
    if (generic != null && generic.isNotEmpty) {
      return generic.toUpperCase();
    }

    return 'UNKNOWN';
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS COLOR
  // ═══════════════════════════════════════════════════════════
  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ONGOING':
      case 'AT SEA':
        return _success;
      case 'COMPLETED':
        return _primary;
      case 'OVERDUE':
        return _danger;
      case 'UPCOMING':
        return _info;
      case 'NOT_DEPARTED':
      case 'NOT STARTED':
        return _warning;
      case 'CANCELLED':
        return _textLight;
      default:
        return _textMid;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS ICON
  // ═══════════════════════════════════════════════════════════
  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'ONGOING':
      case 'AT SEA':
        return Icons.sailing_rounded;
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'OVERDUE':
        return Icons.warning_rounded;
      case 'UPCOMING':
        return Icons.schedule_rounded;
      case 'NOT_DEPARTED':
      case 'NOT STARTED':
        return Icons.pause_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS ORDER
  // ═══════════════════════════════════════════════════════════
  List<String> get _visibleStatuses {
    final statuses = _discoveredStatuses.toList();
    statuses.sort((a, b) {
      final ia = _preferredOrder.indexOf(a);
      final ib = _preferredOrder.indexOf(b);
      if (ia == -1 && ib == -1) return a.compareTo(b);
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    });
    return statuses;
  }

  // ═══════════════════════════════════════════════════════════
  // FIXED COUNT
  // ═══════════════════════════════════════════════════════════
  int _countFor(String? status) {
    if (status == null) return _allCount;
    return _statusCounts[status] ?? 0;
  }

  // ═══════════════════════════════════════════════════════════
  // DATE FORMAT
  // ═══════════════════════════════════════════════════════════
  String? _fmt(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // ═══════════════════════════════════════════════════════════
  // INITIAL DATA
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadingCounts = true;
      _error = null;
    });

    try {
      final allVoyages = await _fetchAllVoyages(status: null);
      if (!mounted) return;

      final counts = <String, int>{};
      final statuses = <String>{};
      for (final voyage in allVoyages) {
        final status = _statusOf(voyage);
        if (status == 'UNKNOWN') continue;
        statuses.add(status);
        counts[status] = (counts[status] ?? 0) + 1;
      }

      setState(() {
        _allVoyages = allVoyages;
        _allCount = allVoyages.length;
        _statusCounts
          ..clear()
          ..addAll(counts);
        _discoveredStatuses = statuses;

        // Apply the active status filter (if any) to the visible list
        _items = _statusFilter == null
            ? allVoyages
            : allVoyages.where((v) => _statusOf(v) == _statusFilter).toList();

        _loading = false;
        _loadingCounts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingCounts = false;
        _error = 'Failed to load voyages: $e';
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FETCH ALL VOYAGES (paginated)
  // ═══════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> _fetchAllVoyages({
    String? status,
  }) async {
    final List<Map<String, dynamic>> result = [];
    int page = 1;
    int expectedTotal = -1;

    while (true) {
      final response = await _api.fetchVoyages(
        status: status,
        fromDate: _fmt(_fromDate),
        toDate: _fmt(_toDate),
        page: page,
        limit: _limit,
      );

      if (response['success'] != true) {
        throw Exception(
          response['message']?.toString() ?? 'Failed to fetch voyages',
        );
      }

      final list = OfficersApiService.extractList(response);
      final pagination = OfficersApiService.extractPagination(response);
      final apiTotal = pagination['total'] ?? response['total'];
      if (apiTotal != null) {
        expectedTotal = _intValue(apiTotal);
      }

      result.addAll(list);

      if (list.isEmpty) break;
      if (expectedTotal >= 0 && result.length >= expectedTotal) break;
      if (list.length < _limit) break;

      page++;
      if (page > 1000) break;
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // SELECT STATUS
  // ═══════════════════════════════════════════════════════════
  Future<void> _selectStatus(String? status) async {
    if (!mounted) return;

    final newFilter = (status == _statusFilter) ? null : status;

    setState(() {
      _statusFilter = newFilter;
      _items = newFilter == null
          ? _allVoyages
          : _allVoyages.where((v) => _statusOf(v) == newFilter).toList();
      _loading = false;
      _error = null;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> get _filteredItems {
    var base = _items;
    if (_statusFilter != null) {
      base = base.where((v) => _statusOf(v) == _statusFilter).toList();
    }

    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return base;

    return base.where((v) {
      final ref = (v['reference_no'] ?? '').toString().toLowerCase();
      final boat = (v['boat_name'] ?? '').toString().toLowerCase();
      final registration =
      (v['boat_reg_no'] ?? '').toString().toLowerCase();
      final owner = (v['owner_name'] ?? '').toString().toLowerCase();
      final destination =
      (v['destination_ports_text'] ?? '').toString().toLowerCase();

      return ref.contains(query) ||
          boat.contains(query) ||
          registration.contains(query) ||
          owner.contains(query) ||
          destination.contains(query);
    }).toList();
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
            'Voyages',
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
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        color: _primary,
        child: Column(
          children: [
            _dateRow(),
            _searchBar(),
            _statusSquares(),
            const Divider(height: 1, color: _divider),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DATE ROW
  // ═══════════════════════════════════════════════════════════
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
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fromDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date == null) return;
                setState(() {
                  _fromDate = date;
                  _statusFilter = null;
                  _searchCtrl.clear();
                });
                await _loadInitialData();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dateChip(
              label: 'To',
              value: _fmt(_toDate) ?? '—',
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _toDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date == null) return;
                setState(() {
                  _toDate = date;
                  _statusFilter = null;
                  _searchCtrl.clear();
                });
                await _loadInitialData();
              },
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Reset to 01 Aug 2026 → today',
            child: Material(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  // ✅ Reset uses the same fixed From (1 Aug 2026)
                  setState(() {
                    _fromDate = DateTime(2026, 8, 1);
                    _toDate = DateTime.now();
                    _statusFilter = null;
                    _searchCtrl.clear();
                  });
                  await _loadInitialData();
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

  // ═══════════════════════════════════════════════════════════
  // DATE CHIP
  // ═══════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════
  Widget _searchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) {
          setState(() {});
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search ref / boat / reg / owner...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              _searchCtrl.clear();
              setState(() {});
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

  // ═══════════════════════════════════════════════════════════
  // STATUS SQUARES
  // ═══════════════════════════════════════════════════════════
  Widget _statusSquares() {
    final statuses = _visibleStatuses;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _statusSquare(
              label: 'All',
              count: _countFor(null),
              icon: Icons.apps_rounded,
              color: _primary,
              selected: _statusFilter == null,
              loading: _loadingCounts,
              onTap: () {
                if (_statusFilter == null) return;
                _selectStatus(null);
              },
            ),

            for (final status in statuses) ...[
              const SizedBox(width: 10),
              _statusSquare(
                label: _pretty(status),
                count: _countFor(status),
                icon: _statusIcon(status),
                color: _statusColor(status),
                selected: _statusFilter == status,
                loading: _loadingCounts,
                urgent: status == 'OVERDUE',
                onTap: () {
                  if (_statusFilter == status) return;
                  _selectStatus(status);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS SQUARE
  // ═══════════════════════════════════════════════════════════
  Widget _statusSquare({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    required bool loading,
    bool urgent = false,
  }) {
    final borderColor = selected
        ? color
        : (urgent ? color.withOpacity(0.45) : _divider);

    return Material(
      color: selected ? color.withOpacity(0.12) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Stack(
          children: [
            // ── Layer 1: main content, all centered ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: selected ? 1.6 : (urgent ? 1.2 : 1),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon box — centered
                  Container(
                    height: 26,
                    width: 26,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),

                  const SizedBox(height: 6),

                  // Count — centered (or spinner while loading)
                  SizedBox(
                    height: 20,
                    child: loading
                        ? Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      ),
                    )
                        : Center(
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Label — centered, wraps to 2 lines
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
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

            // ── Layer 2: checkmark floating top-right ──
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PRETTY STATUS
  // ═══════════════════════════════════════════════════════════
  String _pretty(String value) {
    return value
        .toLowerCase()
        .split('_')
        .map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    })
        .join(' ');
  }

  // ═══════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════
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
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final items = _filteredItems;

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(
            _statusFilter == null
                ? Icons.inbox_outlined
                : Icons.filter_alt_off_rounded,
            size: 48,
            color: _textLight,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _statusFilter == null
                  ? 'No voyages found.'
                  : 'No ${_pretty(_statusFilter!)} voyages found.',
              style: const TextStyle(
                color: _textMid,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        return _voyageTile(items[index]);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // VOYAGE TILE
  // ═══════════════════════════════════════════════════════════
  Widget _voyageTile(Map<String, dynamic> v) {
    final reference = v['reference_no']?.toString() ?? '—';
    final boatName = v['boat_name']?.toString() ?? '—';
    final boatReg = v['boat_reg_no']?.toString() ?? '';
    final owner = v['owner_name']?.toString() ?? '';
    final status = _statusOf(v);
    final statusColor = _statusColor(status);
    final start = _prettyDate(v['voyage_start_date']?.toString());
    final returnDate = _prettyDate(v['voyage_return_date']?.toString());
    final destination = v['destination_ports_text']?.toString() ?? '';
    final crew = _intValue(v['total_crew_count']);
    final catchKg = _doubleValue(v['total_fish_weight_kg']);
    final sos = _intValue(v['sos_count']);
    final citings = _intValue(v['citing_count']);
    final hours = v['actual_hours'];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailsSheet(v),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reference,
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
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _pretty(status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // ── BOAT ──
              Row(
                children: [
                  const Icon(Icons.directions_boat_rounded,
                      size: 14, color: _primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      boatReg.isEmpty
                          ? boatName
                          : '$boatName · $boatReg',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (owner.isNotEmpty)
                    Text(
                      owner,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textLight,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              // ── DATES ──
              Row(
                children: [
                  const Icon(Icons.event_rounded,
                      size: 13, color: _textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$start  →  $returnDate',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _textMid,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // ── DESTINATION ──
              if (destination.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        size: 13, color: _textLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        destination,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _textMid,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1, color: _divider),
              const SizedBox(height: 8),

              // ── STATS ──
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _miniStat(
                    icon: Icons.groups_rounded,
                    label: 'Crew',
                    value: '$crew',
                    color: _info,
                  ),
                  _miniStat(
                    icon: Icons.scale_rounded,
                    label: 'Catch',
                    value: '${catchKg.toStringAsFixed(1)} kg',
                    color: _success,
                  ),
                  if (hours != null)
                    _miniStat(
                      icon: Icons.timer_rounded,
                      label: 'Hours',
                      value: '$hours',
                      color: _warning,
                    ),
                  if (sos > 0)
                    _miniStat(
                      icon: Icons.sos_rounded,
                      label: 'SOS',
                      value: '$sos',
                      color: _danger,
                    ),
                  if (citings > 0)
                    _miniStat(
                      icon: Icons.report_gmailerrorred_rounded,
                      label: 'Citings',
                      value: '$citings',
                      color: Colors.orange,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // ── DETAILS ──
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showDetailsSheet(v),
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

  // ═══════════════════════════════════════════════════════════
  // MINI STAT
  // ═══════════════════════════════════════════════════════════
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
  // DETAILS → VOYAGE DETAILS
  // ═══════════════════════════════════════════════════════════
  void _showDetailsSheet(Map<String, dynamic> v) {
    final intimationId = _intValue(v['intimation_id']);
    final ref = v['reference_no']?.toString();
    final boat = v['boat_name']?.toString();
    final status = _statusOf(v);

    if (intimationId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid voyage ID'),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoyageDetailsScreen(
          intimationId: intimationId,
          referenceNo: ref,
          boatName: boat,
          tripStatus: status,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PRETTY DATE
  // ═══════════════════════════════════════════════════════════
  String _prettyDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month · $hour:$minute';
    } catch (_) {
      return iso.length >= 16 ? iso.substring(0, 16) : iso;
    }
  }
}