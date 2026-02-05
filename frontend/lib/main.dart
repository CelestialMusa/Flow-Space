import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/delivery_lead_dashboard.dart';
import 'screens/deliverable_setup_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/project_detail_screen.dart';
import 'screens/project_setup_screen.dart';
import 'screens/project_create_screen.dart';
import 'screens/sprint_console_screen.dart';
import 'screens/signoff_report_builder_screen.dart';
import 'screens/client_review_screen.dart';
import 'screens/audit_trail_screen.dart';
import 'screens/repository_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'components/app_shell.dart';
import 'screens/client_reviewer_dashboard.dart';
import 'screens/qa_engineer_dashboard.dart';
import 'screens/system_admin_dashboard.dart';
import 'models/user_role.dart';
import 'providers/api_auth_riverpod_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize API Service
    await ApiService.initialize();
    
    runApp(const ProviderScope(child: KhonoApp()));
  // ignore: empty_catches
  } catch (e) {
}
}

class KhonoApp extends ConsumerWidget {
  const KhonoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use read instead of watch to prevent immediate initialization
    // Theme provider will be initialized when needed by individual screens
    final themeMode = ref.read(themeProvider);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        // Routes OUTSIDE the shell (login, email verification)
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const EmailVerificationScreen(),
        ),
        
        // MAIN SHELL - This contains the sidebar and FAB
        ShellRoute(
          builder: (context, state, child) {
            final currentRoute = state.matchedLocation; // Use matchedLocation for accurate route
            return AppShell(
              currentRoute: currentRoute,
              child: child,
            );
          },
          routes: [
            // Dashboard with role-based redirect
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DeliveryLeadDashboard(),
              redirect: (context, state) {
                final user = ref.read(apiCurrentUserProvider);
                if (user == null) {
                  return '/login';
                }
                switch (user.role) {
                  case UserRole.clientReviewer:
                    return '/client-reviewer-dashboard';
                  case UserRole.deliveryLead:
                    return '/delivery-manager-dashboard';
                  case UserRole.systemAdmin:
                    return '/system-admin-dashboard';
                  default:
                    return '/dashboard';
                }
              },
            ),
            
            // Role-specific dashboards
            GoRoute(
              path: '/delivery-manager-dashboard',
              builder: (context, state) => const DeliveryLeadDashboard(),
            ),
            GoRoute(
              path: '/client-reviewer-dashboard',
              builder: (context, state) => const ClientReviewerDashboard(),
            ),
            GoRoute(
              path: '/qa-engineer-dashboard',
              builder: (context, state) => const QaEngineerDashboard(),
            ),
            GoRoute(
              path: '/system-admin-dashboard',
              builder: (context, state) => const SystemAdminDashboard(),
            ),
            
            // Project-related routes (INSIDE SHELL - FAB will show!)
            GoRoute(
              path: '/projects',
              builder: (context, state) => const ProjectsScreen(),
            ),
            GoRoute(
              path: '/projects/create',
              builder: (context, state) => const ProjectCreateScreen(),
            ),
            GoRoute(
              path: '/projects/:projectId',
              builder: (context, state) {
                final projectId = state.pathParameters['projectId']!;
                return ProjectDetailScreen(id: projectId);
              },
            ),
            GoRoute(
              path: '/project-setup',
              builder: (context, state) {
                final projectId = state.uri.queryParameters['projectId'];
                return ProjectSetupScreen(projectId: projectId);
              },
            ),
            GoRoute(
              path: '/project-setup/:projectId',
              builder: (context, state) {
                final projectId = state.pathParameters['projectId']!;
                return ProjectSetupScreen(projectId: projectId);
              },
            ),
            
            // Other routes (INSIDE SHELL)
            GoRoute(
              path: '/deliverable-setup',
              builder: (context, state) => const DeliverableSetupScreen(),
            ),
            GoRoute(
              path: '/sprint-console',
              builder: (context, state) => const SprintConsoleScreen(),
            ),
            GoRoute(
              path: '/signoff-builder',
              builder: (context, state) => const SignoffReportBuilderScreen(),
            ),
            GoRoute(
              path: '/client-review',
              builder: (context, state) => const ClientReviewScreen(),
            ),
            GoRoute(
              path: '/audit-trail',
              builder: (context, state) => const AuditTrailScreen(),
            ),
            GoRoute(
              path: '/repository',
              builder: (context, state) => const RepositoryScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Khonology - Deliverable & Sprint Sign-Off Hub',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

