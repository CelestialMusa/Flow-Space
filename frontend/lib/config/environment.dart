import 'package:flutter/foundation.dart';

class Environment {
  // Environment configuration
  static const String _currentEnvironment = 'PROD'; // Temporarily use PROD to test
  
  // Environment URLs
  static const Map<String, String> _environmentUrls = {
    'PROD': 'https://flow-space.onrender.com/api/v1',
    'SIT': 'http://localhost:3001/api/v1', // Using port 3001 for SIT testing
    'DEV': 'http://localhost:3001/api/v1',
    'LOCAL': 'http://localhost:3001/api/v1',
  };
  
  static String get apiBaseUrl => _environmentUrls[_currentEnvironment] ?? _environmentUrls['DEV']!;
  static const int apiTimeout = 30000;
  
  // Environment helpers
  static bool get isProduction => _currentEnvironment == 'PROD';
  static bool get isSIT => _currentEnvironment == 'SIT';
  static bool get isDevelopment => _currentEnvironment == 'DEV' || _currentEnvironment == 'LOCAL';
  static String get currentEnvironment => _currentEnvironment;
  
  // Debug information
  static void logEnvironmentInfo() {
    debugPrint('Current Environment: $_currentEnvironment');
    debugPrint('API Base URL: $apiBaseUrl');
    debugPrint('Is Production: $isProduction');
    debugPrint('Is SIT: $isSIT');
    debugPrint('Is Development: $isDevelopment');
  }
}