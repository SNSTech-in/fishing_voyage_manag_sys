import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/database_helper.dart';
import '../api_services/boat_owners_api_service.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  factory SyncService() => instance;
  SyncService._internal();

  static final ValueNotifier<bool> needsRelogin = ValueNotifier(false);

  final DatabaseHelper _db = DatabaseHelper();
  final BoatOwnwesApiService _api = BoatOwnwesApiService();

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

  // ============================================================
  // 🔍 LOGGING HELPERS
  // ============================================================

  void _log(String tag, String msg) {
    debugPrint('[$tag] $msg');
  }

  void _logBox(String tag, String title, Map<String, dynamic> data) {
    debugPrint('┌─── $title [$tag] ─────────────────────────────');
    data.forEach((k, v) {
      debugPrint('│ $k : $v');
    });
    debugPrint('└────────────────────────────────────────────────────');
  }

  String _maskToken(String? t) {
    if (t == null) return '❌ null';
    if (t.isEmpty) return '❌ empty';
    if (t.length < 20) return t;
    return '${t.substring(0, 10)}...${t.substring(t.length - 6)}';
  }

  // ---- Token ------------------------------------------------------------------
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ??
          prefs.getString('token') ??
          prefs.getString('auth_token') ??
          prefs.getString('user_token');
      if (token != null && token.isNotEmpty) {
        _log('Token', 'found in prefs (${_maskToken(token)})');
        return token;
      }
      _log('Token', 'prefs has no token under known keys');
    } catch (e) {
      debugPrint('⚠️ [Token] prefs failed: $e');
    }

    try {
      final session = await _db.getUserSession();
      final token = session?['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        _log('Token', 'found in DB session (${_maskToken(token)})');
        return token;
      }
      _log('Token', 'DB session has no access_token');
    } catch (e) {
      debugPrint('⚠️ [Token] DB failed: $e');
    }
    _log('Token', '❌ NOT FOUND anywhere');
    return null;
  }

  /// Read the long-lived refresh token from storage.
  Future<String?> _getRefreshToken() async {
    try {
      final p = await SharedPreferences.getInstance();
      final r = p.getString('refresh_token');
      _log('RefreshToken', r == null ? 'not stored' : 'found (${_maskToken(r)})');
      return r;
    } catch (e) {
      _log('RefreshToken', 'error: $e');
      return null;
    }
  }

  /// Attempt to refresh the access token.
  Future<String?> _tryRefresh() async {
    _log('refresh', 'attempting token refresh...');
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
    _log('refresh', '✅ new token (${_maskToken(newToken)})');
    return newToken;
  }

  // ---- Public API -------------------------------------------------------------
  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint('⚠️ [syncAll] already running – skip');
      return;
    }
    _syncStartedAt = DateTime.now();

    debugPrint('┌────────────────────────────────────────────────────');
    debugPrint('│ 🔄 [syncAll] STARTED @ ${DateTime.now().toIso8601String()}');
    debugPrint('└────────────────────────────────────────────────────');

    try {
      final token = await _getTokenWithRetry();
      if (token == null) {
        debugPrint('⚠️ [syncAll] no token – abort');
        return;
      }
      debugPrint('✅ [syncAll] using token ${_maskToken(token)}');

      await _runStep('syncLocations', () => syncLocations(token));
      await _runStep('syncSos',       () => syncSos(token));
      await _runStep('syncCiting',    () => syncCiting(token));

      debugPrint('┌────────────────────────────────────────────────────');
      debugPrint('│ ✅ [syncAll] COMPLETED @ ${DateTime.now().toIso8601String()}');
      debugPrint('└────────────────────────────────────────────────────');
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
      _log('Token', 'retry ${i + 1}/3 in 500ms');
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  // ---- Device ID ---------------------------------------------------------------
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('device_imei');
    if (cached != null && cached.isNotEmpty) {
      _log('DeviceId', 'cached: $cached');
      return cached;
    }

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
    } catch (e) {
      _log('DeviceId', 'error reading device info: $e');
    }

    await prefs.setString('device_imei', id);
    _log('DeviceId', 'generated & cached: $id');
    return id;
  }

  // ---- Locations --------------------------------------------------------------
  Future<void> syncLocations(String token) async {
    debugPrint('┌─── 🔄 [syncLocations] ─────────────────────────────');
    final pending = await _db.getUnsyncedLocations();
    debugPrint('│ queue size = ${pending.length}');

    if (pending.isEmpty) {
      debugPrint('│ ✅ nothing to sync');
      debugPrint('└────────────────────────────────────────────────────');
      return;
    }

    debugPrint('│ proceeding to send ${pending.length} row(s)');
    debugPrint('└────────────────────────────────────────────────────');

    final deviceId = await _getDeviceId();
    String currentToken = token;
    int ok = 0, fail = 0, dead = 0;
    bool refreshed = false;

    for (final loc in pending) {
      final id = loc['id'] as int;
      final voyageNo =
      (loc['voyage_no'] ?? loc['intimation_id'])?.toString().trim();

      _logBox('syncLocations', 'ROW #$id', {
        'voyage_no': voyageNo ?? 'NULL',
        'intimation_id': loc['intimation_id'],
        'lat': loc['latitude'],
        'lng': loc['longitude'],
        'ts': loc['timestamp'] ?? loc['ping_date_time'],
        'synced': loc['synced'],
      });

      if (voyageNo == null || voyageNo.isEmpty || voyageNo == 'UNKNOWN') {
        debugPrint('🗑️ [syncLocations] DISCARD id=$id — voyage_no="$voyageNo" '
            'intimation_id=${loc['intimation_id']}');
        await _db.markLocationPermanentlyFailed(id);
        dead++;
        continue;
      }

      final ts = (loc['timestamp'] ?? loc['ping_date_time'])?.toString() ??
          DateTime.now().toUtc().toIso8601String();

      try {
        debugPrint('📤 [syncLocations] attempting id=$id voyage=$voyageNo');
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

        debugPrint('📊 [syncLocations] row id=$id result: '
            'success=${r['success']} http=${r['http_status']} '
            'permanent=${r['permanent']}');

        // ───── 401/403 → try refresh ONCE, then retry ─────
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

          debugPrint('📊 [syncLocations] retry id=$id result: '
              'success=${r2['success']} http=${r2['http_status']} '
              'permanent=${r2['permanent']} msg=${r2['message']}');

          if (r2['success'] == true) {
            await _db.markLocationSynced(id);
            debugPrint('✅ [syncLocations] row id=$id marked synced');
            ok++;
          } else if (r2['permanent'] == true) {
            await _db.markLocationPermanentlyFailed(id);
            debugPrint('🗑️ [syncLocations] row id=$id marked permanently failed');
            dead++;
          } else {
            debugPrint('⏸️ [syncLocations] row id=$id left for retry');
            fail++;
          }
          continue;
        }

        // ───── Normal outcomes ─────
        if (r['success'] == true) {
          await _db.markLocationSynced(id);
          debugPrint('✅ [syncLocations] row id=$id marked synced');
          ok++;
        } else if (r['permanent'] == true) {
          await _db.markLocationPermanentlyFailed(id);
          debugPrint('🗑️ [syncLocations] row id=$id marked permanently failed — '
              '${r['message']}');
          dead++;
        } else {
          debugPrint('⏸️ [syncLocations] row id=$id left for retry — '
              '${r['message']}');
          fail++;
        }
      } catch (e, st) {
        fail++;
        debugPrint('❌ [syncLocations] exception on id=$id: $e\n$st');
      }

      if (fail > 0) await Future.delayed(const Duration(milliseconds: 150));
    }

    debugPrint('┌─── 🏁 [syncLocations] SUMMARY ─────────────────────');
    debugPrint('│ ok=$ok fail=$fail dead=$dead');
    debugPrint('└────────────────────────────────────────────────────');
  }

  // ---- SOS --------------------------------------------------------------------
  Future<void> syncSos(String token) async {
    final unsynced = await _db.getUnsyncedSos();
    if (unsynced.isEmpty) {
      debugPrint('✅ [syncSos] nothing to sync');
      return;
    }

    debugPrint('🔄 [syncSos] ${unsynced.length} pending');
    String currentToken = token;
    int ok = 0, fail = 0, dead = 0;
    bool refreshed = false;

    for (final sos in unsynced) {
      final id = sos['id'] as int;
      final ts = (sos['sos_datetime'] ?? sos['timestamp'])?.toString() ??
          DateTime.now().toUtc().toIso8601String();
      final msg = (sos['description'] ?? sos['message'] ?? 'SOS Alert').toString();

      _logBox('syncSos', 'ROW #$id', {
        'intimation_id': sos['intimation_id'],
        'lat': sos['latitude'],
        'lng': sos['longitude'],
        'severity': sos['severity'],
        'sos_type': sos['sos_type'],
      });

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

        debugPrint('📊 [syncSos] row id=$id result: '
            'success=${r['success']} http=${r['http_status']} '
            'permanent=${r['permanent']} msg=${r['message']}');

        if (r['http_status'] == 401 || r['http_status'] == 403) {
          if (refreshed) {
            debugPrint('🔒 [syncSos] auth failed again after refresh — abort');
            break;
          }
          final newToken = await _tryRefresh();
          if (newToken == null) break;
          currentToken = newToken;
          refreshed = true;

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
            debugPrint('✅ [syncSos] row id=$id marked synced');
            ok++;
          } else if (r2['error_code'] == 'TRIP_ALREADY_ENDED' ||
              r2['permanent'] == true) {
            await _db.markSosPermanentlyFailed(id);
            debugPrint('🗑️ [syncSos] row id=$id marked permanently failed — ${r2['error_code']}');
            dead++;
          } else {
            fail++;
          }
          continue;
        }

        if (r['success'] == true) {
          await _db.markSosSynced(id);
          debugPrint('✅ [syncSos] row id=$id marked synced');
          ok++;
        } else if (r['error_code'] == 'TRIP_ALREADY_ENDED' ||
            r['permanent'] == true) {
          await _db.markSosPermanentlyFailed(id);
          debugPrint('🗑️ [syncSos] row id=$id marked permanently failed — ${r['error_code']}');
          dead++;
        } else {
          fail++;
        }
      } catch (e, st) {
        fail++;
        debugPrint('❌ [syncSos] exception on id=$id: $e\n$st');
      }
      if (fail > 0) await Future.delayed(const Duration(milliseconds: 150));
    }

    debugPrint('🏁 [syncSos] ok=$ok fail=$fail dead=$dead');
  }

  // ---- Citing -----------------------------------------------------------------
  Future<void> syncCiting(String token) async {
    final unsynced = await _db.getUnsyncedCiting();
    if (unsynced.isEmpty) {
      debugPrint('✅ [syncCiting] nothing to sync');
      return;
    }

    debugPrint('🔄 [syncCiting] ${unsynced.length} pending');
    String currentToken = token;
    int ok = 0, fail = 0, dead = 0;
    bool refreshed = false;

    for (final c in unsynced) {
      final id = c['id'] as int;
      final ts = (c['timestamp'] ?? c['citing_datetime'])?.toString() ??
          DateTime.now().toUtc().toIso8601String();
      final reason = (c['citing_reason'] ?? c['citing_type'] ?? 'Incident').toString();

      _logBox('syncCiting', 'ROW #$id', {
        'intimation_id': c['intimation_id'],
        'lat': c['latitude'],
        'lng': c['longitude'],
        'citing_type': c['citing_type'],
      });

      try {
        final r = await _api.sendCiting(
          intimationId: c['intimation_id'] ?? 0,
          citingReason: reason,
          latitude: (c['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (c['longitude'] as num?)?.toDouble() ?? 0.0,
          timestamp: ts,
          token: currentToken,
        );

        debugPrint('📊 [syncCiting] row id=$id result: '
            'success=${r['success']} http=${r['http_status']} '
            'permanent=${r['permanent']} msg=${r['message']}');

        if (r['http_status'] == 401 || r['http_status'] == 403) {
          if (refreshed) {
            debugPrint('🔒 [syncCiting] auth failed again after refresh — abort');
            break;
          }
          final newToken = await _tryRefresh();
          if (newToken == null) break;
          currentToken = newToken;
          refreshed = true;

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
            debugPrint('✅ [syncCiting] row id=$id marked synced');
            ok++;
          } else if (r2['permanent'] == true) {
            await _db.markCitingPermanentlyFailed(id);
            debugPrint('🗑️ [syncCiting] row id=$id marked permanently failed');
            dead++;
          } else {
            fail++;
          }
          continue;
        }

        if (r['success'] == true) {
          await _db.markCitingSynced(id);
          debugPrint('✅ [syncCiting] row id=$id marked synced');
          ok++;
        } else if (r['permanent'] == true) {
          await _db.markCitingPermanentlyFailed(id);
          debugPrint('🗑️ [syncCiting] row id=$id marked permanently failed');
          dead++;
        } else {
          fail++;
        }
      } catch (e, st) {
        fail++;
        debugPrint('❌ [syncCiting] exception on id=$id: $e\n$st');
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