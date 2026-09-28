import 'package:flutter/material.dart';

import '../../../../services/api_services/officer_api_service.dart';

class CitingDetailsSheet extends StatefulWidget {
  final int citingId;
  final Map<String, dynamic> initial;
  final ScrollController controller;

  const CitingDetailsSheet({
    super.key,
    required this.citingId,
    required this.initial,
    required this.controller,
  });

  @override
  State<CitingDetailsSheet> createState() => _CitingDetailsSheetState();
}

class _CitingDetailsSheetState extends State<CitingDetailsSheet> {
  final OfficersApiService _api = OfficersApiService();

  static const Color _primary = Color(0xFF1257C7);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMid = Color(0xFF475569);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _warning = Color(0xFFD97706);

  bool _loading = true;
  String? _error;
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.initial);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _api.fetchCitingDetails(widget.citingId);
    if (!mounted) return;

    if (res['success'] == true && res['data'] is Map) {
      setState(() {
        _data = Map<String, dynamic>.from(res['data'] as Map);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Failed to load details';
        _loading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
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
      default:
        return _textMid;
    }
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
      final y = dt.year;
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$d $m $y · $hh:$mm';
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

  double _d(dynamic v, [double fallback = 0]) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final type = _s(_data['citing_type'], 'UNKNOWN').toUpperCase();
    final typeColor = _typeColor(type);
    final ref = _s(_data['citing_ref_no'], 'Citing');
    final status = _s(_data['citing_status'], 'REPORTED');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: _divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.report_gmailerrorred_rounded,
                      color: typeColor, size: 22),
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
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _pretty(status),
                              style: const TextStyle(
                                color: _success,
                                fontSize: 10,
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: _textMid, size: 20),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _divider),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _errorView()
                : _content(),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.error_outline, size: 44, color: Colors.red),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textMid),
          ),
        ),
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

  Widget _content() {
    final boatReg = _s(_data['boat_reg_no']);
    final intRef = _s(_data['reference_no']);
    final reportedBy = _s(_data['reported_by_name']);
    final dt = _prettyDate(_s(_data['citing_datetime'], ''));
    final remarks = _s(_data['remarks'], '');
    final illegalType = _s(_data['illegal_activity_type'], '');
    final sightedCount = _i(_data['sighted_boat_count']);
    final lat = _d(_data['latitude']);
    final lng = _d(_data['longitude']);
    final photoPath = _s(_data['photo_path'], '');
    final reviewedAt = _prettyDate(_s(_data['reviewed_at'], ''));
    final reviewRemarks = _s(_data['review_remarks'], '');
    final intimationId = _i(_data['intimation_id']);

    final hasLocation = lat != 0 || lng != 0;

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        _sectionTitle('Vessel & Reporter'),
        _row(Icons.directions_boat_rounded, 'Boat Reg No', boatReg),
        _row(Icons.tag_rounded, 'Intimation Ref', intRef),
        if (intimationId > 0)
          _row(Icons.confirmation_number_rounded, 'Intimation ID',
              '$intimationId'),
        _row(Icons.person_outline_rounded, 'Reported By', reportedBy),
        _row(Icons.schedule_rounded, 'Reported At', dt),

        const SizedBox(height: 14),

        _sectionTitle('Sighting Details'),
        _row(Icons.category_rounded, 'Citing Type',
            _pretty(_s(_data['citing_type']))),
        if (illegalType.isNotEmpty && illegalType != '—')
          _row(Icons.warning_amber_rounded, 'Illegal Activity',
              _pretty(illegalType)),
        _row(Icons.directions_boat_filled_rounded, 'Sighted Boats',
            '$sightedCount'),

        const SizedBox(height: 14),

        _sectionTitle('Location'),
        if (hasLocation) ...[
          _row(Icons.place_rounded, 'Latitude', lat.toStringAsFixed(6)),
          _row(Icons.place_rounded, 'Longitude', lng.toStringAsFixed(6)),
        ] else
          _row(Icons.location_off_rounded, 'Location', 'Not recorded'),

        const SizedBox(height: 14),

        _sectionTitle('Remarks'),
        if (remarks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('No remarks',
                style: TextStyle(color: _textLight, fontSize: 12.5)),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              remarks,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: _textDark,
                height: 1.4,
              ),
            ),
          ),

        const SizedBox(height: 14),

        _sectionTitle('Status & Review'),
        _row(Icons.verified_rounded, 'Citing Status',
            _pretty(_s(_data['citing_status']))),
        _row(Icons.history_rounded, 'Reviewed At',
            reviewedAt == '—' ? 'Not reviewed' : reviewedAt),
        if (reviewRemarks.isNotEmpty && reviewRemarks != '—')
          _row(Icons.rate_review_rounded, 'Review Remarks', reviewRemarks),

        const SizedBox(height: 14),

        if (photoPath.isNotEmpty && photoPath != '—') ...[
          _sectionTitle('Photo Evidence'),
          _row(Icons.photo_rounded, 'Photo', photoPath),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _textLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: _primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _textMid,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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
}