import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../components/sidebar.dart';
import '../providers/theme_provider.dart';

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
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark),
      ),
      themeMode: themeMode,
      home: Scaffold(
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
            // Main content area - THIS IS THE KEY!
            Expanded(
              child: child,
            ),
          ],
        ),
        // FAB that shows on ALL pages within the shell
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('FAB WORKS! Inside ShellRoute'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/project-setup');
          },
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
