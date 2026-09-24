import 'package:flutter/material.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

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
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const OfficersScreenUI({
    super.key, required this.officers, required this.total, this.currentPage = 1, this.limit = 20,
    required this.loading, required this.search, this.selectedDepartment, this.activeFilter,
    required this.departments, this.totalOfficers = 0, this.activeOfficers = 0, this.inactiveOfficers = 0,
    required this.onSearchChanged, required this.onDepartmentFilterChanged,
    required this.onActiveFilterChanged, this.onPageChanged, this.onLimitChanged, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanPage(
      scrollable: false,
      child: Column(
        children: [
          _header(),
          Expanded(
            child: loading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      FisheriesOfficerOceanLoading(),
                    ],
                  )
                : officers.isEmpty
                    ? _empty()
                    : _list(),
          ),
          _pagination(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(children: [
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Total Officers', value: '$totalOfficers', icon: Icons.badge_rounded, color: FisheriesOfficerOcean.primary)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Active', value: '$activeOfficers', icon: Icons.check_circle_rounded, color: FisheriesOfficerOcean.green)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Inactive', value: '$inactiveOfficers', icon: Icons.error_outline_rounded, color: FisheriesOfficerOcean.red)),
          ]),
          const SizedBox(height: 16),
          FisheriesOfficerOceanSearchField(controller: TextEditingController(text: search), hintText: 'Search by name / mobile...', onChanged: onSearchChanged),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FisheriesOfficerOceanDropdown<String>(value: selectedDepartment ?? 'All', labelText: 'Department', items: ['All', ...departments].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: onDepartmentFilterChanged)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanDropdown<String>(value: activeFilter == null ? 'All' : (activeFilter! ? 'Active' : 'Inactive'), labelText: 'Status', items: const [DropdownMenuItem(value: 'All', child: Text('All')), DropdownMenuItem(value: 'Active', child: Text('Active')), DropdownMenuItem(value: 'Inactive', child: Text('Inactive'))], onChanged: onActiveFilterChanged)),
          ]),
        ],
      ),
    );
  }

  Widget _list() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: officers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _card(officers[i]),
    );
  }

  Widget _card(dynamic o) {
    final name = o['officer_name'] ?? '—';
    final dept = o['department'] ?? '—';
    final mobile = o['mobile_no'] ?? '—';
    final active = o['is_active'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FisheriesOfficerOcean.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: FisheriesOfficerOcean.primary.withOpacity(.08), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_rounded, color: FisheriesOfficerOcean.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: FisheriesOfficerOcean.text, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.business_rounded, size: 12, color: FisheriesOfficerOcean.muted),
              const SizedBox(width: 4),
              Text(dept, style: const TextStyle(color: FisheriesOfficerOcean.muted, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.phone_rounded, size: 12, color: FisheriesOfficerOcean.muted),
              const SizedBox(width: 4),
              Text(mobile, style: const TextStyle(color: FisheriesOfficerOcean.muted, fontSize: 12)),
            ]),
          ])),
          FisheriesOfficerOceanStatusBadge(status: active ? 'Active' : 'Inactive'),
        ],
      ),
    );
  }

  Widget _empty() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          FisheriesOfficerOceanEmpty(
            icon: Icons.badge_outlined,
            title: 'No officers found',
            message: 'No records match filters.',
          ),
        ],
      );

  Widget _pagination() => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(
        top: BorderSide(color: FisheriesOfficerOcean.border),
      ),
    ),
    child: PaginationBar(
      currentPage: currentPage,
      total: total,
      limit: limit,
      onPageChanged: onPageChanged!,
      onLimitChanged: onLimitChanged!,
    ),
  );

}
