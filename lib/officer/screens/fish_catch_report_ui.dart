import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';

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
  final ValueChanged<int> onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;
  final VoidCallback? onRetry;

  const FishCatchReportUI({
    Key? key,
    required this.catchData,
    required this.total,
    required this.currentPage,
    required this.limit,
    required this.loading,
    this.fromDate,
    this.toDate,
    this.selectedGroup,
    required this.groupOptions,
    required this.totalCatchKg,
    required this.totalVoyages,
    required this.onFromDateTap,
    required this.onToDateTap,
    required this.onGroupByChanged,
    required this.onPageChanged,
    required this.onLimitChanged,
    this.onClearFilters,
    this.onRetry,
  }) : super(key: key);

  static const _bg = Color(0xFFF6F7FB);
  static const _ink = Color(0xFF12172B);
  static const _muted = Color(0xFF6B7280);
  static const _accent = Color(0xFF3B5BFD);
  static const _border = Color(0xFFE6E8F0);
  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          _filterBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : catchData.isEmpty
                        ? _empty()
                        : _list(),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: PaginationBar(
              currentPage: currentPage,
              total: total,
              limit: limit,
              onPageChanged: onPageChanged,
              onLimitChanged: onLimitChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    final hasFilters = fromDate != null ||
        toDate != null ||
        (selectedGroup != null && selectedGroup != 'Species');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Catch Report',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total items',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent)),
              ),
              const Spacer(),
              if (hasFilters && onClearFilters != null)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear filters'),
                  style: TextButton.styleFrom(foregroundColor: _muted),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _statCard(
                        'Total Catch',
                        '${NumberFormat('#,##0').format(totalCatchKg.round())} kg',
                        Icons.set_meal_rounded,
                        _accent),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _statCard('Voyages', '$totalVoyages',
                        Icons.directions_boat_filled_rounded, _green),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                  width: 140,
                  child: _dateBtn('From date', fromDate, onFromDateTap)),
              SizedBox(
                  width: 140,
                  child: _dateBtn('To date', toDate, onToDateTap)),
              SizedBox(
                width: 150,
                child: PopupMenuButton<String>(
                  onSelected: onGroupByChanged,
                  itemBuilder: (_) => groupOptions
                      .map((o) => PopupMenuItem(value: o, child: Text(o)))
                      .toList(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.workspaces_outline,
                            size: 15, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('GROUP BY',
                                  style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: _muted,
                                      letterSpacing: 0.4)),
                              Text(selectedGroup ?? 'Species',
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: _ink),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1),
                            ],
                          ),
                        ),
                        Icon(Icons.expand_more_rounded,
                            size: 18, color: Colors.grey[500]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(fontSize: 11.5, color: _muted),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBtn(String label, DateTime? value, VoidCallback onTap) {
    final has = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: has ? _accent.withOpacity(0.4) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 15, color: has ? _accent : Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                has ? DateFormat('dd MMM yyyy').format(value!) : label,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: has ? FontWeight.w600 : FontWeight.w400,
                    color: has ? _ink : Colors.grey[500]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.set_meal_outlined, color: _accent, size: 26),
          ),
          const SizedBox(height: 16),
          const Text('No catch data',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: _ink)),
        ],
      ),
    );
  }

  Widget _list() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFBFD),
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: const [
              Expanded(
                  flex: 4,
                  child: Text('GROUP',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted))),
              Expanded(
                  flex: 2,
                  child: Text('WEIGHT (KG)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      textAlign: TextAlign.right)),
              Expanded(
                  flex: 2,
                  child: Text('QUANTITY',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      textAlign: TextAlign.right)),
              Expanded(
                  flex: 2,
                  child: Text('VOYAGES',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      textAlign: TextAlign.right)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: catchData.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
            itemBuilder: (_, i) {
              final c = catchData[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(c['group_label'] ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: _ink),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                          (c['total_weight_kg'] ?? 0.0).toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _ink),
                          textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('${c['total_quantity'] ?? 0}',
                          style: const TextStyle(fontSize: 14, color: _muted),
                          textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${c['voyage_count'] ?? 0}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _accent)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
