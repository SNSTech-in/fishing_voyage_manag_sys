// lib/officer/screens/sos_report_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../services/api_services/officer_api_service.dart';

class SosReportScreen extends StatefulWidget {
  const SosReportScreen({super.key});

  @override
  State<SosReportScreen> createState() => _SosReportScreenState();
}

class _SosReportScreenState extends State<SosReportScreen> {
  final OfficersApiService _api = OfficersApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  // ✅ Debounce so search fires as user types (not on every keystroke)
  Timer? _searchDebounce;

  static const Color _primary = Color(0xFF1257C7);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMid = Color(0xFF475569);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _warning = Color(0xFFD97706);
  static const Color _success = Color(0xFF059669);

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _loading = true;
  String? _error;

  DateTime _fromDate =
  DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

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

  String _fmt(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  // ============================================================
  // LIVE SEARCH — debounced
  // ============================================================
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
  }

  /// Filters the fetched list on the client using every relevant SOS field.
  /// Always runs after _load() and after every debounced keystroke.
  void _applyLocalSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _filteredItems = List.from(_items);
      });
      return;
    }

    final filtered = _items.where((item) {
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
    }).toList();

    setState(() {
      _filteredItems = filtered;
    });
  }

  // ============================================================
  // LOAD
  // ============================================================
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _api.fetchSosReport(
      fromDate: _fmt(_fromDate),
      toDate: _fmt(_toDate),
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final fetched = OfficersApiService.extractList(res);
      setState(() {
        _items = fetched;
        _loading = false;
      });
      // Apply the current search term to the freshly fetched list.
      _applyLocalSearch();
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Failed to load report';
        _loading = false;
        _filteredItems = [];
      });
    }
  }

  Color _severityColor(String s) {
    switch (s.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return _danger;
      case 'MEDIUM':
        return _warning;
      case 'LOW':
        return _success;
      default:
        return _textLight;
    }
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'OPEN':
        return _danger;
      case 'ACKNOWLEDGED':
        return _warning;
      case 'RESOLVED':
      case 'CLOSED':
        return _success;
      default:
        return _textLight;
    }
  }

  int _countByStatus(String s) => _items
      .where((e) =>
  (e['sos_status']?.toString() ?? '').toUpperCase() == s)
      .length;

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
            'SOS Report',
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
            _searchField(),
            _dateRow(),
            _summaryRow(),
            const Divider(height: 1, color: _divider),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================
  Widget _searchField() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,            // ✅ live search
        onSubmitted: (_) {
          _searchDebounce?.cancel();
          _applyLocalSearch();
        },
        decoration: InputDecoration(
          hintText: 'Search by boat, crew, ref no, description...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: _clearSearch,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _dateRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _dateChip('From', _fmt(_fromDate), () async {
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
            }),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _dateChip('To', _fmt(_toDate), () async {
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
            }),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, String value, VoidCallback onTap) {
    return Material(
      color: _primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 12, color: _primary),
                  const SizedBox(width: 6),
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard('Total', '${_items.length}',
                Icons.sos_rounded, _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard('Open', '${_countByStatus('OPEN')}',
                Icons.warning_amber_rounded, _danger),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
                'Resolved',
                '${_countByStatus('RESOLVED') + _countByStatus('CLOSED')}',
                Icons.check_circle_rounded,
                _success),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              height: 1.1,
            ),
          ),
        ],
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
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ),
        ],
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
                    : 'No SOS events in this range.',
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: _filteredItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _sosTile(_filteredItems[i]),
    );
  }

  Widget _sosTile(Map<String, dynamic> s) {
    final ref = s['sos_ref_no']?.toString() ?? '—';
    final intRef = s['reference_no']?.toString() ?? '';
    final boatName = s['boat_name']?.toString() ?? '';
    final boatReg = s['boat_reg_no']?.toString() ?? '';
    final dt = s['sos_datetime']?.toString() ?? '';
    final type = s['sos_type']?.toString() ?? '';
    final severity = s['severity']?.toString() ?? 'HIGH';
    final status = s['sos_status']?.toString() ?? 'OPEN';
    final desc = s['description']?.toString() ?? '';
    final lat = (s['latitude'] as num?)?.toDouble();
    final lng = (s['longitude'] as num?)?.toDouble();
    final ackBy = s['acknowledged_by_name']?.toString() ?? '';
    final ackAt = s['acknowledged_at']?.toString() ?? '';
    final resolvedAt = s['resolved_at']?.toString() ?? '';
    final respTime = s['response_time_min'];

    final sColor = _severityColor(severity);
    final stColor = _statusColor(status);

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
                  color: sColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: sColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                    const SizedBox(height: 2),
                    Text(
                      [boatName, boatReg]
                          .where((e) => e.isNotEmpty)
                          .join(' · '),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _chip(severity, sColor),
                  const SizedBox(height: 4),
                  _chip(status, stColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 8),
          if (type.isNotEmpty)
            _infoRow(Icons.category_rounded, 'Type', type),
          if (dt.isNotEmpty)
            _infoRow(Icons.schedule_rounded, 'When', dt),
          if (intRef.isNotEmpty)
            _infoRow(Icons.tag_rounded, 'Voyage', intRef),
          if (desc.isNotEmpty)
            _infoRow(Icons.notes_rounded, 'Description', desc),
          if (lat != null && lng != null)
            _infoRow(Icons.location_on_rounded, 'Location',
                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'),
          if (ackBy.isNotEmpty)
            _infoRow(Icons.check_circle_outline_rounded,
                'Acknowledged', '$ackBy @ $ackAt'),
          if (resolvedAt.isNotEmpty)
            _infoRow(Icons.done_all_rounded, 'Resolved', resolvedAt),
          if (respTime != null)
            _infoRow(Icons.timer_rounded, 'Response',
                '$respTime min'),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: _textLight),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _textLight,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}