// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.toString();
    
    return Row(
      children: [
        // Main content
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Dashboard Content',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Current Route: $currentRoute',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Role: Delivery Lead',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
