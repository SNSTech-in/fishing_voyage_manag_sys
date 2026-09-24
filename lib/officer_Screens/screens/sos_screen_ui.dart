import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/status_badge.dart';
import '../widgets/pagination_bar.dart';

class SosScreenUI extends StatelessWidget {
  final List<dynamic> sosList;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final String? selectedStatus;
  final String? selectedSeverity;
  final List<String> statusTabs;
  final List<String> severityOptions;
  final int totalSos, openSos, resolvedSos, closedSos, highSeverity;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusTab;
  final ValueChanged<String?>? onStatusCardTap;
  final ValueChanged<String?> onSeverityChanged;
  final ValueChanged<int> onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const SosScreenUI({
    Key? key,
    required this.sosList,
    required this.total,
    required this.currentPage,
    required this.limit,
    required this.loading,
    required this.search,
    this.selectedStatus,
    this.selectedSeverity,
    required this.statusTabs,
    required this.severityOptions,
    this.totalSos = 0,
    this.openSos = 0,
    this.resolvedSos = 0,
    this.closedSos = 0,
    this.highSeverity = 0,
    required this.onSearchChanged,
    required this.onStatusTab,
    this.onStatusCardTap,
    required this.onSeverityChanged,
    required this.onPageChanged,
    required this.onLimitChanged,
    this.onClearFilters,
  }) : super(key: key);

  static const _bg = Color(0xFFF6F7FB);
  static const _ink = Color(0xFF12172B);
  static const _muted = Color(0xFF6B7280);
  static const _accent = Color(0xFF3B5BFD);
  static const _border = Color(0xFFE6E8F0);
  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFDC2626);
  static const _orange = Color(0xFFF59E0B);
  static const _grey = Color(0xFF6B7280);

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
    final hasFilters = search.isNotEmpty ||
        selectedStatus != null ||
        selectedSeverity != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('SOS Alerts',
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
                    child: _tappableStatCard(
                      title: 'Total SOS',
                      value: '$totalSos',
                      icon: Icons.warning_rounded,
                      color: _accent,
                      isSelected: selectedStatus == null,
                      onTap: () => onStatusCardTap?.call(null),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _tappableStatCard(
                      title: 'Open',
                      value: '$openSos',
                      icon: Icons.error_outline_rounded,
                      color: _red,
                      isSelected: selectedStatus == 'OPEN',
                      onTap: () => onStatusCardTap?.call('OPEN'),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _tappableStatCard(
                      title: 'Resolved',
                      value: '$resolvedSos',
                      icon: Icons.check_circle_rounded,
                      color: _green,
                      isSelected: selectedStatus == 'RESOLVED',
                      onTap: () => onStatusCardTap?.call('RESOLVED'),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _tappableStatCard(
                      title: 'Closed',
                      value: '$closedSos',
                      icon: Icons.lock_outline_rounded,
                      color: _grey,
                      isSelected: selectedStatus == 'CLOSED',
                      onTap: () => onStatusCardTap?.call('CLOSED'),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _tappableStatCard(
                      title: 'High Severity',
                      value: '$highSeverity',
                      icon: Icons.priority_high_rounded,
                      color: _orange,
                      isSelected: false,
                      onTap: () {
                        onSeverityChanged(selectedSeverity == 'HIGH' ? 'All' : 'HIGH');
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by reference or boat...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: _bg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _accent, width: 1.4)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                child: _dropdown('SEVERITY', selectedSeverity ?? 'All',
                    severityOptions, onSeverityChanged),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statusTabsRow(),
        ],
      ),
    );
  }

  Widget _tappableStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : _border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          height: 1),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  const SizedBox(height: 2),
                  Text(title,
                      style: const TextStyle(fontSize: 11, color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTabsRow() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statusTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = statusTabs[i];
          final sel = (selectedStatus == null && label == 'All') ||
              (label != 'All' && selectedStatus == label);
          return Material(
            color: sel ? _accent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => onStatusTab(label),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? _accent : _border),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _ink)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> options,
      ValueChanged<String?> onChange) {
    return PopupMenuButton<String>(
      onSelected: (v) => onChange(v),
      itemBuilder: (_) =>
          options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: _bg, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(Icons.filter_alt_outlined, size: 15, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                          letterSpacing: 0.4)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 18, color: Colors.grey[500]),
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
                  flex: 3,
                  child: Text('REFERENCE',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 2,
                  child: Text('BOAT',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 2,
                  child: Text('TYPE',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 2,
                  child: Text('SEVERITY',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 3,
                  child: Text('RAISED AT',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 2,
                  child: Text('STATUS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
            ],
          ),
        ),
        Expanded(
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
                              style: const TextStyle(
                                  fontSize: 13, color: _ink),
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
                      child: _sevBadge(s['severity'] ?? 'LOW'),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(_fmt(s['sos_datetime']),
                          style: const TextStyle(
                              fontSize: 13, color: _muted),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 2,
                      child: StatusBadge(s['sos_status'] ?? 'OPEN'),
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

  Widget _sevBadge(String sev) {
    final c = sev == 'HIGH'
        ? _red
        : sev == 'MEDIUM'
            ? _orange
            : _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(sev,
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
          maxLines: 1),
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
