import 'dart:async';
import 'dart:io';

import 'package:fishing_voyage_manag_sys/screens/officer_Screens/new_correction/officer_dashboard_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/api_services/boat_owners_api_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/location_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/background_location_task.dart';
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
// ============================================================================
// FOREGROUND LOCATION TASK
// ============================================================================



@pragma('vm:entry-point')
void startLocationTask() {
  FlutterForegroundTask.setTaskHandler(
    BackgroundLocationTask(),
  );
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(
    BackgroundLocationTask(),
  );
}


// ============================================================================
// DATABASE MIGRATION
// ============================================================================

Future<void> _migrateSyncSchema() async {
  try {
    final db = await DatabaseHelper().database;

    await db.rawQuery(
      'PRAGMA busy_timeout = 5000',
    );

    final cutoff = DateTime.now()
        .subtract(
      const Duration(days: 30),
    )
        .toUtc()
        .toIso8601String();

    for (final table in [
      'locations',
      'location_points',
      'boat_locations',
    ]) {
      try {
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master "
              "WHERE type='table' AND name='$table'",
        );

        if (tables.isNotEmpty) {
          await db.delete(
            table,
            where:
            "voyage_no IS NULL "
                "OR voyage_no = '' "
                "OR voyage_no = 'UNKNOWN'",
          );

          final cols = await db.rawQuery(
            "PRAGMA table_info($table)",
          );

          final hasSynced = cols.any(
                (c) => c['name'] == 'synced',
          );

          final hasIsSynced = cols.any(
                (c) => c['name'] == 'is_synced',
          );

          if (hasSynced) {
            await db.update(
              table,
              {'synced': 2},
              where:
              'synced = 0 AND timestamp < ?',
              whereArgs: [cutoff],
            );
          }

          if (hasIsSynced) {
            await db.update(
              table,
              {'synced': 2},
              where:
              'is_synced = 0 AND timestamp < ?',
              whereArgs: [cutoff],
            );
          }
        }
      } catch (e) {
        debugPrint(
          '⚠️ _migrateSyncSchema for $table error: $e',
        );
      }
    }
  } catch (e) {
    debugPrint(
      '⚠️ _migrateSyncSchema failed: $e',
    );
  }
}


// ============================================================================
// CONNECTIVITY LISTENER
// ============================================================================

void initConnectivityListener() {
  Connectivity()
      .onConnectivityChanged
      .listen(
        (List<ConnectivityResult> result) {
      if (result.any(
            (r) => r != ConnectivityResult.none,
      )) {
        debugPrint(
          '🌐 Internet restored – syncing',
        );

        _safeSync();
      }
    },
  );

  Connectivity()
      .checkConnectivity()
      .then(
        (List<ConnectivityResult> result) {
      if (result.any(
            (r) => r != ConnectivityResult.none,
      )) {
        debugPrint(
          '🌐 App started online – syncing',
        );

        _safeSync();
      }
    },
  );
}


void _safeSync() async {
  try {
    await SyncService.instance.syncAll();
  } catch (e) {
    debugPrint(
      '⚠️ syncAll error (ignored): $e',
    );
  }
}


// ============================================================================
// DATABASE VERIFICATION
// ============================================================================

Future<void> verifyDatabase() async {
  try {
    final db = await DatabaseHelper().database;

    await db.rawQuery('SELECT 1');

    debugPrint(
      '✅ Database connection OK',
    );
  } catch (e) {
    debugPrint(
      '⚠️ Database check failed, retrying...: $e',
    );

    DatabaseHelper().resetConnection();

    final db = await DatabaseHelper().database;

    await db.rawQuery('SELECT 1');

    debugPrint(
      '✅ Database reopened OK',
    );
  }
}


// ============================================================================
// DELETE FMTC FOLDER
// ============================================================================

