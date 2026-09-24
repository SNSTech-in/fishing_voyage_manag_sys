import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class CrewNotReturnedUI extends StatelessWidget {
  final List<dynamic> crewList;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final DateTime? fromDate, toDate;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFromDateTap, onToDateTap;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const CrewNotReturnedUI({
    super.key,
    required this.crewList,
    required this.total,
    this.currentPage = 1,
    this.limit = 20,
    required this.loading,
    required this.search,
    this.fromDate,
    this.toDate,
    required this.onSearchChanged,
    required this.onFromDateTap,
    required this.onToDateTap,
    this.onPageChanged,
    this.onLimitChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = search.isNotEmpty ||
        fromDate != null ||
        toDate != null;

    return FisheriesOfficerOceanPage(
      scrollable: false,
      child: Column(
        children: [
          _header(hasFilters),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: FisheriesOfficerOceanCard(
                padding: EdgeInsets.zero,
                child: loading
                    ? const FisheriesOfficerOceanLoading()
                    : crewList.isEmpty
                    ? _empty(hasFilters)
                    : _list(context),
              ),
            ),
          ),
          _pagination(),
        ],
      ),
    );
  }

  Widget _header(bool hasFilters) {
    final missing = crewList
        .where((c) => c['return_status'] == 'MISSING').length;
    final returned = crewList
        .where((c) => c['return_status'] == 'RETURNED').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FisheriesOfficerOceanStatCard(
                  title: 'Total Crew', value: '${crewList.length}',
                  icon: Icons.people_rounded, color: FisheriesOfficerOcean.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FisheriesOfficerOceanStatCard(
                  title: 'Returned', value: '$returned',
                  icon: Icons.check_circle_rounded, color: FisheriesOfficerOcean.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FisheriesOfficerOceanStatCard(
                  title: 'Not Returned', value: '$missing',
                  icon: Icons.person_off_rounded, color: FisheriesOfficerOcean.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          FisheriesOfficerOceanSearchField(
            controller: TextEditingController(text: search),
            hintText: 'Search by crew name...',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: FisheriesOfficerOceanDateButton(
                  text: fromDate != null
                      ? DateFormat('dd-MM-yyyy').format(fromDate!)
                      : 'From date',
                  onTap: onFromDateTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FisheriesOfficerOceanDateButton(
                  text: toDate != null
                      ? DateFormat('dd-MM-yyyy').format(toDate!)
                      : 'To date',
                  onTap: onToDateTap,
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
        ],
      ),
    );
  }

  Widget _list(BuildContext context) => Column(
    children: [
      _tableHeader(),
      Expanded(
        child: ListView.separated(
          itemCount: crewList.length,
          separatorBuilder: (_, __) => const FisheriesOfficerOceanDivider(),
          itemBuilder: (_, i) => _row(context, crewList[i]),
        ),
      ),
    ],
  );

  Widget _tableHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: const BoxDecoration(
      color: FisheriesOfficerOcean.cardSoft,
      border: Border(bottom: BorderSide(color: FisheriesOfficerOcean.border)),
    ),
    child: const Row(
      children: [
        Expanded(flex: 4, child: _Hdr('CREW NAME')),
        Expanded(flex: 4, child: _Hdr('BOAT')),
        Expanded(flex: 2, child: _Hdr('STATUS', center: true)),
        SizedBox(width: 38), // space for the view button
      ],
    ),
  );

  Widget _row(BuildContext context, dynamic c) {
    final name = c['crew_name'] ?? '—';
    final aadhaar = c['aadhaar_last4'];
    final boat = c['boat_name'] ?? '—';
    final reg = c['boat_reg_no'];
    final status = c['return_status'] ?? 'MISSING';

    return GestureDetector(
      onTap: () => _showDetails(context, c),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.text,
                        fontSize: 11.5, fontWeight: FontWeight.w600,
                      )),
                  if (aadhaar != null) ...[
                    const SizedBox(height: 2),
                    Text('XXXX-XXXX-$aadhaar',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FisheriesOfficerOcean.muted, fontSize: 9.5,
                        )),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(boat.toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.text,
                        fontSize: 11,
                      )),
                  if (reg != null) ...[
                    const SizedBox(height: 2),
                    Text(reg.toString(),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FisheriesOfficerOcean.muted, fontSize: 9.5,
                        )),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(child: _statusBadge(status)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showDetails(context, c),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: FisheriesOfficerOcean.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: FisheriesOfficerOcean.primary.withOpacity(.24)),
                ),
                child: const Icon(Icons.visibility_outlined,
                    color: FisheriesOfficerOcean.primary, size: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, dynamic c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FisheriesOfficerOcean.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
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
                      color: FisheriesOfficerOcean.red.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_off_rounded,
                        color: FisheriesOfficerOcean.red, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (c['crew_name'] ?? 'Crew').toString(),
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
            const Divider(height: 1, color: FisheriesOfficerOcean.border),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  _detailRow('Crew Name', c['crew_name']),
                  _detailRow('Aadhaar',
                      c['aadhaar_last4'] != null
                          ? 'XXXX-XXXX-${c['aadhaar_last4']}'
                          : null),
                  _detailRow('Mobile', c['mobile_no']),
                  _detailRow('Boat', c['boat_name']),
                  _detailRow('Boat Reg. No.', c['boat_reg_no']),
                  _detailRow('Owner', c['owner_name']),
                  _detailRow('Voyage Reference', c['reference_no']),
                  _detailRow('Return Status', c['return_status']),
                  _detailRow('Trip End', _fmtFull(c['trip_end_datetime'])),
                  _detailRow('Remarks', c['remarks']),
                  _detailRow('Notified Officer', c['notified_officer_name']),
                  _detailRow('Emergency Contact', c['emergency_contact_name']),
                  _detailRow('Emergency Mobile', c['emergency_contact_no']),
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

  String _fmtFull(String? d) {
    if (d == null) return '—';
    try {
      return DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  Widget _statusBadge(String status) {
    return FisheriesOfficerOceanStatusBadge(status: status);
  }

  Widget _empty(bool hasFilters) => FisheriesOfficerOceanEmpty(
    icon: Icons.person_off_outlined,
    title: 'No crew records',
    message: hasFilters
        ? 'Try adjusting your search or dates.'
        : 'All crew have returned.',
  );

  Widget _pagination() {
    if (onPageChanged == null || onLimitChanged == null) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: const BoxDecoration(
        color: FisheriesOfficerOcean.card,
        border: Border(top: BorderSide(color: FisheriesOfficerOcean.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: PaginationBar(
        currentPage: currentPage, total: total, limit: limit,
        onPageChanged: onPageChanged!, onLimitChanged: onLimitChanged!,
      ),
    );
  }
}

class _Hdr extends StatelessWidget {
  final String text;
  final bool center;
  const _Hdr(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: center ? TextAlign.center : TextAlign.left,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    style: const TextStyle(
      color: FisheriesOfficerOcean.muted,
      fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.5,
    ),
  );
}
