import 'package:flutter/material.dart';
import '../services/officer_api_service.dart';
import '../ui/officers_screen_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class OfficersScreen extends StatefulWidget {
  @override
  _OfficersScreenState createState() => _OfficersScreenState();
}

class _OfficersScreenState extends State<OfficersScreen> {
  final OfficerApiService _api = OfficerApiService();

  // Data
  List<dynamic> _officers = [];
  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool _loading = false;

  // Summary stats
  int _totalOfficers = 0;
  int _activeOfficers = 0;
  int _inactiveOfficers = 0;

  // Filters
  String _search = '';
  String? _selectedDepartment; // null = All
  bool? _activeFilter; // null = All, true = Active, false = Inactive

  // Available departments (populated from data)
  List<String> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetchOfficers();
  }

  Future<void> _fetchOfficers() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchOfficers(
        search: _search.isNotEmpty ? _search : null,
        department: _selectedDepartment,
        active: _activeFilter,
        page: _currentPage,
        limit: _limit,
      );

      // NUCLEAR PARSING
      List items = _api.parseResponse(r);
      int total = 0;
      if (r != null && r['data'] != null && r['data'] is Map) {
        var d = r['data'];
        total = intFromMap(d, ['total', 'total_count', 'count'], fallback: items.length);
        _totalOfficers = intFromMap(d, ['total_officers', 'officers_count'], fallback: items.length);
        _activeOfficers = d['active_officers'] ?? 0;
        _inactiveOfficers = d['inactive_officers'] ?? 0;
      } else {
        total = items.length;
      }

      setState(() {
        _officers = items;
        _total = total;
        // Extract unique departments
        final deptSet = <String>{};
        for (var o in items) {
          final dept = o['department']?.toString();
          if (dept != null && dept.isNotEmpty) deptSet.add(dept);
        }
        _departments = deptSet.toList()..sort();
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error in _fetch: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _search = value;
    _currentPage = 1;
    _fetchOfficers();
  }

  void _onDepartmentFilterChanged(String? dept) {
    setState(() {
      _selectedDepartment = dept == 'All' ? null : dept;
      _currentPage = 1;
    });
    _fetchOfficers();
  }

  void _onActiveFilterChanged(String? val) {
    setState(() {
      if (val == 'All') _activeFilter = null;
      else if (val == 'Active') _activeFilter = true;
      else if (val == 'Inactive') _activeFilter = false;
      _currentPage = 1;
    });
    _fetchOfficers();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fetchOfficers();
  }

  void _onLimitChanged(int limit) {
    setState(() {
      _limit = limit;
      _currentPage = 1;
    });
    _fetchOfficers();
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _selectedDepartment = null;
      _activeFilter = null;
      _currentPage = 1;
    });
    _fetchOfficers();
  }

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanRefresh(
      onRefresh: _fetchOfficers,
      child: OfficersScreenUI(
        officers: _officers,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        loading: _loading,
        search: _search,
        selectedDepartment: _selectedDepartment,
        activeFilter: _activeFilter,
        departments: _departments,
        totalOfficers: _totalOfficers,
        activeOfficers: _activeOfficers,
        inactiveOfficers: _inactiveOfficers,
        onSearchChanged: _onSearchChanged,
        onDepartmentFilterChanged: _onDepartmentFilterChanged,
        onActiveFilterChanged: _onActiveFilterChanged,
        onPageChanged: _onPageChanged,
        onLimitChanged: _onLimitChanged,
        onClearFilters: _clearFilters,
      ),
    );
  }
}
