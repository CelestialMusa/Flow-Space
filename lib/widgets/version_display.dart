import 'package:flutter/material.dart';
import '../services/version_service.dart';

class VersionDisplay extends StatelessWidget {
  const VersionDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final versionInfo = VersionService.getVersionDetails();
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Version: ${versionInfo['version']}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Environment: ${versionInfo['environment']}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
          Text(
            'Build Date: ${versionInfo['year']}-${versionInfo['month'].toString().padLeft(2, '0')}-${versionInfo['day'].toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
          Text(
            'Week ${versionInfo['weekNumber']}, Day ${versionInfo['dayOfWeek']}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class VersionBanner extends StatelessWidget {
  const VersionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Return empty container to hide banner completely
    return const SizedBox.shrink();
    
    // Original banner code (commented out)
    /*
    final versionInfo = VersionService.getVersionDetails();
    final environment = versionInfo['environment'] as String;
    
    Color textColor;
    
    switch (environment) {
      case 'PROD':
        textColor = Colors.red[300] ?? Colors.red;
        break;
      case 'UAT':
        textColor = Colors.orange[300] ?? Colors.orange;
        break;
      case 'SIT':
        textColor = Colors.grey[400] ?? Colors.white70;
        break;
      default:
        textColor = Colors.grey[400] ?? Colors.white70;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${versionInfo['version']} - $environment',
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
    );
    */
  }
}
