import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/officer_api_service.dart';
import '../ui/crew_not_returned_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class CrewNotReturned extends StatefulWidget {
  @override
  _CrewNotReturnedState createState() => _CrewNotReturnedState();
}

class _CrewNotReturnedState extends State<CrewNotReturned> {
  final OfficerApiService _api = OfficerApiService();

  // Data
  List<dynamic> _crewList = [];
  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool _loading = false;

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchCrew();
  }

  Future<void> _fetchCrew() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchCrewNotReturned(
        fromDate: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null,
        toDate: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null,
        search: _search.isNotEmpty ? _search : null,
        page: _currentPage,
        limit: _limit,
      );

      // NUCLEAR PARSING
      List items = _api.parseResponse(r);
      int total = 0;
      if (r != null && r['data'] != null && r['data'] is Map) {
        var d = r['data'];
        total = intFromMap(d, ['total', 'total_count', 'count'], fallback: items.length);
      } else {
        total = items.length;
      }

      setState(() {
        _crewList = items;
        _total = total;
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
    _fetchCrew();
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now().subtract(Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        _currentPage = 1;
      });
      _fetchCrew();
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
      _fetchCrew();
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fetchCrew();
  }

  void _onLimitChanged(int limit) {
    setState(() {
      _limit = limit;
      _currentPage = 1;
    });
    _fetchCrew();
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _search = '';
      _currentPage = 1;
    });
    _fetchCrew();
  }

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanRefresh(
      onRefresh: _fetchCrew,
      child: CrewNotReturnedUI(
        crewList: _crewList,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        loading: _loading,
        search: _search,
        fromDate: _fromDate,
        toDate: _toDate,
        onSearchChanged: _onSearchChanged,
        onFromDateTap: _selectFromDate,
        onToDateTap: _selectToDate,
        onPageChanged: _onPageChanged,
        onLimitChanged: _onLimitChanged,
        onClearFilters: _clearFilters,
      ),
    );
  }
}
