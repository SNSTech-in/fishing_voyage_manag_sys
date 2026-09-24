import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class CitingsScreenUI extends StatelessWidget {
  final List<dynamic> citings;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final String? selectedStatus, selectedSeverity, selectedType, selectedActivity;
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback? onFromDateTap;
  final VoidCallback? onToDateTap;
  final VoidCallback? onClearDates;
  final List<String> statusTabs, severityOptions, typeOptions, activityOptions;
  final int totalCitings, openCitings, resolvedCitings, closedCitings,
      highSeverity, reportedCitings, illegalActivity;
  final ValueChanged<String> onSearchChanged, onStatusTab;
  final ValueChanged<String> onTypeChanged, onActivityChanged;
  final ValueChanged<String?>? onStatusCardTap;
  final ValueChanged<String?> onSeverityChanged;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const CitingsScreenUI({
    super.key,
    required this.citings,
    required this.total,
    this.currentPage = 1,
    this.limit = 20,
    required this.loading,
    required this.search,
    this.selectedStatus,
    this.selectedSeverity,
    this.selectedType,
    this.selectedActivity,
    this.fromDate,
    this.toDate,
    this.onFromDateTap,
    this.onToDateTap,
    this.onClearDates,
    this.statusTabs = const [
      'All',
      'REPORTED',
      'REVIEWED',
      'RESOLVED',
      'CLOSED',
    ],
    this.severityOptions = const ['All', 'HIGH', 'MEDIUM', 'LOW'],
    this.typeOptions = const [
      'All', 'OTHER_STATE_BOAT', 'ILLEGAL_ACTIVITY',
    ],
    this.activityOptions = const [
      'All', 'UNKNOWN', 'OTHER', 'BANNED_GEAR',
    ],
    this.totalCitings = 0,
    this.openCitings = 0,
    this.resolvedCitings = 0,
    this.closedCitings = 0,
    this.highSeverity = 0,
    this.reportedCitings = 0,
    this.illegalActivity = 0,
    required this.onSearchChanged,
    required this.onStatusTab,
    required this.onTypeChanged,
    required this.onActivityChanged,
    this.onStatusCardTap,
    required this.onSeverityChanged,
    this.onPageChanged,
    this.onLimitChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = search.isNotEmpty ||
        selectedStatus != null ||
        selectedSeverity != null;

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
                : citings.isEmpty
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
                  'Total', '$totalCitings',
                  Icons.gavel_rounded, FisheriesOfficerOcean.primary,
                  onTap: onStatusCardTap != null ? () => onStatusCardTap!(null) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Reported', '$reportedCitings',
                  Icons.report_rounded, FisheriesOfficerOcean.orange,
                  onTap: onStatusCardTap != null ? () => onStatusCardTap!('REPORTED') : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Illegal', '$illegalActivity',
                  Icons.warning_amber_rounded, FisheriesOfficerOcean.red,
                  onTap: () => onTypeChanged('ILLEGAL_ACTIVITY'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          FisheriesOfficerOceanSearchField(
            controller: TextEditingController(text: search),
            hintText: 'Search by boat / citing ref...',
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

          Row(
            children: [
              Expanded(
                child: FisheriesOfficerOceanDropdown<String>(
                  labelText: 'TYPE',
                  value: selectedType ?? 'All',
                  items: typeOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => onTypeChanged(v ?? 'All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FisheriesOfficerOceanDropdown<String>(
                  labelText: 'ACTIVITY',
                  value: selectedActivity ?? 'All',
                  items: activityOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => onActivityChanged(v ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: FisheriesOfficerOceanDropdown<String>(
                  labelText: 'SEVERITY',
                  value: selectedSeverity ?? 'All',
                  items: severityOptions
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: onSeverityChanged,
                ),
              ),

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

  Widget _stat(String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1,
                )),
            const SizedBox(height: 4),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
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
    itemCount: citings.length,
    itemBuilder: (_, i) => _card(context, citings[i]),
  );

  Widget _card(BuildContext context, dynamic c) {
    final ref = c['citing_ref_no'] ?? c['reference_no'] ?? '—';
    final vref = c['voyage_reference_no'];
    final boatName = c['boat_name'] ?? '—';
    final reg = c['boat_reg_no'];
    final type = c['citing_type'] ?? '—';
    final severity = (c['severity'] ?? 'LOW').toString().toUpperCase();
    final status = c['citing_status'] ?? 'OPEN';
    final dt = _fmt(c['citing_datetime']);
    final lat = c['latitude'];
    final lng = c['longitude'];

    final sevColor = severity == 'HIGH' || severity == 'CRITICAL'
        ? FisheriesOfficerOcean.red
        : severity == 'MEDIUM'
            ? FisheriesOfficerOcean.orange
            : FisheriesOfficerOcean.green;

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
                    color: sevColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.gavel_rounded,
                      color: sevColor, size: 18),
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
                      if (vref != null) ...[
                        const SizedBox(height: 2),
                        Text(vref.toString(),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FisheriesOfficerOcean.muted,
                              fontSize: 10,
                            )),
                      ],
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sevColor.withOpacity(.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sevColor.withOpacity(.28)),
                  ),
                  child: Text(severity,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: sevColor, fontSize: 9,
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
                    color: FisheriesOfficerOcean.cardSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: FisheriesOfficerOcean.border),
                  ),
                  child: Text(type.toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.text2, fontSize: 9.5,
                        fontWeight: FontWeight.w600,
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
                if (lat != null && lng != null)
                  Text(
                    '${(lat as num).toStringAsFixed(2)},${(lng as num).toStringAsFixed(2)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.primary, fontSize: 9,
                    ),
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
                    child: const Icon(Icons.gavel_rounded,
                        color: FisheriesOfficerOcean.primary, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (c['citing_ref_no'] ?? c['reference_no'] ?? 'Citing')
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
                  _detailRow('Citing Reference', c['citing_ref_no']),
                  _detailRow('Voyage Reference', c['voyage_reference_no']),
                  _detailRow('Boat', c['boat_name']),
                  _detailRow('Boat Reg. No.', c['boat_reg_no']),
                  _detailRow('Reported By', c['reported_by_name']),
                  _detailRow('Type', c['citing_type']),
                  _detailRow('Severity', c['severity']),
                  _detailRow('Status', c['citing_status']),
                  _detailRow('Date & Time', _fmtFull(c['citing_datetime'])),
                  _detailRow('Latitude', c['latitude']),
                  _detailRow('Longitude', c['longitude']),
                  _detailRow('Location', c['location_text']),
                  _detailRow('Description', c['description']),
                  _detailRow('Action Taken', c['action_taken']),
                  _detailRow('Penalty Amount', c['penalty_amount']),
                  _detailRow('Reviewed By', c['reviewed_by_name']),
                  _detailRow('Reviewed At', _fmtFull(c['reviewed_at'])),
                  _detailRow('Resolved At', _fmtFull(c['resolved_at'])),
                  _detailRow('Resolution Remarks', c['resolution_remarks']),
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
            icon: Icons.gavel_outlined,
            title: 'No citings found',
            message: hasFilters
                ? 'Try adjusting your filters.'
                : 'No citing records available.',
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