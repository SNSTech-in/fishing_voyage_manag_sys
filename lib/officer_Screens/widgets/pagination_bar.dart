import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int total;
  final int limit;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onLimitChanged;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.total,
    required this.limit,
    required this.onPageChanged,
    required this.onLimitChanged,
  });

  static const _bg     = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E8F0);
  static const _text   = Color(0xFF475569);
  static const _muted  = Color(0xFF64748B);
  static const _faint  = Color(0xFF94A3B8);
  static const _accent = Color(0xFF2196F3);
  static const _accentSoft = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: _bg,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: const Text('0 – 0 of 0',
            style: TextStyle(fontSize: 10.5, color: _muted)),
      );
    }

    final totalPages = (total / limit).ceil();
    final start = (currentPage - 1) * limit + 1;
    final end = (currentPage * limit).clamp(1, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Page info
          Flexible(
            child: Text(
              '$start – $end of $total',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: _text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // Prev
          _navBtn(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          // Page number
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$currentPage/$totalPages',
              style: const TextStyle(
                fontSize: 10.5,
                color: _accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Next
          _navBtn(
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),
          const SizedBox(width: 4),
          // Limit selector
          _limitSelector(),
        ],
      ),
    );
  }

  Widget _navBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 26, height: 26,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? _accent : _faint,
          ),
        ),
      );

  Widget _limitSelector() => PopupMenuButton<int>(
        onSelected: onLimitChanged,
        color: _bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _border),
        ),
        itemBuilder: (_) => [10, 20, 50, 100]
            .map((e) => PopupMenuItem(
                  value: e,
                  child: Text('$e per page',
                      style: const TextStyle(
                        fontSize: 12, color: _text)),
                ))
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _accentSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _accent.withOpacity(.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$limit',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _accent,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(width: 3),
              const Icon(Icons.expand_more_rounded,
                  size: 13, color: _accent),
            ],
          ),
        ),
      );
}
