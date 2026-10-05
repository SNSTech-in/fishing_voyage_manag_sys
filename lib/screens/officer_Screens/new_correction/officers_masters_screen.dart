import 'package:flutter/material.dart';

import '../../../services/api_services/officer_api_service.dart';

class OfficersMastersScreen extends StatefulWidget {
  const OfficersMastersScreen({super.key});

  @override
  State<OfficersMastersScreen> createState() => _OfficersMastersScreenState();
}

class _OfficersMastersScreenState extends State<OfficersMastersScreen> {
  final OfficersApiService _api = OfficersApiService();
  final _searchCtrl = TextEditingController();

  static const Color _primary = Color(0xFF1257C7);
  static const Color _primaryDark = Color(0xFF07347F);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);

  /// The FULL master list (never mutated by search).
  List<Map<String, dynamic>> _allItems = [];

  /// The currently displayed list (after applying search).
  List<Map<String, dynamic>> _items = [];

  bool _loading = true;
  String? _error;

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

  // ── Networking ─────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Send the search term to the API (server may do its own filtering),
    // but ALSO keep a full local copy for client-side fallback.
    final res = await _api.fetchOfficers(
      search: _searchCtrl.text.trim(),
    );

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _allItems = OfficersApiService.extractList(res);
        _loading = false;
      });
      _applySearch(); // derive _items from the fetched master
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Failed to load officers';
        _loading = false;
      });
    }
  }

  // ── Local search (instant, no network) ─────────────────

  /// Filters `_allItems` by the current search text, matching across
  /// multiple fields (name / id / mobile / email / designation /
  /// department / district) case-insensitively.
  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() => _items = List<Map<String, dynamic>>.from(_allItems));
      return;
    }

    final filtered = _allItems.where((o) {
      final name = (o['officer_name'] ?? o['name'] ?? o['full_name'] ?? '')
          .toString()
          .toLowerCase();
      final id = (o['officer_id'] ?? o['user_id'] ?? '')
          .toString()
          .toLowerCase();
      final mobile = (o['mobile_no'] ?? o['phone'] ?? o['mobile'] ?? '')
          .toString()
          .toLowerCase();
      final email = (o['email'] ?? '').toString().toLowerCase();
      final designation = (o['designation'] ?? '').toString().toLowerCase();
      final department = (o['department'] ?? '').toString().toLowerCase();
      final district = (o['district'] ?? '').toString().toLowerCase();

      return name.contains(q) ||
          id.contains(q) ||
          mobile.contains(q) ||
          email.contains(q) ||
          designation.contains(q) ||
          department.contains(q) ||
          district.contains(q);
    }).toList();

    setState(() => _items = filtered);
  }

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
            'Officers',
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
            _searchBar(),
            const Divider(height: 1, color: _divider),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow() {
    // Summary is based on the FULL master, not the filtered view.
    final active = _allItems.where((e) => e['is_active'] == true).length;
    final departments = _allItems
        .map((e) => e['department']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard('Total', _allItems.length,
                Icons.groups_rounded, Colors.indigo),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard('Active', active,
                Icons.check_circle_rounded, _success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard('Departments', departments,
                Icons.apartment_rounded, _primary),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int value, IconData icon, Color color) {
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

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        // Instant local filtering on every keystroke:
        onChanged: (_) => _applySearch(),
        // Keyboard "search" key also triggers a server refresh:
        onSubmitted: (_) => _load(),
        decoration: InputDecoration(
          hintText: 'Search officers...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              _searchCtrl.clear();
              _applySearch(); // instant reset of the list
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
    );
  }

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
        child: Text('No officers found.',
            style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _officerTile(_items[i]),
    );
  }

  Widget _officerTile(Map<String, dynamic> o) {
    final name =
    (o['officer_name'] ?? o['name'] ?? o['full_name'] ?? '—').toString();
    final designation = o['designation']?.toString() ?? '';
    final department = o['department']?.toString() ?? '';
    final mobile = (o['mobile_no'] ?? o['phone'] ?? o['mobile'] ?? '').toString();
    final email = o['email']?.toString() ?? '';
    final district = o['district']?.toString() ?? '';
    final state = o['state']?.toString() ?? '';
    final isActive = o['is_active'] == true;

    final Color accent = isActive ? _success : _danger;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: accent,
                  size: 22,
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      designation.isEmpty
                          ? department
                          : '$designation · $department',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (mobile.isNotEmpty || email.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: _divider),
            const SizedBox(height: 8),
            if (mobile.isNotEmpty)
              _rowInfo(Icons.phone_rounded, 'Mobile', mobile),
            if (email.isNotEmpty)
              _rowInfo(Icons.mail_outline_rounded, 'Email', email),
            if (district.isNotEmpty || state.isNotEmpty)
              _rowInfo(
                Icons.location_on_outlined,
                'Location',
                [district, state].where((e) => e.isNotEmpty).join(', '),
              ),
          ],
        ],
      ),
    );
  }

  Widget _rowInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _textLight),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _textLight,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}