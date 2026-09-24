import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/officer_api_service.dart';
import 'crew_not_returned_ui.dart';

class CrewNotReturned extends StatefulWidget {
  const CrewNotReturned({super.key});

  @override
  State<CrewNotReturned> createState() => _CrewNotReturnedState();
}

class _CrewNotReturnedState extends State<CrewNotReturned> {
  final _api = OfficerApiService();
  List<dynamic> _list = [];
  int _total = 0, _page = 1, _limit = 20;
  bool _loading = false;
  String _search = '';
  DateTime? _from, _to;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchCrewNotReturned(
        fromDate: _from != null
            ? DateFormat('yyyy-MM-dd').format(_from!)
            : null,
        toDate: _to != null
            ? DateFormat('yyyy-MM-dd').format(_to!)
            : null,
        search: _search.isNotEmpty ? _search : null,
        page: _page,
        limit: _limit,
      );

      if (r['success'] == true) {
        final d = r['data'] ?? {};
        setState(() {
          _list = d['items'] ?? [];
          _total = d['total'] ?? d['total_count'] ?? (d['items'] ?? []).length;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ crew not returned error: $e');
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
    return CrewNotReturnedUI(
      crewList: _list,
      total: _total,
      currentPage: _page,
      limit: _limit,
      loading: _loading,
      search: _search,
      fromDate: _from,
      toDate: _to,
      onSearchChanged: (v) {
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
