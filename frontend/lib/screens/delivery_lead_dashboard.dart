import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/project_floating_action_button.dart';

class DeliveryLeadDashboard extends ConsumerWidget {
  const DeliveryLeadDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.toString();
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar placeholder - this will be handled by MainLayout
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Delivery Lead Dashboard',
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
                    const Text(
                      'FAB should be visible in bottom-right corner',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const ProjectFloatingActionButton(),
    );
  }
}
