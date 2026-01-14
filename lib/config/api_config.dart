class ApiConfig {
  static String _baseUrl = 'http://localhost:3000';

  static String get baseUrl => _baseUrl;
  static String get wsUrl => _baseUrl.replaceFirst('http', 'ws');

  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  static Map<String, String> getAuthHeaders(String? token) {
    final headers = {'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Endpoints
  static String get loginEndpoint => '$baseUrl/api/auth/login';
  static String get refreshTokenEndpoint => '$baseUrl/api/auth/refresh-token';
  static String get turnCredentialsEndpoint => '$baseUrl/api/turn/credentials';
  static String get turnEndpoint => '/turn/credentials';
  static String get healthEndpoint => '$baseUrl/api/health';
  static String get myRoutesEndpoint => '$baseUrl/api/routes/my-routes';
  static String get saveRouteEndpoint => '$baseUrl/api/routes/save';

  static String routeDetailEndpoint(String routeId) =>
      '$baseUrl/api/routes/$routeId';
  static String exportRouteEndpoint(
    String routeId,
    String format,
    bool anonymize,
    int radius,
  ) {
    return '$baseUrl/api/routes/$routeId/export?format=$format&anonymize=$anonymize&radius=$radius';
  }
}
