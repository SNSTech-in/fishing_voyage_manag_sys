import 'package:fishing_voyage_manag_sys/screen/officers_registration_screen.dart';
import 'package:fishing_voyage_manag_sys/screen/reports_screen.dart';
import 'package:fishing_voyage_manag_sys/screen/selection_screen.dart';
import 'package:fishing_voyage_manag_sys/screen/voyages_screen.dart';
import 'package:flutter/material.dart';
import 'registration_screen.dart';
import '../../database/database_helper.dart';

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  State<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dbHelper = DatabaseHelper();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logoutAndClearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout & Clear All Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              size: 60,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'This will clear ALL data including:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• All boat owners'),
            Text('• All voyages'),
            Text('• All officers'),
            Text('• All custom ports'),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout & Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 16),
              const Text('Clearing all data...'),
              FutureBuilder(
                future: _clearAllDatabaseData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        Navigator.pop(context);
                        _navigateToLogin();
                      }
                    });
                  }
                  return Container();
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _clearAllDatabaseData() async {
    try {
      await _dbHelper.clearAllData();
      print('All database data cleared successfully');
    } catch (e) {
      print('Error clearing database: $e');
    }
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectionScreen(),
      ),
          (route) => false,
    );
  }

  void _logout() {
    _logoutAndClearData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text('Officer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout & Clear All',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Voyages'),
            Tab(text: 'Registration'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const VoyagesScreen(),
          const OfficersRegistrationScreen(),
          const ReportsScreen(),
        ],
      ),
    );
  }
}