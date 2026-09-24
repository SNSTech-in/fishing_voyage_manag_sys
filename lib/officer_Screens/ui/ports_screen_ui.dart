import 'package:flutter/material.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class PortsScreenUI extends StatelessWidget {
  final List<dynamic> ports;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final String? selectedState;
  final bool? activeFilter;
  final List<String> states;
  final int totalPorts, activePorts, inactivePorts;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStateFilterChanged;
  final ValueChanged<bool?> onActiveFilterChanged;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const PortsScreenUI({
    super.key, required this.ports, required this.total, this.currentPage = 1, this.limit = 20,
    required this.loading, required this.search, this.selectedState, this.activeFilter,
    required this.states, this.totalPorts = 0, this.activePorts = 0, this.inactivePorts = 0,
    required this.onSearchChanged, required this.onStateFilterChanged,
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
                : ports.isEmpty
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
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Total Ports', value: '$totalPorts', icon: Icons.location_city_rounded, color: FisheriesOfficerOcean.primary)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Active', value: '$activePorts', icon: Icons.check_circle_rounded, color: FisheriesOfficerOcean.green)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Inactive', value: '$inactivePorts', icon: Icons.error_outline_rounded, color: FisheriesOfficerOcean.red)),
          ]),
          const SizedBox(height: 16),
          FisheriesOfficerOceanSearchField(controller: TextEditingController(text: search), hintText: 'Search by port name / code...', onChanged: onSearchChanged),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FisheriesOfficerOceanDropdown<String>(value: selectedState ?? 'All', labelText: 'State', items: ['All', ...states].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: onStateFilterChanged)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanDropdown<String>(value: activeFilter == null ? 'All' : (activeFilter! ? 'Active' : 'Inactive'), labelText: 'Status', items: const [DropdownMenuItem(value: 'All', child: Text('All')), DropdownMenuItem(value: 'Active', child: Text('Active')), DropdownMenuItem(value: 'Inactive', child: Text('Inactive'))], onChanged: (v) => onActiveFilterChanged(v == 'All' ? null : v == 'Active'))),
          ]),
        ],
      ),
    );
  }

  Widget _list() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: ports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _card(ports[i]),
    );
  }

  Widget _card(dynamic p) {
    final name = p['port_name'] ?? p['name'] ?? '—';
    final state = p['state'] ?? '—';
    final active = p['is_active'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FisheriesOfficerOcean.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: FisheriesOfficerOcean.primary.withOpacity(.08), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.anchor_rounded, color: FisheriesOfficerOcean.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: FisheriesOfficerOcean.text, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(state, style: const TextStyle(color: FisheriesOfficerOcean.muted, fontSize: 12, fontWeight: FontWeight.w600)),
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
            icon: Icons.location_off_outlined,
            title: 'No ports found',
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

class _Hdr extends StatelessWidget {
  final String text;
  final bool end;
  const _Hdr(this.text, {this.end = false});
  @override
  Widget build(BuildContext context) => Text(text, textAlign: end ? TextAlign.end : TextAlign.start, style: const TextStyle(color: FisheriesOfficerOcean.muted, fontSize: 11, fontWeight: FontWeight.w700));
}
