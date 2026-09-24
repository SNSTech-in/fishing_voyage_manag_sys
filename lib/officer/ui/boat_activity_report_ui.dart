import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class BoatActivityReportUI extends StatelessWidget {
  final List<dynamic> boatData;
  final int total, currentPage, limit;
  final bool loading;
  final String boatSearch;
  final DateTime? fromDate, toDate;
  final int totalBoats, totalVoyages;
  final double totalCatchKg;
  final ValueChanged<String> onBoatSearchChanged;
  final VoidCallback onFromDateTap, onToDateTap;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const BoatActivityReportUI({
    super.key, required this.boatData, required this.total, this.currentPage = 1, this.limit = 20,
    required this.loading, required this.boatSearch, this.fromDate, this.toDate,
    required this.totalBoats, required this.totalVoyages, required this.totalCatchKg,
    required this.onBoatSearchChanged, required this.onFromDateTap, required this.onToDateTap,
    this.onPageChanged, this.onLimitChanged, this.onClearFilters});

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
                : boatData.isEmpty
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
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Total Boats', value: '$totalBoats', icon: Icons.directions_boat_rounded, color: FisheriesOfficerOcean.primary)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Voyages', value: '$totalVoyages', icon: Icons.sailing_rounded, color: FisheriesOfficerOcean.cyan)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanStatCard(title: 'Catch (kg)', value: '${NumberFormat('#,###').format(totalCatchKg)}', icon: Icons.set_meal_rounded, color: FisheriesOfficerOcean.orange)),
          ]),
          const SizedBox(height: 16),
          FisheriesOfficerOceanSearchField(controller: TextEditingController(text: boatSearch), hintText: 'Search by boat name...', onChanged: onBoatSearchChanged),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FisheriesOfficerOceanDateButton(text: fromDate != null ? DateFormat('dd-MM-yyyy').format(fromDate!) : 'From date', onTap: onFromDateTap)),
            const SizedBox(width: 12),
            Expanded(child: FisheriesOfficerOceanDateButton(text: toDate != null ? DateFormat('dd-MM-yyyy').format(toDate!) : 'To date', onTap: onToDateTap)),
          ]),
        ],
      ),
    );
  }

  Widget _list() {
    return Column(
      children: [
        _tableHeader(),
        Expanded(child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: boatData.length,
          separatorBuilder: (_, __) => const FisheriesOfficerOceanDivider(),
          itemBuilder: (_, i) => _row(boatData[i]),
        )),
      ],
    );
  }

  Widget _tableHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    color: FisheriesOfficerOcean.surface2,
    child: const Row(children: [
      Expanded(flex: 4, child: _Hdr('Boat Name')),
      Expanded(flex: 3, child: _Hdr('Sea Days')),
      Expanded(flex: 3, child: _Hdr('Total Catch', end: true)),
    ]),
  );

  Widget _row(dynamic b) {
    final name = b['boat_name'] ?? '—';
    final seaDays = ((b['sea_days'] ?? 0) as num).toStringAsFixed(1);
    final kg = ((b['total_catch_kg'] ?? 0) as num).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Expanded(flex: 4, child: Text(name, style: const TextStyle(color: FisheriesOfficerOcean.text, fontSize: 13, fontWeight: FontWeight.w700))),
        Expanded(flex: 3, child: Text('$seaDays days', style: const TextStyle(color: FisheriesOfficerOcean.muted, fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(flex: 3, child: Text('$kg kg', textAlign: TextAlign.end, style: const TextStyle(color: FisheriesOfficerOcean.text, fontSize: 13, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  Widget _empty() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          FisheriesOfficerOceanEmpty(
            icon: Icons.directions_boat_outlined,
            title: 'No activity found',
            message: 'No records for this period.',
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
