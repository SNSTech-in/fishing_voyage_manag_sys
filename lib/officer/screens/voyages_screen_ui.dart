import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/status_badge.dart';
import '../widgets/pagination_bar.dart';

/// Modernized, UI-only version of the voyages screen.
/// All data and behavior are injected via constructor params and callbacks
/// from a parent stateful widget — this class stays purely presentational.
class VoyagesScreenUI extends StatelessWidget {
  final List<dynamic> voyages;
  final int total;
  final int currentPage;
  final int limit;
  final bool loading;
  final String search;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? selectedStatus;
  final List<String> statusTabs;

  // Callbacks
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFromDateTap;
  final VoidCallback onToDateTap;
  final ValueChanged<String> onStatusTab;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onLimitChanged;
  final VoidCallback? onClearFilters;

  const VoyagesScreenUI({
    Key? key,
    required this.voyages,
    required this.total,
    required this.currentPage,
    required this.limit,
    required this.loading,
    required this.search,
    this.fromDate,
    this.toDate,
    this.selectedStatus,
    required this.statusTabs,
    required this.onSearchChanged,
    required this.onFromDateTap,
    required this.onToDateTap,
    required this.onStatusTab,
    required this.onPageChanged,
    required this.onLimitChanged,
    this.onClearFilters,
  }) : super(key: key);

  static const _bg = Color(0xFFF6F7FB);
  static const _ink = Color(0xFF12172B);
  static const _muted = Color(0xFF6B7280);
  static const _accent = Color(0xFF3B5BFD);
  static const _border = Color(0xFFE6E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          _buildFilterBar(),
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
                    ? _buildLoadingState()
                    : voyages.isEmpty
                        ? _buildEmptyState()
                        : _buildVoyageList(),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
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

  // ---------------------------------------------------------------------
  // Filter bar
  // ---------------------------------------------------------------------

  Widget _buildFilterBar() {
    final hasFilters = search.isNotEmpty ||
        fromDate != null ||
        toDate != null ||
        selectedStatus != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Voyages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
              const Spacer(),
              if (hasFilters && onClearFilters != null)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: _muted,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final searchField = _SearchField(
                value: search,
                onChanged: onSearchChanged,
              );
              final dateButtons = Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'From date',
                      value: fromDate,
                      onTap: onFromDateTap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateButton(
                      label: 'To date',
                      value: toDate,
                      onTap: onToDateTap,
                    ),
                  ),
                ],
              );

              if (narrow) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 8),
                    dateButtons,
                    const SizedBox(height: 12),
                    _buildStatusTabs(),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(flex: 3, child: searchField),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: dateButtons),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatusTabs(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statusTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final raw = statusTabs[i];
          final label = raw == 'ONGOING' ? 'Active' : raw;   // ✅ user sees "Active"
          final isSelected = (selectedStatus == null && raw == 'All') ||
              (raw != 'All' && selectedStatus == raw);
          return _StatusChip(
            label: label,
            selected: isSelected,
            onTap: () => onStatusTab(raw),   // ✅ sends ONGOING
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // List states
  // ---------------------------------------------------------------------

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: 6,
      itemBuilder: (_, i) => const _SkeletonRow(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: const Icon(Icons.sailing_outlined, color: _accent, size: 26),
            ),
            const SizedBox(height: 16),
            const Text(
              'No voyages found',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: _ink),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filters.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoyageList() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: 900, // Fixed minimum width to prevent squeezing
            child: _buildHeaderRow(),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: voyages.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: _border),
            itemBuilder: (ctx, i) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 900, // Must match header width
                child: _VoyageRow(voyage: voyages[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _muted,
      letterSpacing: 0.2,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFD),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('VOYAGE', style: style)),
          Expanded(flex: 2, child: Text('OWNER', style: style)),
          Expanded(flex: 3, child: Text('DEPARTURE', style: style)),
          Expanded(flex: 3, child: Text('EXPECTED RETURN', style: style)),
          Expanded(flex: 2, child: Text('CREW', style: style)),
          Expanded(flex: 2, child: Text('CATCH', style: style)),
          Expanded(flex: 1, child: Text('SOS', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
        ],
      ),
    );
  }
}