Future<void> _deleteFmtcFolder() async {
  try {
    final docsDir =
    await getApplicationDocumentsDirectory();

    final fmtcDir =
    Directory('${docsDir.path}/fmtc');

    if (await fmtcDir.exists()) {
      await fmtcDir.delete(
        recursive: true,
      );

      debugPrint(
        '🗑️ Deleted corrupted FMTC folder: '
            '${fmtcDir.path}',
      );
    } else {
      debugPrint(
        'ℹ️ No FMTC folder found (already clean)',
      );
    }

    try {
      final supportDir =
      await getApplicationSupportDirectory();

      final fmtcSupport =
      Directory('${supportDir.path}/fmtc');

      if (await fmtcSupport.exists()) {
        await fmtcSupport.delete(
          recursive: true,
        );

        debugPrint(
          '🗑️ Deleted FMTC folder in support dir: '
              '${fmtcSupport.path}',
        );
      }
    } catch (_) {}
  } catch (e) {
    debugPrint(
      '⚠️ Failed to delete FMTC folder: $e',
    );
  }
}


// ============================================================================
// NAVIGATOR
// ============================================================================

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();


// ============================================================================
// MAIN
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  BoatOwnwesApiService.navigatorKey =
      navigatorKey;

  // ------------------------------------------------------------
  // TEMPORARY FMTC CLEANUP
  // ------------------------------------------------------------

  await _deleteFmtcFolder();

  // ------------------------------------------------------------
  // Offline map initialization
  // ------------------------------------------------------------

  await OfflineMapService.init();

  // ------------------------------------------------------------
  // Start application
  // ------------------------------------------------------------

  runApp(
    MyApp(
      navigatorKey: navigatorKey,
    ),
  );

  // ------------------------------------------------------------
  // Post-frame initialization
  // ------------------------------------------------------------

  WidgetsBinding.instance
      .addPostFrameCallback(
        (_) async {
      try {

        try {
          BackgroundServiceManager.init();
        } catch (e) {
          debugPrint(
            '⚠️ BackgroundServiceManager.init failed: $e',
          );
        }

        try {
          await BackgroundServiceManager.start();
        } catch (e) {
          debugPrint(
            '⚠️ background service start failed: $e',
          );
        }

        try {
          OfficerSyncService.instance.start();
        } catch (e) {
          debugPrint(
            '⚠️ OfficerSyncService.start failed: $e',
          );
        }

        try {
          await verifyDatabase();

          final dbHelper =
          DatabaseHelper();

          await dbHelper.database;

          await dbHelper.fixColumnName();

          await dbHelper.importOldRouteData();

          await _migrateSyncSchema();
        } catch (e) {
          debugPrint(
            '⚠️ DB init failed: $e',
          );
        }

        try {
          await initBackgroundService();
        } catch (e) {
          debugPrint(
            '⚠️ initBackgroundService failed: $e',
          );
        }

        try {
          initConnectivityListener();
        } catch (e) {
          debugPrint(
            '⚠️ initConnectivityListener failed: $e',
          );
        }

        try {
          FlutterForegroundTask.init(
            androidNotificationOptions:
            AndroidNotificationOptions(
              channelId:
              'fishing_voyage_location',

              channelName:
              'Voyage Tracking',

              channelDescription:
              'This notification keeps '
                  'location tracking active.',

              channelImportance:
              NotificationChannelImportance.LOW,

              priority:
              NotificationPriority.LOW,

              onlyAlertOnce: true,
            ),

            iosNotificationOptions:
            const IOSNotificationOptions(
              showNotification: true,
              playSound: false,
            ),

            foregroundTaskOptions:
            ForegroundTaskOptions(
              eventAction:
              ForegroundTaskEventAction
                  .repeat(60000),

              autoRunOnBoot: false,

              autoRunOnMyPackageReplaced:
              false,

              allowWifiLock: true,

              allowWakeLock: true,
            ),
          );
        } catch (e) {
          debugPrint(
            '⚠️ FlutterForegroundTask.init failed: $e',
          );
        }

        try {
          final prefs =
          await SharedPreferences
              .getInstance();

          final activeVoyageId =
          prefs.getInt(
            'active_voyage_id',
          );

          if (activeVoyageId != null) {

            final locGranted =
            await Permission
                .location
                .isGranted;

            if (!locGranted) {
              debugPrint(
                '⚠️ Location permission not granted, '
                    'skipping resume tracking.',
              );
            } else {

              if (await FlutterForegroundTask
                  .checkNotificationPermission() !=
                  NotificationPermission.granted) {

                debugPrint(
                  '⚠️ Notification permission not granted.',
                );

              } else {

                await FlutterForegroundTask
                    .startService(
                  notificationTitle:
                  'Voyage tracking active',

                  notificationText:
                  'Recording your voyage location',

                  notificationIcon:
                  const NotificationIcon(
                    metaDataName:
                    'com.fishing_voyage_manag_sys.ICON',

                    backgroundColor:
                    Color(0xFF1257C7),
                  ),

                  callback:
                  startLocationTask,
                );

                LocationService()
                    .startTracking(
                  activeVoyageId,
                  intervalSeconds: 60,
                );
              }
            }
          }
        } catch (e) {
          debugPrint(
            '⚠️ Resume tracking failed: $e',
          );
        }

        debugPrint(
          '✅ [main] All post-runApp init complete',
        );

      } catch (e, st) {

        debugPrint(
          '⚠️ Post-runApp init error: $e\n$st',
        );
      }
    },
  );
}


