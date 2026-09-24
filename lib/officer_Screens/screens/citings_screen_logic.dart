import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_services/officer_api_service.dart';
import '../ui/citings_screen_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class CitingsScreen extends StatefulWidget {
  const CitingsScreen({super.key});

  @override
  State<CitingsScreen> createState() => _CitingsScreenState();
}

class _CitingsScreenState extends State<CitingsScreen> with WidgetsBindingObserver {
  final OfficerApiService _api = OfficerApiService();

  // Data
  List<dynamic> _citings = [];
  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool _loading = false;

  // Summary stats
  int _totalCitingsCount = 0;
  int _reportedCount = 0;
  int _resolvedCount = 0;
  int _illegalCount = 0;

  // Filters
  String _search = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _type; // null means "All"
  String? _activity; // null means "All"
  String? _status; // null means "All"
  String? _severity; // null means "All"

  final List<String> _statusTabs = [
    'All',
    'REPORTED',
    'REVIEWED',
    'RESOLVED',
    'CLOSED',
  ];

  final List<String> _typeOptions = [
    'All',
    'OTHER_STATE_BOAT',
    'ILLEGAL_ACTIVITY',
  ];

  final List<String> _activityOptions = [
    'All',
    'UNKNOWN',
    'OTHER',
    'BANNED_GEAR',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchCitings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchCitings(silent: true);
    }
  }

  Future<void> _fetchCitings({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final r = await _api.fetchCitings(
        search: _search.isNotEmpty ? _search : null,
        fromDate: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null,
        toDate: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null,
        type: _type == 'All' ? null : _type,
        activity: _activity == 'All' ? null : _activity,
        status: _status == 'All' ? null : _status,
        severity: _severity == 'All' ? null : _severity,
        page: _currentPage,
        limit: _limit,
      );

      // NUCLEAR PARSING
      List items = _api.parseResponse(r);
      int total = 0;
      if (r != null && r['data'] != null && r['data'] is Map) {
        var d = r['data'];

        int _countWhere(String key, String value) => items.where((x) =>
            (x[key] ?? '').toString().toUpperCase() == value.toUpperCase()
        ).length;

        total = intFromMap(d, ['total', 'total_count', 'count'], fallback: items.length);
        _totalCitingsCount = total;

        _reportedCount = intFromMap(d, ['reported_citings', 'reported', 'total_reported']);
        if (_reportedCount == 0) _reportedCount = _countWhere('citing_status', 'REPORTED');

        _resolvedCount = intFromMap(d, ['resolved_citings', 'resolved', 'total_resolved']);
        if (_resolvedCount == 0) _resolvedCount = _countWhere('citing_status', 'RESOLVED');

        _illegalCount = intFromMap(d, ['illegal_activity', 'illegal', 'total_illegal']);
        if (_illegalCount == 0) _illegalCount = items.where((c) => (c['citing_type'] ?? '').toString().toUpperCase() == 'ILLEGAL_ACTIVITY').length;
      } else {
        total = items.length;
      }

      if (!mounted) return;
      setState(() {
        _citings = items;
        _total = total;
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error in _fetch: $e");
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _search = value;
      _currentPage = 1;
    });
    _fetchCitings();
  }

  void _onStatusTab(String status) {
    setState(() {
      _status = status == 'All' ? null : status;
      _currentPage = 1;
    });
    _fetchCitings();
  }

  void _onTypeChanged(String? type) {
    setState(() {
      _type = type == 'All' ? null : type;
      _currentPage = 1;
    });
    _fetchCitings();
  }

  void _onActivityChanged(String? activity) {
    setState(() {
      _activity = activity == 'All' ? null : activity;
      _currentPage = 1;
    });
    _fetchCitings();
  }

  void _onSeverityChanged(String? severity) {
    setState(() {
      _severity = severity == 'All' ? null : severity;
      _currentPage = 1;
    });
    _fetchCitings();
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        _currentPage = 1;
      });
      _fetchCitings();
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
        _currentPage = 1;
      });
      _fetchCitings();
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fetchCitings();
  }

  void _onLimitChanged(int limit) {
    setState(() {
      _limit = limit;
      _currentPage = 1;
    });
    _fetchCitings();
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _fromDate = null;
      _toDate = null;
      _type = null;
      _activity = null;
      _status = null;
      _severity = null;
      _currentPage = 1;
    });
    _fetchCitings();
  }

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanRefresh(
      onRefresh: () => _fetchCitings(silent: true),
      child: CitingsScreenUI(
        citings: _citings,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        loading: _loading,
        search: _search,
        fromDate: _fromDate,
        toDate: _toDate,
        onFromDateTap: _selectFromDate,
        onToDateTap: _selectToDate,
        selectedStatus: _status,
        selectedSeverity: _severity,
        selectedType: _type,
        selectedActivity: _activity,
        statusTabs: _statusTabs,
        typeOptions: _typeOptions,
        activityOptions: _activityOptions,
        totalCitings: _totalCitingsCount,
        reportedCitings: _reportedCount,
        resolvedCitings: _resolvedCount,
        illegalActivity: _illegalCount,
        onSearchChanged: _onSearchChanged,
        onStatusTab: _onStatusTab,
        onStatusCardTap: (s) => _onStatusTab(s ?? 'All'),
        onTypeChanged: _onTypeChanged,
        onActivityChanged: _onActivityChanged,
        onSeverityChanged: _onSeverityChanged,
        onPageChanged: _onPageChanged,
        onLimitChanged: _onLimitChanged,
        onClearFilters: _clearFilters,
      ),
    );
  }
}
