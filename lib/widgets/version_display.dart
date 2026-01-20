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
    final versionInfo = VersionService.getVersionDetails();
    final environment = versionInfo['environment'] as String;
    
    Color backgroundColor;
    Color textColor;
    
    switch (environment) {
      case 'PROD':
        backgroundColor = Colors.red[900] ?? Colors.red;
        textColor = Colors.white;
        break;
      case 'UAT':
        backgroundColor = Colors.orange[900] ?? Colors.orange;
        textColor = Colors.white;
        break;
      case 'SIT':
        backgroundColor = Colors.grey[900] ?? Colors.grey;
        textColor = Colors.grey[300] ?? Colors.white70;
        break;
      default:
        backgroundColor = Colors.grey[900] ?? Colors.grey;
        textColor = Colors.grey[300] ?? Colors.white70;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey[800] ?? Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: Text(
        '${versionInfo['version']} - $environment Environment',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
