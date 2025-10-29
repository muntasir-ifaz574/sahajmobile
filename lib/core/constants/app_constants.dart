class AppConstants {
  // App Information
  static const String appName = 'SAHAJMOBILE';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://sm.sahajmobile.org';
  static const String apiVersion = '/api';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_completed';

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const int nidLength = 10;
  static const int phoneNumberLength = 11;

  // Age Requirements
  static const int minAge = 19;
  static const int maxAge = 54;

  // Service Fee Rate
  static const double serviceFeeRate = 0.02; // 2% per month
}
