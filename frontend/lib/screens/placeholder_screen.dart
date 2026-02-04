// placeholder_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/sidebar.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            isCollapsed: false,
            currentRoute: GoRouter.of(context).routeInformationProvider.value.uri.toString(),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getIconForTitle(title),
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This screen is under development',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'deliverable setup':
        return Icons.task;
      case 'sprint console':
        return Icons.timeline;
      case 'projects':
        return Icons.folder;
      default:
        return Icons.construction;
    }
  }
}
