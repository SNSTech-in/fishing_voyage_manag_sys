import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class VoyagesScreenUI extends StatelessWidget {
  final List<dynamic> voyages;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final String? selectedStatus;
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback? onFromDateTap;
  final VoidCallback? onToDateTap;
  final VoidCallback? onClearDates;
  final List<String> statusTabs;
  final int totalVoyages, activeVoyages, overdueVoyages, completedVoyages, cancelledVoyages;
  final ValueChanged<String> onSearchChanged, onStatusTab;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const VoyagesScreenUI({
    super.key,
    required this.voyages,
    required this.total,
    this.currentPage = 1,
    this.limit = 20,
    required this.loading,
    required this.search,
    this.selectedStatus,
    this.fromDate,
    this.toDate,
    this.onFromDateTap,
    this.onToDateTap,
    this.onClearDates,
    this.statusTabs = const [
      'All',
      'ACTIVE',
      'OVERDUE',
      'COMPLETED',
      'CANCELLED',
    ],
    this.totalVoyages = 0,
    this.activeVoyages = 0,
    this.overdueVoyages = 0,
    this.completedVoyages = 0,
    this.cancelledVoyages = 0,
    required this.onSearchChanged,
    required this.onStatusTab,
    this.onPageChanged,
    this.onLimitChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = search.isNotEmpty || selectedStatus != null;

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
                : voyages.isEmpty
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
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _stat(
                  'Total', '$totalVoyages',
                  Icons.sailing_rounded, FisheriesOfficerOcean.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Active', '$activeVoyages',
                  Icons.play_circle_outline_rounded,
                  FisheriesOfficerOcean.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Overdue', '$overdueVoyages',
                  Icons.schedule_rounded,
                  FisheriesOfficerOcean.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          FisheriesOfficerOceanSearchField(
            controller: TextEditingController(text: search),
            hintText: 'Search by boat / voyage ref...',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onFromDateTap,
                  behavior: HitTestBehavior.opaque,
                  child: _dateChip(
                    'From',
                    fromDate != null
                        ? DateFormat('dd-MM-yy').format(fromDate!)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onToDateTap,
                  behavior: HitTestBehavior.opaque,
                  child: _dateChip(
                    'To',
                    toDate != null
                        ? DateFormat('dd-MM-yy').format(toDate!)
                        : null,
                  ),
                ),
              ),
              if (fromDate != null || toDate != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClearDates,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: FisheriesOfficerOcean.red.withOpacity(.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: FisheriesOfficerOcean.red.withOpacity(.28)),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: FisheriesOfficerOcean.red, size: 16),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),



          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statusTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final raw = statusTabs[i];
                final label = raw == 'ONGOING' ? 'Active' : raw;   // ✅ user sees "Active"
                final sel = (selectedStatus == null && raw == 'All') ||
                    (raw != 'All' && selectedStatus == raw);
                return FisheriesOfficerOceanFilterChip(
                  label: label,
                  selected: sel,
                  onTap: () => onStatusTab(raw),   // ✅ sends ONGOING
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
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(.14),
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

  Widget _dateChip(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: FisheriesOfficerOcean.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value != null
              ? FisheriesOfficerOcean.primary.withOpacity(.35)
              : FisheriesOfficerOcean.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range_rounded,
            size: 14,
            color: value != null
                ? FisheriesOfficerOcean.primary
                : FisheriesOfficerOcean.muted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value ?? '$label date',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: value != null
                    ? FisheriesOfficerOcean.text
                    : FisheriesOfficerOcean.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
    itemCount: voyages.length,
    itemBuilder: (_, i) => _card(context, voyages[i]),
  );

  Widget _card(BuildContext context, dynamic v) {
    final ref = v['reference_no'] ?? '—';
    final boatName = v['boat_name'] ?? '—';
    final reg = v['boat_reg_no'];
    final ownerName = v['owner_name'];
    final status = (v['derived_status']
            ?? v['trip_status']
            ?? v['voyage_status']
            ?? 'SCHEDULED')
        .toString()
        .toUpperCase();
    final start = _fmt(v['voyage_start_date']);
    final end = _fmt(v['voyage_return_date']);
    final crewCount = v['total_crew_count'];
    final catchKg = v['total_fish_weight_kg'];

    final statusColor = switch (status) {
      'ACTIVE'    => FisheriesOfficerOcean.green,
      'OVERDUE'   => FisheriesOfficerOcean.orange,
      'COMPLETED' => FisheriesOfficerOcean.blue,
      'CANCELLED' => FisheriesOfficerOcean.red,
      _           => FisheriesOfficerOcean.primary,
    };

    return GestureDetector(
      onTap: () => _showDetails(context, v),
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
                  child: Icon(Icons.sailing_rounded,
                      color: statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ref.toString(),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FisheriesOfficerOcean.text,
                            fontSize: 12.5, fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        reg != null
                            ? '$boatName · $reg'
                            : boatName.toString(),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FisheriesOfficerOcean.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                FisheriesOfficerOceanStatusBadge(status: status),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showDetails(context, v),
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
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: FisheriesOfficerOcean.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(ownerName?.toString() ?? '—',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.text2, fontSize: 10.5,
                      )),
                ),
                if (crewCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: FisheriesOfficerOcean.cardSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: FisheriesOfficerOcean.border),
                    ),
                    child: Text('$crewCount crew',
                        style: const TextStyle(
                          color: FisheriesOfficerOcean.text2, fontSize: 9,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flight_takeoff_rounded,
                    size: 11, color: FisheriesOfficerOcean.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(start,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.muted, fontSize: 10,
                      )),
                ),
                if (catchKg != null) ...[
                  const Icon(Icons.scale_rounded,
                      size: 11, color: FisheriesOfficerOcean.green),
                  const SizedBox(width: 4),
                  Text('${(catchKg as num).toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.green, fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.flight_land_rounded,
                    size: 11, color: FisheriesOfficerOcean.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(end,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.muted, fontSize: 10,
                      )),
                ),
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
  void _showDetails(BuildContext context, dynamic v) {
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
                    child: const Icon(Icons.sailing_rounded,
                        color: FisheriesOfficerOcean.primary, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (v['reference_no'] ?? 'Voyage').toString(),
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
                  _detailRow('Voyage Reference', v['reference_no']),
                  _detailRow('Boat',             v['boat_name']),
                  _detailRow('Boat Reg. No.',    v['boat_reg_no']),
                  _detailRow('Owner',            v['owner_name']),
                  _detailRow('Status',           v['derived_status'] ?? v['trip_status']),
                  _detailRow('Notified Officer', v['notified_officer_name']),
                  _detailRow('Intimation Status',v['intimation_status']),

                  const Divider(height: 24),

                  _detailRow('Departure Port',   _firstPort(v['destination_ports_text'])),
                  _detailRow('Arrival Port',     _lastPort(v['destination_ports_text'])),
                  _detailRow('Voyage Start',     _fmtFull(v['voyage_start_date'])),
                  _detailRow('Voyage Return',    _fmtFull(v['voyage_return_date'])),
                  _detailRow('Trip Start',       _fmtFull(v['trip_start_datetime'])),
                  _detailRow('Trip End',         _fmtFull(v['trip_end_datetime'])),
                  _detailRow('Actual Hours',     v['actual_hours']),

                  const Divider(height: 24),

                  _detailRow('Total Crew',       v['total_crew_count']),
                  _detailRow('Returned Crew',    v['returned_crew_count']),
                  _detailRow('Missing Crew',     v['missing_crew_count']),
                  _detailRow('All Crew Returned',v['all_crew_returned']),

                  const Divider(height: 24),

                  _detailRow('Total Catch (kg)', _fmtKg(v['total_fish_weight_kg'])),
                  _detailRow('SOS Count',        v['sos_count']),
                  _detailRow('Citing Count',     v['citing_count']),

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
            icon: Icons.sailing_outlined,
            title: 'No voyages found',
            message: hasFilters
                ? 'Try adjusting your filters.'
                : 'No voyage records available.',
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

  /// Splits "Mangaluru, Minicoy Island" → returns first port.
  String _firstPort(dynamic text) {
    if (text == null || text.toString().isEmpty) return '—';
    final parts = text.toString().split(',').map((s) => s.trim()).toList();
    return parts.isNotEmpty ? parts.first : '—';
  }

  /// Returns last port (arrival).
  String _lastPort(dynamic text) {
    if (text == null || text.toString().isEmpty) return '—';
    final parts = text.toString().split(',').map((s) => s.trim()).toList();
    return parts.length > 1 ? parts.last : parts.first;
  }

  /// Nicely formats a fish weight or falls back to '0 kg'.
  String _fmtKg(dynamic kg) {
    if (kg == null) return '0 kg';
    if (kg is num) return '${kg.toStringAsFixed(1)} kg';
    return '$kg kg';
  }
}