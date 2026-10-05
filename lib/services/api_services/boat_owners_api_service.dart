// lib/services/boat_owners_api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import '../../database/database_helper.dart';

class BoatOwnwesApiService {
  final http.Client _client = createCustomClient();
  final DatabaseHelper _db = DatabaseHelper();

  static GlobalKey<NavigatorState>? navigatorKey;

  void _notifyError(void Function(String)? onError, String message) {
    if (onError != null) onError(message);
  }

  // ============================================================
  // 🔍 LOGGING HELPERS
  // ============================================================

  void _logRequest(String tag, String method, Uri url, Map<String, String> headers, {Object? body}) {
    debugPrint('┌─── 📤 [$tag] REQUEST ──────────────────────────────');
    debugPrint('│ $method $url');
    debugPrint('│ X-Client-Id : ${headers['X-Client-Id'] ?? headers['x-client-id'] ?? '-'}');
    debugPrint('│ X-API-Key   : ${_mask(headers['X-API-Key'] ?? headers['x-api-key'])}');
    debugPrint('│ Auth        : ${_maskAuth(headers['Authorization'] ?? headers['authorization'])}');
    if (body != null) {
      debugPrint('│ Body        : ${_prettyBody(body)}');
    }
    debugPrint('└────────────────────────────────────────────────────');
  }

  void _logResponse(String tag, http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    debugPrint('┌─── 📥 [$tag] RESPONSE ─────────────────────────────');
    debugPrint('│ Status      : ${res.statusCode} ${ok ? "✅ OK" : "❌ FAILED"}');
    debugPrint('│ Body        : ${_preview(res.body)}');
    debugPrint('└────────────────────────────────────────────────────');
  }

  void _logError(String tag, Object e, [StackTrace? st]) {
    debugPrint('┌─── 💥 [$tag] EXCEPTION ────────────────────────────');
    debugPrint('│ $e');
    if (st != null) debugPrint('│ $st');
    debugPrint('└────────────────────────────────────────────────────');
  }

  void _logSkip(String tag, String reason) {
    debugPrint('⚠️ [$tag] SKIPPED — $reason');
  }

  String _mask(String? key) {
    if (key == null) return '-';
    if (key.length < 12) return key;
    return '${key.substring(0, 8)}...${key.substring(key.length - 4)}';
  }

  String _maskAuth(String? auth) {
    if (auth == null) return '❌ MISSING';
    if (auth.length < 20) return auth;
    return '${auth.substring(0, 17)}...${auth.substring(auth.length - 6)}';
  }

  String _preview(String body) {
    if (body.isEmpty) return '(empty)';
    return body.length > 400 ? '${body.substring(0, 400)}...' : body;
  }

