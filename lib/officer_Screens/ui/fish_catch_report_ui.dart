import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class FishCatchReportUI extends StatelessWidget {
  final List<dynamic> catchData;
  final int total, currentPage, limit;
  final bool loading;
  final DateTime? fromDate, toDate;
  final String? selectedGroup;
  final List<String> groupOptions;
  final double totalCatchKg;
  final int totalVoyages;
  final VoidCallback onFromDateTap, onToDateTap;
  final ValueChanged<String?> onGroupByChanged;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const FishCatchReportUI({
    super.key,
    required this.catchData,
    required this.total,
    this.currentPage = 1,
    this.limit = 20,
    required this.loading,
    this.fromDate,
    this.toDate,
    this.selectedGroup,
    this.groupOptions = const ['Species', 'Voyage', 'Boat'],
    this.totalCatchKg = 0,
    this.totalVoyages = 0,
    required this.onFromDateTap,
    required this.onToDateTap,
    required this.onGroupByChanged,
    this.onPageChanged,
    this.onLimitChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = fromDate != null || toDate != null;

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
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          FisheriesOfficerOceanLoading(),
                        ],
                      )
                    : catchData.isEmpty
                        ? _empty()
                        : _list(),
              ),
            ),
          ),
          _pagination(),
        ],
      ),
    );
  }

  Widget _header(bool hasFilters) {
    final totalWeight = catchData.fold<double>(
        0, (s, c) => s + ((c['total_weight_kg'] ?? 0) as num).toDouble());
    final totalQty = catchData.fold<int>(
        0, (s, c) => s + ((c['total_quantity'] ?? 0) as num).toInt());

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Catch Hero Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FisheriesOfficerOcean.cyan.withOpacity(.15),
                  FisheriesOfficerOcean.primaryDark.withOpacity(.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FisheriesOfficerOcean.cyan.withOpacity(.22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: FisheriesOfficerOcean.cyan.withOpacity(.18),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.set_meal_rounded,
                      color: FisheriesOfficerOcean.cyan, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total Catch',
                          style: TextStyle(
                            color: FisheriesOfficerOcean.muted,
                            fontSize: 10.5, fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        '${NumberFormat('#,##0.0').format(totalWeight)} kg',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FisheriesOfficerOcean.text,
                          fontSize: 22, fontWeight: FontWeight.w800, height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$totalQty',
                        style: const TextStyle(
                          color: FisheriesOfficerOcean.cyan,
                          fontSize: 16, fontWeight: FontWeight.w700,
                        )),
                    const Text('pieces',
                        style: TextStyle(
                          color: FisheriesOfficerOcean.muted, fontSize: 9.5,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Dates
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
          const SizedBox(height: 8),

          // Group By
          FisheriesOfficerOceanDropdown<String>(
            labelText: 'GROUP BY',
            value: selectedGroup ?? 'Species',
            items: groupOptions
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: onGroupByChanged,
          ),
        ],
      ),
    );
  }

  Widget _list() => Column(
    children: [
      _tableHeader(),
      Expanded(
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: catchData.length,
          separatorBuilder: (_, __) => const FisheriesOfficerOceanDivider(),
          itemBuilder: (_, i) => _row(catchData[i]),
        ),
      ),
    ],
  );

  Widget _tableHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: const BoxDecoration(
      color: FisheriesOfficerOcean.surface2,
      border: Border(bottom: BorderSide(color: FisheriesOfficerOcean.border)),
    ),
    child: const Row(
      children: [
        Expanded(flex: 5, child: _Hdr('SPECIES')),
        Expanded(flex: 3, child: _Hdr('WEIGHT', center: true)),
        Expanded(flex: 3, child: _Hdr('QTY', center: true)),
      ],
    ),
  );

  Widget _row(dynamic c) {
    final name = c['group_label'] ?? c['name'] ?? '—';
    final weight = ((c['total_weight_kg'] ?? c['catch_kg'] ?? 0) as num)
        .toStringAsFixed(1);
    final qty = c['total_quantity'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: FisheriesOfficerOcean.cyan.withOpacity(.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.phishing_rounded,
                      color: FisheriesOfficerOcean.cyan, size: 13),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name.toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.text,
                        fontSize: 11.5, fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: FisheriesOfficerOcean.orange.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: FisheriesOfficerOcean.orange.withOpacity(.24),
                  ),
                ),
                child: Text('$weight kg',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.orange,
                      fontSize: 9.5, fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text('$qty',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FisheriesOfficerOcean.text2,
                    fontSize: 11,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          FisheriesOfficerOceanEmpty(
            icon: Icons.set_meal_outlined,
            title: 'No catch data',
            message: 'No fish catch recorded for this period.',
          ),
        ],
      );

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
