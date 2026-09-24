// lib/services/background_sync_task.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/sync_service.dart';

/// This handler runs in a SEPARATE isolate (headless Dart VM).
/// It wakes up on schedule, runs sync, and sleeps again.
///
/// IMPORTANT: Do not rely on any global state from main.dart here.
/// Always re-create dependencies you need (SyncService, DB, etc.).
@pragma('vm:entry-point')
class BackgroundSyncTaskHandler extends TaskHandler {
  Timer? _periodicTimer;
  bool _isSyncing = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('🟢 [BG Task] Service started at $timestamp (starter=$starter)');

    // Run an initial sync when service starts
    await _runSync();

    // Then schedule periodic sync every 15 minutes
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _runSync(),
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Fired by FlutterForegroundTask's `repeat` option (if configured).
    // Not strictly needed since we use a Timer, but keep it safe.
    _runSync();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('🔴 [BG Task] Service stopped at $timestamp');
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  @override
  void onNotificationPressed() {
    // When user taps the persistent notification, bring app to foreground.
    FlutterForegroundTask.launchApp();
  }

  // NOTE: `onReceiveData` is intentionally omitted — its signature changed
  // between flutter_foreground_task versions. We don't need it for sync.

  Future<void> _runSync() async {
    if (_isSyncing) {
      debugPrint('⏳ [BG Task] Sync already running, skipping tick.');
      return;
    }
    _isSyncing = true;
    try {
      debugPrint('🔄 [BG Task] Running background sync...');
      await SyncService.instance.syncAll();
      debugPrint('✅ [BG Task] Sync finished successfully.');
    } catch (e, st) {
      debugPrint('❌ [BG Task] Sync error: $e\n$st');
    } finally {
      _isSyncing = false;
    }
  }
}
