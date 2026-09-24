import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../services/offline_queue_service.dart';
import '../services/offline_map_service.dart';
import 'ui/fisheries_officer_ocean_ui.dart';
import 'screens/officer_dashboard_logic.dart';
import 'screens/voyages_screen.dart';
import 'screens/sos_screen_logic.dart';
import 'screens/citings_screen_logic.dart';
import 'screens/fish_catch_report_logic.dart';
import 'screens/crew_not_returned_logic.dart';
import 'screens/boat_activity_report_logic.dart';
import 'screens/sos_report_logic.dart';
import 'screens/ports_screen_logic.dart';
import 'screens/species_screen_logic.dart';
import 'screens/officers_screen_logic.dart';

class OfficerMainScreen extends StatefulWidget {
  const OfficerMainScreen({Key? key}) : super(key: key);
  @override
  _OfficerMainScreenState createState() => _OfficerMainScreenState();
}

class _OfficerMainScreenState extends State<OfficerMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    OfficerDashboard(),
    VoyagesScreen(),
    SosScreen(),
    CitingsScreen(), // We'll map "More" logic later if needed
  ];

  final List<String> _titles = [
    'Fisheries Officer',
    'Voyages',
    'SOS Alerts',
    'More',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FisheriesOfficerOcean.bg,
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: FisheriesOfficerOcean.headerGradient)),
        title: Text(_titles[_selectedIndex == 3 ? 0 : _selectedIndex],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          FutureBuilder<int>(
            future: OfflineQueueService.instance.totalPendingCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: .5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text('$count',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
        ],
      ),
      drawer: _buildDrawer(),
      body: _selectedIndex < 3 ? _screens[_selectedIndex] : _buildMoreMenu(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10)]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: FisheriesOfficerOcean.primary,
          unselectedItemColor: FisheriesOfficerOcean.muted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.sailing_rounded), label: 'Voyages'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_active_rounded), label: 'SOS'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'More'),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenu() {
    final items = [
      _MoreItem('Citings', Icons.report_problem_rounded, 3),
      _MoreItem('Fish Catch Report', Icons.set_meal_rounded, 4),
      _MoreItem('Crew Not Returned', Icons.person_off_rounded, 5),
      _MoreItem('Boat Activity', Icons.directions_boat_rounded, 6),
      _MoreItem('SOS Report', Icons.analytics_rounded, 7),
      _MoreItem('Ports', Icons.anchor_rounded, 8),
      _MoreItem('Fish Species', Icons.phishing_rounded, 9),
      _MoreItem('Officers', Icons.badge_rounded, 10),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: items.map((it) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: FisheriesOfficerOcean.border)),
        child: ListTile(
          leading: Icon(it.icon, color: FisheriesOfficerOcean.primary),
          title: Text(it.name, style: const TextStyle(color: FisheriesOfficerOcean.text, fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => _getScreen(it.index)));
            if (!mounted) return;
            setState(() {});
          },
        ),
      )).toList(),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 3: return CitingsScreen();
      case 4: return FishCatchReport();
      case 5: return CrewNotReturned();
      case 6: return BoatActivityReport();
      case 7: return SosReport();
      case 8: return PortsScreen();
      case 9: return SpeciesScreen();
      case 10: return OfficersScreen();
      default: return OfficerDashboard();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FisheriesOfficerOcean.card,
        title: const Text(
          'Logout',
          style: TextStyle(color: FisheriesOfficerOcean.text),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: FisheriesOfficerOcean.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: FisheriesOfficerOcean.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('officer_token');
    await prefs.remove('auth_token');
    await prefs.remove('user_token');

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/depart_login_selection',
      (route) => false,
    );
  }

  Future<void> _downloadOfflineMap() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting map download for Lakshadweep area...')),
      );

      await OfflineMapService.downloadLakshadweepTiles(
        onProgress: (progress) {
          debugPrint('Offline map: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Map download completed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Map download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Map download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDrawer() => Drawer(
    backgroundColor: FisheriesOfficerOcean.bg,
    child: ListView(padding: EdgeInsets.zero, children: [
      const DrawerHeader(decoration: BoxDecoration(gradient: FisheriesOfficerOcean.headerGradient),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.account_circle_rounded, color: Colors.white, size: 48),
            SizedBox(height: 12),
            const Text('Fisheries Officer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const Text('Live Monitoring Mode', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
      ListTile(
          leading: const Icon(Icons.download_for_offline_rounded, color: FisheriesOfficerOcean.primary),
          title: const Text('Download Offline Map', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Lakshadweep Coast Area', style: TextStyle(fontSize: 11)),
          onTap: () {
            Navigator.pop(context);
            _downloadOfflineMap();
          }
      ),
      ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          onTap: _handleLogout
      ),
    ]),
  );

  Widget _buildDrawerItem(String title, int index, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? FisheriesOfficerOcean.primary : null),
      title: Text(title),
      tileColor: _selectedIndex == index ? FisheriesOfficerOcean.primary.withOpacity(.05) : null,
      onTap: () { setState(() => _selectedIndex = index); Navigator.pop(context); },
    );
  }
}

class _MoreItem {
  final String name;
  final IconData icon;
  final int index;
  _MoreItem(this.name, this.icon, this.index);
}
