import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/officer_api_service.dart';
import 'boat_activity_report_ui.dart';

class BoatActivityReport extends StatefulWidget {
  const BoatActivityReport({super.key});

  @override
  State<BoatActivityReport> createState() => _BoatActivityReportState();
}

class _BoatActivityReportState extends State<BoatActivityReport> {
  final _api = OfficerApiService();
  List<dynamic> _list = [];
  int _total = 0, _page = 1, _limit = 20;
  bool _loading = false;
  String _search = '';
  DateTime? _from, _to;

  // Summary stats
  int _totalBoats = 0;
  int _totalVoyages = 0;
  double _totalCatch = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchBoatActivity(
        fromDate: _from != null
            ? DateFormat('yyyy-MM-dd').format(_from!)
            : null,
        toDate: _to != null
            ? DateFormat('yyyy-MM-dd').format(_to!)
            : null,
        boat: _search.isNotEmpty ? _search : null,
        page: _page,
        limit: _limit,
      );

      if (r['success'] == true) {
        final d = r['data'] ?? {};
        final items = d['items'] ?? [];
        
        setState(() {
          _list = items;
          _total = d['total'] ?? d['total_count'] ?? items.length;
          _totalBoats = d['total_boats'] ?? items.length;
          _totalVoyages = d['total_voyages'] ?? 0;
          _totalCatch = (d['total_catch_kg'] ?? 0.0).toDouble();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ boat activity: $e');
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
      _search = '';
      _from = null;
      _to = null;
      _page = 1;
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return BoatActivityReportUI(
      boatData: _list,
      total: _total,
      currentPage: _page,
      limit: _limit,
      loading: _loading,
      boatSearch: _search,
      fromDate: _from,
      toDate: _to,
      totalBoats: _totalBoats,
      totalVoyages: _totalVoyages,
      totalCatchKg: _totalCatch,
      onBoatSearchChanged: (v) {
        setState(() {
          _search = v;
          _page = 1;
        });
        _fetch();
      },
      onFromDateTap: () => _pick(true),
      onToDateTap: () => _pick(false),
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
