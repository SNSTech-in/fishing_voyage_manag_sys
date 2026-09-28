import 'package:flutter/material.dart';
import '../../../../services/api_services/officer_api_service.dart';

class SosDetailsSheet extends StatefulWidget {
  final int sosId;
  final Map<String, dynamic>? initial;
  final ScrollController? controller;

  const SosDetailsSheet({
    super.key,
    required this.sosId,
    this.initial,
    this.controller,
  });

  @override
  State<SosDetailsSheet> createState() => _SosDetailsSheetState();
}

class _SosDetailsSheetState extends State<SosDetailsSheet> {
  final OfficersApiService _api = OfficersApiService();

  static const Color _primary = Color(0xFF1257C7);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMid = Color(0xFF475569);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _warning = Color(0xFFD97706);
  static const Color _success = Color(0xFF059669);
  static const Color _info = Color(0xFF0891B2);

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _data = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null; // show spinner only if no initial data
      _error = null;
    });

    final res = await _api.fetchSosDetails(widget.sosId);
    if (!mounted) return;

    if (res['success'] == true) {
      final raw = res['data'];
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      setState(() {
        _data = map;
        _loading = false;
      });
    } else {
      setState(() {
        // Keep showing initial data even on error
        _error = res['message']?.toString() ?? 'Failed to load SOS';
        _loading = false;
      });
    }
  }

  // ── helpers ──────────────────────────────────────────────
  String _s(dynamic v, [String fallback = '—']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? fallback : s;
  }

  String _pretty(String s) {
    return s
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _prettyDate(dynamic iso) {
    if (iso == null) return '—';
    final str = iso.toString();
    if (str.isEmpty) return '—';
    try {
      final dt = DateTime.parse(str.replaceFirst(' ', 'T')).toLocal();
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
      return str.length >= 16 ? str.substring(0, 16) : str;
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
        return _textMid;
    }
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
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

  IconData _statusIcon(String s) {
    switch (s.toUpperCase()) {
      case 'RESOLVED':
      case 'CLOSED':
        return Icons.check_circle_rounded;
      case 'OPEN':
      case 'PENDING':
        return Icons.error_outline_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ── build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Column(
        children: [
          _dragHandle(),
          _header(),
          const Divider(height: 1, color: _divider),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _dragHandle() => Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.only(top: 10, bottom: 6),
    decoration: BoxDecoration(
      color: _divider,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _header() {
    final ref = _s(_data?['sos_ref_no'], 'SOS');
    final severity = _s(_data?['severity'], '—').toUpperCase();
    final status = _s(_data?['sos_status'] ?? _data?['status'], '—')
        .toUpperCase();
    final sevColor = _severityColor(severity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: sevColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sos_rounded, color: sevColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _chip(severity, sevColor),
                    const SizedBox(width: 6),
                    _chip(status, _statusColor(status),
                        icon: _statusIcon(status)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: _primary),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
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
    if (_data == null) {
      return _errorView();
    }

    final d = _data!;
    final voyage = (d['voyage'] is Map)
        ? Map<String, dynamic>.from(d['voyage'])
        : <String, dynamic>{};

    final lat = (d['latitude'] as num?)?.toDouble();
    final lng = (d['longitude'] as num?)?.toDouble();
    final hasLocation =
        lat != null && lng != null && lat != 0 && lng != 0;

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 14, color: _warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Showing cached data — refresh failed: $_error',
                    style: const TextStyle(
                        fontSize: 11, color: _warning),
                  ),
                ),
              ],
            ),
          ),

        // ── Alert Info ──
        _sectionTitle('Alert Info', Icons.notifications_active_rounded),
        _card([
          _kv('SOS Type', _pretty(_s(d['sos_type'], '—'))),
          _kv('Severity',
              _s(d['severity'], '—').toUpperCase(),
              valueColor: _severityColor(_s(d['severity'], ''))),
          _kv('Status',
              _s(d['sos_status'], '—').toUpperCase(),
              valueColor: _statusColor(_s(d['sos_status'], ''))),
          _kv('Raised At', _prettyDate(d['sos_datetime'])),
          if (_s(d['description'], '').isNotEmpty)
            _kv('Description', _s(d['description'])),
        ]),

        // ── Boat & Voyage ──
        _sectionTitle('Boat & Voyage', Icons.directions_boat_rounded),
        _card([
          _kv('Boat', _s(d['boat_name'])),
          _kv('Registration', _s(d['boat_reg_no'])),
          _kv('Reference No', _s(d['reference_no'])),
          _kv('Raised By', _s(d['raised_by_name'])),
          if (_s(voyage['owner_name'], '').isNotEmpty)
            _kv('Owner', _s(voyage['owner_name'])),
          if (_s(voyage['emergency_contact'], '').isNotEmpty)
            _kv('Emergency Contact', _s(voyage['emergency_contact'])),
          if (voyage['total_crew_count'] != null)
            _kv('Total Crew', _s(voyage['total_crew_count'])),
          if (_s(voyage['voyage_return_date'], '').isNotEmpty)
            _kv('Voyage Return',
                _prettyDate(voyage['voyage_return_date'])),
        ]),

        // ── Location ──
        _sectionTitle('Location', Icons.location_on_rounded),
        _card([
          _kv('Source', _s(d['location_source'])),
          _kv(
            'Reported Coords',
            hasLocation
                ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                : '—',
          ),
          if (voyage['last_known_latitude'] != null &&
              voyage['last_known_longitude'] != null)
            _kv(
              'Last Known',
              '${(voyage['last_known_latitude'] as num).toStringAsFixed(5)}, '
                  '${(voyage['last_known_longitude'] as num).toStringAsFixed(5)}',
            ),
        ]),

        // ── Response ──
        _sectionTitle('Response', Icons.support_agent_rounded),
        _card([
          _kv('Acknowledged By', _s(d['acknowledged_by_name'], 'Not yet')),
          _kv('Acknowledged At', _prettyDate(d['acknowledged_at'])),
          _kv('Resolved At', _prettyDate(d['resolved_at'])),
          if (d['response_time_min'] != null)
            _kv('Response Time',
                '${_s(d['response_time_min'])} min'),
          if (_s(d['resolution_remarks'], '').isNotEmpty)
            _kv('Resolution', _s(d['resolution_remarks'])),
        ]),

        const SizedBox(height: 12),
        Center(
          child: Text(
            'SOS ID: ${_s(d['sos_id'])}',
            style: const TextStyle(
              fontSize: 11,
              color: _textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 15, color: _primary),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _primary,
            letterSpacing: 0.6,
          ),
        ),
      ],
    ),
  );

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _divider),
    ),
    child: Column(children: children),
  );

  Widget _kv(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textMid,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? _textDark,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: _danger),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Failed to load SOS details',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textMid),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}