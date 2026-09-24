import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_services/officer_api_service.dart';
import 'sos_report_ui.dart';

class SosReport extends StatefulWidget {
  const SosReport({super.key});

  @override
  State<SosReport> createState() => _SosReportState();
}

class _SosReportState extends State<SosReport> {
  final _api = OfficerApiService();
  List<dynamic> _list = [];
  int _total = 0, _page = 1, _limit = 20;
  bool _loading = false;
  int _totalSos = 0;
  double? _avgResponse;
  DateTime? _from, _to;
  String? _status;
  final _statusOptions = ['All', 'OPEN', 'RESOLVED', 'CLOSED'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchSosReport(
        fromDate: _from != null
            ? DateFormat('yyyy-MM-dd').format(_from!)
            : null,
        toDate: _to != null
            ? DateFormat('yyyy-MM-dd').format(_to!)
            : null,
        status: _status,
        page: _page,
        limit: _limit,
      );

      if (r['success'] == true) {
        final d = r['data'] ?? {};
        setState(() {
          _list = d['items'] ?? [];
          _total = d['total'] ?? d['total_count'] ?? (d['items'] ?? []).length;
          _totalSos = d['total'] ?? d['total_count'] ?? (d['items'] ?? []).length;
          _avgResponse = d['avg_response_time_min']?.toDouble();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ sos report: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _pick(bool from) async {
    final p = await showDatePicker(
      context: context,
      initialDate: from
          ? (_from ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_to ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (p != null) {
      setState(() {
        if (from) {
          _from = p;
        } else {
          _to = p;
        }
        _page = 1;
      });
      _fetch();
    }
  }

  void _clearFilters() {
    setState(() {
      _status = null;
      _from = null;
      _to = null;
      _page = 1;
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return SosReportUI(
      sosList: _list,
      total: _total,
      currentPage: _page,
      limit: _limit,
      loading: _loading,
      fromDate: _from,
      toDate: _to,
      selectedStatus: _status,
      statusOptions: _statusOptions,
      totalSos: _totalSos,
      avgResponseMin: _avgResponse,
      onFromDateTap: () => _pick(true),
      onToDateTap: () => _pick(false),
      onStatusChanged: (s) {
        setState(() {
          _status = s == 'All' ? null : s;
          _page = 1;
        });
        _fetch();
      },
      onPageChanged: (p) {
        setState(() => _page = p);
        _fetch();
      },
      onLimitChanged: (l) {
        setState(() {
          _limit = l;
          _page = 1;
        });
        _fetch();
      },
      onClearFilters: _clearFilters,
    );
  }
}
