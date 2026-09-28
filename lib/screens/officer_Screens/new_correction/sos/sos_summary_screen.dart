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
    _searchCtrl.dispose();
    super.dispose();
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
            onPressed: () => _load(reset: true),
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
            onSubmitted: (_) => _load(reset: true),
            decoration: InputDecoration(
              hintText: 'Search SOS (boat, crew, description)...',
              prefixIcon: const Icon(Icons.search, size: 20),
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
                    _statusFilter = v;
                    _load(reset: true);
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
                    _severityFilter = v;
                    _load(reset: true);
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
    if (_items.isEmpty) {
      return const Center(child: Text('No SOS records found.'));
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      color: _primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _sosTile(_items[i]),
      ),
    );
  }

  // ── SOS Tile (card with View Details button) ────────────
  Widget _sosTile(Map<String, dynamic> item) {
    final severity =
    (item['severity'] ?? 'N/A').toString().toUpperCase();
    final status =
    (item['sos_status'] ?? item['status'] ?? 'N/A')
        .toString()
        .toUpperCase();
    final boat =
    (item['boat_reg_no'] ?? item['boat_name'] ?? 'Unknown Boat')
        .toString();
    final boatName = (item['boat_name'] ?? '').toString();
    final ref = (item['sos_ref_no'] ?? '').toString();
    final datetime = (item['sos_datetime'] ?? item['created_at'] ?? '—')
        .toString();
    final desc =
    (item['description'] ?? item['remarks'] ?? '').toString();
    final raisedBy = (item['raised_by_name'] ?? '').toString();
    final refNo = (item['reference_no'] ?? '').toString();

    final sevColor = _severityColor(severity);
    final statColor = _statusColor(status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetails(item),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: sevColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                severity,
                                style: TextStyle(
                                  color: sevColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── BOAT ──
              Row(
                children: [
                  const Icon(Icons.directions_boat_rounded,
                      size: 14, color: _primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      boatName.isNotEmpty
                          ? '$boatName · $boat'
                          : boat,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (raisedBy.isNotEmpty)
                    Text(
                      'by $raisedBy',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textLight,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              // ── DATETIME ──
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 13, color: _textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _prettyDate(datetime),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _textMid,
                      ),
                    ),
                  ),
                ],
              ),

              // ── REFERENCE ──
              if (refNo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.tag_rounded,
                        size: 13, color: _textLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        refNo,
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

              // ── DESCRIPTION ──
              if (desc.isNotEmpty) ...[
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
                          desc,
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
              const Divider(height: 1, color: _divider),
              const SizedBox(height: 4),

              // ── VIEW DETAILS ──
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openDetails(item),
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

  Color _severityColor(String s) {
    switch (s) {
      case 'HIGH':
      case 'CRITICAL':
        return _danger;
      case 'MEDIUM':
        return _warning;
      case 'LOW':
        return _success;
      default:
        return _textMid;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'RESOLVED':
      case 'CLOSED':
        return _success;
      case 'OPEN':
      case 'PENDING':
        return _warning;
      default:
        return _textMid;
    }
  }

  String _prettyDate(String iso) {
    if (iso.isEmpty || iso == '—') return '—';
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
      return '$d $m ${dt.year} · $hh:$mm';
    } catch (_) {
      return iso.length >= 16 ? iso.substring(0, 16) : iso;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // OPEN SOS DETAILS SHEET  (fetches /sos/{id})
  // ═══════════════════════════════════════════════════════════
  void _openDetails(Map<String, dynamic> item) {
    final sosId = _intValue(item['sos_id']);
    if (sosId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid SOS ID'),
          backgroundColor: _danger,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SosDetailsSheet(
          sosId: sosId,
          initial: item,
          controller: ctrl,
        ),
      ),
    );
  }

  int _intValue(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // ── Pager ───────────────────────────────────────────────
  Widget _pager() {
    final maxPage = (_total / _limit).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Page $_page / $maxPage  (total $_total)'),
          Row(
            children: [
              IconButton(
                onPressed: _page > 1
                    ? () {
                  _page--;
                  _load();
                }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: _page < maxPage
                    ? () {
                  _page++;
                  _load();
                }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}