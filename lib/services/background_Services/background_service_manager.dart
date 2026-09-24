// lib/services/background_service_manager.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'background_sync_task.dart';

class BackgroundServiceManager {
  /// Call this ONCE in main() before runApp().
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'fishing_voyage_bg_sync',
        channelName: 'Background Sync',
        channelDescription:
            'Keeps voyage data synced with the server in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Repeat every 15 minutes even when app is killed
        eventAction: ForegroundTaskEventAction.repeat(15 * 60 * 1000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Request notification permission (Android 13+) — call from UI.
  static Future<bool> requestPermissions() async {
    final notif = await FlutterForegroundTask.checkNotificationPermission();
    if (notif != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    return true;
  }

  /// Start (or restart) the background service.
  static Future<bool> start() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      debugPrint('🟢 [BG Service] Already running.');
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Fishing Voyage Sync',
      notificationText: 'Keeping your data synced in the background...',
      notificationIcon: null, // uses default app icon
      callback: startBackgroundSyncCallback,
    );

    debugPrint('🟢 [BG Service] Started. Result=$result');
    return result != null;
  }

  /// Stop the background service.
  static Future<bool> stop() async {
    final result = await FlutterForegroundTask.stopService();
    debugPrint('🔴 [BG Service] Stopped. Result=$result');
    return result != null;
  }

  /// Check status.
  static Future<bool> isRunning() => FlutterForegroundTask.isRunningService;
}

/// Must be a top-level function (no class wrapper) for the isolate to find it.
@pragma('vm:entry-point')
void startBackgroundSyncCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundSyncTaskHandler());
}
