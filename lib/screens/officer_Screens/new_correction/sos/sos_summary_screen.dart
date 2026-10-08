import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../services/api_services/officer_api_service.dart';
import 'sos_details_sheet.dart';

class SosSummaryScreen extends StatefulWidget {
  const SosSummaryScreen({super.key});

  @override
  State<SosSummaryScreen> createState() => _SosSummaryScreenState();
}

class _SosSummaryScreenState extends State<SosSummaryScreen> {
  final OfficersApiService _api = OfficersApiService();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

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

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _loading = true;
  String? _error;

  int _page = 1;
  final int _limit = 20;
  int _total = 0;

  String? _statusFilter;
  String? _severityFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  int _intValue(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyLocalSearch();
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    _applyLocalSearch();
    _load(reset: true);
  }

  /// Filters the already-fetched list on the client so unrelated
  /// records never show even if the backend ignores the `search` param.
  void _applyLocalSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();

    Iterable<Map<String, dynamic>> result = _items;

    // Filter by dropdown status
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      final want = _statusFilter!.toUpperCase();
      result = result.where((item) {
        final s = (item['sos_status'] ?? item['status'] ?? '')
            .toString()
            .toUpperCase();
        return s == want;
      });
    }

    // Filter by dropdown severity
    if (_severityFilter != null && _severityFilter!.isNotEmpty) {
      final want = _severityFilter!.toUpperCase();
      result = result.where((item) {
        final s = (item['severity'] ?? '').toString().toUpperCase();
        return s == want;
      });
    }

    // Filter by free-text search
    if (q.isNotEmpty) {
      result = result.where((item) {
        final haystack = [
          item['sos_ref_no'],
          item['reference_no'],
          item['boat_name'],
          item['boat_reg_no'],
          item['boat_number'],
          item['crew_name'],
          item['raised_by_name'],
          item['reported_by_name'],
          item['owner_name'],
          item['acknowledged_by_name'],
          item['description'],
          item['remarks'],
          item['sos_type'],
          item['severity'],
          item['sos_status'],
          item['status'],
          item['latitude'],
          item['longitude'],
        ]
            .where((e) => e != null)
            .map((e) => e.toString().toLowerCase())
            .join(' ');
        return haystack.contains(q);
      });
    }

    setState(() {
      _filteredItems = result.toList();
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _page = 1;
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _api.fetchSos(
      search: _searchCtrl.text.trim(),
      status: _statusFilter,
      severity: _severityFilter,
      page: _page,
      limit: _limit,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final list = OfficersApiService.extractList(res);
      final meta = OfficersApiService.extractPagination(res);
      setState(() {
        _items = list;
        _total = meta['total'] ?? list.length;
        _loading = false;
      });
      // Re-apply the current search term to the fresh list.
      _applyLocalSearch();
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Failed to load SOS';
        _loading = false;
      });
    }
  }

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
          padding: EdgeInsets.only(left: 12),
          child: Text(
            'SOS Alerts',
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _searchDebounce?.cancel();
              _load(reset: true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _filters(),
          const Divider(height: 1, color: _divider),
          Expanded(child: _body()),
          if (_total > _limit) _pager(),
        ],
      ),
    );
  }

  // ── Filters ─────────────────────────────────────────────
  Widget _filters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onChanged: _onSearchChanged,
            onSubmitted: (_) {
              _searchDebounce?.cancel();
              _applyLocalSearch();
              _load(reset: true);
            },
            decoration: InputDecoration(
              hintText: 'Search SOS (boat, crew, description)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'OPEN', child: Text('Open')),
                    DropdownMenuItem(
                        value: 'RESOLVED', child: Text('Resolved')),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    _applyLocalSearch();          // filter immediately, no waiting
                    _load(reset: true);           // then refresh from API
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _severityFilter,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'HIGH', child: Text('High')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                    DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  ],
                  onChanged: (v) {
                    setState(() => _severityFilter = v);
                    _applyLocalSearch();          // filter immediately
                    _load(reset: true);           // then refresh from API
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────
  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _load(reset: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_filteredItems.isEmpty) {
      final hasSearch = _searchCtrl.text.trim().isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasSearch ? Icons.search_off_rounded : Icons.inbox_rounded,
                size: 48,
                color: Colors.black26,
              ),
              const SizedBox(height: 8),
              Text(
                hasSearch
                    ? 'No SOS records match your search.'
                    : 'No SOS records found.',
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      color: _primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _filteredItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _sosTile(_filteredItems[i]),
      ),
    );
  }

  // ── SOS Tile (card with View Details button) ────────────
  Widget _sosTile(Map<String, dynamic> item) {
    final severity =
        (item['severity'] ?? 'N/A').toString().toUpperCase();
    final status =
        (item['status'] ?? item['sos_status'] ?? 'N/A')
            .toString()
            .toUpperCase();
    final boat =
        (item['boat_reg_no'] ?? item['boat_name'] ?? 'Unknown Boat')
            .toString();
    final ref = (item['sos_ref_no'] ?? '').toString();
    final datetime =
        (item['sos_datetime'] ?? item['created_at'] ?? '—').toString();
    final desc =
        (item['description'] ?? item['remarks'] ?? '').toString();
    final raisedBy = (item['raised_by_name'] ?? '').toString();
    final refNo = (item['reference_no'] ?? '').toString();

    final sevColor = _severityColor(severity);
    final statColor = _statusColor(status);

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
          // ── HEADER ──
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: sevColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.sos_rounded,
                  size: 18,
                  color: sevColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.isEmpty ? 'SOS Alert' : ref,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (refNo.isNotEmpty)
                      Text(
                        'Voyage: $refNo',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textLight,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── BOAT & TIME ──
          Row(
            children: [
              const Icon(Icons.directions_boat_rounded,
                  size: 14, color: _primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  boat,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _prettyDate(datetime),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textLight,
                ),
              ),
            ],
          ),

          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 12,
                color: _textMid,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 8),

          // ── FOOTER ──
          Row(
            children: [
              if (raisedBy.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 13, color: _textLight),
                    const SizedBox(width: 4),
                    Text(
                      raisedBy,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textMid,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sevColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: sevColor.withOpacity(0.2)),
                ),
                child: Text(
                  '$severity SEVERITY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: sevColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // ── SINGLE ENTRY POINT TO DETAILS ──
              TextButton.icon(
                onPressed: () => _openDetails(item),
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.visibility_rounded, size: 14),
                label: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pager ───────────────────────────────────────────────
  Widget _pager() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_page',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textMid,
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _page > 1
                    ? () {
                  setState(() => _page--);
                  _load();
                }
                    : null,
                child: const Text('Prev'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: (_page * _limit) < _total
                    ? () {
                  setState(() => _page++);
                  _load();
                }
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _severityColor(String sev) {
    switch (sev) {
      case 'HIGH':
        return _danger;
      case 'MEDIUM':
        return _warning;
      case 'LOW':
        return _success;
      default:
        return _primary;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN':
        return _danger;
      case 'RESOLVED':
        return _success;
      default:
        return _primary;
    }
  }

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

  void _openDetails(Map<String, dynamic> item) {
    final sosId = _intValue(item['sos_id'] ?? item['id']);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SosDetailsSheet(
          sosId: sosId,
          initial: item,
        ),
      ),
    );
  }
}
