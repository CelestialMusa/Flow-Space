import 'package:flutter/foundation.dart' show kIsWeb;

class Environment {
  // Environment configuration
  static const String _currentEnvironment = 'SIT'; // Changed from 'PROD' to 'SIT'
  
  // Environment URLs
  static const Map<String, String> _environmentUrls = {
    'PROD': 'https://flow-space.onrender.com/api/v1',
    'SIT': 'http://localhost:3001/api/v1', // Using localhost for SIT testing
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
    print('Current Environment: $_currentEnvironment');
    print('API Base URL: $apiBaseUrl');
    print('Is Production: $isProduction');
    print('Is SIT: $isSIT');
    print('Is Development: $isDevelopment');
  }
}