import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/officer_api_service.dart';
import '../ui/boat_activity_report_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class BoatActivityReport extends StatefulWidget {
  @override
  _BoatActivityReportState createState() => _BoatActivityReportState();
}

class _BoatActivityReportState extends State<BoatActivityReport> {
  final OfficerApiService _api = OfficerApiService();

  // Data
  List<dynamic> _boatData = [];
  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool _loading = false;

  // Summary stats
  int _totalBoats = 0;
  int _totalVoyages = 0;
  double _totalCatchKg = 0.0;

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;
  String _boatSearch = '';

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchBoatActivity(
        fromDate: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null,
        toDate: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null,
        boat: _boatSearch.isNotEmpty ? _boatSearch : null,
        page: _currentPage,
        limit: _limit,
      );

      // NUCLEAR PARSING
      List items = _api.parseResponse(r);
      int total = 0;
      if (r != null && r['data'] != null && r['data'] is Map) {
        var d = r['data'];
        total = intFromMap(d, ['total', 'total_count', 'count'], fallback: items.length);
        _totalBoats = intFromMap(d, ['total_boats', 'boats_count'], fallback: items.length);
        _totalVoyages = intFromMap(d, ['total_voyages', 'voyages_count']);
        _totalCatchKg = (d['total_catch_kg'] ?? d['total_catch'] ?? 0.0).toDouble();
      } else {
        total = items.length;
      }

      setState(() {
        _boatData = items;
        _total = total;
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error in _fetch: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onBoatSearchChanged(String value) {
    _boatSearch = value;
    _currentPage = 1;
    _fetchReport();
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now().subtract(Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        _currentPage = 1;
      });
      _fetchReport();
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
      _fetchReport();
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fetchReport();
  }

  void _onLimitChanged(int limit) {
    setState(() {
      _limit = limit;
      _currentPage = 1;
    });
    _fetchReport();
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _boatSearch = '';
      _currentPage = 1;
    });
    _fetchReport();
  }

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanRefresh(
      onRefresh: _fetchReport,
      child: BoatActivityReportUI(
        boatData: _boatData,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        loading: _loading,
        boatSearch: _boatSearch,
        fromDate: _fromDate,
        toDate: _toDate,
        totalBoats: _totalBoats,
        totalVoyages: _totalVoyages,
        totalCatchKg: _totalCatchKg,
        onBoatSearchChanged: _onBoatSearchChanged,
        onFromDateTap: _selectFromDate,
        onToDateTap: _selectToDate,
        onPageChanged: _onPageChanged,
        onLimitChanged: _onLimitChanged,
        onClearFilters: _clearFilters,
      ),
    );
  }
}
