import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class LicensesScreenUI extends StatelessWidget {
  final List<dynamic> licenseList;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final String? selectedStatus, selectedType;
  final List<String> statusTabs, typeOptions;
  final int totalLicenses, activeLicenses, expiredLicenses, pendingLicenses;
  final ValueChanged<String> onSearchChanged, onStatusTab;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const LicensesScreenUI({
    super.key,
    required this.licenseList,
    required this.total,
    this.currentPage = 1,
    this.limit = 20,
    required this.loading,
    required this.search,
    this.selectedStatus,
    this.selectedType,
    this.statusTabs = const ['All', 'ACTIVE', 'EXPIRED', 'PENDING', 'REVOKED'],
    this.typeOptions = const ['All', 'FISHING', 'BOAT', 'CREW', 'TRADING'],
    this.totalLicenses = 0,
    this.activeLicenses = 0,
    this.expiredLicenses = 0,
    this.pendingLicenses = 0,
    required this.onSearchChanged,
    required this.onStatusTab,
    required this.onTypeChanged,
    this.onPageChanged,
    this.onLimitChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = search.isNotEmpty ||
        selectedStatus != null ||
        selectedType != null;

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
                : licenseList.isEmpty
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
                  'Total', '$totalLicenses',
                  Icons.badge_rounded, FisheriesOfficerOcean.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Active', '$activeLicenses',
                  Icons.check_circle_rounded, FisheriesOfficerOcean.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Expired', '$expiredLicenses',
                  Icons.cancel_rounded, FisheriesOfficerOcean.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          FisheriesOfficerOceanSearchField(
            controller: TextEditingController(text: search),
            hintText: 'Search by license no / holder...',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: FisheriesOfficerOceanDropdown<String>(
                  labelText: 'LICENSE TYPE',
                  value: selectedType ?? 'All',
                  items: typeOptions
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: onTypeChanged,
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
    itemCount: licenseList.length,
    itemBuilder: (_, i) => _card(context, licenseList[i]),
  );

  Widget _card(BuildContext context, dynamic l) {
    final licNo = l['license_no'] ?? l['license_number'] ?? '—';
    final holder = l['holder_name'] ?? l['owner_name'] ?? '—';
    final type = l['license_type'] ?? '—';
    final status = (l['status'] ?? 'ACTIVE').toString().toUpperCase();
    final issued = _fmt(l['issued_at']);
    final expiry = _fmt(l['expiry_at']);
    final vessel = l['boat_name'];

    final statusColor = status == 'ACTIVE'
        ? FisheriesOfficerOcean.green
        : status == 'PENDING'
            ? FisheriesOfficerOcean.orange
            : FisheriesOfficerOcean.red;

    return GestureDetector(
      onTap: () => _showDetails(context, l),
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
                  child: Icon(Icons.badge_rounded,
                      color: statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(licNo.toString(),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FisheriesOfficerOcean.text,
                            fontSize: 12.5, fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(holder.toString(),
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
                  onTap: () => _showDetails(context, l),
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
                const Icon(Icons.category_outlined,
                    size: 13, color: FisheriesOfficerOcean.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(type.toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.text2, fontSize: 10.5,
                      )),
                ),
                if (vessel != null)
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
                        Text(vessel.toString(),
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
                const Icon(Icons.event_available_rounded,
                    size: 11, color: FisheriesOfficerOcean.muted),
                const SizedBox(width: 4),
                Text(issued,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.muted, fontSize: 10,
                    )),
                const Spacer(),
                const Icon(Icons.event_busy_rounded,
                    size: 11,
                    color: FisheriesOfficerOcean.red),
                const SizedBox(width: 4),
                Text(expiry,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.red, fontSize: 10,
                      fontWeight: FontWeight.w600,
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
  void _showDetails(BuildContext context, dynamic l) {
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
                    child: const Icon(Icons.badge_rounded,
                        color: FisheriesOfficerOcean.primary, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (l['license_no'] ?? 'License').toString(),
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
                  _detailRow('License No.', l['license_no']),
                  _detailRow('License Type', l['license_type']),
                  _detailRow('Holder Name', l['holder_name']),
                  _detailRow('Holder ID', l['holder_id']),
                  _detailRow('Phone', l['phone']),
                  _detailRow('Boat', l['boat_name']),
                  _detailRow('Boat Reg. No.', l['boat_reg_no']),
                  _detailRow('Issued At', _fmtFull(l['issued_at'])),
                  _detailRow('Expiry At', _fmtFull(l['expiry_at'])),
                  _detailRow('Issued By', l['issued_by_name']),
                  _detailRow('Fee Paid', l['fee_paid']),
                  _detailRow('Payment Ref.', l['payment_ref']),
                  _detailRow('Status', l['status']),
                  _detailRow('Renewal Count', l['renewal_count']),
                  _detailRow('Remarks', l['remarks']),
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
            icon: Icons.badge_outlined,
            title: 'No licenses found',
            message: hasFilters
                ? 'Try adjusting your filters.'
                : 'No license records available.',
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