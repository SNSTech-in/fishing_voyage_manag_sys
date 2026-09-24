
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/api_services/api_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/location_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/background_location_task.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:fishing_voyage_manag_sys/services/background_Services/officer_sync_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/sync_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/background_service_manager.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/background_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/offline_map_service.dart';
import 'package:fishing_voyage_manag_sys/screens/depart_login_selection.dart';
import 'package:fishing_voyage_manag_sys/screens/boat_owner/boat_selection_screen.dart';
import 'package:fishing_voyage_manag_sys/screens/boat_owner/boat_owner_login_screen.dart';
import 'package:fishing_voyage_manag_sys/screens/boat_owner/boat_owner_details_screen.dart';
import 'package:fishing_voyage_manag_sys/screens/boat_owner/dashboard_screen.dart';

@pragma('vm:entry-point')
void startLocationTask() {
  FlutterForegroundTask.setTaskHandler(BackgroundLocationTask());
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundLocationTask());
}

Future<void> _migrateSyncSchema() async {
  try {
    final db = await DatabaseHelper().database;
    await db.rawQuery('PRAGMA busy_timeout = 5000');

    final cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .toUtc()
        .toIso8601String();

    for (final table in ['locations', 'location_points', 'boat_locations']) {
      try {
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'",
        );
        if (tables.isNotEmpty) {
          // Purge rows that can never be sent.
          await db.delete(
            table,
            where: "voyage_no IS NULL OR voyage_no = '' OR voyage_no = 'UNKNOWN'",
          );

          final cols = await db.rawQuery("PRAGMA table_info($table)");
          final hasSynced = cols.any((c) => c['name'] == 'synced');
          final hasIsSynced = cols.any((c) => c['name'] == 'is_synced');

          if (hasSynced) {
            await db.update(table, {'synced': 2},
                where: 'synced = 0 AND timestamp < ?', whereArgs: [cutoff]);
          }
          if (hasIsSynced) {
            await db.update(table, {'synced': 2},
                where: 'is_synced = 0 AND timestamp < ?', whereArgs: [cutoff]);
          }
        }
      } catch (e) {
        debugPrint('⚠️ _migrateSyncSchema for $table error: $e');
      }
    }
  } catch (e) {
    debugPrint('⚠️ _migrateSyncSchema failed: $e');
  }
}



// =========================================================================
// Connectivity listener – sync immediately when internet returns
// =========================================================================
void initConnectivityListener() {
  Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
    if (result.any((r) => r != ConnectivityResult.none)) {
      debugPrint('🌐 Internet restored – syncing');
      _safeSync();
    }
  });

  // Check once at startup
  Connectivity().checkConnectivity().then((List<ConnectivityResult> result) {
    if (result.any((r) => r != ConnectivityResult.none)) {
      debugPrint('🌐 App started online – syncing');
      _safeSync();
    }
  });
}

void _safeSync() async {
  try {
    await SyncService.instance.syncAll();
  } catch (e) {
    debugPrint('⚠️ syncAll error (ignored): $e');
  }
}

Future<void> verifyDatabase() async {
  try {
    final db = await DatabaseHelper().database;
    await db.rawQuery('SELECT 1');
    debugPrint('✅ Database connection OK');
  } catch (e) {
    debugPrint('⚠️ Database check failed, retrying...: $e');
    // Force reopen
    DatabaseHelper().resetConnection();
    final db = await DatabaseHelper().database;
    await db.rawQuery('SELECT 1');
    debugPrint('✅ Database reopened OK');
  }
}

