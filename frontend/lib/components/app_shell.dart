import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final sidebarProvider = StateProvider<bool>((ref) => false);

class AppShell extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const AppShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSidebarCollapsed = ref.watch(sidebarProvider);

    // Debug logging
    debugPrint('🔍 AppShell BUILD - currentRoute: $currentRoute');
    debugPrint('🔍 AppShell BUILD - shouldShowFAB: ${currentRoute == '/projects'}');

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            isCollapsed: isSidebarCollapsed,
            onToggle: (collapsed) {
              ref.read(sidebarProvider.notifier).state = collapsed;
            },
            currentRoute: currentRoute,
          ),
          // Main content area
          Expanded(
            child: child,
          ),
        ],
      ),
      // FAB that ONLY shows on /projects page
      floatingActionButton: currentRoute == '/projects'
          ? FloatingActionButton(
              onPressed: () => context.go('/projects/create'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class Sidebar extends StatelessWidget {
  final bool isCollapsed;
  final Function(bool) onToggle;
  final String currentRoute;

  const Sidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 80 : 240,
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  const Text(
                    'Khonology',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                  ),
                  onPressed: () => onToggle(!isCollapsed),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SidebarItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: '/dashboard',
                  currentRoute: currentRoute,
                  isCollapsed: isCollapsed,
                ),
                SidebarItem(
                  icon: Icons.timer,
                  label: 'Sprints',
                  route: '/sprint-console',
                  currentRoute: currentRoute,
                  isCollapsed: isCollapsed,
                ),
                SidebarItem(
                  icon: Icons.list,
                  label: 'Deliverables',
                  route: '/deliverable-setup',
                  currentRoute: currentRoute,
                  isCollapsed: isCollapsed,
                ),
                // 🔴 Projects tab — THIS IS THE MISSING PIECE
                SidebarItem(
                  icon: Icons.folder,
                  label: 'Projects 🚀',
                  route: '/projects',
                  currentRoute: currentRoute,
                  isCollapsed: isCollapsed,
                ),
                SidebarItem(
                  icon: Icons.person,
                  label: 'Profile',
                  route: '/profile',
                  currentRoute: currentRoute,
                  isCollapsed: isCollapsed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final bool isCollapsed;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;

    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
              size: 20,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
