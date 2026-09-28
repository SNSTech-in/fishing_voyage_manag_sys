class ApiConstants {
  // ============================================================
  // BASE URL
  // ============================================================
  static const String baseUrl = 'https://api.fishing.stepnstones.in/api/v1';

  // ============================================================
  // API KEYS & CLIENT IDS
  // ============================================================
  static const String apiKey = 'eaSdbEFtN-f5RGzkbjVHGjewUxz7XHDR7F_34PB0DSY';
  static const String clientId = 'MOBILE_APP';

  static const String adminApiKey = 'FBClUvFWPFJBlY4Kw7nX-CGwGhgBMklARi-QqNy3gzg';
  static const String adminClientId = 'WEB_ADMIN';

  // ============================================================
  // AUTH ENDPOINTS
  // ============================================================
  static const String sendOtp = '$baseUrl/auth/poc/send-otp';
  static const String verifyOtp = '$baseUrl/auth/poc/verify-otp';
  static const String createProfile = '$baseUrl/auth/poc/create-profile';
  static const String refreshToken = '$baseUrl/auth/refresh';
  static const String adminLogin = '$baseUrl/auth/admin/login';

  // ============================================================
  // MASTERS ENDPOINTS
  // ============================================================
  static const String ports = '$baseUrl/masters/ports';
  static const String officers = '$baseUrl/masters/officers';
  static const String fishSpecies = '$baseUrl/masters/fish-species';

  // ============================================================
  // OWNER ENDPOINTS
  // ============================================================
  static const String ownerBoats = '$baseUrl/owners/me/boats';
  static const String ownerCrew = '$baseUrl/crew';
  static const String intimationCrew = '$baseUrl/intimations/crew';

  // ============================================================
  // INTIMATION / VOYAGE ENDPOINTS
  // ============================================================
  static const String intimations = '$baseUrl/intimations';
  static const String startTrip = '$baseUrl/intimations/start-trip';
  static const String completeTrip = '$baseUrl/intimations/complete-trip';
  static const String citings = '$baseUrl/intimations/citings';
  static const String sos = '$baseUrl/intimations/sos';
  static const String endTrip = '$baseUrl/intimations/end-trip';
  static const String fishDetails = '$baseUrl/intimations/fish-details';

  // ============================================================
  // PING / LOCATION ENDPOINTS
  // ============================================================
  static const String pings = '$baseUrl/pings';

  static String voyagePings(int intimationId) =>
      '$baseUrl/intimations/$intimationId/pings';

  static String voyagePingsAlt(int intimationId) =>
      '$baseUrl/voyages/$intimationId/pings';

  static String pingsQuery(int intimationId) =>
      '$baseUrl/pings?intimation_id=$intimationId';

  // ============================================================
  // ADMIN ENDPOINTS
  // ============================================================
  static const String adminDashboardSummary =
      '$baseUrl/admin/dashboard/summary';

  static const String adminVoyages = '$baseUrl/admin/voyages';

  static const String adminReportFishCatch =
      '$baseUrl/admin/reports/fish-catch';
  static const String adminReportCrewNotReturned =
      '$baseUrl/admin/reports/crew-not-returned';
  static const String adminReportBoatActivity =
      '$baseUrl/admin/reports/boat-activity';
  static const String adminReportSos = '$baseUrl/admin/reports/sos';

  static const String auditLog = '$baseUrl/admin/audit-log';

  // ============================================================
  // ADMIN-LEVEL SOS & CITINGS (WEB_ADMIN client)
  // ============================================================
  static const String adminSos = '$baseUrl/sos';
  static const String adminCitings = '$baseUrl/citings';

  // ⭐ Voyage details (single)
  static String adminVoyageDetails(int intimationId) =>
      '$baseUrl/admin/voyages/$intimationId';

  // ⭐ Citing details (single)
  static String adminCitingDetails(int citingId) =>
      '$baseUrl/citings/$citingId';

  // ⭐ SOS details (single)
  static String adminSosDetails(int sosId) => '$baseUrl/sos/$sosId';

  // ============================================================
  // PUBLIC HEADERS (Mobile App, No Token)
  // ============================================================
  static Map<String, String> get publicHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': apiKey,
    'X-Client-Id': clientId,
  };

  // ============================================================
  // AUTH HEADERS (Mobile App, With Token)
  // ============================================================
  static Map<String, String> authHeaders(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': apiKey,
    'X-Client-Id': clientId,
    if (token != null && token.isNotEmpty)
      'Authorization': 'Bearer $token',
  };

  // ============================================================
  // ADMIN HEADERS (Web Admin, With Token)
  // ============================================================
  static Map<String, String> adminHeaders(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'x-api-key': adminApiKey,
    'x-client-id': adminClientId,
    if (token != null && token.isNotEmpty)
      'Authorization': 'Bearer $token',
  };

  static Map<String, String> get headers => publicHeaders;
}