import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/database_helper.dart';
import 'sync_service.dart';

// =========================================================================
// 1. INIT – call this from main() BEFORE runApp()
// =========================================================================
Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  // ---- Notification channel (must exist before startForeground) ----
  const channel = AndroidNotificationChannel(
    'fishing_tracker',
    'Fishing Tracker',
    description: 'Tracks voyage location in background',
    importance: Importance.low,
  );

  final notif = FlutterLocalNotificationsPlugin();
  await notif
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // ---- Configure the service ----
  // NOTE: autoStart is FALSE here. We start explicitly below so there is
  // only ONE call to startForegroundService(). Two start paths = race.
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'fishing_tracker',
      initialNotificationTitle: 'Fishing Tracker',
      initialNotificationContent: 'Recording voyage location...',
      foregroundServiceNotificationId: 101,
      foregroundServiceTypes: [AndroidForegroundType.location],
      autoStartOnBoot: true, // plugin handles boot-start itself
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onServiceStart,
      onBackground: onIosBackground,
    ),
  );

  // ---- Start only if not already running ----
  final isRunning = await service.isRunning();
  if (!isRunning) {
    await service.startService();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

// =========================================================================
// 2. SERVICE ENTRY POINT – runs in a separate isolate
// =========================================================================
@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  // Plugin registration for this isolate.
  DartPluginRegistrant.ensureInitialized();

  // ---------------------------------------------------------------------
  // CRITICAL: promote to foreground IMMEDIATELY, before any await / DB /
  // geolocator work. Android gives ~5s after startForegroundService().
  // ---------------------------------------------------------------------
  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  // ---- Command handlers ----
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((_) {
    service.stopSelf();
  });

  // ---------------------------------------------------------------------
  // Now safe to do slow work.
  // ---------------------------------------------------------------------
  final dbHelper = DatabaseHelper();
  final syncService = SyncService();

  double? lastLat;
  double? lastLng;

  final settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  // ---- Location stream (guarded: getPositionStream can throw) ----
  StreamSubscription<Position>? sub;
  try {
    sub = Geolocator.getPositionStream(locationSettings: settings).listen(
          (position) async {
        try {
          if (position.accuracy > 50) return;

          final voyage = await dbHelper.getActiveVoyage();
          if (voyage == null) return;

          if (lastLat != null && lastLng != null) {
            final d = Geolocator.distanceBetween(
              lastLat!,
              lastLng!,
              position.latitude,
              position.longitude,
            );
            if (d < 10) return;
          }
          lastLat = position.latitude;
          lastLng = position.longitude;

          await dbHelper.insertLocationPoint({
            'voyage_id': voyage['id'],
            'intimation_id': voyage['intimation_id'],
            'voyage_no': voyage['voyage_no'],
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
            'ping_date_time': DateTime.now().toIso8601String(),
            'synced': 0,
          });

          // Update notification (service is already foreground)
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Fishing Tracker',
              content:
              'Recording ${voyage['voyage_no']} – ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
            );
          }

          // Sync immediately if online
          final conn = await Connectivity().checkConnectivity();
          if (conn != ConnectivityResult.none) {
            await syncService.syncAll();
          }
        } catch (e) {
          print('⚠️ location handler: $e');
        }
      },
      onError: (e) => print('⚠️ position stream: $e'),
      cancelOnError: false,
    );
  } catch (e) {
    print('⚠️ failed to start location stream: $e');
  }

  // ---- Periodic sync every 5 minutes ----
  final syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn != ConnectivityResult.none) {
        print('⏰ [bg] 5-min sync');
        await syncService.syncAll();
      }
    } catch (e) {
      print('⚠️ periodic sync: $e');
    }
  });

  // ---- Stop handler ----
  service.on('stop').listen((_) async {
    syncTimer.cancel();
    await sub?.cancel();
    service.stopSelf();
  });
}