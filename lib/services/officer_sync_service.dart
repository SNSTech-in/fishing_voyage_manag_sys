import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'offline_queue_service.dart';
import '../officer/services/officer_api_service.dart';
import 'local_db.dart';

class OfficerSyncService {
  OfficerSyncService._();
  static final OfficerSyncService instance = OfficerSyncService._();

  final _api = OfficerApiService();
  bool _syncing = false;

  /// Call once at app startup. It reacts whenever connectivity returns.
  void start() {
    OfflineQueueService.instance.onlineStream().listen((online) async {
      if (online) {
        await flushAll();
      }
    });
  }

  /// Try to push every pending record. Safe to call repeatedly.
  Future<void> flushAll() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _flushSos();
      await _flushCitings();
    } finally {
      _syncing = false;
    }
  }

  Future<void> _flushSos() async {
    final db = await LocalDb.instance.db;
    final rows = await db.query('pending_sos',
        where: 'sync_status = ?', whereArgs: ['pending']);

    for (final row in rows) {
      try {
        final payload = jsonDecode(row['payload'] as String)
            as Map<String, dynamic>;

        final ok = await _api.postSos(payload);

        if (ok) {
          await db.delete('pending_sos',
              where: 'id = ?', whereArgs: [row['id']]);
          debugPrint('✅ SOS synced: ${row['id']}');
        } else {
          await db.update('pending_sos',
              {'retry_count': (row['retry_count'] as int) + 1},
              where: 'id = ?', whereArgs: [row['id']]);
        }
      } catch (e) {
        debugPrint('❌ SOS sync failed: $e');
        await db.update('pending_sos',
            {'last_error': e.toString()},
            where: 'id = ?', whereArgs: [row['id']]);
      }
    }
  }

  Future<void> _flushCitings() async {
    final db = await LocalDb.instance.db;
    final rows = await db.query('pending_citings',
        where: 'sync_status = ?', whereArgs: ['pending']);

    for (final row in rows) {
      try {
        final payload = jsonDecode(row['payload'] as String)
            as Map<String, dynamic>;
        final ok = await _api.postCiting(payload);
        if (ok) {
          await db.delete('pending_citings',
              where: 'id = ?', whereArgs: [row['id']]);
        } else {
          await db.update('pending_citings',
              {'retry_count': (row['retry_count'] as int) + 1},
              where: 'id = ?', whereArgs: [row['id']]);
        }
      } catch (e) {
        debugPrint('❌ Citing sync failed: $e');
      }
    }
  }
}
