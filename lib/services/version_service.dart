import '../utils/version_control.dart';

class VersionService {
  static String getCurrentVersion() {
    return VersionControl.generateVersionNumber();
  }
  
  static Map<String, dynamic> getVersionDetails() {
    return VersionControl.getVersionInfo();
  }
  
  static String getEnvironment() {
    return VersionControl.environment;
  }
  
  static bool isProductionEnvironment() {
    return VersionControl.environment == 'PROD';
  }
  
  static bool isStagingEnvironment() {
    return VersionControl.environment == 'SIT' || VersionControl.environment == 'UAT';
  }
  
  static bool isDevelopmentEnvironment() {
    return VersionControl.environment == 'DEV';
  }
}
