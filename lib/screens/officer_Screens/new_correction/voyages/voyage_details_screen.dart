import 'package:flutter/material.dart';
import '../../../../services/api_services/officer_api_service.dart';

class VoyageDetailsScreen extends StatefulWidget {
  final int intimationId;
  final String? referenceNo;
  final String? boatName;
  final String? tripStatus;

  const VoyageDetailsScreen({
    super.key,
    required this.intimationId,
    this.referenceNo,
    this.boatName,
    this.tripStatus,
  });

  @override
  State<VoyageDetailsScreen> createState() => _VoyageDetailsScreenState();
}

class _VoyageDetailsScreenState extends State<VoyageDetailsScreen> {
  final OfficersApiService _api = OfficersApiService();

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

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _api.fetchVoyageDetails(widget.intimationId);

    if (!mounted) return;

    if (res['success'] == true && res['data'] is Map) {
      setState(() {
        _data = Map<String, dynamic>.from(res['data'] as Map);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ??
            'Failed to load voyage details';
        _loading = false;
      });
    }
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────
  Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : {};

  List<Map<String, dynamic>> _list(dynamic v) =>
      v is List
          ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];

  String _s(dynamic v, [String fallback = '—']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
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

  String _prettyDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
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

  String _pretty(String value) {
    return value
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
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
      case 'NOT_STARTED':
      case 'NOT STARTED':
        return _warning;
      case 'CANCELLED':
        return _textLight;
      default:
        return _textMid;
    }
  }

  // ──────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────
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
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _s(widget.referenceNo, _s(_data['reference_no'], 'Voyage')),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.boatName != null && widget.boatName!.isNotEmpty)
                Text(
                  widget.boatName!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _errorView()
            : _content(),
      ),
    );
  }

  Widget _errorView() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Text(_error!, textAlign: TextAlign.center),
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
    final status = _map(_data['status']);
    final schedule = _map(_data['schedule']);
    final provisions = _map(_data['provisions']);
    final emergency = _map(_data['emergency_contact']);
    final ports = _map(_data['ports']);
    final crew = _list(_data['crew']);
    final tripStart = _map(_data['trip_start']);
    final tripEnd = _map(_data['trip_end']);
    final fish = _map(_data['fish_details']);
    final sos = _list(_data['sos']);
    final citings = _list(_data['citings']);
    final timeline = _list(_data['timeline']);

    final tripStatus = _s(status['trip_status'], widget.tripStatus ?? 'UNKNOWN')
        .toUpperCase();
    final statusColor = _statusColor(tripStatus);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ── HEADER CARD ──────────────────────────────
        _headerCard(tripStatus, statusColor, status),

        const SizedBox(height: 14),

        // ── VESSEL & OWNER ───────────────────────────
        _sectionCard(
          title: 'Vessel & Owner',
          icon: Icons.directions_boat_rounded,
          rows: [
            _Row('Boat Name', _s(_data['boat_name'])),
            _Row('Registration', _s(_data['boat_reg_no'])),
            _Row('Owner', _s(_data['owner_name'])),
            _Row('Created By',
                '${_s(_data['created_by_name'])} · ${_s(_data['created_by_type'])}'),
          ],
        ),

        const SizedBox(height: 12),

        // ── SCHEDULE ─────────────────────────────────
        _sectionCard(
          title: 'Schedule',
          icon: Icons.schedule_rounded,
          rows: [
            _Row('Voyage Start', _prettyDate(_s(schedule['voyage_start_date'], ''))),
            _Row('Voyage Return',
                _prettyDate(_s(schedule['voyage_return_date'], ''))),
          ],
        ),

        const SizedBox(height: 12),

        // ── PORTS ────────────────────────────────────
        _sectionCard(
          title: 'Ports',
          icon: Icons.place_rounded,
          rows: [
            _Row('Primary Port', _s(ports['primary_port_name'])),
            _Row('Destinations', _s(ports['destination_ports_text'])),
            _Row('Destination Count',
                '${_i(ports['destination_port_count'])}'),
          ],
        ),

        const SizedBox(height: 12),

        // ── PROVISIONS ───────────────────────────────
        _sectionCard(
          title: 'Provisions',
          icon: Icons.inventory_2_rounded,
          rows: [
            _Row('Fresh Water', '${_d(provisions['fresh_water_ltr'])} L'),
            _Row('Diesel', '${_d(provisions['diesel_ltr'])} L'),
            _Row('Life Jackets', '${_i(provisions['life_jackets'])}'),
            _Row('Life Buoys', '${_i(provisions['life_buoys'])}'),
            _Row('Comm. Devices',
                '${_i(provisions['communication_devices'])}'),
          ],
        ),

        const SizedBox(height: 12),

        // ── EMERGENCY ────────────────────────────────
        _sectionCard(
          title: 'Emergency Contact',
          icon: Icons.emergency_rounded,
          rows: [
            _Row('Name', _s(emergency['name'])),
            _Row('Contact', _s(emergency['contact'])),
          ],
        ),

        const SizedBox(height: 12),

        // ── CREW ─────────────────────────────────────
        _sectionCard(
          title: 'Crew (${crew.length})',
          icon: Icons.groups_rounded,
          children: [
            if (crew.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No crew members',
                    style: TextStyle(color: _textLight, fontSize: 12.5)),
              )
            else
              ...crew.map((c) => _crewRow(c)),
          ],
        ),

        const SizedBox(height: 12),

        // ── TRIP START ───────────────────────────────
        _sectionCard(
          title: 'Trip Start',
          icon: Icons.play_circle_rounded,
          rows: [
            _Row('Started', tripStart['is_trip_started'] == true ? 'Yes' : 'No'),
            _Row('Date/Time',
                _prettyDate(_s(tripStart['trip_start_datetime'], ''))),
            _Row('By', _s(tripStart['started_by_name'])),
            if (tripStart['latitude'] != null && tripStart['longitude'] != null)
              _Row('Location',
                  '${_d(tripStart['latitude']).toStringAsFixed(5)}, ${_d(tripStart['longitude']).toStringAsFixed(5)}'),
            _Row('Remarks', _s(tripStart['remarks'])),
          ],
        ),

        const SizedBox(height: 12),

        // ── TRIP END ─────────────────────────────────
        _sectionCard(
          title: 'Trip End',
          icon: Icons.flag_rounded,
          rows: [
            _Row('Ended', tripEnd['is_trip_ended'] == true ? 'Yes' : 'No'),
            _Row('Date/Time',
                _prettyDate(_s(tripEnd['trip_end_datetime'], ''))),
            _Row('By', _s(tripEnd['ended_by_name'])),
            _Row('All Crew Returned',
                tripEnd['all_crew_returned'] == true ? 'Yes' : 'No'),
            _Row('Returned Crew',
                '${_i(tripEnd['returned_crew_count'])}'),
            _Row('Missing Crew',
                '${_i(tripEnd['missing_crew_count'])}'),
            _Row('Notified Officer',
                _s(tripEnd['notified_officer_name'])),
          ],
        ),

        const SizedBox(height: 12),

        // ── FISH CATCH ───────────────────────────────
        _sectionCard(
          title: 'Fish Catch',
          icon: Icons.scale_rounded,
          rows: [
            _Row('Fish Data Entered',
                fish['fish_data_entered'] == true ? 'Yes' : 'No'),
            _Row('Total Weight',
                '${_d(fish['total_weight_kg']).toStringAsFixed(2)} kg'),
            _Row('Species Count',
                '${_list(fish['items']).length}'),
          ],
          children: _list(fish['items']).isNotEmpty
              ? _list(fish['items']).map((f) {
            final name = _s(f['fish_name'] ?? f['species_name']);
            final kg = _d(f['weight_kg'] ?? f['total_weight_kg']);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.set_meal_rounded,
                      size: 14, color: _success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _textDark)),
                  ),
                  Text('${kg.toStringAsFixed(2)} kg',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _textDark)),
                ],
              ),
            );
          }).toList()
              : null,
        ),

        const SizedBox(height: 12),

        // ── SOS ──────────────────────────────────────
        _sectionCard(
          title: 'SOS Events (${sos.length})',
          icon: Icons.sos_rounded,
          children: sos.isEmpty
              ? [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('No SOS events',
                  style: TextStyle(color: _textLight, fontSize: 12.5)),
            )
          ]
              : sos.map((s) => _sosRow(s)).toList(),
        ),

        const SizedBox(height: 12),

        // ── CITINGS ──────────────────────────────────
        _sectionCard(
          title: 'Citings (${citings.length})',
          icon: Icons.report_gmailerrorred_rounded,
          children: citings.isEmpty
              ? [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('No citings recorded',
                  style: TextStyle(color: _textLight, fontSize: 12.5)),
            )
          ]
              : citings.map((c) => _citingRow(c)).toList(),
        ),

        const SizedBox(height: 12),

        // ── TIMELINE ─────────────────────────────────
        _sectionCard(
          title: 'Timeline (${timeline.length})',
          icon: Icons.timeline_rounded,
          children: timeline.isEmpty
              ? [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('No timeline events',
                  style: TextStyle(color: _textLight, fontSize: 12.5)),
            )
          ]
              : timeline.map((t) => _timelineRow(t)).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER CARD
  // ═══════════════════════════════════════════════════════════
  Widget _headerCard(
      String tripStatus, Color statusColor, Map<String, dynamic> status) {
    final locked = status['is_locked'] == true;
    final version = _i(status['version_no']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_boat_rounded,
                    color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _s(_data['reference_no']),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_s(_data['boat_name'])} · ${_s(_data['boat_reg_no'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textMid,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (locked)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 11, color: _warning),
                      SizedBox(width: 4),
                      Text(
                        'Locked',
                        style: TextStyle(
                          color: _warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(_pretty(tripStatus), statusColor),
              _chip(
                _pretty(_s(status['intimation_status'])),
                _info,
              ),
              if (version > 0)
                _chip('V$version', _textMid),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.analytics_rounded,
                  size: 14, color: _textLight),
              const SizedBox(width: 6),
              Text(
                'Derived: ${_s(status['derived_status'])}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _textMid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION CARD
  // ═══════════════════════════════════════════════════════════
  Widget _sectionCard({
    required String title,
    required IconData icon,
    List<_Row>? rows,
    List<Widget>? children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: _primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _textLight,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rows != null)
                  ...rows.map((r) => _rowWidget(r.label, r.value)),
                if (children != null) ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowWidget(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  // ═══════════════════════════════════════════════════════════
  // CREW ROW
  // ═══════════════════════════════════════════════════════════
  Widget _crewRow(Map<String, dynamic> c) {
    final name = _s(c['crew_name']);
    final role = _s(c['crew_role']);
    final mobile = _s(c['mobile_no']);
    final aadhaar = _s(c['aadhaar_last4']);
    final isCaptain = c['is_captain'] == true;
    final hasReturned = c['has_returned'];
    final returnStatus = _s(c['return_status']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isCaptain
                  ? Icons.military_tech_rounded
                  : Icons.person_rounded,
              size: 17,
              color: _primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    if (isCaptain) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CAPTAIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _warning,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$role · $mobile${aadhaar.isNotEmpty && aadhaar != '—' ? ' · ****$aadhaar' : ''}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _textMid,
                  ),
                ),
                if (hasReturned != null || returnStatus != '—')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Returned: ${hasReturned == true ? "Yes" : "No"} · $returnStatus',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SOS ROW
  // ═══════════════════════════════════════════════════════════
  Widget _sosRow(Map<String, dynamic> s) {
    final ref = _s(s['sos_ref_no']);
    final type = _s(s['sos_type']);
    final severity = _s(s['severity']).toUpperCase();
    final status = _s(s['sos_status']).toUpperCase();
    final dt = _prettyDate(_s(s['sos_datetime'], ''));
    final desc = _s(s['description']);

    final sevColor = severity == 'HIGH' || severity == 'CRITICAL'
        ? _danger
        : severity == 'MEDIUM'
        ? _warning
        : _success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: sevColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.warning_amber_rounded,
                size: 16, color: sevColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ref,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: sevColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$type · $status',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textMid,
                  ),
                ),
                if (desc.isNotEmpty && desc != '—')
                  Text(desc,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textLight,
                      )),
                Text(dt,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: _textLight,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CITING ROW
  // ═══════════════════════════════════════════════════════════
  Widget _citingRow(Map<String, dynamic> c) {
    final type = _s(c['citing_type']);
    final remarks = _s(c['remarks']);
    final dt = _prettyDate(_s(c['citing_datetime'], ''));
    final lat = c['latitude'];
    final lng = c['longitude'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.report_gmailerrorred_rounded,
                size: 16, color: Colors.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                if (remarks.isNotEmpty && remarks != '—')
                  Text(remarks,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _textMid,
                      )),
                if (lat != null && lng != null)
                  Text(
                    '${_d(lat).toStringAsFixed(5)}, ${_d(lng).toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textLight,
                    ),
                  ),
                Text(dt,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: _textLight,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TIMELINE ROW
  // ═══════════════════════════════════════════════════════════
  Widget _timelineRow(Map<String, dynamic> t) {
    final label = _s(t['label']);
    final action = _s(t['action_type']);
    final dt = _prettyDate(_s(t['action_datetime'], ''));
    final by = _s(t['performed_by_name']);
    final byType = _s(t['performed_by_type']);
    final remarks = _s(t['remarks']);
    final toStatus = _s(t['to_status']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _primary.withOpacity(0.25),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 44,
                color: _divider,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                    ),
                    Text(
                      action,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _textLight,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$dt · $by ($byType)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textMid,
                  ),
                ),
                if (toStatus.isNotEmpty && toStatus != '—')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('→ $toStatus',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        )),
                  ),
                if (remarks.isNotEmpty && remarks != '—')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(remarks,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textLight,
                        )),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper DTO ───────────────────────────────────────────────
class _Row {
  final String label;
  final String value;
  _Row(this.label, this.value);
}