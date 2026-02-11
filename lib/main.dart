import 'package:fishing_voyage_manag_sys/screen/owner_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'screen/splash_screen.dart';
import 'screen/selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.database; // Initialize database

  // Check if user is already registered and logged in
  final sessionInfo = await dbHelper.getSessionInfo();
  final isLoggedIn = sessionInfo?['is_logged_in'] == 1;
  final userId = sessionInfo?['user_id'];

  Widget initialScreen = const SplashScreen();

  if (isLoggedIn && userId != null) {
    // Get owner data
    final owner = await dbHelper.getBoatOwnerById(userId);
    if (owner != null) {
      initialScreen = OwnerDashboard(ownerData: owner);
    } else {
      // If session exists but owner not found, go to selection screen
      initialScreen = const SelectionScreen();
    }
  } else {
    // Not logged in, go to selection screen after splash
    initialScreen = const SplashScreen();
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fishing Voyage Management System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
        ),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}