import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_badge.dart';

class CrewNotReturnedUI extends StatelessWidget {
  final List<dynamic> crewList;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final DateTime? fromDate, toDate;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFromDateTap, onToDateTap;
  final ValueChanged<int> onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const CrewNotReturnedUI({
    Key? key,
    required this.crewList,
    required this.total,
    required this.currentPage,
    required this.limit,
    required this.loading,
    required this.search,
    this.fromDate,
    this.toDate,
    required this.onSearchChanged,
    required this.onFromDateTap,
    required this.onToDateTap,
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
                    : crewList.isEmpty
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
              const Text('Crew Not Returned',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by crew name...',
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
              SizedBox(
                  width: 160,
                  child: _dateBtn('From date', fromDate, onFromDateTap)),
              SizedBox(
                  width: 160,
                  child: _dateBtn('To date', toDate, onToDateTap)),
            ],
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
            child: const Icon(Icons.person_off_outlined,
                color: _accent, size: 26),
          ),
          const SizedBox(height: 16),
          const Text('No crew records',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: _ink)),
          const SizedBox(height: 4),
          const Text('All crew have returned.',
              style: TextStyle(color: _muted, fontSize: 13)),
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
                  flex: 2,
                  child: Text('CREW NAME',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 2,
                  child: Text('AADHAAR',
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
                  flex: 3,
                  child: Text('VOYAGE REF',
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
              Expanded(
                  flex: 3,
                  child: Text('REMARKS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1)),
              Expanded(
                  flex: 2,
                  child: Text('OFFICER',
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
            itemCount: crewList.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
            itemBuilder: (_, i) {
              final c = crewList[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(c['crew_name'] ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _ink),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                          c['aadhaar_last4'] != null
                              ? 'XXXX-XXXX-${c['aadhaar_last4']}'
                              : '—',
                          style: const TextStyle(fontSize: 13, color: _muted),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['boat_name'] ?? '—',
                              style: const TextStyle(fontSize: 13, color: _ink),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1),
                          if (c['boat_reg_no'] != null)
                            Text(c['boat_reg_no'],
                                style: const TextStyle(
                                    fontSize: 11, color: _muted),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(c['reference_no'] ?? '—',
                          style: const TextStyle(
                              fontSize: 13,
                              color: _accent,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 2,
                      child: StatusBadge(c['return_status'] ?? 'MISSING'),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(c['remarks'] ?? '—',
                          style: const TextStyle(fontSize: 13, color: _muted),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(c['notified_officer_name'] ?? '—',
                          style: const TextStyle(fontSize: 13, color: _ink),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
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
