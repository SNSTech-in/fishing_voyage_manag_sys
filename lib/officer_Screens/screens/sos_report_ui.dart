import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_badge.dart';

class SosReportUI extends StatelessWidget {
  final List<dynamic> sosList;
  final int total, currentPage, limit;
  final bool loading;
  final DateTime? fromDate, toDate;
  final String? selectedStatus;
  final List<String> statusOptions;
  final int totalSos;
  final double? avgResponseMin;
  final VoidCallback onFromDateTap, onToDateTap;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int> onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const SosReportUI({
    Key? key,
    required this.sosList,
    required this.total,
    required this.currentPage,
    required this.limit,
    required this.loading,
    this.fromDate,
    this.toDate,
    this.selectedStatus,
    required this.statusOptions,
    required this.totalSos,
    this.avgResponseMin,
    required this.onFromDateTap,
    required this.onToDateTap,
    required this.onStatusChanged,
    required this.onPageChanged,
    required this.onLimitChanged,
    this.onClearFilters,
  }) : super(key: key);

  static const _bg = Color(0xFFF6F7FB);
  static const _ink = Color(0xFF12172B);
  static const _muted = Color(0xFF6B7280);
  static const _accent = Color(0xFF3B5BFD);
  static const _border = Color(0xFFE6E8F0);
  static const _red = Color(0xFFDC2626);

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
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : sosList.isEmpty
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('SOS Report',
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
                child: Text('$total total',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent)),
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
                    child: _statCard('Total SOS', '$totalSos',
                        Icons.warning_rounded, _red),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _statCard(
                        'Avg Response',
                        avgResponseMin != null
                            ? '${avgResponseMin!.toStringAsFixed(0)} min'
                            : '—',
                        Icons.timer_rounded,
                        _accent),
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
                  width: 160,
                  child: _dateBtn('From date', fromDate, onFromDateTap)),
              SizedBox(
                  width: 160,
                  child: _dateBtn('To date', toDate, onToDateTap)),
              SizedBox(
                width: 150,
                child: PopupMenuButton<String>(
                  onSelected: onStatusChanged,
                  itemBuilder: (_) => statusOptions
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
                        Icon(Icons.filter_alt_outlined,
                            size: 15, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('STATUS',
                                  style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: _muted,
                                      letterSpacing: 0.4)),
                              Text(selectedStatus ?? 'All',
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: _ink),
                                  overflow: TextOverflow.ellipsis),
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
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
                child:
                    const Icon(Icons.warning_outlined, color: _accent, size: 26),
              ),
              const SizedBox(height: 16),
              const Text('No SOS alerts',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _ink)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _list() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Container(
            width: 800,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFBFD),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: const [
                Expanded(
                    flex: 3,
                    child: Text('REFERENCE',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _muted))),
                Expanded(
                    flex: 2,
                    child: Text('BOAT',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _muted))),
                Expanded(
                    flex: 2,
                    child: Text('TYPE',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _muted))),
                Expanded(
                    flex: 2,
                    child: Text('SEVERITY',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _muted))),
                Expanded(
                    flex: 3,
                    child: Text('RAISED AT',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _muted))),
                Expanded(
                    flex: 2,
                    child: Text('STATUS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _muted))),
                Expanded(
                    flex: 2,
                    child: Text('RESP (MIN)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _muted),
                        textAlign: TextAlign.right)),
              ],
            ),
          ),
          SizedBox(
            width: 800,
            height: 400,
            child: ListView.separated(
              itemCount: sosList.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
              itemBuilder: (_, i) {
              final s = sosList[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['sos_ref_no'] ?? '—',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _ink),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1),
                          if (s['reference_no'] != null)
                            Text(s['reference_no'],
                                style: const TextStyle(
                                    fontSize: 11, color: _muted),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['boat_name'] ?? '—',
                              style: const TextStyle(fontSize: 13, color: _ink),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1),
                          if (s['boat_reg_no'] != null)
                            Text(s['boat_reg_no'],
                                style: const TextStyle(
                                    fontSize: 11, color: _muted),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(s['sos_type'] ?? '—',
                          style: const TextStyle(fontSize: 13, color: _muted),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 2,
                      child: StatusBadge(s['sos_status'] ?? 'OPEN'),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(_fmt(s['sos_datetime']),
                          style: const TextStyle(fontSize: 13, color: _muted),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        s['response_time_min'] != null
                            ? '${s['response_time_min']} min'
                            : '—',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _ink),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sevBadge(String sev) {
    final c = sev == 'HIGH'
        ? Colors.red
        : sev == 'MEDIUM'
            ? Colors.orange
            : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(sev,
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _fmt(String? d) {
    if (d == null) return '—';
    try {
      final dt = DateTime.parse(d);
      return DateFormat('dd-MM-yyyy HH:mm').format(dt);
    } catch (_) {
      return d;
    }
  }
}
