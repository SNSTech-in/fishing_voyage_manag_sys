import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../database/database_helper.dart';
import 'api_constants.dart';

class OfficersApiService {
  final http.Client _client = http.Client();
  final DatabaseHelper _db = DatabaseHelper();

  // ─────────────────────────────────────────────────────────────
  // TOKEN
  // ─────────────────────────────────────────────────────────────
  Future<String?> _getToken() async {
    try {
      final session = await _db.getOfficerSession();
      final token = session?['access_token']?.toString();
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('⚠️ [OfficersApiService] token read failed: $e');
    }
    return null;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return ApiConstants.adminHeaders(token);
  }

  // ─────────────────────────────────────────────────────────────
  // CORE REQUEST HELPERS
  // ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _get(
      String url, {
        Map<String, String>? query,
        Duration timeout = const Duration(seconds: 30),
      }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: query);
      debugPrint('📡 GET $uri');

      final res =
      await _client.get(uri, headers: await _headers()).timeout(timeout);
      debugPrint('📡 ← ${res.statusCode}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          decoded['success'] = decoded['success'] ?? true;
          decoded['statusCode'] = res.statusCode;
          return decoded;
        }
        return {'success': true, 'data': decoded, 'statusCode': res.statusCode};
      }
      return {
        'success': false,
        'message': 'HTTP ${res.statusCode}',
        'statusCode': res.statusCode,
      };
    } catch (e) {
      debugPrint('❌ GET $url failed: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> _post(
      String url, {
        Map<String, dynamic>? body,
        Duration timeout = const Duration(seconds: 30),
      }) async {
    try {
      debugPrint('📡 POST $url');
      final res = await _client
          .post(Uri.parse(url),
          headers: await _headers(), body: jsonEncode(body ?? {}))
          .timeout(timeout);
      debugPrint('📡 ← ${res.statusCode}');

      final decoded =
      res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        decoded['success'] = res.statusCode >= 200 && res.statusCode < 300;
        decoded['statusCode'] = res.statusCode;
        return decoded;
      }
      return {
        'success': res.statusCode >= 200 && res.statusCode < 300,
        'data': decoded,
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NORMALIZED LIST EXTRACTOR
  // ─────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> extractList(Map<String, dynamic> res) {
    final raw = res['data'];
    List? list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      list = (raw['items'] ?? raw['list'] ?? raw['data']) as List?;
    }
    if (list == null) return [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Map<String, int> extractPagination(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map) {
      return {
        'total': _asInt(data['total'] ?? data['count']),
        'page': _asInt(data['page'] ?? 1),
        'page_size': _asInt(data['page_size'] ?? data['limit'] ?? 20),
      };
    }
    return {'total': 0, 'page': 1, 'page_size': 20};
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  // ═════════════════════════════════════════════════════════════
  // 1. AUTH
  // ═════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> login(String username, String password) async {
    return _post(
      ApiConstants.adminLogin,
      body: {'username': username, 'password': password},
    );
  }

  // ═════════════════════════════════════════════════════════════
  // 2. DASHBOARD
  // ═════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> fetchDashboardStats({
    String? fromDate,
    String? toDate,
    int? portId,
    String? district,
  }) =>
      _get(ApiConstants.adminDashboardSummary, query: {
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
        if (portId != null) 'port_id': '$portId',
        if (district != null && district.isNotEmpty) 'district': district,
      });

  // ═════════════════════════════════════════════════════════════
  // 3. VOYAGES
  // ═════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> fetchVoyages({
    String? search,
    String? fromDate,
    String? toDate,
    String? status,
    int page = 1,
    int limit = 20,
  }) =>
      _get(ApiConstants.adminVoyages, query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': '$page',
        'page_size': '$limit',
      });

  Future<Map<String, dynamic>> fetchVoyageDetails(int intimationId) =>
      _get(ApiConstants.adminVoyageDetails(intimationId));

  // ═════════════════════════════════════════════════════════════
  // 4. SOS
  // ═════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> fetchSos({
    String? search,
    String? fromDate,
    String? toDate,
    String? status,
    String? severity,
    int page = 1,
    int limit = 20,
  }) =>
      _get(ApiConstants.adminSos, query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (status != null && status.isNotEmpty) 'status': status,
        if (severity != null && severity.isNotEmpty) 'severity': severity,
        'page': '$page',
        'page_size': '$limit',
        '_ts': '${DateTime.now().millisecondsSinceEpoch}',
      });

  Future<Map<String, dynamic>> fetchSosReport({
    String? fromDate,
    String? toDate,
    String? status,
    int page = 1,
    int limit = 20,
  }) =>
      _get(ApiConstants.adminReportSos, query: {
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': '$page',
        'page_size': '$limit',
      });

  Future<bool> postSos(Map<String, dynamic> payload) async {
    final res = await _post(ApiConstants.adminSos, body: payload);
    return res['success'] == true;
  }

  // ═════════════════════════════════════════════════════════════
  // 5. CITINGS
  // ═════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> fetchCitings({
    String? search,
    String? fromDate,
    String? toDate,
    String? type,
    String? activity,
    String? status,
    String? severity,
    int page = 1,
    int limit = 20,
  }) =>
      _get(ApiConstants.adminCitings, query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (type != null && type.isNotEmpty) 'type': type,
        if (activity != null && activity.isNotEmpty) 'activity': activity,
        if (status != null && status.isNotEmpty) 'status': status,
        if (severity != null && severity.isNotEmpty) 'severity': severity,
        'page': '$page',
        'page_size': '$limit',
        '_ts': '${DateTime.now().millisecondsSinceEpoch}',
      });

  /// ⭐ Fetch ONE citing's full detail.
  /// Endpoint: GET /citings/{citingId}
  Future<Map<String, dynamic>> fetchCitingDetails(int citingId) =>
      _get(ApiConstants.adminCitingDetails(citingId));

  Future<bool> postCiting(Map<String, dynamic> payload) async {
    final res = await _post(ApiConstants.adminCitings, body: payload);
    return res['success'] == true;
  }

  // ═════════════════════════════════════════════════════════════
  // 6. REPORTS
  // ═════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> fetchFishCatchReport({
    String? fromDate,
    String? toDate,
    String? groupBy,
    int page = 1,
    int limit = 20,
  }) =>
      _get(ApiConstants.adminReportFishCatch, query: {
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (groupBy != null && groupBy.isNotEmpty) 'group_by': groupBy,
        'page': '$page',
        'page_size': '$limit',
      });

  Future<Map<String, dynamic>> fetchCrewNotReturned({
    String? fromDate,
    String? toDate,
    String? search,
    int page = 1,
    int limit = 20,
  }) =>
      _get(ApiConstants.adminReportCrewNotReturned, query: {
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': '$page',
        'page_size': '$limit',
      });

  Future<Map<String, dynamic>> fetchBoatActivity({
    String? fromDate,
    String? toDate,
    String? boat,
    int page = 1,
    int limit = 20,
  }) =>
      _get(ApiConstants.adminReportBoatActivity, query: {
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (boat != null && boat.isNotEmpty) 'boat': boat,
        'page': '$page',
        'page_size': '$limit',
      });

  // ═════════════════════════════════════════════════════════════
  // 7. MASTERS
  // ═════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> fetchPorts({
    String? search,
    String? state,
    bool? active,
    int page = 1,
    int limit = 20,
  }) =>
      _get(ApiConstants.ports, query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (state != null && state.isNotEmpty) 'state': state,
        if (active != null) 'active': '$active',
        'include_inactive': 'true',
        'page': '$page',
        'page_size': '$limit',
      });

  Future<Map<String, dynamic>> fetchSpecies({
    String? search,
    bool? banned,
    bool? active,
    int page = 1,
    int limit = 20,
  }) =>
      _get(ApiConstants.fishSpecies, query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (banned != null) 'banned': '$banned',
        if (active != null) 'active': '$active',
        'include_banned': 'true',
        'page': '$page',
        'page_size': '$limit',
      });

  Future<Map<String, dynamic>> fetchOfficers({
    String? search,
    String? department,
    bool? active,
    int page = 1,
    int limit = 20,
  }) =>
      _get(ApiConstants.officers, query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (department != null && department.isNotEmpty) 'department': department,
        if (active != null) 'active': '$active',
        'page': '$page',
        'page_size': '$limit',
      });

  // ═════════════════════════════════════════════════════════════
  // 8. VOYAGE ROUTE
  // ═════════════════════════════════════════════════════════════
  Future<List<LatLng>> fetchVoyageRoute(int intimationId) async {
    final paths = [
      ApiConstants.voyagePings(intimationId),
      ApiConstants.voyagePingsAlt(intimationId),
      ApiConstants.pingsQuery(intimationId),
    ];

    for (final path in paths) {
      try {
        final res = await _get(path, timeout: const Duration(seconds: 20));
        if (res['success'] != true) continue;

        final items = extractList(res);
        final pts = <LatLng>[];
        for (final p in items) {
          final lat = (p['latitude'] as num?)?.toDouble();
          final lng = (p['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null && lat != 0 && lng != 0) {
            pts.add(LatLng(lat, lng));
          }
        }
        if (pts.isNotEmpty) return pts;
      } catch (e) {
        debugPrint('🗺️ route try $path failed: $e');
      }
    }
    return [];
  }

  /// ⭐ Fetch ONE SOS's full detail.
  /// Endpoint: GET /sos/{sosId}
  Future<Map<String, dynamic>> fetchSosDetails(int sosId) =>
      _get(ApiConstants.adminSosDetails(sosId));

  // ═════════════════════════════════════════════════════════════
  // 9. AUDIT LOG
  // ═════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> fetchAuditLog({
    int page = 1,
    int limit = 20,
    String? tableName,
    String? actionType,
    String? fromDate,
    String? toDate,
  }) =>
      _get(ApiConstants.auditLog, query: {
        'page': '$page',
        'page_size': '$limit',
        if (tableName != null && tableName.isNotEmpty)
          'table_name': tableName,
        if (actionType != null && actionType.isNotEmpty)
          'action_type': actionType,
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      });
}