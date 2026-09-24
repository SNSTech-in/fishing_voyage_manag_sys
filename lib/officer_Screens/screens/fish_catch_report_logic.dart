import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_services/officer_api_service.dart';
import '../ui/fish_catch_report_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class FishCatchReport extends StatefulWidget {
  @override
  _FishCatchReportState createState() => _FishCatchReportState();
}

class _FishCatchReportState extends State<FishCatchReport> {
  final OfficerApiService _api = OfficerApiService();

  // Data
  List<dynamic> _catchData = [];
  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool _loading = false;

  // Summary stats
  double _totalCatchKg = 0.0;
  int _totalVoyages = 0;

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _groupBy; // null means "Species"

  final List<String> _groupOptions = [
    'Species',
    'Voyage',
    'Boat',
  ];

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchFishCatchReport(
        fromDate: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 30))),
        toDate: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        groupBy: _groupBy == 'Species' ? null : _groupBy?.toLowerCase(),
        page: _currentPage,
        limit: _limit,
      );

      print('🐟 FishCatch Response: $r');
      print('🐟 success: ${r['success']}');
      print('🐟 data: ${r['data']}');

      // NUCLEAR PARSING
      List items = _api.parseResponse(r);
      int total = 0;
      if (r != null && r['data'] != null && r['data'] is Map) {
        var d = r['data'];
        total = intFromMap(d, ['total', 'total_count', 'count'], fallback: items.length);
        _totalCatchKg = (d['total_catch_kg'] ?? d['total_catch'] ?? 0.0).toDouble();
        _totalVoyages = intFromMap(d, ['total_voyages', 'voyage_count']);
      } else {
        total = items.length;
      }

      setState(() {
        _catchData = items;
        _total = total;
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error in _fetch: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onGroupByChanged(String? group) {
    setState(() {
      _groupBy = group;
      _currentPage = 1;
    });
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

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanRefresh(
      onRefresh: _fetchReport,
      child: FishCatchReportUI(
        catchData: _catchData,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        loading: _loading,
        fromDate: _fromDate,
        toDate: _toDate,
        selectedGroup: _groupBy,
        groupOptions: _groupOptions,
        totalCatchKg: _totalCatchKg,
        totalVoyages: _totalVoyages,
        onFromDateTap: _selectFromDate,
        onToDateTap: _selectToDate,
        onGroupByChanged: _onGroupByChanged,
        onPageChanged: _onPageChanged,
        onLimitChanged: _onLimitChanged,
      ),
    );
  }
}
