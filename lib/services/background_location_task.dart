import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/event_location_service.dart';
import 'package:fishing_voyage_manag_sys/services/sync_service.dart';

class BackgroundLocationTask extends TaskHandler {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _busy = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Warm up DB so first capture isn't slow / doesn't fail.
    await _dbHelper.database;
    debugPrint('✅ BackgroundLocationTask started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_busy) {
      debugPrint('⏭️ previous tick running – skip');
      return;
    }
    _busy = true;
    unawaited(
      _captureAndStoreLocation().catchError((Object e, StackTrace st) {
        debugPrint('❌ [BG] $e\n$st');
      }).whenComplete(() => _busy = false),
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('🛑 BackgroundLocationTask destroyed');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  // ---------------------------------------------------------------------------
  // Core capture pipeline
  // ---------------------------------------------------------------------------
  Future<void> _captureAndStoreLocation() async {
    final now = DateTime.now();
    debugPrint('🛰️ [BG] tick @ $now');

    try {
      // --- 1. Active voyage check -----------------------------------------
      final prefs = await SharedPreferences.getInstance();
      final voyageId = prefs.getInt('active_voyage_id');
      final voyageNo = prefs.getString('active_voyage_no') ?? '';

      if (voyageId == null) {
        debugPrint('⚠️ [BG] no active voyage – skip');
        return;
      }
      if (voyageNo.isEmpty || voyageNo == 'UNKNOWN') {
        debugPrint('⚠️ [BG] voyageNo empty – skip (would be rejected by server)');
        return;
      }

      // --- 2. Location service + permission -------------------------------
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ [BG] location service disabled');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ [BG] permission denied ($permission)');
        return;
      }

      // --- 3. Get position with fallback ----------------------------------
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (e) {
        debugPrint('⚠️ [BG] getCurrentPosition failed: $e');
      }

      position ??= await _safeLastKnown();

      if (position == null) {
        debugPrint('❌ [BG] no position available');
        return;
      }

      // --- 4. Accuracy filter ---------------------------------------------
      if (position.accuracy > 50) {
        debugPrint('📍 [BG] poor accuracy '
            '(${position.accuracy.toStringAsFixed(1)}m) – skip');
        return;
      }

      // --- 5. Distance filter ---------------------------------------------
      final last = await _dbHelper.getLastLocationPoint(voyageId);
      if (last != null) {
        final d = Geolocator.distanceBetween(
          (last['latitude'] as num).toDouble(),
          (last['longitude'] as num).toDouble(),
          position.latitude,
          position.longitude,
        );
        if (d < 15.0) {
          debugPrint('📍 [BG] small movement '
              '(${d.toStringAsFixed(1)}m) – skip');
          return;
        }
      }

      // --- 6. Persist locally (ALWAYS, even offline) ----------------------
      final ts = DateTime.now().toUtc().toIso8601String();
      try {
        await _dbHelper.insertLocation(
          voyageId,
          position.latitude,
          position.longitude,
          voyageNo: voyageNo,
          timestamp: ts,
        );
        debugPrint('💾 [BG] stored @ ${position.latitude},'
            '${position.longitude} acc=${position.accuracy.toStringAsFixed(0)}');
      } catch (e, st) {
        debugPrint('❌ [BG] insertLocation failed: $e\n$st');
        return; // nothing to sync
      }

      // --- 7. Cache for SOS / citing fallback -----------------------------
      try {
        await EventLocationService.cacheLastKnown(
          lat: position.latitude,
          lng: position.longitude,
          accuracy: position.accuracy,
        );
      } catch (e) {
        debugPrint('⚠️ [BG] cacheLastKnown failed (non-fatal): $e');
      }

      // --- 8. Opportunistic sync ------------------------------------------
      final online = await _hasRealConnectivity();
      if (!online) {
        debugPrint('📴 [BG] offline – will sync later');
        return;
      }

      try {
        await SyncService().syncAll();
        debugPrint('✅ [BG] syncAll complete');
      } catch (e, st) {
        debugPrint('⚠️ [BG] syncAll error (queued for next tick): $e\n$st');
      }
    } catch (e, st) {
      debugPrint('❌ [BG] fatal: $e\n$st');
    }
  }

  Future<Position?> _safeLastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Returns true only if a usable network interface exists.
  Future<bool> _hasRealConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      debugPrint('⚠️ [BG] connectivity check failed: $e');
      return false;
    }
  }
}