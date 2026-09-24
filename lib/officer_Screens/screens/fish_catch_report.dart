import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_services/officer_api_service.dart';
import 'fish_catch_report_ui.dart';

class FishCatchReport extends StatefulWidget {
  const FishCatchReport({super.key});

  @override
  State<FishCatchReport> createState() => _FishCatchReportState();
}

class _FishCatchReportState extends State<FishCatchReport> {
  final _api = OfficerApiService();
  List<dynamic> _list = [];
  int _total = 0, _page = 1, _limit = 20;
  bool _loading = false;
  double _totalCatch = 0;
  int _totalVoyages = 0;
  DateTime? _from, _to;
  String? _groupBy;
  final _groups = ['Species', 'Voyage', 'Boat'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchFishCatchReport(
        fromDate: _from != null
            ? DateFormat('yyyy-MM-dd').format(_from!)
            : null,
        toDate: _to != null
            ? DateFormat('yyyy-MM-dd').format(_to!)
            : null,
        groupBy: _groupBy == 'Species' ? null : _groupBy?.toLowerCase(),
        page: _page,
        limit: _limit,
      );

      if (r['success'] == true) {
        final d = r['data'] ?? {};
        final list = d['items'] ?? [];

        setState(() {
          _list = list;
          _total = d['total'] ?? d['total_count'] ?? list.length;
          _totalCatch = (d['total_weight_kg'] ?? 0).toDouble();
          _totalVoyages = (d['total_voyages'] ?? 0) as int;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ fish catch error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _pick(bool isFrom) async {
    final p = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_from ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_to ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (p != null) {
      setState(() {
        if (isFrom) {
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
      _from = null;
      _to = null;
      _groupBy = null;
      _page = 1;
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return FishCatchReportUI(
      catchData: _list,
      total: _total,
      currentPage: _page,
      limit: _limit,
      loading: _loading,
      fromDate: _from,
      toDate: _to,
      selectedGroup: _groupBy,
      groupOptions: _groups,
      totalCatchKg: _totalCatch,
      totalVoyages: _totalVoyages,
      onFromDateTap: () => _pick(true),
      onToDateTap: () => _pick(false),
      onGroupByChanged: (g) {
        setState(() {
          _groupBy = g;
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