// ===========================================================================
// Sub-widgets
// ===========================================================================

class _SearchField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController.fromValue(
        TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        ),
      ),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search by reference number...',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: value.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => onChanged(''),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF6F7FB),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VoyagesScreenUI._accent, width: 1.4),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? VoyagesScreenUI._accent.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: hasValue ? VoyagesScreenUI._accent : Colors.grey[500],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasValue ? DateFormat('dd MMM yyyy').format(value!) : label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue ? VoyagesScreenUI._ink : Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.selected, required this.onTap});

  Color get _dotColor {
    switch (label.toUpperCase()) {
      case 'ACTIVE':
      case 'ONGOING':
        return const Color(0xFF16A34A); // green
      case 'COMPLETED':
        return const Color(0xFF2563EB); // blue
      case 'OVERDUE':
        return const Color(0xFFF59E0B); // amber
      case 'CANCELLED':
        return const Color(0xFFDC2626); // red
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selColor = label == 'All' ? VoyagesScreenUI._accent : _dotColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: selected ? selColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? selColor : VoyagesScreenUI._border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != 'All') ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : _dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : VoyagesScreenUI._ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoyageRow extends StatefulWidget {
  final dynamic voyage;
  const _VoyageRow({required this.voyage});

  @override
  State<_VoyageRow> createState() => _VoyageRowState();
}

class _VoyageRowState extends State<_VoyageRow> {
  bool _hovering = false;

  String _formatDate(String? date) {
    if (date == null) return '—';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.voyage;
    final sosCount = v['sos_count'] ?? 0;
    final crewCount = v['crew_count'] ?? 0;
    final totalCrew = v['total_crew'] ?? 0;

    final status = (v['derived_status']
            ?? v['trip_status']
            ?? v['status']
            ?? '')
        .toString()
        .toUpperCase();

    final stripeColor = switch (status) {
      'ONGOING' || 'ACTIVE' => const Color(0xFF16A34A), // green
      'COMPLETED'           => const Color(0xFF2563EB), // blue
      'OVERDUE'             => const Color(0xFFF59E0B), // amber
      'CANCELLED'           => const Color(0xFFDC2626), // red
      _                     => const Color(0xFF9CA3AF), // grey fallback
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hovering ? const Color(0xFFF6F7FB) : Colors.white,
          border: Border(left: BorderSide(color: stripeColor, width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v['reference_no'] ?? '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: VoyagesScreenUI._ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.directions_boat_filled_rounded,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        v['boat_name'] ?? '—',
                        style: TextStyle(fontSize: 12.5, color: VoyagesScreenUI._muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                v['owner'] ?? '—',
                style: const TextStyle(fontSize: 13.5, color: VoyagesScreenUI._ink),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _formatDate(v['departure']),
                style: TextStyle(fontSize: 13, color: VoyagesScreenUI._muted),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _formatDate(v['expected_return']),
                style: TextStyle(fontSize: 13, color: VoyagesScreenUI._muted),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '$crewCount/$totalCrew',
                    style: const TextStyle(fontSize: 13, color: VoyagesScreenUI._ink),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${v['catch_kg'] ?? 0} kg',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: VoyagesScreenUI._ink),
              ),
            ),
            Expanded(
              flex: 1,
              child: sosCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$sosCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    )
                  : Text('—', style: TextStyle(color: Colors.grey[300])),
            ),
            Expanded(
              flex: 2,
              child: StatusBadge(status),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  Widget _bar(double width) => Container(
        width: width,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEFF5),
          borderRadius: BorderRadius.circular(4),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: VoyagesScreenUI._border)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _bar(90)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _bar(70)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _bar(80)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _bar(80)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _bar(40)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _bar(50)),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _bar(20)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _bar(60)),
        ],
      ),
    );
  }
}
