import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  factory SyncService() => instance;
  SyncService._internal();

  static final ValueNotifier<bool> needsRelogin = ValueNotifier(false);

  final DatabaseHelper _db = DatabaseHelper();
  final ApiService _api = ApiService();

  // ---- Sync lock with watchdog ------------------------------------------------
  DateTime? _syncStartedAt;
  static const _syncTimeout = Duration(minutes: 2);

  bool get _isSyncing {
    final started = _syncStartedAt;
    if (started == null) return false;
    if (DateTime.now().difference(started) > _syncTimeout) {
      debugPrint('⚠️ [syncAll] previous sync timed out – resetting lock');
      _syncStartedAt = null;
      return false;
    }
    return true;
  }

  // ---- Token ------------------------------------------------------------------
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ??
          prefs.getString('token') ??
          prefs.getString('auth_token') ??
          prefs.getString('user_token');
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('⚠️ [Token] prefs failed: $e');
    }

    try {
      final session = await _db.getUserSession();
      final token = session?['access_token']?.toString();
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('⚠️ [Token] DB failed: $e');
    }
    return null;
  }

  /// Read the long-lived refresh token from storage.
  Future<String?> _getRefreshToken() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getString('refresh_token');
    } catch (_) {
      return null;
    }
  }

  /// Attempt to refresh the access token.
  /// Returns the new token on success, null on failure.
  Future<String?> _tryRefresh() async {
    final refresh = await _getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      debugPrint('⚠️ [refresh] no refresh_token stored — cannot refresh');
      needsRelogin.value = true;
      return null;
    }
    final newToken = await _api.refreshAccessToken(refresh);
    if (newToken == null) {
      debugPrint('⚠️ [refresh] refresh failed — user must re-login');
      needsRelogin.value = true;
      return null;
    }
    return newToken;
  }

  // ---- Public API -------------------------------------------------------------
  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint('⚠️ [syncAll] already running – skip');
      return;
    }
    _syncStartedAt = DateTime.now();

    try {
      final token = await _getTokenWithRetry();
      if (token == null) {
        debugPrint('⚠️ [syncAll] no token – abort');
        return;
      }

      await _runStep('syncLocations', () => syncLocations(token));
      await _runStep('syncSos',       () => syncSos(token));
      await _runStep('syncCiting',    () => syncCiting(token));
    } catch (e, st) {
      debugPrint('❌ [syncAll] fatal: $e\n$st');
    } finally {
      _syncStartedAt = null;
    }
  }

  Future<void> _runStep(String name, Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e, st) {
      debugPrint('❌ [syncAll] $name threw: $e\n$st');
    }
  }

  Future<String?> _getTokenWithRetry() async {
    for (var i = 0; i < 3; i++) {
      final t = await _getToken();
      if (t != null && t.isNotEmpty) return t;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  // ---- Device ID ---------------------------------------------------------------
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('device_imei');
    if (cached != null && cached.isNotEmpty) return cached;

    String id = 'IMEI-UNKNOWN';
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        id = 'IMEI-${a.id}';
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        id = 'IMEI-${i.identifierForVendor ?? 'IOS'}';
      }
    } catch (_) {}

    await prefs.setString('device_imei', id);
    return id;
  }

  // ---- Locations --------------------------------------------------------------
  Future<void> syncLocations(String token) async {
    final pending = await _db.getUnsyncedLocations();
    if (pending.isEmpty) {
      debugPrint('✅ [syncLocations] nothing to sync');
      return;
    }

    debugPrint('🔄 [syncLocations] ${pending.length} pending');

    final deviceId = await _getDeviceId();
    String currentToken = token;
    int ok = 0, fail = 0, dead = 0;
    bool refreshed = false;   // only try refreshing ONCE per sync run

    for (final loc in pending) {
      final id = loc['id'] as int;
      final voyageNo =
          (loc['voyage_no'] ?? loc['intimation_id'])?.toString().trim();
      if (voyageNo == null || voyageNo.isEmpty || voyageNo == 'UNKNOWN') {
        await _db.markLocationPermanentlyFailed(id);
        dead++;
        continue;
      }
      final ts = (loc['timestamp'] ?? loc['ping_date_time'])?.toString() ??
          DateTime.now().toUtc().toIso8601String();

      try {
        final r = await _api.sendPing(
          voyageNo: voyageNo,
          intimationId: loc['intimation_id'] as int?,
          latitude: (loc['latitude'] as num).toDouble(),
          longitude: (loc['longitude'] as num).toDouble(),
          timestamp: ts,
          token: currentToken,
          deviceId: deviceId,
          pingVia: 'MOBILE_APP',
          versionNo: '1.4.2',
        );

        // ─────────────────────────────────────────────────────────
        // 401/403 → try refresh ONCE, then retry the same ping
        // ─────────────────────────────────────────────────────────
        if (r['http_status'] == 401 || r['http_status'] == 403) {
          if (refreshed) {
            debugPrint('🔒 [syncLocations] auth failed again after refresh — abort');
            break;
          }
          debugPrint('🔒 [syncLocations] 401 — attempting token refresh');
          final newToken = await _tryRefresh();
          if (newToken == null) {
            debugPrint('🔒 [syncLocations] refresh failed — abort, will retry later');
            break;
          }
          currentToken = newToken;
          refreshed = true;
          debugPrint('✅ [syncLocations] refreshed — retrying same row');

          // Retry this same row once with the new token
          final r2 = await _api.sendPing(
            voyageNo: voyageNo,
            intimationId: loc['intimation_id'] as int?,
            latitude: (loc['latitude'] as num).toDouble(),
            longitude: (loc['longitude'] as num).toDouble(),
            timestamp: ts,
            token: currentToken,
            deviceId: deviceId,
            pingVia: 'MOBILE_APP',
            versionNo: '1.4.2',
          );
          if (r2['success'] == true) {
            await _db.markLocationSynced(id);
            ok++;
          } else if (r2['permanent'] == true) {
            await _db.markLocationPermanentlyFailed(id);
            dead++;
          } else {
            fail++;
          }
          continue;
        }

        // ─────────────────────────────────────────────────────────
        // Normal outcomes
        // ─────────────────────────────────────────────────────────
        if (r['success'] == true) {
          await _db.markLocationSynced(id);
          ok++;
        } else if (r['permanent'] == true) {
          await _db.markLocationPermanentlyFailed(id);
          dead++;
        } else {
          fail++;
        }
      } catch (e) {
        fail++;
        debugPrint('❌ loc $id: $e');
      }

      if (fail > 0) await Future.delayed(const Duration(milliseconds: 150));
    }

    debugPrint('🏁 [syncLocations] ok=$ok fail=$fail dead=$dead');
  }

  // ---- SOS --------------------------------------------------------------------
  Future<void> syncSos(String token) async {
    final unsynced = await _db.getUnsyncedSos();
    if (unsynced.isEmpty) return;

    debugPrint('🔄 [syncSos] ${unsynced.length} pending');
    String currentToken = token;
    int ok = 0, fail = 0, dead = 0;
    bool refreshed = false;

    for (final sos in unsynced) {
      final id = sos['id'] as int;
      final ts = (sos['sos_datetime'] ?? sos['timestamp'])?.toString() ??
          DateTime.now().toUtc().toIso8601String();
      final msg = (sos['description'] ?? sos['message'] ?? 'SOS Alert').toString();

      try {
        final r = await _api.sendSos(
          intimationId: sos['intimation_id'] ?? 0,
          latitude: (sos['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (sos['longitude'] as num?)?.toDouble() ?? 0.0,
          timestamp: ts,
          message: msg,
          token: currentToken,
          sosType: (sos['sos_type'] ?? 'OTHER').toString(),
          locationSource: (sos['location_source'] ?? 'GPS').toString(),
          severity: (sos['severity'] ?? 'HIGH').toString(),
        );

        if (r['http_status'] == 401 || r['http_status'] == 403) {
          if (refreshed) {
            debugPrint('🔒 [syncSos] auth failed again after refresh — abort');
            break;
          }
          debugPrint('🔒 [syncSos] 401 — attempting token refresh');
          final newToken = await _tryRefresh();
          if (newToken == null) {
            debugPrint('🔒 [syncSos] refresh failed — abort');
            break;
          }
          currentToken = newToken;
          refreshed = true;
          debugPrint('✅ [syncSos] refreshed — retrying same row');

          final r2 = await _api.sendSos(
            intimationId: sos['intimation_id'] ?? 0,
            latitude: (sos['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (sos['longitude'] as num?)?.toDouble() ?? 0.0,
            timestamp: ts,
            message: msg,
            token: currentToken,
            sosType: (sos['sos_type'] ?? 'OTHER').toString(),
            locationSource: (sos['location_source'] ?? 'GPS').toString(),
            severity: (sos['severity'] ?? 'HIGH').toString(),
          );
          if (r2['success'] == true) {
            await _db.markSosSynced(id);
            ok++;
          } else if (r2['error_code'] == 'TRIP_ALREADY_ENDED' ||
              r2['permanent'] == true) {
            await _db.markSosPermanentlyFailed(id);
            dead++;
          } else {
            fail++;
          }
          continue;
        }

        if (r['success'] == true) {
          await _db.markSosSynced(id);
          ok++;
        } else if (r['error_code'] == 'TRIP_ALREADY_ENDED' ||
            r['permanent'] == true) {
          await _db.markSosPermanentlyFailed(id);
          dead++;
        } else {
          fail++;
        }
      } catch (e) {
        fail++;
        debugPrint('❌ SOS $id: $e');
      }
      if (fail > 0) await Future.delayed(const Duration(milliseconds: 150));
    }

    debugPrint('🏁 [syncSos] ok=$ok fail=$fail dead=$dead');
  }

  // ---- Citing -----------------------------------------------------------------
  Future<void> syncCiting(String token) async {
    final unsynced = await _db.getUnsyncedCiting();
    if (unsynced.isEmpty) return;

    debugPrint('🔄 [syncCiting] ${unsynced.length} pending');
    String currentToken = token;
    int ok = 0, fail = 0, dead = 0;
    bool refreshed = false;

    for (final c in unsynced) {
      final id = c['id'] as int;
      final ts = (c['timestamp'] ?? c['citing_datetime'])?.toString() ??
          DateTime.now().toUtc().toIso8601String();
      final reason = (c['citing_reason'] ?? c['citing_type'] ?? 'Incident').toString();

      try {
        final r = await _api.sendCiting(
          intimationId: c['intimation_id'] ?? 0,
          citingReason: reason,
          latitude: (c['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (c['longitude'] as num?)?.toDouble() ?? 0.0,
          timestamp: ts,
          token: currentToken,
        );

        if (r['http_status'] == 401 || r['http_status'] == 403) {
          if (refreshed) {
            debugPrint('🔒 [syncCiting] auth failed again after refresh — abort');
            break;
          }
          debugPrint('🔒 [syncCiting] 401 — attempting token refresh');
          final newToken = await _tryRefresh();
          if (newToken == null) {
            debugPrint('🔒 [syncCiting] refresh failed — abort');
            break;
          }
          currentToken = newToken;
          refreshed = true;
          debugPrint('✅ [syncCiting] refreshed — retrying same row');

          final r2 = await _api.sendCiting(
            intimationId: c['intimation_id'] ?? 0,
            citingReason: reason,
            latitude: (c['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (c['longitude'] as num?)?.toDouble() ?? 0.0,
            timestamp: ts,
            token: currentToken,
          );
          if (r2['success'] == true) {
            await _db.markCitingSynced(id);
            ok++;
          } else if (r2['permanent'] == true) {
            await _db.markCitingPermanentlyFailed(id);
            dead++;
          } else {
            fail++;
          }
          continue;
        }

        if (r['success'] == true) {
          await _db.markCitingSynced(id);
          ok++;
        } else if (r['permanent'] == true) {
          await _db.markCitingPermanentlyFailed(id);
          dead++;
        } else {
          fail++;
        }
      } catch (e) {
        fail++;
        debugPrint('❌ citing $id: $e');
      }
      if (fail > 0) await Future.delayed(const Duration(milliseconds: 150));
    }

    debugPrint('🏁 [syncCiting] ok=$ok fail=$fail dead=$dead');
  }

  // ---- Legacy helpers ---------------------------------------------------------
  Future<void> syncSosEvents() async {
    final t = await _getToken();
    if (t != null) await syncSos(t);
  }

  Future<void> syncCitingEvents() async {
    final t = await _getToken();
    if (t != null) await syncCiting(t);
  }

  void startPeriodicSync({int intervalSeconds = 300}) {
    Timer.periodic(Duration(seconds: intervalSeconds), (_) => syncAll());
  }
}