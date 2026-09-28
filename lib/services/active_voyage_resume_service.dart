import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'api_services/boat_owners_api_service.dart';

class ActiveVoyageResumeService {
  static final ActiveVoyageResumeService instance =
      ActiveVoyageResumeService._internal();
  factory ActiveVoyageResumeService() => instance;
  ActiveVoyageResumeService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final BoatOwnwesApiService _api = BoatOwnwesApiService();

  /// On app start (after login), checks the backend for an ONGOING voyage.
  /// If found, upserts it into the local `voyages` table so the background
  /// task picks it up. Returns the voyage map, or null if none is active.
  Future<Map<String, dynamic>?> resumeIfActive() async {
    debugPrint('🔁 [resume] checking backend for active voyage...');

    final r = await _api.getIntimations(page: 1, pageSize: 50);

    if (r['success'] != true) {
      debugPrint('🔁 [resume] intimations fetch failed: ${r['message']}');
      return null;
    }

    final items = (r['data']?['items'] ?? r['data'] ?? []) as List;
    debugPrint('🔁 [resume] fetched ${items.length} voyages from backend');

    Map<String, dynamic>? active;
    for (final v in items) {
      if (v is! Map) continue;
      final s = (v['derived_status'] ??
              v['trip_status'] ??
              v['status'] ??
              '')
          .toString()
          .toUpperCase();
      if (s == 'ONGOING' || s == 'ACTIVE' || s == 'AT SEA') {
        active = Map<String, dynamic>.from(v);
        break;
      }
    }

    if (active == null) {
      debugPrint('🔁 [resume] no ONGOING/ACTIVE voyage on backend');
      return null;
    }

    final intimationId = active['intimation_id'] as int?;
    final referenceNo = active['reference_no']?.toString();

    if (intimationId == null || referenceNo == null || referenceNo.isEmpty) {
      debugPrint('🔁 [resume] malformed voyage — skipping');
      return null;
    }

    // Ensure status/derived_status is set so syncVoyages saves the status in local DB
    active['derived_status'] ??= active['status'] ?? active['trip_status'] ?? 'ONGOING';

    // Upsert into local `voyages` table so the background task sees it
    await _db.syncVoyages(items: [active]);

    // Update SharedPreferences as well for backward compatibility
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_voyage_id', intimationId);
      await prefs.setString('active_voyage_no', referenceNo);
    } catch (e) {
      debugPrint('🔁 [resume] prefs sync error (non-fatal): $e');
    }

    debugPrint('🔁 [resume] ✅ restored voyage $referenceNo '
        '(intimation_id=$intimationId) into local DB');

    return active;
  }
}