// ============================================================================
// MY APP
// ============================================================================

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState>
  navigatorKey;

  const MyApp({
    super.key,
    required this.navigatorKey,
  });

  @override
  State<MyApp> createState() =>
      _MyAppState();
}


class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver {

  late final StreamSubscription<
      List<ConnectivityResult>>
  _connectivitySub;

  late final VoidCallback
  _reloginListener;


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(this);

    _reloginListener = () {

      if (SyncService
          .needsRelogin
          .value) {

        debugPrint(
          '🔒 Session expired and refresh failed '
              '— redirecting to login selection',
        );

        SharedPreferences
            .getInstance()
            .then(
              (p) {

            p.remove(
              'access_token',
            );

            p.remove(
              'refresh_token',
            );

          },
        );

        // ⭐ Clear both boat-owner session AND officer session
        DatabaseHelper()
            .clearUserSession();

        DatabaseHelper()
            .clearOfficerSession();

        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil(
          '/depart_login_selection',
              (_) => false,
        );

        SyncService
            .needsRelogin
            .value = false;
      }
    };


    SyncService
        .needsRelogin
        .addListener(
      _reloginListener,
    );


    _connectivitySub =
        Connectivity()
            .onConnectivityChanged
            .listen(
              (results) {

            final online =
            results.any(
                  (r) =>
              r !=
                  ConnectivityResult.none,
            );

            if (online) {
              SyncService()
                  .syncAll();
            }
          },
        );
  }


  @override
  void dispose() {

    SyncService
        .needsRelogin
        .removeListener(
      _reloginListener,
    );

    _connectivitySub.cancel();

    WidgetsBinding.instance
        .removeObserver(this);

    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {

    if (state ==
        AppLifecycleState.resumed) {

      SyncService()
          .syncAll();
    }
  }


  @override
  Widget build(
      BuildContext context,
      ) {

    return MaterialApp(
      title:
      'Fishers Department',

      debugShowCheckedModeBanner:
      false,

      navigatorKey:
      widget.navigatorKey,

      theme:
      ThemeData(

        colorScheme:
        ColorScheme.fromSeed(
          seedColor:
          const Color(
            0xFF1A237E,
          ),
        ),

        scaffoldBackgroundColor:
        const Color(
          0xFFF5F7FA,
        ),

        useMaterial3:
        true,

        appBarTheme:
        const AppBarTheme(

          elevation:
          0,

          centerTitle:
          false,

          backgroundColor:
          Colors.white,

          foregroundColor:
          Color(
            0xFF07347F,
          ),
        ),

        elevatedButtonTheme:
        ElevatedButtonThemeData(

          style:
          ElevatedButton.styleFrom(

            backgroundColor:
            const Color(
              0xFF1257C7,
            ),

            foregroundColor:
            Colors.white,

            shape:
            RoundedRectangleBorder(

              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
          ),
        ),
      ),

      initialRoute:
      '/',

      routes: {

        '/':
            (context) =>
        const SplashScreen(),

        '/depart_login_selection':
            (context) =>
        const DepartLoginSelection(),

        '/boat_selection':
            (context) =>
        const BoatSelectionScreen(),

        '/boat_owner_login':
            (context) =>
        const BoatOwnerLoginScreen(),

        '/boat_owner_details':
            (context) =>
        const BoatOwnerDetailsScreen(),

        '/dashboard':
            (context) =>
        const DashboardScreen(),

        // ⭐ OFFICER ROUTES
        '/depart_login_selection':
            (context) =>
        const DepartLoginSelection(),

        '/depart_login_selection':
            (context) =>
        const DepartLoginSelection(),
      },
    );
  }
}


// ============================================================================
// SPLASH SCREEN
// ============================================================================

class SplashScreen
    extends StatefulWidget {

  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}


class _SplashScreenState
    extends State<SplashScreen>
    with WidgetsBindingObserver {

  bool _permissionProcessStarted = false;

  // ---------------------------------------------------------------------------
  // Loading state shown in the UI
  // ---------------------------------------------------------------------------
  String _statusText = 'Checking permissions...';
  bool _isDone = false;

  // Flag to prevent double navigation
  bool _navigated = false;


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initializeSplash();
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🔄 Lifecycle: $state');
    // No longer blocking on lifecycle — just logging.
  }


  // ---------------------------------------------------------------------------
  // Safe status update helper
  // ---------------------------------------------------------------------------
  void _setStatus(String text) {
    if (!mounted) return;
    setState(() {
      _statusText = text;
    });
  }


  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================

  Future<void> _initializeSplash() async {

    await Future.delayed(
      const Duration(milliseconds: 600),
    );

    if (!mounted) return;

    try {
      _setStatus('Preparing database...');
      await _migrateSyncSchema();
    } catch (e) {
      debugPrint(
        '⚠️ Splash migration error: $e',
      );
    }

    await _requestPermissionsOneByOne();

    if (!mounted) return;

    _setStatus('Loading...');
    await _checkLoginAndBoatStatus();
  }


  // ==========================================================================
  // ONE-BY-ONE PERMISSION FLOW
  // ==========================================================================

  Future<void> _requestPermissionsOneByOne() async {

    if (_permissionProcessStarted) {
      return;
    }

    _permissionProcessStarted = true;

    if (!Platform.isAndroid) {
      return;
    }

    try {

      debugPrint(
        '========================================',
      );

      debugPrint(
        '🔐 STARTING PERMISSION FLOW',
      );

      debugPrint(
        '========================================',
      );

      // 1. Notification
      _setStatus('Requesting notification permission...');
      await _requestNotificationPermission();

      // 2. Foreground location
      _setStatus('Requesting location permission...');
      await _requestLocationPermission();

      // 3. Background location
      _setStatus('Requesting background location permission...');
      await _requestLocationAlwaysPermission();

      // 4. Battery optimization — fires intent and moves on
      //    (does NOT wait for the user to return)
      _setStatus('Checking battery optimization...');
      await _requestBatteryOptimization();

      // 5. Final status
      _setStatus('Verifying permissions...');
      await _printFinalPermissionStatus();

    } catch (e, stackTrace) {

      debugPrint(
        '❌ Permission flow error: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }


  // ==========================================================================
  // 1. NOTIFICATION PERMISSION
  // ==========================================================================

  Future<void>
  _requestNotificationPermission() async {

    try {

      PermissionStatus status =
      await Permission.notification.status;

      debugPrint(
        '🔔 Notification current status: '
            '$status',
      );

      if (status.isGranted) {
        debugPrint(
          '✅ Notification permission already granted.',
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        debugPrint(
          '⚠️ Notification permission permanently denied.',
        );
        return;
      }

      debugPrint(
        '🔔 Requesting notification permission...',
      );

      status =
      await Permission.notification.request();

      debugPrint(
        '🔔 Notification result: $status',
      );

    } catch (e) {

      debugPrint(
        '❌ Notification permission error: $e',
      );
    }
  }


  // ==========================================================================
  // 2. LOCATION PERMISSION
  // ==========================================================================

  Future<void>
  _requestLocationPermission() async {

    try {

      PermissionStatus status =
      await Permission.location.status;

      debugPrint(
        '📍 Location current status: '
            '$status',
      );

      if (status.isGranted) {
        debugPrint(
          '✅ Location permission already granted.',
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        debugPrint(
          '⚠️ Location permission permanently denied.',
        );
        return;
      }

      debugPrint(
        '📍 Requesting location permission...',
      );

      status =
      await Permission.location.request();

      debugPrint(
        '📍 Location result: $status',
      );

    } catch (e) {

      debugPrint(
        '❌ Location permission error: $e',
      );
    }
  }


  // ==========================================================================
  // 3. LOCATION ALWAYS
  // ==========================================================================

  Future<void>
  _requestLocationAlwaysPermission() async {

    try {

      final locationStatus =
      await Permission.location.status;

      if (!locationStatus.isGranted) {

        debugPrint(
          '⚠️ Foreground location not granted.',
        );

        debugPrint(
          '⚠️ Cannot request Allow all the time yet.',
        );

        return;
      }

      PermissionStatus status =
      await Permission.locationAlways.status;

      debugPrint(
        '📍 Allow all the time current status: '
            '$status',
      );

      if (status.isGranted) {
        debugPrint(
          '✅ Allow all the time already granted.',
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        debugPrint(
          '⚠️ Allow all the time permanently denied.',
        );
        return;
      }

      debugPrint(
        '📍 Opening Android Location settings '
            'for Allow all the time...',
      );

      status =
      await Permission.locationAlways.request();

      debugPrint(
        '📍 Allow all the time result: $status',
      );

    } catch (e) {

      debugPrint(
        '❌ Location Always error: $e',
      );
    }
  }


  // ==========================================================================
  // 4. BATTERY OPTIMIZATION
  //
  // IMPORTANT: This method no longer waits for the user to return from
  // Android Settings. It fires the intent (or skips it if already granted)
  // and returns immediately so the splash can continue to the next screen.
  // ==========================================================================

  Future<void>
  _requestBatteryOptimization() async {

    const String packageName =
        'com.fishing_voyage_manag_sys';

    try {

      PermissionStatus status =
      await Permission
          .ignoreBatteryOptimizations
          .status;

      debugPrint(
        '🔋 Battery optimization current status: '
            '$status',
      );

      // Already allowed — nothing to do.
      if (status.isGranted) {
        debugPrint(
          '✅ Battery optimization already allowed.',
        );
        return;
      }

      // Permanently denied — can't do anything.
      if (status.isPermanentlyDenied) {
        debugPrint(
          '⚠️ Battery optimization permanently denied '
              '— skipping.',
        );
        return;
      }

      // Fire-and-forget: launch the Android Settings intent,
      // but DO NOT wait for the user to come back.
      debugPrint(
        '🔋 Opening Android battery optimization settings '
            '(fire-and-forget)...',
      );

      bool opened = false;

      // Attempt 1: Direct app-targeted intent
      opened = await _tryLaunchBatteryIntent(
        AndroidIntent(
          action:
          'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
          data: 'package:$packageName',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        ),
        label: 'REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      );

      // Attempt 2: Full battery optimization list
      if (!opened) {
        opened = await _tryLaunchBatteryIntent(
          AndroidIntent(
            action:
            'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
            flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
          ),
          label: 'IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
      }

      // Attempt 3: App info screen (always exists)
      if (!opened) {
        opened = await _tryLaunchBatteryIntent(
          AndroidIntent(
            action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
            data: 'package:$packageName',
            flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
          ),
          label: 'APPLICATION_DETAILS_SETTINGS',
        );
      }

      debugPrint(
        '🔋 Battery optimization intent fired: $opened '
            '(not waiting for return)',
      );

    } catch (e, st) {

      debugPrint(
        '❌ Battery optimization error: $e\n$st',
      );
    }
  }


  /// Attempts to launch an Android settings intent WITHOUT waiting
  /// for the user to return. Returns true if it launched successfully.
  Future<bool> _tryLaunchBatteryIntent(
      AndroidIntent intent, {
        required String label,
      }) async {
    try {
      debugPrint('🔋 Launching intent: $label');
      await intent.launch();
      debugPrint('✅ Intent launched: $label');

      // Small delay so the intent actually starts before we move on.
      await Future.delayed(const Duration(milliseconds: 300));

      return true;
    } catch (e) {
      debugPrint('⚠️ Intent failed ($label): $e');
      return false;
    }
  }


  // ==========================================================================
  // FINAL PERMISSION STATUS
  // ==========================================================================

  Future<void>
  _printFinalPermissionStatus() async {

    try {

      final notification =
      await Permission.notification.status;

      final location =
      await Permission.location.status;

      final always =
      await Permission.locationAlways.status;

      final battery =
      await Permission
          .ignoreBatteryOptimizations
          .status;

      debugPrint(
        '========================================',
      );

      debugPrint(
        '🔐 FINAL PERMISSION STATUS',
      );

      debugPrint(
        '🔔 Notification : $notification',
      );

      debugPrint(
        '📍 Location     : $location',
      );

      debugPrint(
        '📍 Always       : $always',
      );

      debugPrint(
        '🔋 Battery      : $battery',
      );

      debugPrint(
        '========================================',
      );

    } catch (e) {

      debugPrint(
        '⚠️ Could not read final permission status: $e',
      );
    }
  }


  // ==========================================================================
  // LOGIN / BOAT STATUS
  //
  // ⭐ Order of checks:
  //   1. Officer logged in (DB-backed officer_session) → OfficerMainScreen
  //   2. Boat owner logged in + boats selected        → Dashboard
  //   3. Boat owner logged in, no boats               → BoatSelection
  //   4. Nobody logged in                             → DepartLoginSelection
  // ==========================================================================

  Future<void>
  _checkLoginAndBoatStatus() async {

    if (!mounted) return;

    try {

      final db = DatabaseHelper();

      // ------------------------------------------------------------------
      // ⭐ STEP 1: CHECK IF AN OFFICER IS ALREADY LOGGED IN (DB-backed)
      // ------------------------------------------------------------------
      final bool officerLoggedIn =
      await db.isOfficerLoggedIn();

      if (!mounted) return;

      if (officerLoggedIn) {
        debugPrint(
          '👮 Officer already logged in (DB) '
              '— redirecting to OfficerMainScreen',
        );
        _navigateToOfficerMain();
        return;
      }

      // ------------------------------------------------------------------
      // STEP 2: CHECK BOAT OWNER LOGIN (existing logic)
      // ------------------------------------------------------------------
      final bool isLoggedIn =
      await db.isUserLoggedIn();

      if (!mounted) return;

      if (!isLoggedIn) {
        _navigateTo('/depart_login_selection');
        return;
      }

      final bool hasSelectedBoats =
      await db.hasSelectedBoats();

      if (!mounted) return;

      if (hasSelectedBoats) {
        _navigateTo('/dashboard');
      } else {
        _markDone();
        _navigated = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const BoatSelectionScreen(
              isSelectionMode: true,
            ),
          ),
        );
      }

    } catch (e) {

      debugPrint(
        '❌ Error checking login status: $e',
      );

      if (mounted) {
        _navigateTo('/depart_login_selection');
      }
    }
  }


  // ------------------------------------------------------------------
  // ⭐ NAVIGATE DIRECTLY TO OFFICER MAIN SCREEN
  // ------------------------------------------------------------------
  void _navigateToOfficerMain() {
    if (!mounted || _navigated) return;
    _navigated = true;
    _markDone();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const OfficerDashboardScreen(),
      ),
    );
  }


  void _navigateTo(String route) {
    if (!mounted || _navigated) return;
    _navigated = true;
    _markDone();
    Navigator.pushReplacementNamed(context, route);
  }


  void _markDone() {
    if (!mounted) return;
    setState(() {
      _isDone = true;
      _statusText = 'Ready';
    });
  }


  // ==========================================================================
  // SPLASH UI
  // ==========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {

    return Scaffold(
      body:
      Container(

        width:
        double.infinity,

        height:
        double.infinity,

        decoration:
        const BoxDecoration(

          gradient:
          LinearGradient(

            begin:
            Alignment.topCenter,

            end:
            Alignment.bottomCenter,

            colors: [

              Color(
                0xFF1257C7,
              ),

              Color(
                0xFF07347F,
              ),
            ],
          ),
        ),

        child:
        Column(

          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            Container(

              padding:
              const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),

              decoration:
              BoxDecoration(

                color:
                Colors.white,

                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),

              child:
              const Text(

                'UTLCRAFT',

                style:
                TextStyle(

                  color:
                  Color(
                    0xFF07347F,
                  ),

                  fontSize:
                  32,

                  fontWeight:
                  FontWeight.bold,

                  letterSpacing:
                  2,
                ),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(

              'Fisheries Department',

              style:
              TextStyle(

                color:
                Colors.white,

                fontSize:
                14,

                fontWeight:
                FontWeight.w500,
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            // Show spinner while loading, show checkmark when done
            _isDone
                ? const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 36,
            )
                : const CircularProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // Status text updates as each step completes
            Text(

              _statusText,

              style:
              TextStyle(

                color:
                Colors.white.withOpacity(
                  0.8,
                ),

                fontSize:
                12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}