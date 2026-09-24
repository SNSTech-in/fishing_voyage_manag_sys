// lib/services/event_location_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';

/// ─────────────────────────────────────────────────────────────
///  Unified location service for event records (SOS, Citings, etc.)
///
///  Works ONLINE and OFFLINE. Falls back through 4 layers so that
///  the coordinates are NEVER (0.0, 0.0).
///
///  Fallback chain:
///    1. Fresh GPS fix          (highest accuracy, up to 30 s)
///    2. OS last-known position (a few minutes stale at worst)
///    3. SharedPreferences cache (updated continuously by tracking)
///    4. Latest point from the voyage's local tracking DB
///
///  If ALL fail, returns `null` — the caller MUST show an error
///  and NOT save a record with (0,0).
/// ─────────────────────────────────────────────────────────────
class EventLocationService {
  static const String _prefsLatKey = 'last_known_lat';
  static const String _prefsLngKey = 'last_known_lng';
  static const String _prefsAccKey = 'last_known_accuracy';
  static const String _prefsTimeKey = 'last_known_time';

  // ═══════════════════════════════════════════════════════════
  //  PUBLIC API — ONE METHOD FOR BOTH SOS AND CITINGS
  // ═══════════════════════════════════════════════════════════

  /// Acquire a valid location for an event record.
  ///
  /// - [voyageId]   : Used to fetch the last DB tracking point as fallback.
  /// - [tag]        : Log prefix, e.g. 'SOS' or 'Citing'.
  /// - [maxWait]    : How long to wait for a fresh fix (default 30 s).
  static Future<EventLocation?> acquire({
    required int voyageId,
    String tag = 'Event',
    Duration maxWait = const Duration(seconds: 3),
  }) async {
    debugPrint('📍 [$tag] Starting location acquisition...');

    // ── 0. Permissions
    if (!await _ensurePermission(tag)) {
      debugPrint('❌ [$tag] Permission denied');
      return _fallbackFromDb(voyageId, tag);
    }

    // ── 1. Fresh GPS fix
    final fresh = await _tryFreshFix(maxWait, tag);
    if (fresh != null) {
      debugPrint(
        '✅ [$tag] Fresh fix: ${fresh.lat}, ${fresh.lng} '
        '(±${fresh.accuracy.toStringAsFixed(1)}m)',
      );
      await cacheLastKnown(
        lat: fresh.lat,
        lng: fresh.lng,
        accuracy: fresh.accuracy,
      );
      return fresh;
    }

    // ── 2. OS last-known
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && _isValid(last.latitude, last.longitude)) {
        final loc = EventLocation(
          lat: last.latitude,
          lng: last.longitude,
          accuracy: last.accuracy,
          source: 'os_last_known',
        );
        debugPrint('✅ [$tag] OS last-known: ${loc.lat}, ${loc.lng}');
        await cacheLastKnown(
          lat: loc.lat,
          lng: loc.lng,
          accuracy: loc.accuracy,
        );
        return loc;
      }
    } catch (e) {
      debugPrint('⚠️ [$tag] getLastKnownPosition failed: $e');
    }

    // ── 3. SharedPreferences cache
    final cached = await _readCached();
    if (cached != null) {
      debugPrint(
        '✅ [$tag] Cached: ${cached.lat}, ${cached.lng} '
        '(age: ${DateTime.now().difference(cached.time).inMinutes} min)',
      );
      return cached;
    }

    // ── 4. Last DB tracking point for this voyage
    return _fallbackFromDb(voyageId, tag);
  }

  /// Write a location to the shared cache.
  /// Call this from your tracking service on every new GPS point.
  static Future<void> cacheLastKnown({
    required double lat,
    required double lng,
    double accuracy = 0.0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsLatKey, lat);
      await prefs.setDouble(_prefsLngKey, lng);
      await prefs.setDouble(_prefsAccKey, accuracy);
      await prefs.setString(
        _prefsTimeKey,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════
  //  INTERNALS
  // ═══════════════════════════════════════════════════════════

  static Future<bool> _ensurePermission(String tag) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('⚠️ [$tag] Location services disabled');
        return false;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ [$tag] permission check failed: $e');
      return false;
    }
  }

  static Future<EventLocation?> _tryFreshFix(
    Duration maxWait,
    String tag,
  ) async {
    final completer = Completer<EventLocation?>();
    StreamSubscription<Position>? sub;

    try {
      const settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );

      sub = Geolocator.getPositionStream(locationSettings: settings)
          .listen((pos) {
        if (_isValid(pos.latitude, pos.longitude) &&
            !completer.isCompleted) {
          completer.complete(EventLocation(
            lat: pos.latitude,
            lng: pos.longitude,
            accuracy: pos.accuracy,
            source: 'gps_fresh',
          ));
        }
      }, onError: (e) {
        debugPrint('⚠️ [$tag] stream error: $e');
        if (!completer.isCompleted) completer.complete(null);
      });

      return await completer.future.timeout(
        maxWait,
        onTimeout: () {
          debugPrint(
            '⏱️ [$tag] Fresh fix timed out after ${maxWait.inSeconds}s',
          );
          return null;
        },
      );
    } catch (e) {
      debugPrint('⚠️ [$tag] fresh fix exception: $e');
      return null;
    } finally {
      await sub?.cancel();
    }
  }

  /// Last resort — use the most recent point from the voyage's local DB.
  static Future<EventLocation?> _fallbackFromDb(
    int voyageId,
    String tag,
  ) async {
    try {
      final points =
          await DatabaseHelper().getLocationsForVoyage(voyageId);
      if (points.isEmpty) {
        debugPrint('❌ [$tag] No DB fallback available');
        return null;
      }
      final latest = points.last;
      final lat = (latest['latitude'] as num?)?.toDouble();
      final lng = (latest['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null || !_isValid(lat, lng)) {
        debugPrint('❌ [$tag] DB fallback invalid: $lat, $lng');
        return null;
      }
      debugPrint('✅ [$tag] DB fallback: $lat, $lng');
      return EventLocation(
        lat: lat,
        lng: lng,
        accuracy: 0.0,
        source: 'db_fallback',
        time: DateTime.tryParse(
              latest['timestamp']?.toString() ??
                  latest['ping_date_time']?.toString() ??
                  '',
            ) ??
            DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [$tag] DB fallback failed: $e');
      return null;
    }
  }

  static bool _isValid(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    return true;
  }

  static Future<EventLocation?> _readCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_prefsLatKey);
      final lng = prefs.getDouble(_prefsLngKey);
      if (lat == null || lng == null) return null;
      if (!_isValid(lat, lng)) return null;

      final acc = prefs.getDouble(_prefsAccKey) ?? 0.0;
      final timeStr = prefs.getString(_prefsTimeKey);
      final time = timeStr != null
          ? DateTime.tryParse(timeStr) ?? DateTime.now()
          : DateTime.now();

      return EventLocation(
        lat: lat,
        lng: lng,
        accuracy: acc,
        source: 'prefs_cache',
        time: time,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The acquired location object.
class EventLocation {
  final double lat;
  final double lng;
  final double accuracy;
  final String source;
  final DateTime time;

  EventLocation({
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.source,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  @override
  String toString() =>
      'EventLocation($lat, $lng, ±${accuracy.toStringAsFixed(1)}m, '
      'src=$source)';
}
