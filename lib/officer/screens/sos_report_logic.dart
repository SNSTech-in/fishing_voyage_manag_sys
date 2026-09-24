import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/officer_api_service.dart';
import '../ui/sos_report_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class SosReport extends StatefulWidget {
  const SosReport({super.key});

  @override
  State<SosReport> createState() => _SosReportState();
}

class _SosReportState extends State<SosReport> {
  final OfficerApiService _api = OfficerApiService();

  // Data
  List<dynamic> _sosList = [];
  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool _loading = false;

  // Summary stats
  int _totalSos = 0;
  double? _avgResponseMin;

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _status; // null means "All"

  final List<String> _statusOptions = [
    'All',
    'OPEN',
    'RESOLVED',
    'CLOSED',
  ];

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchSosReport(
        fromDate: _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null,
        toDate: _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null,
        status: _status == 'All' ? null : _status,
        page: _currentPage,
        limit: _limit,
      );

      // NUCLEAR PARSING
      List items = _api.parseResponse(r);
      int total = 0;
      if (r != null && r['data'] != null && r['data'] is Map) {
        var d = r['data'];
        total = intFromMap(d, ['total', 'total_count', 'count'], fallback: items.length);
        _totalSos = intFromMap(d, ['total_sos', 'sos_count'], fallback: items.length);
        _avgResponseMin = (d['avg_response_min'] ?? 0.0).toDouble();
      } else {
        total = items.length;
      }

      setState(() {
        _sosList = items;
        _total = total;
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error in _fetch: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onStatusChanged(String? status) {
    setState(() {
      _status = status == 'All' ? null : status;
      _currentPage = 1;
    });
    _fetchReport();
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
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
      _status = null;
      _currentPage = 1;
    });
    _fetchReport();
  }

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanRefresh(
      onRefresh: _fetchReport,
      child: SosReportUI(
        sosList: _sosList,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        loading: _loading,
        fromDate: _fromDate,
        toDate: _toDate,
        selectedStatus: _status,
        statusOptions: _statusOptions,
        totalSos: _totalSos,
        avgResponseMin: _avgResponseMin,
        onFromDateTap: _selectFromDate,
        onToDateTap: _selectToDate,
        onStatusChanged: _onStatusChanged,
        onPageChanged: _onPageChanged,
        onLimitChanged: _onLimitChanged,
        onClearFilters: _clearFilters,
      ),
    );
  }
}
