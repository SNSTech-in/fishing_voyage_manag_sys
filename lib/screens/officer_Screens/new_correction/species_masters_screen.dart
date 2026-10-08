import 'package:flutter/material.dart';

import '../../../services/api_services/officer_api_service.dart';

class SpeciesMastersScreen extends StatefulWidget {
  const SpeciesMastersScreen({super.key});

  @override
  State<SpeciesMastersScreen> createState() => _SpeciesMastersScreenState();
}

class _SpeciesMastersScreenState extends State<SpeciesMastersScreen> {
  final OfficersApiService _api = OfficersApiService();
  final _searchCtrl = TextEditingController();

  // Palette
  static const Color _primary = Color(0xFF1257C7);
  static const Color _primaryDark = Color(0xFF07347F);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _success = Color(0xFF059669);
  static const Color _warning = Color(0xFFD97706);

  /// The FULL master list (never touched by filters).
  List<Map<String, dynamic>> _allItems = [];

  /// The currently displayed list (after applying status + search filters).
  List<Map<String, dynamic>> _items = [];

  bool _loading = true;
  String? _error;

  // Filters
  bool? _bannedFilter; // null = all, true = banned only, false = not banned
  bool? _activeFilter; // null = all, true = active only, false = inactive only

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Robust field readers ────────────────────────────────

