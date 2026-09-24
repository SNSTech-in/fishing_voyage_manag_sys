import 'package:flutter/material.dart';
import '../services/officer_api_service.dart';
import 'ports_screen_ui.dart';

class PortsScreen extends StatefulWidget {
  const PortsScreen({super.key});

  @override
  State<PortsScreen> createState() => _PortsScreenState();
}

class _PortsScreenState extends State<PortsScreen> {
  final _api = OfficerApiService();
  List<dynamic> _list = [];
  int _total = 0, _currentPage = 1, _limit = 20;
  bool _loading = false;
  int _totalPortsCount = 0, _activePortsCount = 0, _inactivePortsCount = 0;
  String _search = '';
  String? _state;
  bool? _active;
  List<String> _states = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchPorts(
        search: _search.isNotEmpty ? _search : null,
        state: _state,
        active: _active,
        page: _currentPage,
        limit: _limit,
      );
      if (r['success'] == true) {
        final d = r['data'] ?? {};
        final list = d['items'] ?? [];
        final activeCount = list.where((p) => p['is_active'] == true || p['active'] == true).length;
        final inactiveCount = list.length - activeCount;
        
        if (_states.isEmpty) {
          final stateSet = <String>{};
          for (var p in list) {
            final st = p['state']?.toString();
            if (st != null && st.isNotEmpty) stateSet.add(st);
          }
          _states = stateSet.toList()..sort();
        }

        setState(() {
          _list = list;
          _total = d['total'] ?? list.length;
          _totalPortsCount = d['total'] ?? list.length;
          _activePortsCount = activeCount;
          _inactivePortsCount = inactiveCount;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ ports error: $e');
      setState(() => _loading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _state = null;
      _active = null;
      _currentPage = 1;
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return PortsScreenUI(
      ports: _list,
      total: _total,
      currentPage: _currentPage,
      limit: _limit,
      loading: _loading,
      search: _search,
      selectedState: _state,
      activeFilter: _active,
      states: _states,
      totalPorts: _totalPortsCount,
      activePorts: _activePortsCount,
      inactivePorts: _inactivePortsCount,
      onSearchChanged: (v) {
        setState(() {
          _search = v;
          _currentPage = 1;
        });
        _fetch();
      },
      onStateFilterChanged: (s) {
        setState(() {
          _state = s == 'All' ? null : s;
          _currentPage = 1;
        });
        _fetch();
      },
      onActiveFilterChanged: (v) {
        setState(() {
          _active = v;
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
