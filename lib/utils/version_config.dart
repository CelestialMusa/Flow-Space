class VersionConfig {
  static const String currentVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String environment = 'PROD';
  
  static Map<String, dynamic> getVersionConfig() {
    return {
      'version': currentVersion,
      'buildNumber': buildNumber,
      'environment': environment,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  static String getFullVersion() {
    return '$currentVersion+$buildNumber';
  }
  
  static bool isProduction() {
    return environment == 'PROD';
  }
  
  static bool isStaging() {
    return environment == 'UAT';
  }
  
  static bool isDevelopment() {
    return environment == 'DEV' || environment == 'SIT';
  }
}
