import 'package:flutter/material.dart';
import '../services/officer_api_service.dart';
import '../ui/species_screen_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class SpeciesScreen extends StatefulWidget {
  @override
  _SpeciesScreenState createState() => _SpeciesScreenState();
}

class _SpeciesScreenState extends State<SpeciesScreen> {
  final OfficerApiService _api = OfficerApiService();

  // Data
  List<dynamic> _species = [];
  int _total = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool _loading = false;

  // Summary stats
  int _totalSpecies = 0;
  int _bannedSpecies = 0;
  int _activeSpecies = 0;

  // Filters
  String _search = '';
  bool? _bannedFilter; // null = All, true = Banned, false = Not Banned
  bool? _activeFilter; // null = All, true = Active, false = Inactive

  @override
  void initState() {
    super.initState();
    _fetchSpecies();
  }

  Future<void> _fetchSpecies() async {
    setState(() => _loading = true);
    try {
      final r = await _api.fetchSpecies(
        search: _search.isNotEmpty ? _search : null,
        banned: _bannedFilter,
        active: _activeFilter,
        page: _currentPage,
        limit: _limit,
      );

      // NUCLEAR PARSING
      List items = _api.parseResponse(r);
      int total = 0;
      if (r != null && r['data'] != null && r['data'] is Map) {
        var d = r['data'];
        total = intFromMap(d, ['total', 'total_count', 'count'], fallback: items.length);
        _totalSpecies = intFromMap(d, ['total_species', 'species_count'], fallback: items.length);
        _bannedSpecies = d['banned_species'] ?? 0;
        _activeSpecies = d['active_species'] ?? 0;
      } else {
        total = items.length;
      }

      setState(() {
        _species = items;
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
    _fetchSpecies();
  }

  void _onBannedFilterChanged(String? val) {
    setState(() {
      if (val == 'All') _bannedFilter = null;
      else if (val == 'Banned') _bannedFilter = true;
      else if (val == 'Not Banned') _bannedFilter = false;
      _currentPage = 1;
    });
    _fetchSpecies();
  }

  void _onActiveFilterChanged(String? val) {
    setState(() {
      if (val == 'All') _activeFilter = null;
      else if (val == 'Active') _activeFilter = true;
      else if (val == 'Inactive') _activeFilter = false;
      _currentPage = 1;
    });
    _fetchSpecies();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fetchSpecies();
  }

  void _onLimitChanged(int limit) {
    setState(() {
      _limit = limit;
      _currentPage = 1;
    });
    _fetchSpecies();
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _bannedFilter = null;
      _activeFilter = null;
      _currentPage = 1;
    });
    _fetchSpecies();
  }

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanRefresh(
      onRefresh: _fetchSpecies,
      child: SpeciesScreenUI(
        species: _species,
        total: _total,
        currentPage: _currentPage,
        limit: _limit,
        loading: _loading,
        search: _search,
        bannedFilter: _bannedFilter,
        activeFilter: _activeFilter,
        totalSpecies: _totalSpecies,
        bannedSpecies: _bannedSpecies,
        activeSpecies: _activeSpecies,
        onSearchChanged: _onSearchChanged,
        onBannedFilterChanged: _onBannedFilterChanged,
        onActiveFilterChanged: _onActiveFilterChanged,
        onPageChanged: _onPageChanged,
        onLimitChanged: _onLimitChanged,
        onClearFilters: _clearFilters,
      ),
    );
  }
}
