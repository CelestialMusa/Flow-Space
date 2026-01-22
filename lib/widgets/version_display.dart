import 'package:flutter/material.dart';
import '../services/version_service.dart';
import 'package:google_fonts/google_fonts.dart';

class VersionDisplay extends StatelessWidget {
  const VersionDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final versionInfo = VersionService.getVersionDetails();
    final environment = versionInfo['environment'] as String;
    
    // Environment-specific colors
    Color textColor;
    Color bgColor;
    
    switch (environment) {
      case 'PROD':
        textColor = Colors.red[300] ?? Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        break;
      case 'UAT':
        textColor = Colors.orange[300] ?? Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'SIT':
        textColor = Colors.blue[300] ?? Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.1);
        break;
      default:
        textColor = Colors.grey[400] ?? Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        '${versionInfo['version']} - $environment',
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
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
  }
}