/// ⚠️ TEMPORARY: Deletes the corrupted FMTC database folder.
/// Remove this function AND its call after the app runs successfully once.
Future<void> _deleteFmtcFolder() async {
  try {
    final docsDir = await getApplicationDocumentsDirectory();
    final fmtcDir = Directory('${docsDir.path}/fmtc');

    if (await fmtcDir.exists()) {
      await fmtcDir.delete(recursive: true);
      debugPrint('🗑️ Deleted corrupted FMTC folder: ${fmtcDir.path}');
    } else {
      debugPrint('ℹ️ No FMTC folder found (already clean)');
    }

    // Also try the AppSupport dir (some Android versions use it)
    try {
      final supportDir = await getApplicationSupportDirectory();
      final fmtcSupport = Directory('${supportDir.path}/fmtc');
      if (await fmtcSupport.exists()) {
        await fmtcSupport.delete(recursive: true);
        debugPrint('🗑️ Deleted FMTC folder in support dir: ${fmtcSupport.path}');
      }
    } catch (_) {}
  } catch (e) {
    debugPrint('⚠️ Failed to delete FMTC folder: $e');
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// =========================================================================
// MAIN
// =========================================================================
void main() async {
  // ─── STEP 1: Bare minimum BEFORE first frame ───
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.navigatorKey = navigatorKey;

  // ⚠️ TEMPORARY: Remove this line after the app runs once successfully
  await _deleteFmtcFolder();

  // Initialize FMTC via service (idempotent + self-healing)
  await OfflineMapService.init();

  // ─── STEP 2: Render the UI immediately ───
  runApp(MyApp(navigatorKey: navigatorKey));

  // ─── STEP 3: Defer all plugin/async work AFTER the first frame ───
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      // 1) Foreground service plugin registration
      try {
        BackgroundServiceManager.init();
      } catch (e) {
        debugPrint('⚠️ BackgroundServiceManager.init failed: $e');
      }

      // 2) Permissions (needs Activity — now safe)
      try {
        await BackgroundServiceManager.requestPermissions();
      } catch (e) {
        debugPrint('⚠️ requestPermissions failed: $e');
      }

      // 3) Start background sync service
      try {
        await BackgroundServiceManager.start();
      } catch (e) {
        debugPrint('⚠️ background service start failed: $e');
      }

      // 4) Officer sync watcher
      try {
        OfficerSyncService.instance.start();
      } catch (e) {
        debugPrint('⚠️ OfficerSyncService.start failed: $e');
      }

      // 5) Database health + one-time fixes
      try {
        await verifyDatabase();
        final dbHelper = DatabaseHelper();
        await dbHelper.database;
        // await dbHelper.clearStuckSos(); // Removed to prevent accidental deletion of unsynced SOS
        await dbHelper.fixColumnName();
        await dbHelper.importOldRouteData();
        await _migrateSyncSchema();
      } catch (e) {
        debugPrint('⚠️ DB init failed: $e');
      }

      // 6) Background location service (legacy layer)
      try {
        await initBackgroundService();
      } catch (e) {
        debugPrint('⚠️ initBackgroundService failed: $e');
      }

      // 7) Connectivity listener
      try {
        initConnectivityListener();
      } catch (e) {
        debugPrint('⚠️ initConnectivityListener failed: $e');
      }

      // 9) Foreground task config
      try {
        FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'fishing_voyage_location',
            channelName: 'Voyage Tracking',
            channelDescription:
            'This notification keeps location tracking active.',
            channelImportance: NotificationChannelImportance.LOW,
            priority: NotificationPriority.LOW,
            onlyAlertOnce: true,
          ),
          iosNotificationOptions: const IOSNotificationOptions(
            showNotification: true,
            playSound: false,
          ),
          foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.repeat(60000),
            autoRunOnBoot: true,
            autoRunOnMyPackageReplaced: true,
            allowWifiLock: true,
            allowWakeLock: true,
          ),
        );
      } catch (e) {
        debugPrint('⚠️ FlutterForegroundTask.init failed: $e');
      }

      // 10) Resume tracking if there was an active voyage
      try {
        final prefs = await SharedPreferences.getInstance();
        final activeVoyageId = prefs.getInt('active_voyage_id');
        if (activeVoyageId != null) {
          if (await FlutterForegroundTask.checkNotificationPermission() !=
              NotificationPermission.granted) {
            await FlutterForegroundTask.requestNotificationPermission();
          }

          await FlutterForegroundTask.startService(
            notificationTitle: 'Voyage tracking active',
            notificationText: 'Recording your voyage location',
            notificationIcon: const NotificationIcon(
              metaDataName: 'com.example.fishing_voyage_manag_sys.ICON',
              backgroundColor: Color(0xFF1257C7),
            ),
            callback: startLocationTask,
          );

          LocationService().startTracking(activeVoyageId,
              intervalSeconds: 60);
        }
      } catch (e) {
        debugPrint('⚠️ Resume tracking failed: $e');
      }

      debugPrint('✅ [main] All post-runApp init complete');
    } catch (e, st) {
      debugPrint('⚠️ Post-runApp init error: $e\n$st');
    }
  });
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  late final VoidCallback _reloginListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _reloginListener = () {
      if (SyncService.needsRelogin.value) {
        debugPrint('🔒 Session expired and refresh failed — redirecting to login selection');
        SharedPreferences.getInstance().then((p) {
          p.remove('access_token');
          p.remove('refresh_token');
        });
        DatabaseHelper().clearUserSession();
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/depart_login_selection',
              (_) => false,
        );
        SyncService.needsRelogin.value = false;
      }
    };
    SyncService.needsRelogin.addListener(_reloginListener);

    // Flush when network comes back
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        SyncService().syncAll();
      }
    });
  }

  @override
  void dispose() {
    SyncService.needsRelogin.removeListener(_reloginListener);
    _connectivitySub.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SyncService().syncAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fishers Department',
      debugShowCheckedModeBanner: false,
      navigatorKey: widget.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF07347F),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1257C7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/depart_login_selection': (context) => const DepartLoginSelection(),
        '/boat_selection': (context) => const BoatSelectionScreen(),
        '/boat_owner_login': (context) => const BoatOwnerLoginScreen(),
        '/boat_owner_details': (context) => const BoatOwnerDetailsScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _migrateSyncSchema();
    _checkLoginAndBoatStatus();
  }

  Future<void> _checkLoginAndBoatStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final db = DatabaseHelper();
    final bool isLoggedIn = await db.isUserLoggedIn();
    if (!mounted) return;
    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/depart_login_selection');
      return;
    }
    try {
      final hasSelectedBoats = await db.hasSelectedBoats();
      if (!mounted) return;
      if (hasSelectedBoats) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BoatSelectionScreen(isSelectionMode: true),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking boat selection: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/boat_selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1257C7), Color(0xFF07347F)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'UTLCRAFT',
                style: TextStyle(
                  color: Color(0xFF07347F),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fisheries Department',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
