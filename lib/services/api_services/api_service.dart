// lib/services/api_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import '../../database/database_helper.dart';

class ApiService {
  final http.Client _client = createCustomClient();
  final DatabaseHelper _db = DatabaseHelper();

  // Global navigator key for navigation from non-widget context
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Helper to call the error callback if provided.
  void _notifyError(void Function(String)? onError, String message) {
    if (onError != null) {
      onError(message);
    }
  }

  // ============================================================
  // SECURITY & HEADERS
  // ============================================================

  Future<Map<String, String>> _getHeadersWithAccessToken() async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Key': ApiConstants.apiKey,
      'X-Client-Id': ApiConstants.clientId,
    };

    final session = await _db.getUserSession();
    if (session != null) {
      String? token = session['access_token'] ?? session['setup_token'];
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// ✅ FIXED: Now inside the class, so `_db` is accessible.
  Future<Map<String, String>> _getHeadersWithSetupToken() async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Key': ApiConstants.apiKey,
      'X-Client-Id': ApiConstants.clientId,
    };

    try {
      final session = await _db.getUserSession();

      if (session != null) {
        if (session['setup_token'] != null &&
            session['setup_token'].toString().isNotEmpty) {
          final token = session['setup_token'].toString();
          headers['Authorization'] = 'Bearer $token';
          print('🔑 Setup token added to headers for profile creation');
        } else {
          print('⚠️ No setup_token found in session');
        }
      } else {
        print('⚠️ No session found in database');
      }
    } catch (e) {
      print('⚠️ Error getting token from database: $e');
    }

    return headers;
  }

  // ============================================================
  // SESSION MANAGEMENT
  // ============================================================

  Future<void> _handleTokenExpired() async {
    await _db.clearUserSession();
    if (navigatorKey?.currentContext != null) {
      Navigator.pushNamedAndRemoveUntil(
        navigatorKey!.currentContext!,
        '/depart_login_selection',
            (route) => false,
      );
    }
  }

  Future<Map<String, dynamic>> _checkResponse(Map<String, dynamic> data) async {
    if (data['success'] == false) {
      if (data['error_code'] == 'TOKEN_EXPIRED' ||
          data['error_code'] == 'INVALID_TOKEN') {
        print('⚠️ _checkResponse: Token expired or invalid');
        await _handleTokenExpired();
      } else if (data['error_code'] == 'INVALID_API_KEY') {
        print('❌ _checkResponse: INVALID_API_KEY. Please verify ApiConstants.apiKey');
      }
    }
    return data;
  }

  // ============================================================
  // AUTH FLOW
  // ============================================================

  Future<Map<String, dynamic>> sendOtp(String mobileNo) async {
    final body = {'mobile_no': mobileNo};
    print('📤 [sendOtp] REQUEST: $body');

    final response = await _client.post(
      Uri.parse(ApiConstants.sendOtp),
      headers: ApiConstants.publicHeaders,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [sendOtp] RESPONSE: $data');

    return _checkResponse(data);
  }

  Future<Map<String, dynamic>> verifyOtp(String mobileNo, String otp) async {
    final body = {'mobile_no': mobileNo, 'otp': otp};
    print('📤 [verifyOtp] REQUEST: $body');

    final response = await _client.post(
      Uri.parse(ApiConstants.verifyOtp),
      headers: ApiConstants.publicHeaders,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [verifyOtp] RESPONSE: $data');

    if (data['success'] == true && data['data'] != null) {
      final responseData = data['data'];
      if (responseData['setup_token'] != null) {
        print('🔑 verifyOtp: Saving setup_token');
        await _db.insertUserSession({
          'mobile_no': mobileNo,
          'setup_token': responseData['setup_token'],
          'access_token': null,
          'refresh_token': null,
          'token_type': null,
          'expires_in': responseData['expires_in'],
          'profile_data': 0,
          'owner_id': null,
          'user_name': null,
          'role': null,
        });
      } else if (responseData['access_token'] != null) {
        print('🔑 verifyOtp: Saving access_token');
        final token = responseData['access_token'].toString();
        final refreshToken = responseData['refresh_token']?.toString();

        // Save to SharedPreferences for sync fallback
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await prefs.setString('refresh_token', refreshToken);
        }

        final user = responseData['user'];
        await _db.insertUserSession({
          'mobile_no': user?['mobile_no'] ?? mobileNo,
          'setup_token': null,
          'access_token': token,
          'refresh_token': responseData['refresh_token'],
          'token_type': responseData['token_type'] ?? 'Bearer',
          'expires_in': responseData['expires_in'],
          'profile_data': 1,
          'owner_id': user?['owner_id'],
          'user_name': user?['name'],
          'role': user?['role'],
        });
      }
    }
    return _checkResponse(data);
  }

  Future<Map<String, dynamic>> createProfile({
    required String ownerName,
    required String aadhaarNo,
    required String primaryPortId,
    required String otp,
    required String mobileNo,
    required String address,
  }) async {
    final String url = ApiConstants.createProfile;
    final Map<String, String> headers = await _getHeadersWithSetupToken();

    final Map<String, dynamic> body = {
      'owner_name': ownerName,
      'aadhaar_no': aadhaarNo,
      'primary_port_id': primaryPortId,
      'mobile_no': mobileNo,
      'address': address,
    };

    print('═══════════════════════════════════════════════════════════');
    print('📤 [CREATE PROFILE] REQUEST');
    print('📍 URL: $url');
    print('📦 Request Body: ${jsonEncode(body)}');
    print('═══════════════════════════════════════════════════════════');

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');
      print('═══════════════════════════════════════════════════════════\n');

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] != null) {
        final responseData = data['data'];
        if (responseData['access_token'] != null) {
          final session = await _db.getUserSession();
          if (session != null) {
            await _db.updateUserSession({
              'id': session['id'],
              'mobile_no': session['mobile_no'],
              'setup_token': null,
              'access_token': responseData['access_token'],
              'refresh_token': responseData['refresh_token'],
              'token_type': responseData['token_type'],
              'expires_in': responseData['expires_in'],
              'profile_data': responseData['profile_data'] ?? 1,
              'owner_id': responseData['user']?['owner_id'],
              'user_name': responseData['user']?['name'],
              'role': responseData['user']?['role'],
            });
            print('✅ Access token saved after profile creation');
          }
        }
      }

      return await _checkResponse(data);
    } catch (e) {
      print('❌ [CREATE PROFILE] ERROR: $e');
      return {
        'success': false,
        'message': 'Failed to create profile: $e',
        'data': null,
        'error_code': 'NETWORK_ERROR',
      };
    }
  }

  /// Refresh the access token using the stored refresh token.
  /// Returns the new access token on success, null on failure.
  Future<String?> refreshAccessToken(String refreshToken) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/auth/refresh');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Key': ApiConstants.apiKey,
      'X-Client-Id': ApiConstants.clientId,
    };
    final body = {'refresh_token': refreshToken};

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔁 [refreshToken] POST $uri');

    try {
      final res = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      debugPrint('📥 [refreshToken] status=${res.statusCode}');
      debugPrint('   body      : ${res.body}');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('❌ [refreshToken] non-2xx — giving up');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      Map<String, dynamic> json = {};
      try {
        json = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      final newToken = json['access_token']?.toString() ??
          json['token']?.toString() ??
          json['data']?['access_token']?.toString();

      if (newToken == null || newToken.isEmpty) {
        debugPrint('❌ [refreshToken] no access_token in response');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      // Persist both tokens (refresh_token may rotate)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', newToken);

      final newRefresh = json['refresh_token']?.toString() ??
          json['data']?['refresh_token']?.toString();
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await prefs.setString('refresh_token', newRefresh);
      }

      final session = await _db.getUserSession();
      if (session != null) {
        await _db.updateUserSession({
          ...session,
          'access_token': newToken,
          if (newRefresh != null && newRefresh.isNotEmpty)
            'refresh_token': newRefresh,
        });
      }

      debugPrint('✅ [refreshToken] new access_token saved');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return newToken;
    } on TimeoutException {
      debugPrint('❌ [refreshToken] timeout');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    } on SocketException catch (e) {
      debugPrint('❌ [refreshToken] network: ${e.message}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    } catch (e) {
      debugPrint('❌ [refreshToken] unknown: $e');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    }
  }

  Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? refresh = prefs.getString('refresh_token');

    if (refresh == null || refresh.isEmpty) {
      final session = await _db.getUserSession();
      refresh = session?['refresh_token']?.toString();
    }

    if (refresh == null || refresh.isEmpty) return null;
    return await refreshAccessToken(refresh);
  }

  // ============================================================
  // MASTER DATA
  // ============================================================

  Future<Map<String, dynamic>> getPorts() async {
    final headers = await _getHeadersWithAccessToken();
    print('📤 [getPorts] REQUEST');

    final response = await _client
        .get(Uri.parse(ApiConstants.ports), headers: headers)
        .timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [getPorts] RESPONSE: ${data['success'] == true ? 'List of ${data['data']?.length} ports' : data}');

    return _checkResponse(data);
  }

  Future<Map<String, dynamic>> getBoats({int page = 1, int pageSize = 20}) async {
    final headers = await _getHeadersWithAccessToken();
    final url = '${ApiConstants.ownerBoats}?page=$page&page_size=$pageSize';
    print('📤 [getBoats] REQUEST: $url');

    final response = await _client.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [getBoats] RESPONSE: ${data['success'] == true ? 'List of boats' : data}');

    return _checkResponse(data);
  }

  Future<Map<String, dynamic>> addBoat({
    required String boatRegNo,
    required String boatName,
    required String licenceId,
    required String licenceIssueDate,
    required String licenceValidUpto,
  }) async {
    final headers = await _getHeadersWithAccessToken();
    final body = {
      'boat_reg_no': boatRegNo,
      'boat_name': boatName,
      'licence_id': licenceId,
      'licence_issue_date': licenceIssueDate,
      'licence_valid_upto': licenceValidUpto,
    };
    print('📤 [addBoat] REQUEST: $body');

    final response = await _client.post(
      Uri.parse(ApiConstants.ownerBoats),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [addBoat] RESPONSE: $data');

    return _checkResponse(data);
  }

  Future<Map<String, dynamic>> getCrewList({int page = 1, int pageSize = 20}) async {
    final headers = await _getHeadersWithAccessToken();
    final url = '${ApiConstants.ownerCrew}?page=$page&page_size=$pageSize';
    print('📤 [getCrewList] REQUEST: $url');

    final response = await _client.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [getCrewList] RESPONSE: ${data['success'] == true ? 'List of crew' : data}');

    return _checkResponse(data);
  }

  Future<Map<String, dynamic>> addCrew({
    required String crewName,
    required String aadhaarNo,
    required String nicRef,
    required String mobileNo,
    required String gender,
    required String crewRole,
    required bool isCaptain,
    required bool canLogin,
    required String emergencyContactName,
    required String emergencyContactNo,
    required String address,
  }) async {
    final String url = ApiConstants.ownerCrew;
    final Map<String, String> headers = await _getHeadersWithAccessToken();

    final Map<String, dynamic> body = {
      'crew_name': crewName,
      'aadhaar_no': aadhaarNo,
      'nic_ref': nicRef,
      'mobile_no': mobileNo,
      'gender': gender,
      'crew_role': crewRole,
      'is_captain': isCaptain,
      'can_login': canLogin,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_no': emergencyContactNo,
      'address_line1': address,
    };

    print('═══════════════════════════════════════════════════════════');
    print('📤 [ADD CREW] REQUEST');
    print('📍 URL: $url');
    print('📦 Request Body: ${jsonEncode(body)}');
    print('═══════════════════════════════════════════════════════════');

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');
      print('═══════════════════════════════════════════════════════════\n');

      final data = jsonDecode(response.body);
      return await _checkResponse(data);
    } catch (e) {
      print('❌ [ADD CREW] ERROR: $e');
      return {
        'success': false,
        'message': 'Failed to add crew: $e',
        'data': null,
        'error_code': 'NETWORK_ERROR',
      };
    }
  }

  // ============================================================
  // INTIMATIONS (VOYAGES)
  // ============================================================

  Future<Map<String, dynamic>> createIntimation(Map<String, dynamic> body) async {
    final headers = await _getHeadersWithAccessToken();
    print('📤 [createIntimation] REQUEST: $body');

    final response = await _client.post(
      Uri.parse(ApiConstants.intimations),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [createIntimation] RESPONSE: $data');

    return _checkResponse(data);
  }

  Future<Map<String, dynamic>> getIntimations({
    int page = 1,
    int pageSize = 20,
    void Function(String errorMessage)? onError,
  }) async {
    final headers = await _getHeadersWithAccessToken();
    final url = '${ApiConstants.intimations}?page=$page&page_size=$pageSize';

    debugPrint('🌐 Fetching voyages from: $url');

    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Status: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        debugPrint('📄 Body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📥 [getIntimations] RESPONSE: Success (List of intimations)');
        return await _checkResponse(data);
      } else if (response.statusCode == 404) {
        debugPrint('❌ ERROR 404: Endpoint not found.');
        debugPrint('   Checked URL: $url');
        debugPrint('   Please update ApiConstants.voyagesPath to the correct path (e.g., /intimations).');
        _notifyError(onError, 'Endpoint not found (404). Please contact support.');
        return {'success': false, 'message': 'Endpoint not found (404)', 'error_code': 'NOT_FOUND'};
      } else {
        debugPrint('❌ HTTP Error ${response.statusCode}: ${response.body}');
        _notifyError(onError, 'Server error ${response.statusCode}. Please try again.');
        final data = jsonDecode(response.body);
        return await _checkResponse(data);
      }
    } catch (e, stack) {
      debugPrint('❌ Network/Parse error in getIntimations: $e\n$stack');
      _notifyError(onError, 'Network error. Please check your connection.');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Robust alternative that returns a List on success
  Future<List<dynamic>> fetchVoyages({
    void Function(String errorMessage)? onError,
  }) async {
    final response = await getIntimations(onError: onError);
    if (response['success'] == true) {
      final data = response['data'];
      if (data is Map && data.containsKey('items')) return data['items'] as List;
      if (data is List) return data;
    }
    return [];
  }

  Future<Map<String, dynamic>> startVoyage({
    required String intimationId,
    required int userId,
    double? latitude,
    double? longitude,
    String? remarks,
  }) async {
    final headers = await _getHeadersWithAccessToken();

    final body = {
      'intimation_id': int.parse(intimationId),
      'user_id': userId,
      'latitude': latitude ?? 0.0,
      'longitude': longitude ?? 0.0,
      'remarks': remarks ?? 'Departed on schedule',
    };
    print('📤 [startVoyage] REQUEST: $body');

    final response = await _client.post(
      Uri.parse(ApiConstants.startTrip),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [startVoyage] RESPONSE: $data');

    return _checkResponse(data);
  }

  Future<Map<String, dynamic>> endTrip({
    required int intimationId,
    required String tripEndDatetime,
    required String endTripSubmitTime,
    required double latitude,
    required double longitude,
    required String all_crew_returned,
    required List<Map<String, dynamic>> crew_returns,
    required int notifiedOfficerId,
    String? tripEndRemarks,
    String? token,
  }) async
  {
    final headers = token != null
        ? ApiConstants.authHeaders(token)
        : await _getHeadersWithAccessToken();

    final body = {
      'intimation_id': intimationId,
      'trip_end_datetime': tripEndDatetime,
      'end_trip_submit_time': endTripSubmitTime,
      'latitude': latitude,
      'longitude': longitude,
      'all_crew_returned': all_crew_returned,
      'crew_returns': crew_returns,
      'notified_officer_id': notifiedOfficerId,
    };
    if (tripEndRemarks != null) body['trip_end_remarks'] = tripEndRemarks;
    print('📤 [endTrip] REQUEST: $body');

    final response = await _client.post(
      Uri.parse(ApiConstants.endTrip),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [endTrip] RESPONSE: $data');

    return _checkResponse(data);
  }

  // ============================================================
  // PING API (Real-time location tracking)
  // ============================================================

  Future<Map<String, dynamic>> sendPing({
    required String? voyageNo,
    int? intimationId,
    required double latitude,
    required double longitude,
    required String timestamp,
    required String token,
    String? deviceId,
    String? pingVia,
    String? versionNo,
  }) async {
    // 1. Resolve voyage_no — never send "UNKNOWN"
    final vNo = (voyageNo != null && voyageNo.trim().isNotEmpty)
        ? voyageNo.trim()
        : (intimationId?.toString() ?? '');

    if (vNo.isEmpty || vNo == 'UNKNOWN') {
      debugPrint('🚫 [sendPing] skipping — no valid voyage_no');
      return {
        'success': false,
        'http_status': null,
        'permanent': true,
        'message': 'no voyage_no',
      };
    }

    // 2. Format timestamp: "yyyy-MM-dd HH:mm:ss" local time
    String p(int n) => n.toString().padLeft(2, '0');
    final dt = DateTime.tryParse(timestamp)?.toLocal() ?? DateTime.now();
    final formatted = '${dt.year}-${p(dt.month)}-${p(dt.day)} '
        '${p(dt.hour)}:${p(dt.minute)}:${p(dt.second)}';

    // 3. Build body — exactly 7 keys as per backend spec
    final body = {
      'voyage_no': vNo,
      'device_id': deviceId ?? 'MOBILE_APP',
      'ping_via': pingVia ?? 'MOBILE_APP',
      'version_no': versionNo ?? '1.4.2',
      'latitude': latitude,
      'longitude': longitude,
      'ping_date_time': formatted,
    };

    // 4. Headers — must include X-API-Key and X-Client-Id
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Key': 'eaSdbEFtN-f5RGzkbjVHGjewUxz7XHDR7F_34PB0DSY',
      'X-Client-Id': 'X-Client-Id',
      'Authorization': 'Bearer $token',
    };

    // 5. POST
    final uri = Uri.parse('https://api.fishing.stepnstones.in/api/v1/pings');

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📤 [sendPing] POST $uri');
    debugPrint('   voyage_no : $vNo');
    debugPrint('   device_id : ${body['device_id']}');
    debugPrint('   ping_dt   : $formatted');
    debugPrint('   lat/lng   : $latitude, $longitude');
    debugPrint('   body      : ${jsonEncode(body)}');

    try {
      final res = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      debugPrint('📥 [sendPing] status=${res.statusCode}');
      debugPrint('   body      : ${res.body}');

      Map<String, dynamic> json = {};
      try {
        json = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      // ✅ 2xx AND success == true
      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          json['success'] == true) {
        debugPrint('✅ [sendPing] ping_id=${json['data']?['ping_id']}');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return {'success': true, 'http_status': res.statusCode, ...json};
      }

      // 🔒 Auth failure — retryable with fresh token
      if (res.statusCode == 401 || res.statusCode == 403) {
        debugPrint('🔒 [sendPing] auth rejected — token invalid/expired');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return {
          'success': false,
          'http_status': res.statusCode,
          'permanent': false,
          'message': json['message'] ?? 'unauthorized',
        };
      }

      // ⚠️ 4xx validation — do NOT retry forever
      if (res.statusCode >= 400 && res.statusCode < 500) {
        debugPrint('❌ [sendPing] client error — payload rejected');
        debugPrint('   message   : ${json['message']}');
        debugPrint('   error_code: ${json['error_code']}');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return {
          'success': false,
          'http_status': res.statusCode,
          'permanent': true,
          'message': json['message'] ?? 'client error',
          'error_code': json['error_code'],
        };
      }

      // 🖥️ 5xx — retryable
      debugPrint('❌ [sendPing] server error (${res.statusCode})');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return {
        'success': false,
        'http_status': res.statusCode,
        'permanent': false,
        'message': json['message'] ?? 'server error',
      };
    } on TimeoutException {
      debugPrint('❌ [sendPing] timeout (20s)');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return {'success': false, 'http_status': null, 'permanent': false, 'message': 'timeout'};
    } on SocketException catch (e) {
      debugPrint('❌ [sendPing] network: ${e.message}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return {'success': false, 'http_status': null, 'permanent': false, 'message': 'network: ${e.message}'};
    } catch (e) {
      debugPrint('❌ [sendPing] unknown: $e');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return {'success': false, 'http_status': null, 'permanent': false, 'message': '$e'};
    }
  }

  // ============================================================
  // SOS & CITING
  // ============================================================

  Future<Map<String, dynamic>> sendSos({
    required int intimationId,
    required double latitude,
    required double longitude,
    required String timestamp,
    String? message,
    required String token,
    String? sosType,
    String? locationSource,
    String? severity,
  }) async {
    const validSources = {'GPS', 'NETWORK', 'MANUAL'};
    const validTypes = {
      'MEDICAL',
      'ENGINE_FAILURE',
      'FIRE',
      'CAPSIZE',
      'MAN_OVERBOARD',
      'PIRACY',
      'WEATHER',
      'FUEL_SHORTAGE',
      'OTHER',
    };
    const validSeverities = {'HIGH', 'MEDIUM', 'LOW'};

    final src = (locationSource ?? 'GPS').toUpperCase();
    final type = (sosType ?? 'OTHER').toUpperCase();
    final sev = (severity ?? 'HIGH').toUpperCase();

    final payload = {
      'intimation_id': intimationId,
      'latitude': latitude,
      'longitude': longitude,
      'location_source': validSources.contains(src) ? src : 'GPS',
      'sos_datetime': timestamp,
      'sos_type': validTypes.contains(type) ? type : 'OTHER',
      'severity': validSeverities.contains(sev) ? sev : 'HIGH',
      'description': message ?? 'SOS Alert',
    };

    final url = Uri.parse('${ApiConstants.baseUrl}/intimations/sos');

    try {
      final headers = token.isNotEmpty
          ? ApiConstants.authHeaders(token)
          : await _getHeadersWithAccessToken();

      final res = await _client
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      Map<String, dynamic> json = {};
      try {
        json = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          (json['success'] == true || json.isEmpty)) {
        return {'success': true, 'http_status': res.statusCode, ...json};
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        return {
          'success': false,
          'http_status': res.statusCode,
          'permanent': false,
          'message': json['message'] ?? 'unauthorized',
        };
      }
      if (res.statusCode >= 400 && res.statusCode < 500) {
        return {
          'success': false,
          'http_status': res.statusCode,
          'permanent': true,
          'message': json['message'] ?? 'client error',
          'error_code': json['error_code'],
        };
      }
      return {
        'success': false,
        'http_status': res.statusCode,
        'permanent': false,
        'message': json['message'] ?? 'server error',
      };
    } on TimeoutException {
      return {'success': false, 'http_status': null, 'permanent': false};
    } on SocketException {
      return {'success': false, 'http_status': null, 'permanent': false};
    } catch (e) {
      return {
        'success': false,
        'http_status': null,
        'permanent': false,
        'message': '$e',
      };
    }
  }

  // Support legacy naming
  Future<Map<String, dynamic>> sendSOS({
    required int intimationId,
    required double latitude,
    required double longitude,
    required String locationSource,
    required String sosDateTime,
    String? sosType,
    String? severity,
    String? description,
  }) async {
    final session = await _db.getUserSession();
    final token = session?['access_token'] ?? '';

    return await sendSos(
      intimationId: intimationId,
      latitude: latitude,
      longitude: longitude,
      timestamp: sosDateTime,
      message: description,
      token: token,
      sosType: sosType,
      locationSource: locationSource,
      severity: severity,
    );
  }

  Future<Map<String, dynamic>> sendCiting({
    required int intimationId,
    required double latitude,
    required double longitude,
    String? citingType,
    String? citingDatetime,
    String? illegalActivityType,
    int? sightedBoatCount,
    String? remarks,
    String? citingReason,
    String? timestamp,
    String? token,
  }) async {
    try {
      final headers = token != null && token.isNotEmpty
          ? ApiConstants.authHeaders(token)
          : await _getHeadersWithAccessToken();

      final body = {
        'intimation_id': intimationId,
        'latitude': latitude,
        'longitude': longitude,
        'citing_type': citingType ?? citingReason ?? 'GENERAL',
        'citing_datetime': timestamp ?? citingDatetime ?? DateTime.now().toIso8601String(),
      };
      if (illegalActivityType != null) body['illegal_activity_type'] = illegalActivityType;
      if (sightedBoatCount != null) body['sighted_boat_count'] = sightedBoatCount;
      if (remarks != null) body['remarks'] = remarks;

      final res = await _client
          .post(
        Uri.parse(ApiConstants.citings),
        headers: headers,
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 20));

      Map<String, dynamic> json = {};
      try {
        json = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          (json['success'] == true || json.isEmpty)) {
        return {'success': true, 'http_status': res.statusCode, ...json};
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        return {
          'success': false,
          'http_status': res.statusCode,
          'permanent': false,
          'message': json['message'] ?? 'unauthorized',
        };
      }
      if (res.statusCode >= 400 && res.statusCode < 500) {
        return {
          'success': false,
          'http_status': res.statusCode,
          'permanent': true,
          'message': json['message'] ?? 'client error',
          'error_code': json['error_code'],
        };
      }
      return {
        'success': false,
        'http_status': res.statusCode,
        'permanent': false,
        'message': json['message'] ?? 'server error',
      };
    } on TimeoutException {
      return {'success': false, 'http_status': null, 'permanent': false};
    } on SocketException {
      return {'success': false, 'http_status': null, 'permanent': false};
    } catch (e) {
      return {
        'success': false,
        'http_status': null,
        'permanent': false,
        'message': '$e',
      };
    }
  }

  // ============================================================
  // FISH SPECIES & CATCH
  // ============================================================

  Future<Map<String, dynamic>> getFishSpecies({
    void Function(String errorMessage)? onError,
  }) async {
    final headers = await _getHeadersWithAccessToken();
    final url = Uri.parse(ApiConstants.fishSpecies);
    debugPrint('🌐 Fetching fish species from: $url');

    try {
      final response = await _client.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Status code: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        debugPrint('📄 Body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
      }

      if (response.statusCode != 200) {
        debugPrint('❌ HTTP error ${response.statusCode}: ${response.body}');
        _notifyError(onError, 'Server error ${response.statusCode}.');
        return {'success': false, 'message': 'HTTP error ${response.statusCode}'};
      }

      if (response.body.isEmpty) {
        debugPrint('⚠️ Response body is empty');
        _notifyError(onError, 'Server returned empty data.');
        return {'success': false, 'message': 'Empty response'};
      }

      final data = jsonDecode(response.body);
      if (data == null) {
        debugPrint('⚠️ JSON decoding resulted in null');
        _notifyError(onError, 'Invalid data format from server.');
        return {'success': false, 'message': 'JSON decoding failed'};
      }

      if (data is Map<String, dynamic>) {
        debugPrint('📥 [getFishSpecies] RESPONSE: Success');
        if (data['data'] != null && data['data'] is List && data['data'].isNotEmpty) {
          debugPrint('🔍 API Fish Species sample keys: ${data['data'][0].keys}');
        }
        return await _checkResponse(data);
      } else {
        debugPrint('⚠️ Response is not a Map, it is: ${data.runtimeType}');
        _notifyError(onError, 'Unexpected data structure.');
        return {'success': false, 'message': 'Invalid response format'};
      }
    } catch (e, stack) {
      debugPrint('❌ Network/parse error in getFishSpecies: $e\n$stack');
      _notifyError(onError, 'Network error. Please check your connection.');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> saveFishDetails({
    required int intimationId,
    required List<Map<String, dynamic>> items,
  }) async {
    final headers = await _getHeadersWithAccessToken();
    final body = {
      'intimation_id': intimationId,
      'items': items,
    };
    print('📤 [saveFishDetails] REQUEST: $body');

    final response = await _client.post(
      Uri.parse(ApiConstants.fishDetails),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [saveFishDetails] RESPONSE: $data');

    return _checkResponse(data);
  }

  // ============================================================
  // OFFICERS & CREW FOR INTIMATION
  // ============================================================

  Future<Map<String, dynamic>> getOfficers() async {
    final headers = await _getHeadersWithAccessToken();
    print('📤 [getOfficers] REQUEST');

    final response = await _client.get(
      Uri.parse(ApiConstants.officers),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [getOfficers] RESPONSE: ${data['success'] == true ? 'List of ${data['data']?.length} officers' : data}');

    return _checkResponse(data);
  }

  Future<Map<String, dynamic>> getIntimationCrew({
    required int intimationId,
    required int boatId,
  }) async {
    final headers = await _getHeadersWithAccessToken();
    final body = {
      'intimation_id': intimationId,
      'boat_id': boatId,
    };
    print('📤 [getIntimationCrew] REQUEST: $body');

    final response = await _client.post(
      Uri.parse(ApiConstants.intimationCrew),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    final data = jsonDecode(response.body);
    print('📥 [getIntimationCrew] RESPONSE: $data');

    return _checkResponse(data);
  }

  // ============================================================
  // SYNC ENDPOINTS
  // ============================================================

  Future<Map<String, dynamic>> syncLocations(
      Map<String, dynamic> payload,
      String token,
      ) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.batchLocationUrl),
        headers: ApiConstants.authHeaders(token),
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 [syncLocations API] Status: ${response.statusCode}');
      debugPrint('📄 [syncLocations API] Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('❌ [syncLocations API] Exception: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> syncSos(
      Map<String, dynamic> payload,
      String token,
      ) async {
    final response = await _client.post(
      Uri.parse(ApiConstants.batchSosUrl),
      headers: ApiConstants.authHeaders(token),
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> syncCitings(
      Map<String, dynamic> payload,
      String token,
      ) async {
    final response = await _client.post(
      Uri.parse(ApiConstants.batchCitingsUrl),
      headers: ApiConstants.authHeaders(token),
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(response.body);
  }

  void dispose() {
    _client.close();
  }

  Future<bool> isConnected() async {
    final List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }
}

// ============================================================
// CUSTOM HTTP CLIENT (Fix TLS/SSL Issues)
// ============================================================

http.Client createCustomClient() {
  final context = SecurityContext.defaultContext;
  context.allowLegacyUnsafeRenegotiation = true;
  final httpClient = HttpClient(context: context);
  return IOClient(httpClient);
}

// ============================================================
// RETRY UTILITY
// ============================================================

Future<T> retryApiCall<T>(
    Future<T> Function() apiCall, {
      int maxRetries = 3,
      Duration delay = const Duration(seconds: 2),
    }) async {
  int attempts = 0;
  while (true) {
    try {
      return await apiCall();
    } catch (e) {
      attempts++;
      if (attempts >= maxRetries) rethrow;
      print('⚠️ API call failed (attempt $attempts/$maxRetries): $e');
      print('🔄 Retrying in ${delay.inSeconds}s...');
      await Future.delayed(delay);
    }
  }
}