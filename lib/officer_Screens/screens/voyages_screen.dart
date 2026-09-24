import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_services/officer_api_service.dart';
import '../ui/voyages_screen_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class VoyagesScreen extends StatefulWidget {
  const VoyagesScreen({super.key});

  @override
  State<VoyagesScreen> createState() => _VoyagesScreenState();
}

class _VoyagesScreenState extends State<VoyagesScreen> {
  final OfficerApiService _api = OfficerApiService();

  List<dynamic> _voyageList = [];
  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool _loading = true;
  String _search = '';
  String? _selectedStatus;

  int _totalVoyages = 0;
  int _activeVoyages = 0;
  int _overdueVoyages = 0;
  int _completedVoyages = 0;
  int _cancelledVoyages = 0;

  static const List<String> _statusTabs = [
    'All', 'ONGOING', 'OVERDUE', 'COMPLETED', 'CANCELLED',
  ];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }
    setState(() => _loading = true);
    try {
      final r = await _api.fetchVoyages(
        search: _search.isNotEmpty ? _search : null,
        status: _selectedStatus,
        page: _currentPage,
        limit: _limit,
      );

      final items = _api.parseResponse(r);

      int total = items.length;
      if (r['data'] is Map) {
        final d = r['data'] as Map;
        
        int _countWhere(String key, String value) => items.where((x) =>
            (x[key] ?? '').toString().toUpperCase() == value.toUpperCase()
        ).length;

        // Try backend keys first; if they are 0/null, compute from items
        total = intFromMap(d, ['total', 'total_count', 'count'], fallback: items.length);
        
        _totalVoyages = total;
        
        _activeVoyages = intFromMap(d, ['active_voyages', 'active', 'total_active']);
        if (_activeVoyages == 0) {
          _activeVoyages = _countWhere('derived_status', 'ACTIVE') + _countWhere('derived_status', 'ONGOING');
        }
        if (_activeVoyages == 0) {
          _activeVoyages = _countWhere('status', 'ACTIVE') + _countWhere('status', 'ONGOING');
        }

        _overdueVoyages = intFromMap(d, ['overdue_voyages', 'overdue', 'total_overdue']);
        if (_overdueVoyages == 0) _overdueVoyages = _countWhere('derived_status', 'OVERDUE');
        if (_overdueVoyages == 0) _overdueVoyages = _countWhere('status', 'OVERDUE');

        _completedVoyages = intFromMap(d, ['completed_voyages', 'completed', 'total_completed']);
        if (_completedVoyages == 0) _completedVoyages = _countWhere('derived_status', 'COMPLETED');
        if (_completedVoyages == 0) _completedVoyages = _countWhere('status', 'COMPLETED');

        _cancelledVoyages = intFromMap(d, ['cancelled_voyages', 'cancelled', 'total_cancelled']);
        if (_cancelledVoyages == 0) _cancelledVoyages = _countWhere('derived_status', 'CANCELLED');
        if (_cancelledVoyages == 0) _cancelledVoyages = _countWhere('status', 'CANCELLED');
      }

      if (!mounted) return;
      setState(() {
        _voyageList = items;
        _total      = total;
        _loading    = false;
      });
    } catch (e) {
      debugPrint('❌ voyages: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load voyages: $e')),
      );
    }
  }

  void _onSearchChanged(String v) {
    _search = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _currentPage = 1;
      _load();
    });
  }

  void _onStatusTab(String tab) {
    setState(() {
      _selectedStatus = (tab == 'All') ? null : tab;
      _currentPage = 1;
    });
    _load();
  }

  void _onPageChanged(int p) {
    setState(() => _currentPage = p);
    _load();
  }

  void _onLimitChanged(int l) {
    setState(() {
      _limit = l;
      _currentPage = 1;
    });
    _load();
  }

  void _onClearFilters() {
    setState(() {
      _search = '';
      _selectedStatus = null;
      _currentPage = 1;
    });
    _load();
  }

  Future<void> _refresh() async {
    await _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: FisheriesOfficerOcean.primary,
      backgroundColor: FisheriesOfficerOcean.card,
      child: VoyagesScreenUI(
        voyages: _voyageList,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        loading: _loading,
        search: _search,
        selectedStatus: _selectedStatus,
        statusTabs: _statusTabs,
        totalVoyages: _totalVoyages,
        activeVoyages: _activeVoyages,
        overdueVoyages: _overdueVoyages,
        completedVoyages: _completedVoyages,
        cancelledVoyages: _cancelledVoyages,
        onSearchChanged: _onSearchChanged,
        onStatusTab: _onStatusTab,
        onPageChanged: _onPageChanged,
        onLimitChanged: _onLimitChanged,
        onClearFilters: _onClearFilters,
      ),
    );
  }
}
