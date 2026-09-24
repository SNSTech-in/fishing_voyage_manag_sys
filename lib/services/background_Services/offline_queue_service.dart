import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../database/database_helper.dart';

class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  /// Save an SOS locally. Returns the inserted row id.
  Future<int> queueSos({
    required Map<String, dynamic> payload,
    required double lat,
    required double lng,
  }) async {
    final db = await DatabaseHelper().database;
    final msg = payload['message'] ??
        payload['remarks'] ??
        payload['description'] ??
        'SOS Alert';
    final id = await db.insert('sos_queue', {
      'intimation_id': payload['intimation_id'],
      'boat_reg_no': payload['boat_reg_no'],
      'latitude': lat,
      'longitude': lng,
      'sos_datetime': payload['sos_datetime'] ??
          DateTime.now().toUtc().toIso8601String(),
      'description': msg,
      'remarks': msg,
      'sos_type': payload['sos_type'] ?? 'OTHER',
      'severity': payload['severity'] ?? 'HIGH',
      'location_source': payload['location_source'] ?? 'GPS',
      'synced': 0,
    });
    debugPrint('💾 [queueSos] INSERTED id=$id into sos_queue');
    return id;
  }

  /// Save a citing locally. Returns the inserted row id.
  Future<int> queueCiting({
    required Map<String, dynamic> payload,
    required double lat,
    required double lng,
    required String citingType,
  }) async {
    final db = await DatabaseHelper().database;
    final id = await db.insert('citing_queue', {
      'intimation_id': payload['intimation_id'],
      'latitude': lat,
      'longitude': lng,
      'citing_datetime': payload['citing_datetime'] ??
          DateTime.now().toUtc().toIso8601String(),
      'citing_reason': citingType,
      'citing_type': citingType,
      'remarks': payload['remarks'],
      'sighted_boat_count': payload['sighted_boat_count'],
      'illegal_activity_type': payload['illegal_activity_type'],
      'synced': 0,
    });
    debugPrint('💾 [queueCiting] INSERTED id=$id into citing_queue');
    return id;
  }

  /// Returns true if the queued row with [id] has been marked synced.
  Future<bool> isSynced(int id) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query(
      'sos_queue',
      where: 'id = ? AND synced = 1',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) return true;

    final rows2 = await db.query(
      'citing_queue',
      where: 'id = ? AND synced = 1',
      whereArgs: [id],
      limit: 1,
    );
    return rows2.isNotEmpty;
  }

  /// Returns true if any usable network interface is available.
  Future<bool> isOnline() async {
    try {
      final r = await Connectivity().checkConnectivity();
      if (r is List) {
        return r.any((e) => e != ConnectivityResult.none);
      }
      return r != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all pending items (for UI badges like "3 pending uploads").
  Future<List<Map<String, dynamic>>> pendingSos() async {
    return await DatabaseHelper().getUnsyncedSos();
  }

  Future<List<Map<String, dynamic>>> pendingCitings() async {
    return await DatabaseHelper().getUnsyncedCiting();
  }

  /// Returns total count of all pending offline items.
  Future<int> totalPendingCount() async {
    final sos = await pendingSos();
    final citings = await pendingCitings();
    return sos.length + citings.length;
  }

  /// Listen for connectivity changes. Triggers a sync when online.
  Stream<bool> onlineStream() => Connectivity()
      .onConnectivityChanged
      .map((list) => list.any((e) => e != ConnectivityResult.none));
}
