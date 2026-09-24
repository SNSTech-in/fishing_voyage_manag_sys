import 'package:flutter/material.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class SpeciesScreenUI extends StatelessWidget {
  final List<dynamic> species;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final bool? bannedFilter, activeFilter;
  final int totalSpecies, bannedSpecies, activeSpecies;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onBannedFilterChanged, onActiveFilterChanged;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const SpeciesScreenUI({
    super.key, required this.species, required this.total, this.currentPage = 1, this.limit = 20,
    required this.loading, required this.search, this.bannedFilter, this.activeFilter,
    required this.totalSpecies, required this.bannedSpecies, required this.activeSpecies,
    required this.onSearchChanged, required this.onBannedFilterChanged,
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
                : species.isEmpty
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
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Total Species', value: '$totalSpecies', icon: Icons.set_meal_rounded, color: FisheriesOfficerOcean.primary)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Active', value: '$activeSpecies', icon: Icons.check_circle_rounded, color: FisheriesOfficerOcean.green)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Banned', value: '$bannedSpecies', icon: Icons.block_rounded, color: FisheriesOfficerOcean.red)),
          ]),
          const SizedBox(height: 16),
          FisheriesOfficerOceanSearchField(controller: TextEditingController(text: search), hintText: 'Search by fish name...', onChanged: onSearchChanged),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FisheriesOfficerOceanDropdown<String>(value: bannedFilter == null ? 'All' : (bannedFilter! ? 'Banned' : 'Not Banned'), labelText: 'Banned', items: const [DropdownMenuItem(value: 'All', child: Text('All')), DropdownMenuItem(value: 'Banned', child: Text('Banned')), DropdownMenuItem(value: 'Not Banned', child: Text('Not Banned'))], onChanged: onBannedFilterChanged)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanDropdown<String>(value: activeFilter == null ? 'All' : (activeFilter! ? 'Active' : 'Inactive'), labelText: 'Active', items: const [DropdownMenuItem(value: 'All', child: Text('All')), DropdownMenuItem(value: 'Active', child: Text('Active')), DropdownMenuItem(value: 'Inactive', child: Text('Inactive'))], onChanged: onActiveFilterChanged)),
          ]),
        ],
      ),
    );
  }

  Widget _list() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: species.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _card(species[i]),
    );
  }

  Widget _card(dynamic s) {
    final name = s['fish_name'] ?? '—';
    final banned = s['is_banned'] == true;
    final active = s['is_active'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FisheriesOfficerOcean.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: FisheriesOfficerOcean.primary.withOpacity(.08), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.phishing_rounded, color: FisheriesOfficerOcean.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: FisheriesOfficerOcean.text, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(banned ? 'Banned Species' : 'Permitted Species', style: TextStyle(color: banned ? FisheriesOfficerOcean.red : FisheriesOfficerOcean.muted, fontSize: 12, fontWeight: FontWeight.w600)),
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
            icon: Icons.set_meal_outlined,
            title: 'No species found',
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
