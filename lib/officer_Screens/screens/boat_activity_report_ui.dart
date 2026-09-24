import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

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
    super.key,
    required this.boatData,
    required this.total,
    this.currentPage = 1,
    this.limit = 20,
    required this.loading,
    required this.boatSearch,
    this.fromDate,
    this.toDate,
    this.totalBoats = 0,
    this.totalVoyages = 0,
    this.totalCatchKg = 0,
    required this.onBoatSearchChanged,
    required this.onFromDateTap,
    required this.onToDateTap,
    this.onPageChanged,
    this.onLimitChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = boatSearch.isNotEmpty ||
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
                    : boatData.isEmpty
                        ? _empty(hasFilters)
                        : _list(),
              ),
            ),
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
    final totalCatch = boatData.fold<double>(
      0, (s, b) => s + ((b['total_catch_kg'] ?? 0) as num).toDouble());
    final totalVoy = boatData.fold<int>(
      0, (s, b) => s + ((b['voyage_count'] ?? 0) as num).toInt());

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total Boats', '${boatData.length}',
                  Icons.directions_boat_rounded, FisheriesOfficerOcean.cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  'Voyages', '$totalVoy',
                  Icons.sailing_rounded, FisheriesOfficerOcean.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  'Total Catch',
                  '${NumberFormat('#,##0').format(totalCatch.round())}',
                  Icons.set_meal_rounded, FisheriesOfficerOcean.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          FisheriesOfficerOceanSearchField(
            controller: TextEditingController(text: boatSearch),
            hintText: 'Search by boat name...',
            onChanged: onBoatSearchChanged,
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

  // ─────────────────────────────────────────────────────────────
  // STAT CARD
  // ─────────────────────────────────────────────────────────────
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: FisheriesOfficerOcean.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(.14),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 7),
          Text(value,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1,
              )),
          const SizedBox(height: 3),
          Text(title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FisheriesOfficerOcean.muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LIST
  // ─────────────────────────────────────────────────────────────
  Widget _list() => Column(
    children: [
      _tableHeader(),
      Expanded(
        child: ListView.separated(
          itemCount: boatData.length,
          separatorBuilder: (_, __) => const FisheriesOfficerOceanDivider(),
          itemBuilder: (_, i) => _row(boatData[i]),
        ),
      ),
    ],
  );

  Widget _tableHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    decoration: const BoxDecoration(
      color: FisheriesOfficerOcean.surface2,
      border: Border(bottom: BorderSide(color: FisheriesOfficerOcean.border)),
    ),
    child: const Row(
      children: [
        Expanded(flex: 5, child: _Hdr('BOAT')),
        Expanded(flex: 3, child: _Hdr('OWNER')),
        Expanded(flex: 2, child: _Hdr('VOY', center: true)),
        Expanded(flex: 2, child: _Hdr('DEP', center: true)),
        Expanded(flex: 2, child: _Hdr('DONE', center: true)),
        Expanded(flex: 2, child: _Hdr('SEA', center: true)),
        Expanded(flex: 3, child: _Hdr('CATCH', center: true)),
      ],
    ),
  );

  Widget _row(dynamic b) {
    final name = b['boat_name'] ?? '—';
    final reg = b['boat_reg_no'];
    final owner = b['owner_name'] ?? '—';
    final voyages = b['voyage_count'] ?? 0;
    final departures = b['departures'] ?? 0;
    final completed = b['completed'] ?? 0;
    final seaDays = ((b['sea_days'] ?? 0) as num).toStringAsFixed(2);
    final catchKg = ((b['total_catch_kg'] ?? 0) as num).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          // BOAT — name + reg
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FisheriesOfficerOcean.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reg != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    reg.toString(),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.muted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // OWNER
          Expanded(
            flex: 3,
            child: Text(
              owner.toString(),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FisheriesOfficerOcean.text2,
                fontSize: 10.5,
              ),
            ),
          ),
          // VOYAGES
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '$voyages',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // DEPARTURES
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '$departures',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.text,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          // COMPLETED
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '$completed',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // SEA DAYS
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                seaDays,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.text2,
                  fontSize: 10.5,
                ),
              ),
            ),
          ),
          // CATCH
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: FisheriesOfficerOcean.orange.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: FisheriesOfficerOcean.orange.withOpacity(.24),
                  ),
                ),
                child: Text(
                  catchKg,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FisheriesOfficerOcean.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EMPTY
  // ─────────────────────────────────────────────────────────────
  Widget _empty(bool hasFilters) => FisheriesOfficerOceanEmpty(
    icon: Icons.directions_boat_outlined,
    title: 'No boat activity',
    message: hasFilters
        ? 'Try adjusting your search or filters.'
        : 'No boat activity records are available.',
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
        color: FisheriesOfficerOcean.surface,
        border: Border(top: BorderSide(color: FisheriesOfficerOcean.border)),
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
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );
}
