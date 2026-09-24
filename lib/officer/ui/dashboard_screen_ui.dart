import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'fisheries_officer_ocean_ui.dart';

class DashboardScreenUI extends StatelessWidget {
  final bool loading;
  final String officerName;
  final String? district;
  final int totalBoats, activeBoats;
  final int totalFishermen, activeFishermen;
  final int totalLicenses, expiredLicenses;
  final int totalVoyages, activeVoyages;
  final int totalCatches, pendingCatches;
  final int openSos, resolvedSos;
  final int openCitings, highSeverityCitings;
  final double totalCatchWeightKg;
  final List<dynamic> recentActivity;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onQuickAction;

  const DashboardScreenUI({
    super.key,
    required this.loading,
    required this.officerName,
    this.district,
    this.totalBoats = 0,
    this.activeBoats = 0,
    this.totalFishermen = 0,
    this.activeFishermen = 0,
    this.totalLicenses = 0,
    this.expiredLicenses = 0,
    this.totalVoyages = 0,
    this.activeVoyages = 0,
    this.totalCatches = 0,
    this.pendingCatches = 0,
    this.openSos = 0,
    this.resolvedSos = 0,
    this.openCitings = 0,
    this.highSeverityCitings = 0,
    this.totalCatchWeightKg = 0,
    this.recentActivity = const [],
    this.onRefresh,
    this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const FisheriesOfficerOceanPage(
        scrollable: false,
        child: FisheriesOfficerOceanLoading(),
      );
    }

    return FisheriesOfficerOceanPage(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _greeting(),
          const SizedBox(height: 14),
          _sosAlert(),
          const SizedBox(height: 14),
          _sectionTitle('Overview'),
          const SizedBox(height: 8),
          _overviewGrid(),
          const SizedBox(height: 16),
          _sectionTitle('Catch Summary'),
          const SizedBox(height: 8),
          _catchSummaryCard(),
          const SizedBox(height: 16),
          _sectionTitle('Quick Actions'),
          const SizedBox(height: 8),
          _quickActions(),
          const SizedBox(height: 16),
          _sectionTitle('Recent Activity'),
          const SizedBox(height: 8),
          _recentActivityList(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GREETING
  // ─────────────────────────────────────────────────────────────
  Widget _greeting() {
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    final today = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FisheriesOfficerOcean.primary,
                  FisheriesOfficerOcean.primary.withValues(alpha: .7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sailing_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greet,',
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.muted,
                      fontSize: 11,
                    )),
                const SizedBox(height: 2),
                Text(officerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    )),
                if (district != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 11, color: FisheriesOfficerOcean.primary),
                      const SizedBox(width: 3),
                      Text(district!,
                          style: const TextStyle(
                            color: FisheriesOfficerOcean.muted,
                            fontSize: 10,
                          )),
                    ],
                  ),
                ],
                const SizedBox(height: 2),
                Text(today,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.muted,
                      fontSize: 9.5,
                    )),
              ],
            ),
          ),
          if (onRefresh != null)
            GestureDetector(
              onTap: onRefresh,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: FisheriesOfficerOcean.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FisheriesOfficerOcean.border),
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: FisheriesOfficerOcean.primary, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SOS ALERT BANNER
  // ─────────────────────────────────────────────────────────────
  Widget _sosAlert() {
    if (openSos == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FisheriesOfficerOcean.green.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: FisheriesOfficerOcean.green.withValues(alpha: .28)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: FisheriesOfficerOcean.green.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_rounded,
                    color: FisheriesOfficerOcean.green, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('All Clear',
                        style: TextStyle(
                          color: FisheriesOfficerOcean.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        )),
                    SizedBox(height: 2),
                    Text('No active SOS alerts in your area.',
                        style: TextStyle(
                          color: FisheriesOfficerOcean.muted,
                          fontSize: 10,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () => onQuickAction?.call('sos'),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FisheriesOfficerOcean.red.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: FisheriesOfficerOcean.red.withValues(alpha: .35)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: FisheriesOfficerOcean.red.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: FisheriesOfficerOcean.red, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '$openSos Active SOS Alert${openSos > 1 ? "s" : ""}',
                        style: const TextStyle(
                          color: FisheriesOfficerOcean.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 2),
                    const Text('Tap to view and respond immediately.',
                        style: TextStyle(
                          color: FisheriesOfficerOcean.muted,
                          fontSize: 10,
                        )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: FisheriesOfficerOcean.red, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION TITLE
  // ─────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Text(title,
        style: const TextStyle(
          color: FisheriesOfficerOcean.text,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        )),
  );

  // ─────────────────────────────────────────────────────────────
  // OVERVIEW GRID
  // ─────────────────────────────────────────────────────────────
  Widget _overviewGrid() {
    final items = [
      _OverviewItem(
        'Boats',
        '$totalBoats',
        '$activeBoats active',
        Icons.directions_boat_rounded,
        FisheriesOfficerOcean.primary,
        'boats',
      ),
      _OverviewItem(
        'Fishermen',
        '$totalFishermen',
        '$activeFishermen active',
        Icons.people_alt_rounded,
        FisheriesOfficerOcean.green,
        'fishermen',
      ),
      _OverviewItem(
        'Licenses',
        '$totalLicenses',
        '$expiredLicenses expired',
        Icons.badge_rounded,
        FisheriesOfficerOcean.orange,
        'licenses',
      ),
      _OverviewItem(
        'Voyages',
        '$totalVoyages',
        '$activeVoyages active',
        Icons.sailing_rounded,           // ← FIXED: icon restored
        FisheriesOfficerOcean.blue,      // ← FIXED: color back in 5th slot
        'voyages',
      ),
      _OverviewItem(
        'Catches',
        '$totalCatches',
        '$pendingCatches pending',
        Icons.set_meal_rounded,
        FisheriesOfficerOcean.primary,
        'catches',
      ),
      _OverviewItem(
        'Citings',
        '$openCitings',
        '$highSeverityCitings high',
        Icons.gavel_rounded,
        FisheriesOfficerOcean.red,
        'citings',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
        ),
        itemBuilder: (_, i) => _overviewCard(items[i]),
      ),
    );
  }

  Widget _overviewCard(_OverviewItem it) {
    return GestureDetector(
      onTap: () => onQuickAction?.call(it.action),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FisheriesOfficerOcean.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: it.color.withValues(alpha: .20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: it.color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(it.icon, color: it.color, size: 16),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded,
                    color: it.color.withValues(alpha: .6), size: 14),
              ],
            ),
            const SizedBox(height: 8),
            Text(it.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: it.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1,
                )),
            const SizedBox(height: 4),
            Text(it.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 1),
            Text(it.sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.muted,
                  fontSize: 9.5,
                )),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CATCH SUMMARY
  // ─────────────────────────────────────────────────────────────
  Widget _catchSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: FisheriesOfficerOcean.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: FisheriesOfficerOcean.green.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.scale_rounded,
                      color: FisheriesOfficerOcean.green, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Total Recorded Catch',
                      style: TextStyle(
                        color: FisheriesOfficerOcean.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                Text('${totalCatchWeightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.green,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                      'Verified',
                      '${totalCatches - pendingCatches}',
                      FisheriesOfficerOcean.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _miniStat('Pending', '$pendingCatches',
                      FisheriesOfficerOcean.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _miniStat('Total', '$totalCatches',
                      FisheriesOfficerOcean.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1,
              )),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FisheriesOfficerOcean.muted,
                fontSize: 9.5,
              )),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // QUICK ACTIONS
  // ─────────────────────────────────────────────────────────────
  Widget _quickActions() {
    final actions = [
      _QuickItem('New Citing', Icons.gavel_rounded,
          FisheriesOfficerOcean.red, 'new_citing'),
      _QuickItem('Add Boat', Icons.add_circle_outline_rounded,
          FisheriesOfficerOcean.primary, 'new_boat'),
      _QuickItem('Register User', Icons.person_add_alt_1_rounded,
          FisheriesOfficerOcean.green, 'new_fisherman'),
      _QuickItem('Issue License', Icons.badge_rounded,
          FisheriesOfficerOcean.orange, 'new_license'),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final a = actions[i];
          return GestureDetector(
            onTap: () => onQuickAction?.call(a.action),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FisheriesOfficerOcean.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: a.color.withValues(alpha: .24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(a.icon, color: a.color, size: 16),
                  ),
                  const Spacer(),
                  Text(a.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.text,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RECENT ACTIVITY
  // ─────────────────────────────────────────────────────────────
  Widget _recentActivityList() {
    if (recentActivity.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: FisheriesOfficerOceanEmpty(
          icon: Icons.history_rounded,
          title: 'No recent activity',
          message: 'Actions you take will appear here.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children:
        recentActivity.take(8).map((a) => _activityRow(a)).toList(),
      ),
    );
  }

  Widget _activityRow(dynamic a) {
    final title = a['title'] ?? '—';
    final sub = a['subtitle'];
    final type = (a['type'] ?? '').toString().toLowerCase();
    final dt = _fmtRelative(a['timestamp']);

    final color = type == 'sos'
        ? FisheriesOfficerOcean.red
        : type == 'citing'
        ? FisheriesOfficerOcean.orange
        : type == 'catch'
        ? FisheriesOfficerOcean.green
        : type == 'license'
        ? FisheriesOfficerOcean.primary
        : FisheriesOfficerOcean.blue;

    final icon = type == 'sos'
        ? Icons.warning_rounded
        : type == 'citing'
        ? Icons.gavel_rounded
        : type == 'catch'
        ? Icons.set_meal_rounded
        : type == 'license'
        ? Icons.badge_rounded
        : Icons.info_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FisheriesOfficerOcean.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FisheriesOfficerOcean.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    )),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FisheriesOfficerOcean.muted,
                        fontSize: 10,
                      )),
                ],
              ],
            ),
          ),
          Text(dt,
              style: const TextStyle(
                color: FisheriesOfficerOcean.muted,
                fontSize: 9.5,
              )),
        ],
      ),
    );
  }

  String _fmtRelative(String? d) {
    if (d == null) return '';
    try {
      final t = DateTime.parse(d);
      final diff = DateTime.now().difference(t);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return DateFormat('dd-MM').format(t);
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// SMALL MODELS
// ─────────────────────────────────────────────────────────────
class _OverviewItem {
  final String label, value, sub, action;
  final IconData icon;
  final Color color;

  _OverviewItem(
      this.label,
      this.value,
      this.sub,
      this.icon,
      this.color,
      this.action,
      );
}

class _QuickItem {
  final String label, action;
  final IconData icon;
  final Color color;

  _QuickItem(this.label, this.icon, this.color, this.action);
}