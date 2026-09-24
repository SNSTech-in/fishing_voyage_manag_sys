import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class CatchesScreenUI extends StatelessWidget {
  final List<dynamic> catchList;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final String? selectedStatus, selectedSpecies;
  final List<String> statusTabs, speciesOptions;
  final int totalCatches, verifiedCatches, pendingCatches, rejectedCatches;
  final double totalWeightKg;
  final ValueChanged<String> onSearchChanged, onStatusTab;
  final ValueChanged<String?> onSpeciesChanged;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const CatchesScreenUI({
    super.key,
    required this.catchList,
    required this.total,
    this.currentPage = 1,
    this.limit = 20,
    required this.loading,
    required this.search,
    this.selectedStatus,
    this.selectedSpecies,
    this.statusTabs = const ['All', 'PENDING', 'VERIFIED', 'REJECTED'],
    this.speciesOptions = const [
      'All', 'TUNA', 'SARDINE', 'MACKEREL', 'PRAWN', 'CRAB', 'OTHER',
    ],
    this.totalCatches = 0,
    this.verifiedCatches = 0,
    this.pendingCatches = 0,
    this.rejectedCatches = 0,
    this.totalWeightKg = 0,
    required this.onSearchChanged,
    required this.onStatusTab,
    required this.onSpeciesChanged,
    this.onPageChanged,
    this.onLimitChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = search.isNotEmpty ||
        selectedStatus != null ||
        selectedSpecies != null;

    return FisheriesOfficerOceanPage(
      scrollable: false,
      child: Column(
        children: [
          _header(hasFilters),
          Expanded(
            child: loading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      FisheriesOfficerOceanLoading(),
                    ],
                  )
                : catchList.isEmpty
                    ? _empty(hasFilters)
                    : _list(context),
          ),
          _pagination(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _header(bool hasFilters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _stat(
                  'Total Catches', '$totalCatches',
                  Icons.set_meal_rounded, FisheriesOfficerOcean.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Verified', '$verifiedCatches',
                  Icons.verified_rounded, FisheriesOfficerOcean.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Pending', '$pendingCatches',
                  Icons.hourglass_top_rounded, FisheriesOfficerOcean.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          FisheriesOfficerOceanSearchField(
            controller: TextEditingController(text: search),
            hintText: 'Search by boat / species / voyage...',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: FisheriesOfficerOceanDropdown<String>(
                  labelText: 'SPECIES',
                  value: selectedSpecies ?? 'All',
                  items: speciesOptions
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: onSpeciesChanged,
                ),
              ),
              if (hasFilters && onClearFilters != null) ...[
                const SizedBox(width: 8),
                FisheriesOfficerOceanButton(
                  text: '',
                  icon: Icons.close_rounded,
                  onPressed: onClearFilters!,
                  outlined: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statusTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final label = statusTabs[i];
                final sel = (selectedStatus == null && label == 'All') ||
                    (label != 'All' && selectedStatus == label);
                return FisheriesOfficerOceanFilterChip(
                  label: label,
                  selected: sel,
                  onTap: () => onStatusTab(label),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: FisheriesOfficerOcean.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color, fontSize: 18,
                fontWeight: FontWeight.w800, height: 1,
              )),
          const SizedBox(height: 4),
          Text(title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FisheriesOfficerOcean.muted,
                fontSize: 10, fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LIST
  // ─────────────────────────────────────────────────────────────
  Widget _list(BuildContext context) => ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
    itemCount: catchList.length,
    itemBuilder: (_, i) => _card(context, catchList[i]),
  );

  Widget _card(BuildContext context, dynamic c) {
    final catchId = c['catch_id'] ?? c['reference_no'] ?? '—';
    final species = c['species'] ?? c['species_name'] ?? '—';
    final boatName = c['boat_name'] ?? '—';
    final reg = c['boat_reg_no'];
    final weight = c['weight_kg'];
    final quality = (c['quality'] ?? '—').toString().toUpperCase();
    final status = (c['status'] ?? 'PENDING').toString().toUpperCase();
    final dt = _fmt(c['caught_at'] ?? c['catch_datetime']);
    final port = c['landing_port'];

    final statusColor = status == 'VERIFIED'
        ? FisheriesOfficerOcean.green
        : status == 'PENDING'
            ? FisheriesOfficerOcean.orange
            : FisheriesOfficerOcean.red;

    final qualityColor = quality == 'A' || quality == 'PREMIUM'
        ? FisheriesOfficerOcean.green
        : quality == 'B' || quality == 'GOOD'
            ? FisheriesOfficerOcean.primary
            : FisheriesOfficerOcean.orange;

    return GestureDetector(
      onTap: () => _showDetails(context, c),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: FisheriesOfficerOcean.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.set_meal_rounded,
                      color: statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(species.toString(),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FisheriesOfficerOcean.text,
                            fontSize: 12.5, fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(catchId.toString(),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FisheriesOfficerOcean.muted,
                            fontSize: 10,
                          )),
                    ],
                  ),
                ),
                FisheriesOfficerOceanStatusBadge(status: status),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showDetails(context, c),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: FisheriesOfficerOcean.primary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: FisheriesOfficerOcean.primary
                              .withOpacity(.24)),
                    ),
                    child: const Icon(Icons.visibility_outlined,
                        color: FisheriesOfficerOcean.primary, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.directions_boat_outlined,
                    size: 13, color: FisheriesOfficerOcean.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    reg != null ? '$boatName · $reg' : boatName.toString(),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.text2, fontSize: 10.5,
                    ),
                  ),
                ),
                if (weight != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: FisheriesOfficerOcean.green.withOpacity(.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: FisheriesOfficerOcean.green.withOpacity(.28)),
                    ),
                    child: Text('${(weight as num).toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: FisheriesOfficerOcean.green, fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: qualityColor.withOpacity(.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: qualityColor.withOpacity(.28)),
                  ),
                  child: Text('Grade $quality',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: qualityColor, fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.schedule_rounded,
                    size: 11, color: FisheriesOfficerOcean.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(dt,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.muted, fontSize: 10,
                      )),
                ),
                if (port != null) ...[
                  const Icon(Icons.anchor_rounded,
                      size: 11, color: FisheriesOfficerOcean.primary),
                  const SizedBox(width: 4),
                  Text(port.toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.primary, fontSize: 9.5,
                      )),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DETAIL SHEET
  // ─────────────────────────────────────────────────────────────
  void _showDetails(BuildContext context, dynamic c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FisheriesOfficerOcean.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: FisheriesOfficerOcean.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: FisheriesOfficerOcean.primary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.set_meal_rounded,
                        color: FisheriesOfficerOcean.primary, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (c['species'] ?? c['species_name'] ?? 'Catch')
                          .toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.text,
                        fontSize: 15, fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: FisheriesOfficerOcean.muted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: FisheriesOfficerOcean.borderLight),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  _detailRow('Catch ID', c['catch_id']),
                  _detailRow('Voyage Ref.', c['voyage_reference_no']),
                  _detailRow('Species', c['species']),
                  _detailRow('Local Name', c['local_name']),
                  _detailRow('Boat', c['boat_name']),
                  _detailRow('Boat Reg. No.', c['boat_reg_no']),
                  _detailRow('Captain', c['captain_name']),
                  _detailRow('Caught At', _fmtFull(c['caught_at'])),
                  _detailRow('Weight (kg)', c['weight_kg']),
                  _detailRow('Quantity', c['quantity']),
                  _detailRow('Grade / Quality', c['quality']),
                  _detailRow('Landing Port', c['landing_port']),
                  _detailRow('Fishing Zone', c['fishing_zone']),
                  _detailRow('Latitude', c['latitude']),
                  _detailRow('Longitude', c['longitude']),
                  _detailRow('Market Price / kg', c['price_per_kg']),
                  _detailRow('Total Value', c['total_value']),
                  _detailRow('Status', c['status']),
                  _detailRow('Verified By', c['verified_by_name']),
                  _detailRow('Verified At', _fmtFull(c['verified_at'])),
                  _detailRow('Remarks', c['remarks']),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final val = (value == null || value.toString().isEmpty)
        ? '—'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(val,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EMPTY
  // ─────────────────────────────────────────────────────────────
  Widget _empty(bool hasFilters) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          FisheriesOfficerOceanEmpty(
            icon: Icons.set_meal_outlined,
            title: 'No catches found',
            message: hasFilters
                ? 'Try adjusting your filters.'
                : 'No catch records available.',
          ),
        ],
      );

  // ─────────────────────────────────────────────────────────────
  // PAGINATION
  // ─────────────────────────────────────────────────────────────
  Widget _pagination() {
    if (onPageChanged == null || onLimitChanged == null) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: const BoxDecoration(
        color: FisheriesOfficerOcean.card,
        border: Border(
            top: BorderSide(color: FisheriesOfficerOcean.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: PaginationBar(
        currentPage: currentPage,
        total: total,
        limit: limit,
        onPageChanged: onPageChanged!,
        onLimitChanged: onLimitChanged!,
      ),
    );
  }

  String _fmt(String? d) {
    if (d == null) return '—';
    try {
      return DateFormat('dd-MM-yy HH:mm').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  String _fmtFull(String? d) {
    if (d == null) return '—';
    try {
      return DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }
}