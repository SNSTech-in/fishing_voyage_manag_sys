import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/officer_api_service.dart';
import '../ui/ports_screen_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class PortsScreen extends StatefulWidget {
  const PortsScreen({super.key});

  @override
  State<PortsScreen> createState() => _PortsScreenState();
}

class _PortsScreenState extends State<PortsScreen> {
  final OfficerApiService _api = OfficerApiService();

  // Data
  List<dynamic> _ports = [];
  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool _loading = false;

  // Summary stats
  int _totalPorts = 0;
  int _activePorts = 0;
  int _inactivePorts = 0;

  // Filters
  String _search = '';
  String? _selectedState; // null = All
  bool? _activeFilter; // null = All, true = Active, false = Inactive

  // Available states (populated from data)
  List<String> _states = [];

  @override
  void initState() {
    super.initState();
    _fetchPorts();
  }

  Future<void> _fetchPorts() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchPorts(
        search: _search.isNotEmpty ? _search : null,
        state: _selectedState,
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
        _totalPorts = intFromMap(d, ['total_ports', 'ports_count'], fallback: items.length);
        _activePorts = d['active_ports'] ?? 0;
        _inactivePorts = d['inactive_ports'] ?? 0;
      } else {
        total = items.length;
      }

      setState(() {
        _ports = items;
        _total = total;
        // Extract unique states
        final stateSet = <String>{};
        for (var p in items) {
          final st = p['state']?.toString();
          if (st != null && st.isNotEmpty) stateSet.add(st);
        }
        _states = stateSet.toList()..sort();
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
    _fetchPorts();
  }

  void _onStateFilterChanged(String? state) {
    setState(() {
      _selectedState = state == 'All' ? null : state;
      _currentPage = 1;
    });
    _fetchPorts();
  }

  void _onActiveFilterChanged(bool? active) {
    setState(() {
      _activeFilter = active;
      _currentPage = 1;
    });
    _fetchPorts();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fetchPorts();
  }

  void _onLimitChanged(int limit) {
    setState(() {
      _limit = limit;
      _currentPage = 1;
    });
    _fetchPorts();
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _selectedState = null;
      _activeFilter = null;
      _currentPage = 1;
    });
    _fetchPorts();
  }

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanRefresh(
      onRefresh: _fetchPorts,
      child: PortsScreenUI(
        ports: _ports,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        loading: _loading,
        search: _search,
        selectedState: _selectedState,
        activeFilter: _activeFilter,
        states: _states,
        totalPorts: _totalPorts,
        activePorts: _activePorts,
        inactivePorts: _inactivePorts,
        onSearchChanged: _onSearchChanged,
        onStateFilterChanged: _onStateFilterChanged,
        onActiveFilterChanged: _onActiveFilterChanged,
        onPageChanged: _onPageChanged,
        onLimitChanged: _onLimitChanged,
        onClearFilters: _clearFilters,
      ),
    );
  }
}
