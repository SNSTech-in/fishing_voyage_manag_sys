import 'package:flutter/material.dart';
import '../services/officer_api_service.dart';
import 'officers_screen_ui.dart';

class OfficersScreen extends StatefulWidget {
  const OfficersScreen({super.key});

  @override
  State<OfficersScreen> createState() => _OfficersScreenState();
}

class _OfficersScreenState extends State<OfficersScreen> {
  final _api = OfficerApiService();
  List<dynamic> _list = [];
  bool _loading = false;
  String _search = '';
  String? _department;
  bool? _activeFilter;

  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;

  int _totalOfficersCount = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;
  List<String> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchOfficers(
        search: _search.isNotEmpty ? _search : null,
        department: _department,
        active: _activeFilter,
        page: _currentPage,
        limit: _limit,
      );

      if (r['success'] == true) {
        final d = r['data'] ?? {};
        final list = d['items'] ?? [];
        
        // Metadata
        final meta = d['meta'] ?? {};
        final total = meta['total'] ?? list.length;

        // Stats calculation
        // For accurate stats, we usually need a summary API, 
        // but here we follow the pattern of the UI which recalculates from the current list for display
        // However, we still pass the counts if the UI uses them from fields.
        final active = list.where((o) => o['is_active'] == true).length;
        final inactive = list.length - active;

        // Build department list if not already populated (or update it)
        if (_departments.isEmpty) {
          final deptSet = <String>{};
          for (var o in list) {
            final dep = o['department']?.toString();
            if (dep != null && dep.isNotEmpty) deptSet.add(dep);
          }
          _departments = deptSet.toList()..sort();
        }

        setState(() {
          _list = list;
          _total = total;
          _totalOfficersCount = total;
          _activeCount = active;
          _inactiveCount = inactive;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ officers error: $e');
      setState(() => _loading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _department = null;
      _activeFilter = null;
      _currentPage = 1;
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return OfficersScreenUI(
      officers: _list,
      total: _total,
      currentPage: _currentPage,
      limit: _limit,
      loading: _loading,
      search: _search,
      selectedDepartment: _department,
      activeFilter: _activeFilter,
      departments: _departments,
      totalOfficers: _totalOfficersCount,
      activeOfficers: _activeCount,
      inactiveOfficers: _inactiveCount,
      onSearchChanged: (v) {
        setState(() {
          _search = v;
          _currentPage = 1;
        });
        _fetch();
      },
      onDepartmentFilterChanged: (d) {
        setState(() {
          _department = d == 'All' ? null : d;
          _currentPage = 1;
        });
        _fetch();
      },
      onActiveFilterChanged: (v) {
        setState(() {
          if (v == 'All') {
            _activeFilter = null;
          } else if (v == 'Active') {
            _activeFilter = true;
          } else {
            _activeFilter = false;
          }
          _currentPage = 1;
        });
        _fetch();
      },
      onPageChanged: (p) {
        setState(() => _currentPage = p);
        _fetch();
      },
      onLimitChanged: (l) {
        setState(() {
          _limit = l;
          _currentPage = 1;
        });
        _fetch();
      },
      onClearFilters: _clearFilters,
    );
  }
}
