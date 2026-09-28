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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _api.fetchSpecies(
      search: _searchCtrl.text.trim(),
      banned: _bannedFilter,
      active: _activeFilter,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _items = OfficersApiService.extractList(res);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Failed to load species';
        _loading = false;
      });
    }
  }

  int _countBanned() =>
      _items.where((e) => e['is_banned'] == true).length;

  int _countActive() =>
      _items.where((e) => e['is_active'] == true).length;

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

  // ── Summary cards (Total / Active / Banned) ──────────────
  Widget _summaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              label: 'Total',
              value: _items.length,
              icon: Icons.list_alt_rounded,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
              label: 'Active',
              value: _countActive(),
              icon: Icons.check_circle_rounded,
              color: _success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
              label: 'Banned',
              value: _countBanned(),
              icon: Icons.block_rounded,
              color: _danger,
            ),
          ),
        ],
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

  // ── Search + filter chips ────────────────────────────────
  Widget _searchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Search species...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  _load();
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
                  selected: _bannedFilter == null &&
                      _activeFilter == null,
                  onTap: () {
                    setState(() {
                      _bannedFilter = null;
                      _activeFilter = null;
                    });
                    _load();
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
                    _load();
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
                    _load();
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
                    _load();
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
                    _load();
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
    return Material(
      color: selected ? color.withOpacity(0.15) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : _divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? color : _textDark,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────
  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _speciesTile(_items[i]),
    );
  }

  Widget _speciesTile(Map<String, dynamic> s) {
    final name = s['fish_name']?.toString() ?? '—';
    final id = s['species_id'] ?? '—';
    final isBanned = s['is_banned'] == true;
    final isActive = s['is_active'] == true;

    final Color accent = isBanned
        ? _danger
        : (!isActive ? _warning : _success);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                '$id',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: -0.1,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _statusChip(
                      label: isActive ? 'Active' : 'Inactive',
                      color: isActive ? _success : _warning,
                      icon: isActive
                          ? Icons.check_circle_rounded
                          : Icons.pause_circle_rounded,
                    ),
                    _statusChip(
                      label: isBanned ? 'Banned' : 'Allowed',
                      color: isBanned ? _danger : _primary,
                      icon: isBanned
                          ? Icons.block_rounded
                          : Icons.verified_rounded,
                    ),
                  ],
                ),
              ],
            ),
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
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}