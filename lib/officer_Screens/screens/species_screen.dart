import 'package:flutter/material.dart';
import '../../services/api_services/officer_api_service.dart';
import 'species_screen_ui.dart';

class SpeciesScreen extends StatefulWidget {
  const SpeciesScreen({super.key});

  @override
  State<SpeciesScreen> createState() => _SpeciesScreenState();
}

class _SpeciesScreenState extends State<SpeciesScreen> {
  final _api = OfficerApiService();
  List<dynamic> _list = [];
  bool _loading = false;
  String _search = '';
  bool? _bannedFilter;
  bool? _activeFilter;

  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;

  int _totalSpecies = 0;
  int _bannedCount = 0;
  int _activeCount = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchSpecies(
        search: _search.isNotEmpty ? _search : null,
        banned: _bannedFilter,
        active: _activeFilter,
        page: _currentPage,
        limit: _limit,
      );

      if (r['success'] == true) {
        final d = r['data'] ?? {};
        final list = d['items'] ?? [];
        
        // Metadata if available, otherwise fallback
        final meta = d['meta'] ?? {};
        final total = meta['total'] ?? list.length;
        
        // Stats - usually these would come from an API summary, 
        // but if not, we can approximate from current list or meta
        // For now, let's keep the logic of counting from list if summary not present
        final int banned = list.where((s) => s['is_banned'] == true).length;
        final int active = list.where((s) => s['is_active'] == true).length;

        setState(() {
          _list = list;
          _total = total;
          _totalSpecies = total; // Assuming total matches totalSpecies for simplicity
          _bannedCount = banned; 
          _activeCount = active;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('❌ species error: $e');
      setState(() => _loading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _bannedFilter = null;
      _activeFilter = null;
      _currentPage = 1;
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return SpeciesScreenUI(
      species: _list,
      total: _total,
      currentPage: _currentPage,
      limit: _limit,
      loading: _loading,
      search: _search,
      bannedFilter: _bannedFilter,
      activeFilter: _activeFilter,
      totalSpecies: _totalSpecies,
      bannedSpecies: _bannedCount,
      activeSpecies: _activeCount,
      onSearchChanged: (v) {
        setState(() {
          _search = v;
          _currentPage = 1;
        });
        _fetch();
      },
      onBannedFilterChanged: (v) {
        setState(() {
          if (v == 'All') {
            _bannedFilter = null;
          } else if (v == 'Banned') {
            _bannedFilter = true;
          } else {
            _bannedFilter = false;
          }
          _currentPage = 1;
        });
        _fetch();
      },
      onActiveFilterChanged: (v) {
        setState(() {
          if (v == 'All') {
            _activeFilter = null;
          } else if (v == 'Active') {
            _activeFilter = true;
          } else {
            _activeFilter = false;
          }
          _currentPage = 1;
        });
        _fetch();
      },
      onPageChanged: (p) {
        setState(() => _currentPage = p);
        _fetch();
      },
      onLimitChanged: (l) {
        setState(() {
          _limit = l;
          _currentPage = 1;
        });
        _fetch();
      },
      onClearFilters: _clearFilters,
    );
  }
}
