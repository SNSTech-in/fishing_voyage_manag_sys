class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://api.fishing.stepnstones.in/api/v1';

  // 🧪 BATCH SYNC PATHS (Change these to test different endpoints)
  static const String batchLocationPath = '/locations/batch';
  static const String batchSosPath = '/intimations/sos/batch';
  static const String batchCitingsPath = '/intimations/citings/batch';

  static String get batchLocationUrl => '$baseUrl$batchLocationPath';
  static String get batchSosUrl => '$baseUrl$batchSosPath';
  static String get batchCitingsUrl => '$baseUrl$batchCitingsPath';

  // Auth Endpoints
  static const String sendOtp = '$baseUrl/auth/poc/send-otp';
  static const String verifyOtp = '$baseUrl/auth/poc/verify-otp';
  static const String createProfile = '$baseUrl/auth/poc/create-profile';
  static const String refreshToken = '$baseUrl/auth/refresh';

  // Masters Endpoints
  static const String ports = '$baseUrl/masters/ports';
  static const String officers = '$baseUrl/masters/officers';
  static const String fishSpecies = '$baseUrl/masters/fish-species';

  // Owner Endpoints
  static const String ownerBoats = '$baseUrl/owners/me/boats';
  static const String ownerCrew = '$baseUrl/crew';
  static const String intimationCrew = '$baseUrl/intimations/crew';

  // Intimation Endpoints
  static const String intimations = '$baseUrl/intimations';
  static const String startTrip = '$baseUrl/intimations/start-trip';
  static const String completeTrip = '$baseUrl/intimations/complete-trip';
  static const String citings = '$baseUrl/intimations/citings';
  static const String sos = '$baseUrl/intimations/sos';
  static const String endTrip = '$baseUrl/intimations/end-trip';
  static const String fishDetails = '$baseUrl/intimations/fish-details';

  // Report Endpoints
  static const String sosReport = '$baseUrl/reports/sos';
  static const String fishCatchReport = '$baseUrl/reports/fish-catch';
  static const String crewNotReturnedReport = '$baseUrl/reports/crew-not-returned';
  static const String boatActivityReport = '$baseUrl/reports/boat-activity';

  // Officer Endpoints
  static const String officerStats = '$baseUrl/officer/stats';

  // API Keys
  static const String apiKey = 'eaSdbEFtN-f5RGzkbjVHGjewUxz7XHDR7F_34PB0DSY';
  static const String clientId = 'MOBILE_APP';

  // Public Headers (Without Token)
  static Map<String, String> get publicHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': apiKey,
    'X-Client-Id': clientId,
  };

  // Auth Headers with Token
  static Map<String, String> authHeaders(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': apiKey,
    'X-Client-Id': clientId,
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  static Map<String, String> get headers => publicHeaders;
}
