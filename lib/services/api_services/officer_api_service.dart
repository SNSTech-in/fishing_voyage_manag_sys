import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'api_constants.dart';

int intFromMap(Map? m, List<String> keys, {int fallback = 0}) {
  if (m == null) return fallback;
  for (final k in keys) {
    final v = m[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null) return p;
    }
  }
  return fallback;
}

class OfficerApiService {
  final String baseUrl = ApiConstants.baseUrl;
  final String apiKey = "FBClUvFWPFJBlY4Kw7nX-CGwGhgBMklARi-QqNy3gzg";
  final http.Client _client = http.Client();

  // 1. AUTHENTICATION
  Future<Map<String, dynamic>> loginAdmin(String username, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/admin/login'),
        headers: {
          'X-API-Key': apiKey,
          'X-Client-Id': 'WEB_ADMIN',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'username': username, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token')
          ?? prefs.getString('officer_token')
          ?? prefs.getString('auth_token')
          ?? prefs.getString('user_token');
      if (token != null && token.isNotEmpty) {
        print('🔑 [Token] Found: ${token.substring(0, 20)}...');
        return token;
      }
    } catch (e) {
      print('⚠️ [Token] SharedPreferences error: $e');
    }
    print('❌ [Token] Not found');
    return null;
  }

  Future<Map<String, String>> _getAdminHeaders() async {
    final token = await _getToken();
    return {
      'X-API-Key': apiKey,
      'X-Client-Id': 'WEB_ADMIN',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, String>> _getMobileHeaders() async {
    final token = await _getToken();
    return {
      'X-API-Key': apiKey,
      'X-Client-Id': 'MOBILE_APP',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  List parseResponse(dynamic response) {
    if (response == null) return [];
    try {
      if (response is List) return response;
      if (response is Map) {
        var data = response['data'];
        if (data == null) return [];
        if (data is List) return data;
        if (data is Map) return data['items'] ?? data['list'] ?? data['data'] ?? [];
      }
    } catch (e) { print("❌ Parsing Error: $e"); }
    return [];
  }

  Future<Map<String, dynamic>> _adminRequest(String endpoint, {Map<String, String>? params}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);
      final response = await _client.get(uri, headers: await _getAdminHeaders());
      return jsonDecode(response.body);
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  Future<Map<String, dynamic>> _makeRequest(String endpoint, {Map<String, String>? params}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);
      final response = await _client.get(uri, headers: await _getMobileHeaders());
      return jsonDecode(response.body);
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  // ==========================================
  // ALL METHODS RESTORED TO MATCH LOGIC FILES
  // ==========================================
  Future<Map<String, dynamic>> fetchDashboardStats() async => _adminRequest('/admin/dashboard/summary');

  Future<Map<String, dynamic>> fetchAllVoyages({int page = 1, int limit = 100}) async =>
      _adminRequest('/admin/voyages', params: {'page': page.toString(), 'page_size': limit.toString()});

  Future<Map<String, dynamic>> fetchVoyages({String? search, String? fromDate, String? toDate, String? status, int page = 1, int limit = 20}) async =>
      _adminRequest('/admin/voyages', params: {
        if (search != null) 'search': search,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (status != null) 'status': status,
        'page': page.toString(),
        'page_size': limit.toString(),
      });

  Future<Map<String, dynamic>> fetchSos({
    String? search,
    String? fromDate,
    String? toDate,
    String? status,
    String? severity,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getToken();

    final params = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (status != null && status.isNotEmpty) 'status': status,
      if (severity != null && severity.isNotEmpty) 'severity': severity,
      'page': page.toString(),
      'page_size': limit.toString(),
      '_ts': DateTime.now().millisecondsSinceEpoch.toString(), // cache-buster
    };

    final uri = Uri.parse('$baseUrl/sos')
        .replace(queryParameters: params);

    print('📡 [fetchSos] URL: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'x-client-id': 'WEB_ADMIN',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 [fetchSos] Status: ${response.statusCode}');
      print('📄 [fetchSos] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('❌ [fetchSos] Exception: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

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
  }) async {
    final token = await _getToken();

    final params = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (type != null && type.isNotEmpty) 'type': type,
      if (activity != null && activity.isNotEmpty) 'activity': activity,
      if (status != null && status.isNotEmpty) 'status': status,
      if (severity != null && severity.isNotEmpty) 'severity': severity,
      'page': page.toString(),
      'page_size': limit.toString(),
      '_ts': DateTime.now().millisecondsSinceEpoch.toString(), // cache-buster
    };

    final uri = Uri.parse('$baseUrl/citings')
        .replace(queryParameters: params);

    print('📡 [fetchCitings] URL: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'x-client-id': 'WEB_ADMIN',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 [fetchCitings] Status: ${response.statusCode}');
      print('📄 [fetchCitings] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('❌ [fetchCitings] Exception: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchFishCatchReport({
    String? fromDate,
    String? toDate,
    String? groupBy,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getToken();

    final params = {
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (groupBy != null && groupBy.isNotEmpty) 'group_by': groupBy,
      'page': page.toString(),
      'page_size': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/admin/reports/fish-catch')
        .replace(queryParameters: params);

    print('📡 [fetchFishCatchReport] URL: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'x-client-id': 'WEB_ADMIN',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 [fetchFishCatchReport] Status: ${response.statusCode}');
      print('📄 [fetchFishCatchReport] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('❌ [fetchFishCatchReport] Exception: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchCrewNotReturned({
    String? fromDate,
    String? toDate,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getToken();

    final params = {
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page.toString(),
      'page_size': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/admin/reports/crew-not-returned')
        .replace(queryParameters: params);

    print('📡 [fetchCrewNotReturned] URL: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'x-client-id': 'WEB_ADMIN',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 [fetchCrewNotReturned] Status: ${response.statusCode}');
      print('📄 [fetchCrewNotReturned] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('❌ [fetchCrewNotReturned] Exception: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchBoatActivity({
    String? fromDate,
    String? toDate,
    String? boat,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getToken();

    final params = {
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (boat != null && boat.isNotEmpty) 'boat': boat,
      'page': page.toString(),
      'page_size': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/admin/reports/boat-activity')
        .replace(queryParameters: params);

    print('📡 [fetchBoatActivity] URL: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'x-client-id': 'WEB_ADMIN',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 [fetchBoatActivity] Status: ${response.statusCode}');
      print('📄 [fetchBoatActivity] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('❌ [fetchBoatActivity] Exception: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchSosReport({
    String? fromDate,
    String? toDate,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getToken();

    final params = {
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page.toString(),
      'page_size': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/admin/reports/sos')
        .replace(queryParameters: params);

    print('📡 [fetchSosReport] URL: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'x-client-id': 'WEB_ADMIN',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 [fetchSosReport] Status: ${response.statusCode}');
      print('📄 [fetchSosReport] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('❌ [fetchSosReport] Exception: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchPorts({
    String? search,
    String? state,
    bool? active,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getToken();

    final params = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (state != null && state.isNotEmpty) 'state': state,
      if (active != null) 'active': active.toString(),
      'include_inactive': 'true',
      'page': page.toString(),
      'page_size': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/masters/ports')
        .replace(queryParameters: params);

    print('📡 [fetchPorts] URL: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'x-client-id': 'WEB_ADMIN',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 [fetchPorts] Status: ${response.statusCode}');
      print('📄 [fetchPorts] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('❌ [fetchPorts] Exception: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchSpecies({
    String? search,
    bool? banned,
    bool? active,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getToken();

    final params = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (banned != null) 'banned': banned.toString(),
      if (active != null) 'active': active.toString(),
      'include_banned': 'true',   // 👈 always fetch banned species too
      'page': page.toString(),
      'page_size': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/masters/fish-species')
        .replace(queryParameters: params);

    print('📡 [fetchSpecies] URL: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'x-client-id': 'WEB_ADMIN',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 [fetchSpecies] Status: ${response.statusCode}');
      print('📄 [fetchSpecies] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('❌ [fetchSpecies] Exception: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchOfficers({
    String? search,
    String? department,
    bool? active,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getToken();

    final params = {
      if (search != null && search.isNotEmpty) 'search': search,
      if (department != null && department.isNotEmpty) 'department': department,
      if (active != null) 'active': active.toString(),
      'page': page.toString(),
      'page_size': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/masters/officers')
        .replace(queryParameters: params);

    print('📡 [fetchOfficers] URL: $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'x-client-id': 'WEB_ADMIN',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 [fetchOfficers] Status: ${response.statusCode}');
      print('📄 [fetchOfficers] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('❌ [fetchOfficers] Exception: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<List<LatLng>> fetchVoyageRoute(int intimationId) async {
    final token = await _getToken();
    if (token == null) return [];

    final headers = {
      'X-API-Key': apiKey,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Try these paths — first one that returns data wins
    final paths = [
      '/intimations/$intimationId/pings',
      '/voyages/$intimationId/pings',
      '/pings?intimation_id=$intimationId',
    ];

    for (final path in paths) {
      try {
        final uri = Uri.parse('$baseUrl$path');
        debugPrint('🗺️ [Route] trying $uri');

        final res = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));

        debugPrint('🗺️ [Route] status ${res.statusCode}');
        if (res.statusCode != 200) continue;

        final data = jsonDecode(res.body);
        if (data['success'] != true) continue;

        final items = (data['data']?['items'] ??
            data['data']?['pings'] ??
            data['data'] ??
            []) as List;

        final pts = <LatLng>[];
        for (final p in items) {
          final lat = (p['latitude'] as num?)?.toDouble();
          final lng = (p['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null && lat != 0 && lng != 0) {
            pts.add(LatLng(lat, lng));
          }
        }

        debugPrint('🗺️ [Route] parsed ${pts.length} points');
        if (pts.isNotEmpty) return pts;
      } catch (e) {
        debugPrint('🗺️ [Route] $path failed: $e');
      }
    }
    return [];
  }

  // --- POST METHODS FOR SYNC SERVICE ---

  Future<bool> postSos(Map<String, dynamic> payload) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/sos'),
        headers: await _getAdminHeaders(),
        body: jsonEncode(payload),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('❌ postSos error: $e');
      return false;
    }
  }

  Future<bool> postCiting(Map<String, dynamic> payload) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/citings'),
        headers: await _getAdminHeaders(),
        body: jsonEncode(payload),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('❌ postCiting error: $e');
      return false;
    }
  }
}
