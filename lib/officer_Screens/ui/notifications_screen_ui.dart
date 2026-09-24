import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/pagination_bar.dart';
import 'fisheries_officer_ocean_ui.dart';

class NotificationsScreenUI extends StatelessWidget {
  final List<dynamic> notificationList;
  final int total, currentPage, limit;
  final bool loading;
  final String search;
  final String? selectedType;
  final List<String> typeTabs;
  final int unreadCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeTab;
  final ValueChanged<dynamic>? onTapNotification;
  final ValueChanged<dynamic>? onMarkRead;
  final ValueChanged<dynamic>? onDelete;
  final VoidCallback? onMarkAllRead;
  final ValueChanged<int>? onPageChanged, onLimitChanged;
  final VoidCallback? onClearFilters;

  const NotificationsScreenUI({
    super.key,
    required this.notificationList,
    required this.total,
    this.currentPage = 1,
    this.limit = 20,
    required this.loading,
    required this.search,
    this.selectedType,
    this.typeTabs = const [
      'All',
      'SOS',
      'CITING',
      'LICENSE',
      'SYSTEM',
    ],
    this.unreadCount = 0,
    required this.onSearchChanged,
    required this.onTypeTab,
    this.onTapNotification,
    this.onMarkRead,
    this.onDelete,
    this.onMarkAllRead,
    this.onPageChanged,
    this.onLimitChanged,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = search.isNotEmpty || selectedType != null;

    return FisheriesOfficerOceanPage(
      scrollable: false,
      child: Column(
        children: [
          _header(hasFilters),
          Expanded(
            child: loading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      FisheriesOfficerOceanLoading(),
                    ],
                  )
                : notificationList.isEmpty
                    ? _empty(hasFilters)
                    : _list(context),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _stat(
                  'Total', '$total',
                  Icons.notifications_rounded,
                  FisheriesOfficerOcean.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Unread', '$unreadCount',
                  Icons.mark_email_unread_rounded,
                  FisheriesOfficerOcean.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Read', '${total - unreadCount}',
                  Icons.mark_email_read_rounded,
                  FisheriesOfficerOcean.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          FisheriesOfficerOceanSearchField(
            controller: TextEditingController(text: search),
            hintText: 'Search notifications...',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              if (unreadCount > 0 && onMarkAllRead != null)
                Expanded(
                  child: FisheriesOfficerOceanButton(
                    text: 'Mark All Read',
                    icon: Icons.done_all_rounded,
                    onPressed: onMarkAllRead!,
                    outlined: true,
                  ),
                ),
              if (hasFilters && onClearFilters != null) ...[
                if (unreadCount > 0) const SizedBox(width: 8),
                FisheriesOfficerOceanButton(
                  text: '',
                  icon: Icons.close_rounded,
                  onPressed: onClearFilters!,
                  outlined: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: typeTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final label = typeTabs[i];
                final sel = (selectedType == null && label == 'All') ||
                    (label != 'All' && selectedType == label);
                return FisheriesOfficerOceanFilterChip(
                  label: label,
                  selected: sel,
                  onTap: () => onTypeTab(label),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: FisheriesOfficerOcean.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color, fontSize: 18,
                fontWeight: FontWeight.w800, height: 1,
              )),
          const SizedBox(height: 4),
          Text(title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FisheriesOfficerOcean.muted,
                fontSize: 10, fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LIST
  // ─────────────────────────────────────────────────────────────
  Widget _list(BuildContext context) => ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
    itemCount: notificationList.length,
    itemBuilder: (_, i) => _card(context, notificationList[i]),
  );

  Widget _card(BuildContext context, dynamic n) {
    final title = n['title'] ?? '—';
    final body = n['body'] ?? n['message'];
    final type = (n['type'] ?? 'SYSTEM').toString().toUpperCase();
    final isRead = n['is_read'] == true || n['read'] == true;
    final dt = _fmt(n['created_at'] ?? n['timestamp']);
    final ref = n['reference_no'];

    final (color, icon) = _typeStyle(type);

    return GestureDetector(
      onTap: () {
        onTapNotification?.call(n);
        if (!isRead) onMarkRead?.call(n);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead
              ? FisheriesOfficerOcean.card
              : color.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? FisheriesOfficerOcean.border
                : color.withValues(alpha: .32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: FisheriesOfficerOcean.text,
                                  fontSize: 12.5,
                                  fontWeight: isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                )),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(type,
                                style: TextStyle(
                                  color: color, fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                )),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.schedule_rounded,
                              size: 10,
                              color: FisheriesOfficerOcean.muted),
                          const SizedBox(width: 3),
                          Text(dt,
                              style: const TextStyle(
                                color: FisheriesOfficerOcean.muted,
                                fontSize: 9.5,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: () => onDelete!.call(n),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: FisheriesOfficerOcean.red.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: FisheriesOfficerOcean.red, size: 16),
                    ),
                  ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body.toString(),
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FisheriesOfficerOcean.text2,
                    fontSize: 10.5, height: 1.35,
                  )),
            ],
            if (ref != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.tag_rounded,
                      size: 11, color: FisheriesOfficerOcean.primary),
                  const SizedBox(width: 4),
                  Text(ref.toString(),
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.primary, fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, IconData) _typeStyle(String type) {
    switch (type) {
      case 'SOS':
        return (FisheriesOfficerOcean.red, Icons.warning_rounded);
      case 'CITING':
        return (FisheriesOfficerOcean.orange, Icons.gavel_rounded);
      case 'LICENSE':
        return (FisheriesOfficerOcean.primary, Icons.badge_rounded);
      case 'CATCH':
        return (FisheriesOfficerOcean.green, Icons.set_meal_rounded);
      case 'BOAT':
        return (FisheriesOfficerOcean.primary,
            Icons.directions_boat_rounded);
      default:
        return (FisheriesOfficerOcean.blue, Icons.info_outline_rounded);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // EMPTY
  // ─────────────────────────────────────────────────────────────
  Widget _empty(bool hasFilters) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          FisheriesOfficerOceanEmpty(
            icon: Icons.notifications_off_outlined,
            title: 'No notifications',
            message: hasFilters
                ? 'Try adjusting your filters.'
                : "You're all caught up!",
          ),
        ],
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
        color: FisheriesOfficerOcean.card,
        border: Border(
            top: BorderSide(color: FisheriesOfficerOcean.border)),
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

  String _fmt(String? d) {
    if (d == null) return '—';
    try {
      final t = DateTime.parse(d);
      final diff = DateTime.now().difference(t);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('dd-MM-yy').format(t);
    } catch (_) {
      return d;
    }
  }
}