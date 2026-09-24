import 'package:flutter/material.dart';
import '../widgets/pagination_bar.dart';

class OfficersScreenUI extends StatelessWidget {
  final List<dynamic> officers;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final String? selectedDepartment;
  final bool? activeFilter;
  final List<String> departments;
  final int totalOfficers, activeOfficers, inactiveOfficers;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onDepartmentFilterChanged, onActiveFilterChanged;
  final ValueChanged<int> onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const OfficersScreenUI({
    Key? key,
    required this.officers,
    required this.total,
    required this.currentPage,
    required this.limit,
    required this.loading,
    required this.search,
    this.selectedDepartment,
    this.activeFilter,
    required this.departments,
    required this.totalOfficers,
    required this.activeOfficers,
    required this.inactiveOfficers,
    required this.onSearchChanged,
    required this.onDepartmentFilterChanged,
    required this.onActiveFilterChanged,
    required this.onPageChanged,
    required this.onLimitChanged,
    this.onClearFilters,
  }) : super(key: key);

  static const _bg = Color(0xFFF6F7FB);
  static const _ink = Color(0xFF12172B);
  static const _muted = Color(0xFF6B7280);
  static const _accent = Color(0xFF3B5BFD);
  static const _border = Color(0xFFE6E8F0);
  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          _filterBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : officers.isEmpty
                        ? _empty()
                        : _list(),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: PaginationBar(
              currentPage: currentPage,
              total: total,
              limit: limit,
              onPageChanged: onPageChanged,
              onLimitChanged: onLimitChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    final activeValue = activeFilter == null
        ? 'All'
        : (activeFilter! ? 'Active' : 'Inactive');
    final hasFilters = search.isNotEmpty ||
        selectedDepartment != null ||
        activeFilter != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Officers',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total total',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent)),
              ),
              const Spacer(),
              if (hasFilters && onClearFilters != null)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear filters'),
                  style: TextButton.styleFrom(foregroundColor: _muted),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statCard('Total Officers', '$totalOfficers',
                    Icons.badge_rounded, _accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard('Active', '$activeOfficers',
                    Icons.check_circle_rounded, _green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard('Inactive', '$inactiveOfficers',
                    Icons.block_rounded, _red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name or designation...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: _bg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _accent, width: 1.4)),
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: _dropdown(
                    'DEPARTMENT',
                    selectedDepartment ?? 'All',
                    ['All', ...departments],
                    onDepartmentFilterChanged),
              ),
              SizedBox(
                width: 150,
                child: _dropdown('ACTIVE', activeValue,
                    ['All', 'Active', 'Inactive'], onActiveFilterChanged),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1)),
                const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(fontSize: 11.5, color: _muted),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> options,
      ValueChanged<String?> onChange) {
    return PopupMenuButton<String>(
      onSelected: onChange,
      itemBuilder: (_) =>
          options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: _bg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(Icons.filter_alt_outlined, size: 15, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                          letterSpacing: 0.4)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 18, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.badge_outlined, color: _accent, size: 26),
          ),
          const SizedBox(height: 16),
          const Text('No officers found',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: _ink)),
        ],
      ),
    );
  }

  Widget _list() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFBFD),
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: const [
              Expanded(
                  flex: 2,
                  child: Text('NAME',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 2,
                  child: Text('DESIGNATION',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 2,
                  child: Text('DEPARTMENT',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 2,
                  child: Text('MOBILE',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 2,
                  child: Text('DISTRICT',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 1,
                  child: Text('ACTIVE',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: officers.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
            itemBuilder: (_, i) {
              final o = officers[i];
              final active = o['is_active'] == true;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(o['officer_name'] ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _ink),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(o['designation'] ?? '—',
                          style: const TextStyle(fontSize: 13, color: _muted),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 2,
                      child: _deptBadge(o['department'] ?? '—'),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(o['mobile_no'] ?? '—',
                          style: const TextStyle(fontSize: 13, color: _ink),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(o['district'] ?? '—',
                          style: const TextStyle(fontSize: 13, color: _muted),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(child: _activeBadge(active)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _deptBadge(String dept) {
    Color c;
    if (dept.contains('POLICE')) {
      c = Colors.blue;
    } else if (dept.contains('FISHERIES')) {
      c = const Color(0xFF16A34A);
    } else {
      c = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(dept.replaceAll('_', ' '),
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
          maxLines: 1),
    );
  }

  Widget _activeBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (active ? _green : _red).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(active ? 'Yes' : 'No',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? _green : _red)),
    );
  }
}