  String _prettyBody(Object? body) {
    if (body == null) return 'null';
    try {
      final decoded = body is String ? jsonDecode(body) : body;
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return body.toString();
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
      } else {
        debugPrint('⚠️ [_getHeadersWithAccessToken] session exists but no token');
      }
    } else {
      debugPrint('⚠️ [_getHeadersWithAccessToken] no session in DB');
    }
    return headers;
  }

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
    debugPrint('🔓 [_handleTokenExpired] clearing session and navigating to login');
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
      debugPrint('⚠️ [_checkResponse] success=false — error_code=${data['error_code']} message=${data['message']}');
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
    final url = Uri.parse(ApiConstants.sendOtp);
    _logRequest('sendOtp', 'POST', url, ApiConstants.publicHeaders, body: body);

    try {
      final response = await _client.post(
        url,
        headers: ApiConstants.publicHeaders,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      _logResponse('sendOtp', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('sendOtp', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String mobileNo, String otp) async {
    final body = {'mobile_no': mobileNo, 'otp': otp};
    final url = Uri.parse(ApiConstants.verifyOtp);
    _logRequest('verifyOtp', 'POST', url, ApiConstants.publicHeaders, body: body);

    try {
      final response = await _client.post(
        url,
        headers: ApiConstants.publicHeaders,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      _logResponse('verifyOtp', response);
      final data = jsonDecode(response.body);

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
    } catch (e, st) {
      _logError('verifyOtp', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
  }

  Future<Map<String, dynamic>> createProfile({
    required String ownerName,
    required String aadhaarNo,
    required String primaryPortId,
    required String otp,
    required String mobileNo,
    required String address,
  }) async {
    final url = Uri.parse(ApiConstants.createProfile);
    final headers = await _getHeadersWithSetupToken();

    final body = {
      'owner_name': ownerName,
      'aadhaar_no': aadhaarNo,
      'primary_port_id': primaryPortId,
      'mobile_no': mobileNo,
      'address': address,
    };

    _logRequest('createProfile', 'POST', url, headers, body: body);

    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      _logResponse('createProfile', response);
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
    } catch (e, st) {
      _logError('createProfile', e, st);
      return {
        'success': false,
        'message': 'Failed to create profile: $e',
        'data': null,
        'error_code': 'NETWORK_ERROR',
      };
    }
  }

  Future<String?> refreshAccessToken(String refreshToken) async {
    final uri = Uri.parse(ApiConstants.refreshToken);
    final headers = ApiConstants.publicHeaders;
    final body = {'refresh_token': refreshToken};

    _logRequest('refreshToken', 'POST', uri, headers, body: body);

    try {
      final res = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      _logResponse('refreshToken', res);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('❌ [refreshToken] non-2xx — giving up');
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
        return null;
      }

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
      return newToken;
    } on TimeoutException {
      debugPrint('❌ [refreshToken] timeout');
      return null;
    } on SocketException catch (e) {
      debugPrint('❌ [refreshToken] network: ${e.message}');
      return null;
    } catch (e, st) {
      _logError('refreshToken', e, st);
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

    if (refresh == null || refresh.isEmpty) {
      debugPrint('❌ [refreshToken] no refresh token stored anywhere');
      return null;
    }
    return await refreshAccessToken(refresh);
  }

  // ============================================================
  // MASTER DATA
  // ============================================================

  Future<Map<String, dynamic>> getPorts() async {
    final headers = await _getHeadersWithAccessToken();
    final url = Uri.parse(ApiConstants.ports);
    _logRequest('getPorts', 'GET', url, headers);

    try {
      final response = await _client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      _logResponse('getPorts', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('getPorts', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
  }

  Future<Map<String, dynamic>> getBoats({int page = 1, int pageSize = 20}) async {
    final headers = await _getHeadersWithAccessToken();
    final url = Uri.parse('${ApiConstants.ownerBoats}?page=$page&page_size=$pageSize');
    _logRequest('getBoats', 'GET', url, headers);

    try {
      final response = await _client.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      _logResponse('getBoats', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('getBoats', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
  }

  Future<Map<String, dynamic>> addBoat({
    required String boatRegNo,
    required String boatName,
    required String licenceId,
    required String licenceIssueDate,
    required String licenceValidUpto,
  }) async {
    final headers = await _getHeadersWithAccessToken();
    final url = Uri.parse(ApiConstants.ownerBoats);
    final body = {
      'boat_reg_no': boatRegNo,
      'boat_name': boatName,
      'licence_id': licenceId,
      'licence_issue_date': licenceIssueDate,
      'licence_valid_upto': licenceValidUpto,
    };

    _logRequest('addBoat', 'POST', url, headers, body: body);

    try {
      final response = await _client.post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      _logResponse('addBoat', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('addBoat', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
  }

  Future<Map<String, dynamic>> getCrewList({int page = 1, int pageSize = 20}) async {
    final headers = await _getHeadersWithAccessToken();
    final url = Uri.parse('${ApiConstants.ownerCrew}?page=$page&page_size=$pageSize');
    _logRequest('getCrewList', 'GET', url, headers);

    try {
      final response = await _client.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      _logResponse('getCrewList', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('getCrewList', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
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
    final url = Uri.parse(ApiConstants.ownerCrew);
    final headers = await _getHeadersWithAccessToken();

    final body = {
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

    _logRequest('addCrew', 'POST', url, headers, body: body);

    try {
      final response = await _client.post(url, headers: headers, body: jsonEncode(body));
      _logResponse('addCrew', response);
      final data = jsonDecode(response.body);
      return await _checkResponse(data);
    } catch (e, st) {
      _logError('addCrew', e, st);
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
    final url = Uri.parse(ApiConstants.intimations);
    _logRequest('createIntimation', 'POST', url, headers, body: body);

    try {
      final response = await _client.post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      _logResponse('createIntimation', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('createIntimation', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
  }

  Future<Map<String, dynamic>> getIntimations({
    int page = 1,
    int pageSize = 20,
    void Function(String errorMessage)? onError,
  }) async {
    final headers = await _getHeadersWithAccessToken();
    final url = Uri.parse('${ApiConstants.intimations}?page=$page&page_size=$pageSize');

    _logRequest('getIntimations', 'GET', url, headers);

    try {
      final response = await _client.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      _logResponse('getIntimations', response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return await _checkResponse(data);
      } else if (response.statusCode == 404) {
        debugPrint('❌ [getIntimations] 404 — endpoint not found: $url');
        _notifyError(onError, 'Endpoint not found (404). Please contact support.');
        return {'success': false, 'message': 'Endpoint not found (404)', 'error_code': 'NOT_FOUND'};
      } else {
        _notifyError(onError, 'Server error ${response.statusCode}. Please try again.');
        final data = jsonDecode(response.body);
        return await _checkResponse(data);
      }
    } catch (e, st) {
      _logError('getIntimations', e, st);
      _notifyError(onError, 'Network error. Please check your connection.');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

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
    final url = Uri.parse(ApiConstants.startTrip);

    final body = {
      'intimation_id': int.parse(intimationId),
      'user_id': userId,
      'latitude': latitude ?? 0.0,
      'longitude': longitude ?? 0.0,
      'remarks': remarks ?? 'Departed on schedule',
    };

    _logRequest('startVoyage', 'POST', url, headers, body: body);

    try {
      final response = await _client.post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      _logResponse('startVoyage', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('startVoyage', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
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
  }) async {
    final headers = token != null
        ? ApiConstants.authHeaders(token)
        : await _getHeadersWithAccessToken();

    final url = Uri.parse(ApiConstants.endTrip);

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

    _logRequest('endTrip', 'POST', url, headers, body: body);

    try {
      final response = await _client.post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      _logResponse('endTrip', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('endTrip', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
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
    final vNo = (voyageNo != null && voyageNo.trim().isNotEmpty)
        ? voyageNo.trim()
        : (intimationId?.toString() ?? '');

    if (vNo.isEmpty || vNo == 'UNKNOWN') {
      _logSkip('sendPing', 'no valid voyage_no (voyageNo=$voyageNo intimationId=$intimationId)');
      return {
        'success': false,
        'http_status': null,
        'permanent': true,
        'message': 'no voyage_no',
      };
    }

    String p(int n) => n.toString().padLeft(2, '0');
    final dt = DateTime.tryParse(timestamp)?.toLocal() ?? DateTime.now();
    final formatted = '${dt.year}-${p(dt.month)}-${p(dt.day)} '
        '${p(dt.hour)}:${p(dt.minute)}:${p(dt.second)}';

    final body = {
      'voyage_no': vNo,
      'device_id': deviceId ?? 'MOBILE_APP',
      'ping_via': pingVia ?? 'MOBILE_APP',
      'version_no': versionNo ?? '1.4.2',
      'latitude': latitude,
      'longitude': longitude,
      'ping_date_time': formatted,
    };

    final headers = ApiConstants.authHeaders(token);
    final uri = Uri.parse(ApiConstants.pings);

    _logRequest('sendPing', 'POST', uri, headers, body: body);

    try {
      final res = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      _logResponse('sendPing', res);

      Map<String, dynamic> json = {};
      try {
        json = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          json['success'] == true) {
        debugPrint('✅ [sendPing] ping_id=${json['data']?['ping_id']}');
        return {'success': true, 'http_status': res.statusCode, ...json};
      }

      if (res.statusCode == 401 || res.statusCode == 403) {
        debugPrint('🔒 [sendPing] auth rejected — token invalid/expired');
        return {
          'success': false,
          'http_status': res.statusCode,
          'permanent': false,
          'message': json['message'] ?? 'unauthorized',
        };
      }

      if (res.statusCode >= 400 && res.statusCode < 500) {
        debugPrint('❌ [sendPing] client error — payload rejected');
        return {
          'success': false,
          'http_status': res.statusCode,
          'permanent': true,
          'message': json['message'] ?? 'client error',
          'error_code': json['error_code'],
        };
      }

      debugPrint('❌ [sendPing] server error (${res.statusCode})');
      return {
        'success': false,
        'http_status': res.statusCode,
        'permanent': false,
        'message': json['message'] ?? 'server error',
      };
    } on TimeoutException {
      _logError('sendPing', 'timeout (20s)');
      return {'success': false, 'http_status': null, 'permanent': false, 'message': 'timeout'};
    } on SocketException catch (e) {
      _logError('sendPing', 'network: ${e.message}');
      return {'success': false, 'http_status': null, 'permanent': false, 'message': 'network: ${e.message}'};
    } catch (e, st) {
      _logError('sendPing', e, st);
      return {'success': false, 'http_status': null, 'permanent': false, 'message': '$e'};
    }
  }

  /// Fetch the full ping history for a voyage from the server.
  ///
  /// Used by the route map to reconstruct the travelled route after a
  /// reinstall (local SQLite is wiped on uninstall).
  ///
  /// Tries multiple plausible endpoint shapes so this works regardless
  /// of whether the backend exposes /voyages/{id}/locations or /pings?voyage_no=...
  Future<Map<String, dynamic>> getVoyageLocations({
    required int intimationId,
    String? voyageNo,
  }) async {
    final headers = await _getHeadersWithAccessToken();

    final candidateUris = <Uri>[
      Uri.parse('${ApiConstants.baseUrl}/boat-owner/voyages/$intimationId/locations'),
      Uri.parse('${ApiConstants.intimations}/$intimationId/locations'),
      if (voyageNo != null && voyageNo.isNotEmpty)
        Uri.parse('${ApiConstants.pings}?voyage_no=$voyageNo'),
    ];

    Object? lastError;

    for (final uri in candidateUris) {
      _logRequest('getVoyageLocations', 'GET', uri, headers);
      try {
        final response = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 25));

        _logResponse('getVoyageLocations', response);

        if (response.statusCode == 404) {
          // Try the next candidate.
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          lastError = 'HTTP ${response.statusCode}';
          continue;
        }

        Map<String, dynamic> json = {};
        try {
          json = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          lastError = 'Invalid JSON from $uri';
          continue;
        }

        // Normalize common shapes to a `locations` list.
        List<dynamic> raw = const [];
        final data = json['data'];
        if (data is Map && data['locations'] is List) {
          raw = data['locations'] as List;
        } else if (data is List) {
          raw = data;
        } else if (json['locations'] is List) {
          raw = json['locations'] as List;
        } else if (json['items'] is List) {
          raw = json['items'] as List;
        }

        final normalized = <Map<String, dynamic>>[];
        for (final item in raw) {
          if (item is! Map) continue;
          final lat = (item['latitude'] as num?)?.toDouble();
          final lng = (item['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;
          final ts = (item['ping_date_time'] ??
                  item['timestamp'] ??
                  item['created_at'] ??
                  '')
              .toString();
          normalized.add({
            'latitude': lat,
            'longitude': lng,
            'timestamp': ts,
            'voyage_no': item['voyage_no']?.toString() ?? voyageNo ?? '',
          });
        }

        return {'success': true, 'locations': normalized};
      } catch (e, st) {
        lastError = e;
        _logError('getVoyageLocations', e, st);
      }
    }

    return {
      'success': false,
      'locations': const <Map<String, dynamic>>[],
      'message': 'All candidate endpoints failed: $lastError',
    };
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
      'MEDICAL','ENGINE_FAILURE','FIRE','CAPSIZE','MAN_OVERBOARD',
      'PIRACY','WEATHER','FUEL_SHORTAGE','OTHER',
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

    final url = Uri.parse(ApiConstants.sos);
    final headers = token.isNotEmpty
        ? ApiConstants.authHeaders(token)
        : await _getHeadersWithAccessToken();

    _logRequest('sendSos', 'POST', url, headers, body: payload);

    try {
      final res = await _client
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      _logResponse('sendSos', res);

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
      _logError('sendSos', 'timeout');
      return {'success': false, 'http_status': null, 'permanent': false};
    } on SocketException catch (e) {
      _logError('sendSos', 'network: ${e.message}');
      return {'success': false, 'http_status': null, 'permanent': false};
    } catch (e, st) {
      _logError('sendSos', e, st);
      return {
        'success': false,
        'http_status': null,
        'permanent': false,
        'message': '$e',
      };
    }
  }

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
    final headers = token != null && token.isNotEmpty
        ? ApiConstants.authHeaders(token)
        : await _getHeadersWithAccessToken();

    final url = Uri.parse(ApiConstants.citings);

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

    _logRequest('sendCiting', 'POST', url, headers, body: body);

    try {
      final res = await _client
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      _logResponse('sendCiting', res);

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
      _logError('sendCiting', 'timeout');
      return {'success': false, 'http_status': null, 'permanent': false};
    } on SocketException catch (e) {
      _logError('sendCiting', 'network: ${e.message}');
      return {'success': false, 'http_status': null, 'permanent': false};
    } catch (e, st) {
      _logError('sendCiting', e, st);
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
    _logRequest('getFishSpecies', 'GET', url, headers);

    try {
      final response = await _client.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      _logResponse('getFishSpecies', response);

      if (response.statusCode != 200) {
        _notifyError(onError, 'Server error ${response.statusCode}.');
        return {'success': false, 'message': 'HTTP error ${response.statusCode}'};
      }

      if (response.body.isEmpty) {
        _notifyError(onError, 'Server returned empty data.');
        return {'success': false, 'message': 'Empty response'};
      }

      final data = jsonDecode(response.body);
      if (data == null) {
        _notifyError(onError, 'Invalid data format from server.');
        return {'success': false, 'message': 'JSON decoding failed'};
      }

      if (data is Map<String, dynamic>) {
        return await _checkResponse(data);
      } else {
        _notifyError(onError, 'Unexpected data structure.');
        return {'success': false, 'message': 'Invalid response format'};
      }
    } catch (e, st) {
      _logError('getFishSpecies', e, st);
      _notifyError(onError, 'Network error. Please check your connection.');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> saveFishDetails({
    required int intimationId,
    required List<Map<String, dynamic>> items,
  }) async {
    final headers = await _getHeadersWithAccessToken();
    final url = Uri.parse(ApiConstants.fishDetails);
    final body = {
      'intimation_id': intimationId,
      'items': items,
    };

    _logRequest('saveFishDetails', 'POST', url, headers, body: body);

    try {
      final response = await _client.post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      _logResponse('saveFishDetails', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('saveFishDetails', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
  }

  // ============================================================
  // OFFICERS & CREW FOR INTIMATION
  // ============================================================

  Future<Map<String, dynamic>> getOfficers() async {
    final headers = await _getHeadersWithAccessToken();
    final url = Uri.parse(ApiConstants.officers);
    _logRequest('getOfficers', 'GET', url, headers);

    try {
      final response = await _client.get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      _logResponse('getOfficers', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('getOfficers', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
  }

  Future<Map<String, dynamic>> getIntimationCrew({
    required int intimationId,
    required int boatId,
  }) async {
    final headers = await _getHeadersWithAccessToken();
    final url = Uri.parse(ApiConstants.intimationCrew);
    final body = {
      'intimation_id': intimationId,
      'boat_id': boatId,
    };

    _logRequest('getIntimationCrew', 'POST', url, headers, body: body);

    try {
      final response = await _client.post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      _logResponse('getIntimationCrew', response);
      final data = jsonDecode(response.body);
      return _checkResponse(data);
    } catch (e, st) {
      _logError('getIntimationCrew', e, st);
      return {'success': false, 'message': e.toString(), 'error_code': 'NETWORK_ERROR'};
    }
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