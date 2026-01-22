// ignore_for_file: prefer_single_quotes

class Environment {
  // App Configuration
  static const String appName = 'Khonology';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A social learning platform built with Flutter';

  // API Configuration - Use const for production URL from build
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: "http://localhost:3001/api/v1",
  );
  
  static String get apiBaseUrl => _apiBaseUrl;
  static const int apiTimeout = 30000;

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;

  // Development Settings
  static const bool debugMode = bool.fromEnvironment('DEBUG_MODE', defaultValue: true);
  static const String logLevel = 'debug';

  // Environment-specific configurations
  static bool get isProduction => !debugMode;
  static bool get isDevelopment => debugMode;
  
  // Check if running on Render.com
  static bool get isRenderDeployed => apiBaseUrl.contains('onrender.com');
}
