import 'package:flutter/material.dart';
import '../../services/api_services/officer_api_service.dart';
import '../ui/citings_screen_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class CitingsScreen extends StatefulWidget {
  @override
  State<CitingsScreen> createState() => _CitingsScreenState();
}

class _CitingsScreenState extends State<CitingsScreen> with WidgetsBindingObserver {
  final _api = OfficerApiService();

  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String _search = '';
  String? _status, _type, _activity, _severity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final r = await _api.fetchCitings(page: 1, limit: 200);
      final items = (r['data']?['items'] ?? r['data']?['list'] ?? []) as List;
      if (!mounted) return;
      setState(() {
        _all = items.map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _view => _all.where((c) {
    if (_status   != null && c['citing_status']        != _status)   return false;
    if (_type     != null && c['citing_type']          != _type)     return false;
    if (_activity != null && c['illegal_activity_type']!= _activity) return false;
    if (_severity != null && c['severity']             != _severity) return false;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      return '${c['citing_ref_no']} ${c['reference_no']} ${c['boat_reg_no']}'
          .toLowerCase().contains(q);
    }
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final v = _view;
    return FisheriesOfficerOceanRefresh(
      onRefresh: () => _load(silent: true),
      child: CitingsScreenUI(
      citings: v,
      total: v.length,
      currentPage: 1,
      limit: 200,
      loading: _loading,
      search: _search,
      selectedStatus: _status,
      selectedType: _type,
      selectedActivity: _activity,
      selectedSeverity: _severity,
      statusTabs: const ['All', 'REPORTED', 'REVIEWED', 'RESOLVED', 'CLOSED'],
      totalCitings: _all.length,
      reportedCitings: _all.where((c) => c['citing_status'] == 'REPORTED').length,
      resolvedCitings: _all.where((c) => c['citing_status'] == 'RESOLVED').length,
      illegalActivity: _all.where((c) => c['citing_type'] == 'ILLEGAL_ACTIVITY').length,
      typeOptions: const ['All', 'OTHER_STATE_BOAT', 'ILLEGAL_ACTIVITY'],
      activityOptions: const ['All', 'UNKNOWN', 'OTHER', 'BANNED_GEAR'],
      onSearchChanged: (x) => setState(() => _search = x),
      onStatusTab: (s) => setState(() => _status = s == 'All' ? null : s),
      onStatusCardTap: (s) => setState(() => _status = s),
      onTypeChanged: (s) => setState(() => _type = s == 'All' ? null : s),
      onActivityChanged: (s) => setState(() => _activity = s == 'All' ? null : s),
      onSeverityChanged: (s) => setState(() => _severity = s == 'All' ? null : s),
      onPageChanged: (_) {},
      onLimitChanged: (_) {},
      onClearFilters: () => setState(() {
        _search = '';
        _status = null;
        _type = null;
        _activity = null;
        _severity = null;
      }),
      onFromDateTap: () {},
      onToDateTap: () {},
      ),
    );
  }
}
