import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class SosReportUI extends StatelessWidget {
  final List<dynamic> sosList;
  final int total, currentPage, limit;
  final bool loading;
  final DateTime? fromDate, toDate;
  final String? selectedStatus;
  final List<String> statusOptions;
  final int totalSos, openSos, resolvedSos;
  final double? avgResponseMin;
  final VoidCallback onFromDateTap, onToDateTap;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const SosReportUI({
    super.key, required this.sosList, required this.total, this.currentPage = 1, this.limit = 20,
    required this.loading, this.fromDate, this.toDate, this.selectedStatus,
    required this.statusOptions, this.totalSos = 0, this.openSos = 0, this.resolvedSos = 0,
    this.avgResponseMin, required this.onFromDateTap, required this.onToDateTap,
    required this.onStatusChanged, this.onPageChanged, this.onLimitChanged, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanPage(
      scrollable: false,
      child: Column(
        children: [
          _header(),
          Expanded(
            child: loading ? const FisheriesOfficerOceanLoading() : sosList.isEmpty ? _empty() : _list(),
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
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Total SOS', value: '$totalSos', icon: Icons.warning_rounded, color: FisheriesOfficerOcean.red)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Resolved', value: '$resolvedSos', icon: Icons.check_circle_rounded, color: FisheriesOfficerOcean.green)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Pending', value: '$openSos', icon: Icons.hourglass_top_rounded, color: FisheriesOfficerOcean.orange)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FisheriesOfficerOceanDateButton(text: fromDate != null ? DateFormat('dd-MM-yyyy').format(fromDate!) : 'From date', onTap: onFromDateTap)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanDateButton(text: toDate != null ? DateFormat('dd-MM-yyyy').format(toDate!) : 'To date', onTap: onToDateTap)),
          ]),
          const SizedBox(height: 12),
          FisheriesOfficerOceanDropdown<String>(value: selectedStatus ?? 'All', labelText: 'Alert Status', items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: onStatusChanged),
        ],
      ),
    );
  }

  Widget _list() {
    return Column(
      children: [
        _tableHeader(),
        Expanded(child: ListView.separated(
          itemCount: sosList.length,
          separatorBuilder: (_, __) => const FisheriesOfficerOceanDivider(),
          itemBuilder: (_, i) => _row(sosList[i]),
        )),
      ],
    );
  }

  Widget _tableHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    color: FisheriesOfficerOcean.surface2,
    child: const Row(children: [
      Expanded(flex: 3, child: _Hdr('Date & Time')),
      Expanded(flex: 3, child: _Hdr('Boat')),
      Expanded(flex: 4, child: _Hdr('Severity', end: true)),
    ]),
  );

  Widget _row(dynamic s) {
    final dt = _fmt(s['sos_datetime']);
    final boat = s['boat_reg_no'] ?? '—';
    final severity = (s['severity'] ?? 'LOW').toString().toUpperCase();

    final boatKey = boatKeyOf(s is Map ? Map<String, dynamic>.from(s) : {});
    final bc = boatColor(boatKey);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Expanded(flex: 3, child: Text(dt, style: const TextStyle(color: FisheriesOfficerOcean.text, fontSize: 12, fontWeight: FontWeight.w700))),
        Expanded(flex: 3, child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bc.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bc.withValues(alpha: .24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: bc, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(boatKey ?? '—',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: bc, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        )),
        Expanded(flex: 4, child: Align(alignment: Alignment.centerRight, child: FisheriesOfficerOceanStatusBadge(status: severity))),
      ]),
    );
  }

  Widget _empty() => const FisheriesOfficerOceanEmpty(icon: Icons.warning_amber_outlined, title: 'No SOS alerts', message: 'No records match filters.');

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
  String _fmt(String? d) {
    if (d == null) return '—';
    try { return DateFormat('dd-MM-yy HH:mm').format(DateTime.parse(d)); } catch (_) { return d; }
  }
}

class _Hdr extends StatelessWidget {
  final String text;
  final bool end;
  const _Hdr(this.text, {this.end = false});
  @override
  Widget build(BuildContext context) => Text(text, textAlign: end ? TextAlign.end : TextAlign.start, style: const TextStyle(color: FisheriesOfficerOcean.muted, fontSize: 11, fontWeight: FontWeight.w700));
}
