import 'package:flutter/material.dart';
import '../../../database/database_helper.dart';
import '../../../services/api_services/officer_api_service.dart';
import 'auditLog/audit_log_screen.dart';
import 'officer_login_screen.dart';
import 'sos/sos_summary_screen.dart';
import 'citing/citings_summary_screen.dart';
import 'voyages/voyages_summary_screen.dart';
import 'ports_masters_screen.dart';
import 'species_masters_screen.dart';
import 'officers_masters_screen.dart';
import 'fishCatchReport/fish_catch_report_screen.dart';
import 'crew_not_returned_screen.dart';
import 'boatActivity/boat_activity_report_screen.dart';
import 'sos/sos_report_screen.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  final OfficersApiService _api = OfficersApiService();
  final DatabaseHelper _db = DatabaseHelper();

  // Palette
  static const Color _primary = Color(0xFF1257C7);
  static const Color _primaryDark = Color(0xFF07347F);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMid = Color(0xFF475569);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _warning = Color(0xFFD97706);

  bool _loading = true;
  String? _error;
  String _officerName = 'Officer';
  String _officerRole = 'Fisheries Officer';

  // Dashboard sections
  Map<String, dynamic> _counts = {};
  Map<String, dynamic> _alerts = {};
  List<Map<String, dynamic>> _topPorts = [];
  Map<String, dynamic> _catchSummary = {};
  List<Map<String, dynamic>> _trend = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await _db.getOfficerSession();
      if (session != null && mounted) {
        setState(() {
          _officerName =
              session['officer_name']?.toString() ?? 'Officer';
        });
      }
    } catch (e) {
      debugPrint('⚠️ Could not read officer session: $e');
    }

    final res = await _api.fetchDashboardStats();

    if (!mounted) return;

    if (res['success'] == true && res['data'] is Map) {
      final d = Map<String, dynamic>.from(res['data'] as Map);
      setState(() {
        _counts = (d['counts'] is Map)
            ? Map<String, dynamic>.from(d['counts'])
            : {};
        _alerts = (d['alerts'] is Map)
            ? Map<String, dynamic>.from(d['alerts'])
            : {};
        _topPorts = (d['top_ports'] is List)
            ? (d['top_ports'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
            : [];
        _catchSummary = (d['catch_summary'] is Map)
            ? Map<String, dynamic>.from(d['catch_summary'])
            : {};
        _trend = (d['trend'] is List)
            ? (d['trend'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
            : [];
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Failed to load dashboard';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
            'You will be signed out and all locally stored data will be cleared.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout')),
        ],
      ),
    );
    if (confirm != true) return;

    await _db.clearAllData();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OfficerLoginScreen()),
          (_) => false,
    );
  }

  int _i(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  double _d(dynamic v, [double fallback = 0]) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  // ═══════════════════════════════════════════════════════════
  // MORE OPTIONS SHEET
  // ═══════════════════════════════════════════════════════════
  void _showMoreOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.94,
          expand: false,
          builder: (ctx, ctrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                    child: Container(
                      height: 4,
                      width: 44,
                      decoration: BoxDecoration(
                        color: _divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                    child: Row(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.apps_rounded,
                              color: Colors.white, size: 21),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'More Options',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _textDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Drag up to see all features',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded,
                              color: _textMid, size: 20),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: _divider),

                  Expanded(
                    child: ListView(
                      controller: ctrl,
                      padding:
                      const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      children: [
                        // ═══════════════════════════════════════
                        // GENERAL
                        // ═══════════════════════════════════════
                        _moreSectionHeader('General'),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                          children: [
                            _moreTile(
                              icon: Icons.dashboard_rounded,
                              title: 'Dashboard',
                              color: _primary,
                              onTap: () {
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ═══════════════════════════════════════
                        // OPERATIONS
                        // ═══════════════════════════════════════
                        _moreSectionHeader('Operations'),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                          children: [
                            _moreTile(
                              icon: Icons.directions_boat_rounded,
                              title: 'Voyages',
                              color: Colors.blue,
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const VoyagesSummaryScreen()));
                              },
                            ),
                            _moreTile(
                              icon: Icons.warning_amber_rounded,
                              title: 'SOS',
                              color: Colors.redAccent,
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const SosSummaryScreen()));
                              },
                            ),
                            _moreTile(
                              icon: Icons.report_gmailerrorred_rounded,
                              title: 'Citings',
                              color: Colors.orange,
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const CitingsSummaryScreen()));
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ═══════════════════════════════════════
                        // REPORTS
                        // ═══════════════════════════════════════
                        _moreSectionHeader('Reports'),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                          children: [
                            _moreTile(
                              icon: Icons.scale_rounded,
                              title: 'Fish Catch',
                              color: const Color(0xFF0891B2),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const FishCatchReportScreen()));
                              },
                            ),
                            _moreTile(
                              icon: Icons.person_off_rounded,
                              title: 'Crew Not\nReturned',
                              color: const Color(0xFFDC2626),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const CrewNotReturnedScreen()));
                              },
                            ),
                            _moreTile(
                              icon: Icons.sailing_rounded,
                              title: 'Boat\nActivity',
                              color: const Color(0xFF7C3AED),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const BoatActivityReportScreen()));
                              },
                            ),
                            _moreTile(
                              icon: Icons.sos_rounded,
                              title: 'SOS\nReport',
                              color: Colors.redAccent,
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const SosReportScreen()));
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ═══════════════════════════════════════
                        // ADMINISTRATION
                        // ═══════════════════════════════════════
                        _moreSectionHeader('Administration'),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                          children: [
                            _moreTile(
                              icon: Icons.anchor_rounded,
                              title: 'Ports',
                              color: Colors.teal,
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const PortsMastersScreen()));
                              },
                            ),
                            _moreTile(
                              icon: Icons.set_meal_rounded,
                              title: 'Fish\nSpecies',
                              color: const Color(0xFF0891B2),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const SpeciesMastersScreen()));
                              },
                            ),
                            _moreTile(
                              icon: Icons.badge_rounded,
                              title: 'Officers',
                              color: const Color(0xFF7C3AED),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const OfficersMastersScreen()));
                              },
                            ),
                            _moreTile(
                              icon: Icons.people_alt_rounded,
                              title: 'System\nUsers',
                              color: const Color(0xFF64748B),
                              onTap: () {
                                _showComingSoon(ctx, 'System Users');
                              },
                            ),
                            _moreTile(
                              icon: Icons.history_rounded,
                              title: 'Audit\nLog',
                              color: const Color(0xFF334155),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const AuditLogScreen()));
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ═══════════════════════════════════════
                        // ACCOUNT
                        // ═══════════════════════════════════════
                        _moreSectionHeader('Account'),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                          children: [
                            _moreTile(
                              icon: Icons.refresh_rounded,
                              title: 'Refresh',
                              color: _primary,
                              onTap: () {
                                Navigator.pop(ctx);
                                _bootstrap();
                              },
                            ),
                            _moreTile(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              color: _danger,
                              onTap: () {
                                Navigator.pop(ctx);
                                _logout();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showComingSoon(BuildContext ctx, String feature) {
    Navigator.pop(ctx);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _warning,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$feature will be available soon',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moreSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: _textLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: _divider)),
      ],
    );
  }

  Widget _moreTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  letterSpacing: -0.1,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DRAWER
  // ═══════════════════════════════════════════════════════════
  Widget _buildDrawer() {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 3),
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 40, color: _primary),
                ),
                const SizedBox(height: 14),
                Text(
                  _officerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _officerRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Menu ───────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 12),
              children: [
                // ─── GENERAL ────────────────────────────────
                _drawerSectionHeader('General'),
                _drawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  color: _primary,
                  onTap: () => Navigator.pop(context),
                ),

                // ─── OPERATIONS ─────────────────────────────
                _drawerSectionHeader('Operations'),
                _drawerItem(
                  icon: Icons.directions_boat,
                  title: 'Voyages',
                  color: Colors.blue,
                  badge: _i(_counts['total_intimations']),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const VoyagesSummaryScreen()));
                  },
                ),
                _drawerItem(
                  icon: Icons.warning_amber_rounded,
                  title: 'SOS',
                  color: Colors.redAccent,
                  badge: _i(_alerts['open_sos']),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SosSummaryScreen()));
                  },
                ),
                _drawerItem(
                  icon: Icons.report_gmailerrorred,
                  title: 'Citings',
                  color: Colors.orange,
                  badge: _i(_alerts['citings_pending_review']),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const CitingsSummaryScreen()));
                  },
                ),

                // ─── REPORTS ────────────────────────────────
                _drawerSectionHeader('Reports'),
                _drawerItem(
                  icon: Icons.scale_rounded,
                  title: 'Fish Catch',
                  color: const Color(0xFF0891B2),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const FishCatchReportScreen()));
                  },
                ),
                _drawerItem(
                  icon: Icons.person_off_rounded,
                  title: 'Crew Not Returned',
                  color: _danger,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const CrewNotReturnedScreen()));
                  },
                ),
                _drawerItem(
                  icon: Icons.sailing_rounded,
                  title: 'Boat Activity',
                  color: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const BoatActivityReportScreen()));
                  },
                ),
                _drawerItem(
                  icon: Icons.sos_rounded,
                  title: 'SOS Report',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SosReportScreen()));
                  },
                ),

                // ─── ADMINISTRATION ─────────────────────────
                _drawerSectionHeader('Administration'),
                _drawerItem(
                  icon: Icons.anchor,
                  title: 'Ports',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const PortsMastersScreen()));
                  },
                ),
                _drawerItem(
                  icon: Icons.set_meal,
                  title: 'Fish Species',
                  color: const Color(0xFF0891B2),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const SpeciesMastersScreen()));
                  },
                ),
                _drawerItem(
                  icon: Icons.badge_rounded,
                  title: 'Officers',
                  color: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const OfficersMastersScreen()));
                  },
                ),
                _drawerItem(
                  icon: Icons.people_alt_rounded,
                  title: 'System Users',
                  color: const Color(0xFF64748B),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonGlobal('System Users');
                  },
                ),
                _drawerItem(
                  icon: Icons.history_rounded,
                  title: 'Audit Log',
                  color: const Color(0xFF334155),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AuditLogScreen()));
                  },
                ),
              ],
            ),
          ),

          // ── Logout ─────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 14 + bottomPadding),
            child: Material(
              color: _danger.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border:
                    Border.all(color: _danger.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: _danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            size: 17, color: _danger),
                      ),
                      const SizedBox(width: 11),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 13,
                          color: _danger,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: _danger.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonGlobal(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _warning,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$feature will be available soon',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: _textLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _divider)),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: _textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Fisheries Officer Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _bootstrap,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _bootstrap,
        color: _primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _errorView()
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _quickAccessHeader(),
            const SizedBox(height: 8),
            _topThreeTiles(),
            const SizedBox(height: 20),

            _sectionTitle('Overview'),
            _countsGrid(),
            const SizedBox(height: 20),

            _sectionTitle('Alerts'),
            _alertsGrid(),
            const SizedBox(height: 20),

            _sectionTitle('Trend'),
            _trendChartCard(),
            const SizedBox(height: 20),

            _sectionTitle('Top Ports'),
            _topPortsCard(),
            const SizedBox(height: 20),

            _sectionTitle('Top Species by Catch'),
            _topSpeciesCard(),
          ],
        ),
      ),
    );
  }

  Widget _quickAccessHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _primaryDark,
          ),
        ),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _showMoreOptionsSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apps_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topThreeTiles() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const cols = 3;
        final tileSize =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: tileSize,
              height: tileSize,
              child: _squareTile(
                icon: Icons.directions_boat_rounded,
                title: 'Voyages',
                subtitle: '${_i(_counts['total_intimations'])} total',
                color: Colors.blue,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VoyagesSummaryScreen())),
              ),
            ),
            SizedBox(
              width: tileSize,
              height: tileSize,
              child: _squareTile(
                icon: Icons.report_gmailerrorred_rounded,
                title: 'Citings',
                subtitle:
                '${_i(_alerts['citings_pending_review'])} pending',
                color: Colors.orange,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CitingsSummaryScreen())),
              ),
            ),
            SizedBox(
              width: tileSize,
              height: tileSize,
              child: _squareTile(
                icon: Icons.anchor_rounded,
                title: 'Ports',
                subtitle: '${_topPorts.length} active',
                color: Colors.teal,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PortsMastersScreen())),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _squareTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.2,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _textLight,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Center(child: Text(_error!, textAlign: TextAlign.center)),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton(
            onPressed: _bootstrap,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _primaryDark,
      ),
    ),
  );

  Widget _countsGrid() {
    final tiles = <_StatTile>[
      _StatTile('Total', _i(_counts['total_intimations']),
          Icons.list_alt, Colors.indigo),
      _StatTile('Ongoing', _i(_counts['ongoing']),
          Icons.sailing, Colors.green),
      _StatTile('Overdue', _i(_counts['overdue']),
          Icons.warning, Colors.deepOrange),
      _StatTile('Completed', _i(_counts['completed']),
          Icons.check_circle, Colors.teal),
      _StatTile('Upcoming', _i(_counts['upcoming']),
          Icons.schedule, Colors.blue),
      _StatTile('Cancelled', _i(_counts['cancelled']),
          Icons.cancel, Colors.grey),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const cols = 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((t) => SizedBox(
            width: tileWidth,
            child: _statCard(t),
          ))
              .toList(),
        );
      },
    );
  }

  Widget _statCard(_StatTile t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.color.withOpacity(0.25)),
      ),
      child: SizedBox(
        height: 92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(t.icon, color: t.color, size: 22),
            Flexible(
              child: Text(
                '${t.value}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: t.color,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                t.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertsGrid() {
    final tiles = <_StatTile>[
      _StatTile('Open SOS', _i(_alerts['open_sos']),
          Icons.sos, Colors.red),
      _StatTile('Crew Not Returned', _i(_alerts['crew_not_returned']),
          Icons.person_off, Colors.deepOrange),
      _StatTile('Citings Pending', _i(_alerts['citings_pending_review']),
          Icons.pending_actions, Colors.orange),
      _StatTile('Licences Expiring (30d)',
          _i(_alerts['licences_expiring_30d']),
          Icons.badge_outlined, Colors.amber),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const cols = 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((t) => SizedBox(
            width: tileWidth,
            child: _statCard(t),
          ))
              .toList(),
        );
      },
    );
  }

  Widget _trendChartCard() {
    if (_trend.isEmpty) {
      return const Text('No trend data.',
          style: TextStyle(color: Colors.black54));
    }

    final points = _trend
        .map((e) => _i(e['intimations']))
        .toList(growable: false);
    final dates = _trend
        .map((e) => e['date']?.toString() ?? '')
        .toList(growable: false);

    final maxVal =
    points.isEmpty ? 1 : points.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _LineChartPainter(
                values: points,
                maxValue: maxVal,
                lineColor: const Color(0xFF0E8FBF),
                fillColor: const Color(0xFF0E8FBF).withOpacity(0.12),
                gridColor: Colors.grey.shade200,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_shortDate(dates.isNotEmpty ? dates.first : ''),
                  style: const TextStyle(
                      fontSize: 10, color: Colors.black54)),
              if (dates.length > 2)
                Text(_shortDate(dates[dates.length ~/ 2]),
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black54)),
              Text(_shortDate(dates.isNotEmpty ? dates.last : ''),
                  style: const TextStyle(
                      fontSize: 10, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    if (iso.length >= 10) return iso.substring(0, 10);
    return iso;
  }

  Widget _topPortsCard() {
    if (_topPorts.isEmpty) {
      return const Text('No port activity yet.',
          style: TextStyle(color: Colors.black54));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: _topPorts.map((p) {
          final name = p['port_name']?.toString() ?? '—';
          final count = _i(p['voyage_count']);
          return Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$count voyage${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _topSpeciesCard() {
    final species = (_catchSummary['top_species'] is List)
        ? (_catchSummary['top_species'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        : <Map<String, dynamic>>[];

    final totalKg = _d(_catchSummary['total_weight_kg']);

    if (species.isEmpty) {
      return const Text('No species data.',
          style: TextStyle(color: Colors.black54));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ...species.map((s) {
            final name = s['fish_name']?.toString() ?? '—';
            final weight = _d(s['weight_kg']);
            final weightText = weight == weight.roundToDouble()
                ? '${weight.toInt()} kg'
                : '${weight} kg';
            return Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    weightText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 1),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _primaryDark,
                    ),
                  ),
                ),
                Text(
                  '${totalKg.toStringAsFixed(2)} kg',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tiny DTO ────────────────────────────────────────────────
class _StatTile {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatTile(this.label, this.value, this.icon, this.color);
}

// ═════════════════════════════════════════════════════════════
// LINE CHART PAINTER
// ═════════════════════════════════════════════════════════════
class _LineChartPainter extends CustomPainter {
  final List<int> values;
  final int maxValue;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  _LineChartPainter({
    required this.values,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const leftPad = 24.0;
    const rightPad = 8.0;
    const topPad = 8.0;
    const bottomPad = 20.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const steps = 4;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= steps; i++) {
      final y = topPad + chartH - (chartH * i / steps);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );

      final labelVal = ((maxValue * i) / steps).round();
      tp.text = TextSpan(
        text: '$labelVal',
        style: const TextStyle(color: Colors.black45, fontSize: 10),
      );
      tp.layout();
      tp.paint(
          canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    final n = values.length;
    final dx = n > 1 ? chartW / (n - 1) : 0.0;

    final offsets = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = leftPad + dx * i;
      final y = topPad + chartH - (chartH * values[i] / maxValue);
      offsets.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);

    for (int i = 0; i < n - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final c1 = Offset(p0.dx + (p1.dx - p0.dx) * 0.4, p0.dy);
      final c2 = Offset(p0.dx + (p1.dx - p0.dx) * 0.6, p1.dy);
      linePath.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(offsets.last.dx, topPad + chartH)
      ..lineTo(offsets.first.dx, topPad + chartH)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final p in offsets) {
      canvas.drawCircle(p, 3.5, dotFill);
      canvas.drawCircle(p, 3.5, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values ||
          oldDelegate.maxValue != maxValue ||
          oldDelegate.lineColor != lineColor;
}