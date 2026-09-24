import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class FishermenScreenUI extends StatelessWidget {
  final List<dynamic> fishermanList;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final String? selectedStatus;
  final List<String> statusTabs;
  final int totalFishermen, activeFishermen, inactiveFishermen,
      suspendedFishermen;
  final ValueChanged<String> onSearchChanged, onStatusTab;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const FishermenScreenUI({
    super.key,
    required this.fishermanList,
    required this.total,
    this.currentPage = 1,
    this.limit = 20,
    required this.loading,
    required this.search,
    this.selectedStatus,
    this.statusTabs = const ['All', 'ACTIVE', 'INACTIVE', 'SUSPENDED'],
    this.totalFishermen = 0,
    this.activeFishermen = 0,
    this.inactiveFishermen = 0,
    this.suspendedFishermen = 0,
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
                : fishermanList.isEmpty
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
                  'Total', '$totalFishermen',
                  Icons.people_alt_rounded,
                  FisheriesOfficerOcean.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Active', '$activeFishermen',
                  Icons.check_circle_rounded, FisheriesOfficerOcean.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Suspended', '$suspendedFishermen',
                  Icons.block_rounded, FisheriesOfficerOcean.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          FisheriesOfficerOceanSearchField(
            controller: TextEditingController(text: search),
            hintText: 'Search by name / ID / phone...',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),

          if (hasFilters && onClearFilters != null)
            Align(
              alignment: Alignment.centerRight,
              child: FisheriesOfficerOceanButton(
                text: 'Clear Filters',
                icon: Icons.close_rounded,
                onPressed: onClearFilters!,
                outlined: true,
              ),
            ),
          const SizedBox(height: 8),

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
    itemCount: fishermanList.length,
    itemBuilder: (_, i) => _card(context, fishermanList[i]),
  );

  Widget _card(BuildContext context, dynamic f) {
    final name = f['full_name'] ?? f['fisherman_name'] ?? '—';
    final fisherId = f['fisherman_id'] ?? f['fisher_id'];
    final phone = f['phone'] ?? f['mobile'];
    final boatName = f['boat_name'];
    final village = f['village'] ?? f['address'];
    final status = (f['status'] ?? 'ACTIVE').toString().toUpperCase();
    final license = f['license_no'];
    final joined = _fmt(f['registered_at']);

    final statusColor = status == 'ACTIVE'
        ? FisheriesOfficerOcean.green
        : status == 'INACTIVE'
            ? FisheriesOfficerOcean.orange
            : FisheriesOfficerOcean.red;

    final initial = name.toString().trim().isNotEmpty
        ? name.toString().trim()[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => _showDetails(context, f),
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
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(initial,
                      style: TextStyle(
                        color: statusColor, fontSize: 16,
                        fontWeight: FontWeight.w800,
                      )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.toString(),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FisheriesOfficerOcean.text,
                            fontSize: 12.5, fontWeight: FontWeight.w700,
                          )),
                      if (fisherId != null) ...[
                        const SizedBox(height: 2),
                        Text(fisherId.toString(),
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
                  onTap: () => _showDetails(context, f),
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
                const Icon(Icons.phone_rounded,
                    size: 13, color: FisheriesOfficerOcean.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(phone?.toString() ?? '—',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.text2, fontSize: 10.5,
                      )),
                ),
                if (boatName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: FisheriesOfficerOcean.cardSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: FisheriesOfficerOcean.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_boat_outlined,
                            size: 10, color: FisheriesOfficerOcean.text2),
                        const SizedBox(width: 3),
                        Text(boatName.toString(),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FisheriesOfficerOcean.text2, fontSize: 9,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 11, color: FisheriesOfficerOcean.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(village?.toString() ?? '—',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.muted, fontSize: 10,
                      )),
                ),
                if (license != null) ...[
                  const Icon(Icons.badge_outlined,
                      size: 11, color: FisheriesOfficerOcean.green),
                  const SizedBox(width: 4),
                  Text(license.toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.green, fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.event_rounded,
                    size: 11, color: FisheriesOfficerOcean.muted),
                const SizedBox(width: 4),
                Text(joined,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.muted, fontSize: 10,
                    )),
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
  void _showDetails(BuildContext context, dynamic f) {
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
                    child: const Icon(Icons.people_alt_rounded,
                        color: FisheriesOfficerOcean.primary, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (f['full_name'] ?? f['fisherman_name'] ?? 'Fisherman')
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
                  _detailRow('Full Name', f['full_name']),
                  _detailRow('Fisherman ID', f['fisherman_id']),
                  _detailRow('Phone', f['phone']),
                  _detailRow('Alternate Phone', f['alternate_phone']),
                  _detailRow('Email', f['email']),
                  _detailRow('Gender', f['gender']),
                  _detailRow('Date of Birth', _fmtFull(f['dob'])),
                  _detailRow('Aadhaar No.', f['aadhaar_no']),
                  _detailRow('Address', f['address']),
                  _detailRow('Village', f['village']),
                  _detailRow('District', f['district']),
                  _detailRow('State', f['state']),
                  _detailRow('Boat', f['boat_name']),
                  _detailRow('Boat Reg. No.', f['boat_reg_no']),
                  _detailRow('License No.', f['license_no']),
                  _detailRow('License Expiry', _fmtFull(f['license_expiry'])),
                  _detailRow('Status', f['status']),
                  _detailRow('Registered At', _fmtFull(f['registered_at'])),
                  _detailRow('Remarks', f['remarks']),
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
            icon: Icons.people_alt_outlined,
            title: 'No fishermen found',
            message: hasFilters
                ? 'Try adjusting your filters.'
                : 'No fisherman records available.',
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
      return DateFormat('dd-MM-yy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  String _fmtFull(String? d) {
    if (d == null) return '—';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }
}