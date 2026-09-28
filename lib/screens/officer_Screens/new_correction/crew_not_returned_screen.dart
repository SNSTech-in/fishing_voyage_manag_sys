import 'package:flutter/material.dart';

import '../../../services/api_services/officer_api_service.dart';

class CrewNotReturnedScreen extends StatefulWidget {
  const CrewNotReturnedScreen({super.key});

  @override
  State<CrewNotReturnedScreen> createState() =>
      _CrewNotReturnedScreenState();
}

class _CrewNotReturnedScreenState extends State<CrewNotReturnedScreen> {
  final OfficersApiService _api = OfficersApiService();

  static const Color _primary = Color(0xFF1257C7);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _warning = Color(0xFFD97706);

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  DateTime _fromDate =
  DateTime.now().subtract(const Duration(days: 365));
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

    final res = await _api.fetchCrewNotReturned(
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
            'Crew Not Returned',
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
            _dateRow(),
            _summaryBanner(),
            const Divider(height: 1, color: _divider),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _dateRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _dateChip(
              'From',
              _fmt(_fromDate),
                  () async {
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
          const SizedBox(width: 10),
          Expanded(
            child: _dateChip(
              'To',
              _fmt(_toDate),
                  () async {
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

  Widget _summaryBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _danger.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.person_off_rounded,
                  color: _danger, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_items.length} missing',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _danger,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Crew members flagged as not returned',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('No missing crew in this range.',
            style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _crewTile(_items[i]),
    );
  }

  Widget _crewTile(Map<String, dynamic> e) {
    final crewName = e['crew_name']?.toString() ?? '—';
    final mobile = e['mobile_no']?.toString() ?? '';
    final aadhaar = e['aadhaar_last4']?.toString() ?? '';
    final boatName = e['boat_name']?.toString() ?? '';
    final boatReg = e['boat_reg_no']?.toString() ?? '';
    final ownerName = e['owner_name']?.toString() ?? '';
    final ref = e['reference_no']?.toString() ?? '';
    final status = e['return_status']?.toString() ?? 'MISSING';
    final remarks = e['remarks']?.toString() ?? '';
    final tripEnd = e['trip_end_datetime']?.toString() ?? '';
    final notified = e['notified_officer_name']?.toString() ?? '';
    final emergencyName = e['emergency_contact_name']?.toString() ?? '';
    final emergencyNo = e['emergency_contact_no']?.toString() ?? '';

    final isMissing = status.toUpperCase().contains('MISSING');
    final color = isMissing ? _danger : _warning;

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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.person_off_rounded,
                    color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crewName,
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
                      boatReg.isEmpty
                          ? boatName
                          : '$boatName · $boatReg',
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
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 8),
          if (ref.isNotEmpty) _infoRow(Icons.tag_rounded, 'Ref', ref),
          if (ownerName.isNotEmpty)
            _infoRow(Icons.person_outline_rounded, 'Owner', ownerName),
          if (mobile.isNotEmpty)
            _infoRow(Icons.phone_rounded, 'Mobile', mobile),
          if (aadhaar.isNotEmpty)
            _infoRow(Icons.credit_card_rounded, 'Aadhaar', '****$aadhaar'),
          if (emergencyName.isNotEmpty || emergencyNo.isNotEmpty)
            _infoRow(
              Icons.emergency_rounded,
              'Emergency',
              '$emergencyName $emergencyNo'.trim(),
            ),
          if (tripEnd.isNotEmpty)
            _infoRow(Icons.schedule_rounded, 'Trip ended', tripEnd),
          if (notified.isNotEmpty)
            _infoRow(Icons.campaign_rounded, 'Notified', notified),
          if (remarks.isNotEmpty)
            _infoRow(Icons.notes_rounded, 'Remarks', remarks),
        ],
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