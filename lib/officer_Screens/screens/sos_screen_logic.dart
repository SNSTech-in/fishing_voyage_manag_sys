import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_services/officer_api_service.dart';
import '../ui/sos_screen_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class SosScreen extends StatefulWidget {
  @override
  _SosScreenState createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with WidgetsBindingObserver {
  final OfficerApiService _api = OfficerApiService();

  // Data
  List<dynamic> _sosList = [];
  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool _loading = false;

  // Filters
  String _search = '';
  String? _status; // null means "All"
  String? _severity; // null means "All"

  final List<String> _statusTabs = [
    'All',
    'OPEN',
    'RESOLVED',
    'CLOSED',
  ];

  final List<String> _severityOptions = [
    'All',
    'HIGH',
    'MEDIUM',
    'LOW',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchSos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchSos(silent: true);
    }
  }

  Future<void> _fetchSos({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final r = await _api.fetchSos(
        search: _search.isNotEmpty ? _search : null,
        status: _status == 'All' ? null : _status,
        severity: _severity == 'All' ? null : _severity,
        page: _currentPage,
        limit: _limit,
      );

      List items = _api.parseResponse(r);
      int total = 0;
      if (r != null && r['data'] != null && r['data'] is Map) {
        var d = r['data'];
        total = intFromMap(d, ['total', 'total_count', 'count'], fallback: items.length);
      } else {
        total = items.length;
      }

      if (!mounted) return;
      setState(() {
        _sosList = items;
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
    _search = value;
    _currentPage = 1;
    _fetchSos();
  }

  void _onStatusTab(String status) {
    setState(() {
      _status = status == 'All' ? null : status;
      _currentPage = 1;
    });
    _fetchSos();
  }

  void _onSeverityChanged(String? severity) {
    setState(() {
      _severity = severity == 'All' ? null : severity;
      _currentPage = 1;
    });
    _fetchSos();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fetchSos();
  }

  void _onLimitChanged(int limit) {
    setState(() {
      _limit = limit;
      _currentPage = 1;
    });
    _fetchSos();
  }

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanRefresh(
      onRefresh: () => _fetchSos(silent: true),
      child: SosScreenUI(
        sosList: _sosList,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        loading: _loading,
        search: _search,
        selectedStatus: _status,
        selectedSeverity: _severity,
        statusTabs: _statusTabs,
        severityOptions: _severityOptions,
        onSearchChanged: _onSearchChanged,
        onStatusTab: _onStatusTab,
        onStatusCardTap: (s) => _onStatusTab(s ?? 'All'),
        onSeverityChanged: _onSeverityChanged,
        onPageChanged: _onPageChanged,
        onLimitChanged: _onLimitChanged,
      ),
    );
  }
}
