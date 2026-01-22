import '../utils/version_control.dart';

class VersionService {
  static Map<String, dynamic> getVersionDetails() {
    return VersionControl.getVersionInfo();
  }
  
  static String getCurrentVersion() {
    return VersionControl.generateVersionNumber();
  }
  
  static String getEnvironment() {
    return VersionControl.environment;
  }
  
  static String getFormattedVersionInfo() {
    return VersionControl.getFormattedVersionInfo();
  }
  
  static bool isProductionEnvironment() {
    return VersionControl.isProductionEnvironment();
  }
  
  static bool isStagingEnvironment() {
    return VersionControl.isStagingEnvironment();
  }
  
  static bool isDevelopmentEnvironment() {
    return VersionControl.isDevelopmentEnvironment();
  }
}