  /// Convert a JSON value to bool regardless of `true` / `"true"` / 1 / "1".
  bool _asBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes' || s == 'y';
  }

  /// Read "is active" from a record, trying several plausible key names
  /// so this works no matter how the backend names the field.
  bool _activeOf(Map<String, dynamic> e) {
    for (final k in const [
      'is_active',
      'active',
      'isActive',
      'enabled',
      'is_enabled',
    ]) {
      if (e.containsKey(k)) return _asBool(e[k]);
    }
    return false;
  }

  /// Read "is banned" from a record, trying several plausible key names.
  bool _bannedOf(Map<String, dynamic> e) {
    for (final k in const [
      'is_banned',
      'banned',
      'isBanned',
      'blocked',
      'is_blocked',
    ]) {
      if (e.containsKey(k)) return _asBool(e[k]);
    }
    return false;
  }

  // ── Networking ──────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Fetch the FULL master list. We do not rely on the backend to filter.
    final res = await _api.fetchSpecies(
      search: _searchCtrl.text.trim(),
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _allItems = OfficersApiService.extractList(res);
        _loading = false;
      });
      _applyFilters(); // derive _items from the freshly-fetched master
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Failed to load species';
        _loading = false;
      });
    }
  }

  // ── Local filtering (NO network call) ───────────────────

  /// Re-derives `_items` from `_allItems` using the current filter chips
  /// and search text. This is synchronous and guarantees the list shown
  /// matches the selected category.
  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();

    var filtered = List<Map<String, dynamic>>.from(_allItems);

    // Banned / Not banned (applied first so Active can exclude banned)
    if (_bannedFilter != null) {
      filtered = filtered
          .where((e) => _bannedOf(e) == _bannedFilter)
          .toList();
    }

    // Active / Inactive: only meaningful when we're not showing banned records.
    // A banned species is never counted as Active.
    if (_activeFilter != null) {
      filtered = filtered.where((e) {
        final active = _activeOf(e);
        final banned = _bannedOf(e);
        if (_activeFilter == true) {
          return active && !banned;   // active AND not banned
        } else {
          return !active && !banned;  // inactive AND not banned
        }
      }).toList();
    }

    // Search
    if (q.isNotEmpty) {
      filtered = filtered.where((e) {
        final name = (e['fish_name'] ?? '').toString().toLowerCase();
        final id = (e['species_id'] ?? '').toString().toLowerCase();
        return name.contains(q) || id.contains(q);
      }).toList();
    }

    setState(() {
      _items = filtered;
    });
  }

  // ── Summary counts derived from the FULL master list ────

  // Total = every species we fetched, regardless of flags.
  int get _totalCount => _allItems.length;

  // Banned: banned flag is on (active flag is ignored here — banned wins).
  int get _bannedCount =>
      _allItems.where(_bannedOf).length;

  // Active: active AND not banned, so the buckets don't overlap.
  int get _activeCount => _allItems
      .where((e) => _activeOf(e) && !_bannedOf(e))
      .length;

  // Inactive/Other: not banned and not active. Total = Active + Banned + Other.
  int get _otherCount => _allItems
      .where((e) => !_activeOf(e) && !_bannedOf(e))
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Fish Species',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: _primary,
        child: Column(
          children: [
            _summaryRow(),
            _searchAndFilters(),
            const Divider(height: 1, color: _divider),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  // ── Summary cards (Total / Active / Banned / Inactive) ─────────────
  Widget _summaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _summaryCard(
              label: 'Total',
              value: _totalCount,
              icon: Icons.list_alt_rounded,
              color: Colors.indigo,
            ),
            const SizedBox(width: 10),
            _summaryCard(
              label: 'Active',
              value: _activeCount,
              icon: Icons.check_circle_rounded,
              color: _success,
            ),
            const SizedBox(width: 10),
            _summaryCard(
              label: 'Banned',
              value: _bannedCount,
              icon: Icons.block_rounded,
              color: _danger,
            ),
            const SizedBox(width: 10),
            _summaryCard(
              label: 'Inactive',
              value: _otherCount,
              icon: Icons.pause_circle_rounded,
              color: _warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search + filter chips ───────────────────────────────
  Widget _searchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            // Apply locally so search + chip filters compose correctly.
            onChanged: (_) => _applyFilters(),
            onSubmitted: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Search species...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  _applyFilters();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  label: 'All',
                  selected:
                  _bannedFilter == null && _activeFilter == null,
                  onTap: () {
                    setState(() {
                      _bannedFilter = null;
                      _activeFilter = null;
                    });
                    _applyFilters(); // local, synchronous
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Active only',
                  selected: _activeFilter == true,
                  color: _success,
                  onTap: () {
                    setState(() {
                      _activeFilter = true;
                      _bannedFilter = null;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Inactive only',
                  selected: _activeFilter == false,
                  color: _warning,
                  onTap: () {
                    setState(() {
                      _activeFilter = false;
                      _bannedFilter = null;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Banned only',
                  selected: _bannedFilter == true,
                  color: _danger,
                  onTap: () {
                    setState(() {
                      _bannedFilter = true;
                      _activeFilter = null;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Not banned',
                  selected: _bannedFilter == false,
                  color: _primary,
                  onTap: () {
                    setState(() {
                      _bannedFilter = false;
                      _activeFilter = null;
                    });
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color color = _primary,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : _textDark,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? color : _divider,
          width: selected ? 1.5 : 1,
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────
  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'No species found.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _speciesTile(_items[i]),
    );
  }

  Widget _speciesTile(Map<String, dynamic> item) {
    final name = (item['fish_name'] ?? 'Unknown Species').toString();
    final scientific = (item['scientific_name'] ?? '').toString();
    final malayalam = (item['malayalam_name'] ?? '').toString();
    final active = _activeOf(item);
    final banned = _bannedOf(item);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phishing_rounded,
              size: 20,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Title(
                  color: _textDark,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ),
                if (scientific.isNotEmpty || malayalam.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [scientific, malayalam]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              // When the "Banned only" filter is active, the Active/Inactive
              // chip is redundant (and contradictory). Hide it.
              if (_bannedFilter != true)
                _statusChip(
                  label: active ? 'Active' : 'Inactive',
                  color: active ? _success : _warning,
                  icon: active
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_rounded,
                ),

              // Show the Banned/Allowed chip EXCEPT when filtering
              // "Not banned" — in that case every record is Allowed, so the
              // tag adds no information. Keep it for "Banned only" and "All".
              if (_bannedFilter != false)
                _statusChip(
                  label: banned ? 'Banned' : 'Allowed',
                  color: banned ? _danger : _primary,
                  icon: banned
                      ? Icons.block_rounded
                      : Icons.verified_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
