import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/flownet_theme.dart';
import 'notification_center_widget.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_icons.dart';
import 'sidebar_version_display.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'background_image.dart';

class SidebarScaffold extends StatefulWidget {
  final Widget child;

  const SidebarScaffold({super.key, required this.child});

  @override
  State<SidebarScaffold> createState() => _SidebarScaffoldState();
}

class _SidebarScaffoldState extends State<SidebarScaffold> {
  bool _collapsed = false;
  static const double _sidebarWidth = 280;
  static const double _collapsedWidth = 80;

  List<_NavItem> get _navItems {
    final authService = AuthService();
    final allItems = [
      // Work-focused items only
      const _NavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        iconName: 'dashboard',
        route: '/dashboard',
        requiredPermission: null,
      ),
      const _NavItem(
        label: 'Sprints',
        icon: Icons.timer_outlined,
        iconName: 'sprints',
        route: '/sprint-console',
        requiredPermission: 'view_sprints',
      ),
      const _NavItem(
        label: 'Notifications',
        icon: Icons.notifications_outlined,
        iconName: 'notifications',
        route: '/notifications',
        requiredPermission: null,
      ),
      const _NavItem(
        label: 'Timeline',
        icon: Icons.calendar_today_outlined,
        iconName: 'timeline',
        route: '/timeline',
        requiredPermission: null,
      ),
      const _NavItem(
        label: 'Approval Requests',
        icon: Icons.assignment_outlined,
        iconName: 'approval_requests',
        route: '/approval-requests',
        requiredPermission: 'view_approvals',
      ),
      const _NavItem(
        label: 'Repository',
        icon: Icons.folder_outlined,
        iconName: 'repository',
        route: '/repository',
        requiredPermission: 'view_all_deliverables',
      ),
      const _NavItem(
        label: 'Reports',
        icon: Icons.assessment_outlined,
        iconName: 'reports',
        route: '/report-repository',
        requiredPermission: 'view_all_deliverables',
      ),
      const _NavItem(
        label: 'Role Management',
        icon: Icons.admin_panel_settings_outlined,
        iconName: 'role_management',
        route: '/role-management',
        requiredPermission: 'manage_users',
      ),
      const _NavItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        iconName: 'settings',
        route: '/settings',
        requiredPermission: null,
      ),
      const _NavItem(
        label: 'Profile',
        icon: Icons.person_outline,
        iconName: 'account',
        route: '/profile',
        requiredPermission: null,
      ),
      const _NavItem(
        label: 'Projects',
        icon: Icons.folder_outlined,
        iconName: 'teams',
        route: '/project-workspace',
        requiredPermission: null,
      ),
    ];

    // Filter items based on user permissions
    return allItems.where((item) {
      if (item.requiredPermission == null) return true;
      return authService.hasPermission(item.requiredPermission!);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _restoreSidebarState();
  }

  void _restoreSidebarState() {
    // Restore sidebar state from SharedPreferences or other storage
    // For now, we'll use a default state
    _collapsed = false;
  }

  void _persistSidebarState() {
    // Save sidebar state to SharedPreferences or other storage
    // Implementation would go here
  }

  void _toggleSidebar() {
    setState(() {
      _collapsed = !_collapsed;
    });
    _persistSidebarState();
  }

  @override
  Widget build(BuildContext context) {
    final routeLocation = GoRouterState.of(context).uri.path;
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final authService = AuthService();

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: BackgroundImage(
          child: Row(
            children: [
              // Sidebar with professional glassmorphism - optimized to 3 layers
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _collapsed ? _collapsedWidth : _sidebarWidth,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: Colors.white.withAlpha((0.1 * 255).round()),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Header with logo and collapse toggle
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 24,
                        bottom: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/Icons/Red_Khono_Discs.png',
                            width: _collapsed ? 28 : 64,
                            height: _collapsed ? 28 : 64,
                            fit: BoxFit.contain,
                          ),
                          IconButton(
                            onPressed: _toggleSidebar,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              _collapsed
                                  ? Icons.chevron_right
                                  : Icons.chevron_left,
                              color: FlownetColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Navigation items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _navItems.length,
                        itemExtent: 56,
                        cacheExtent: 200,
                        addAutomaticKeepAlives: true,
                        itemBuilder: (context, index) {
                          final item = _navItems[index];
                          final active = routeLocation.startsWith(item.route);
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? FlownetColors.crimsonRed
                                      .withAlpha((0.1 * 255).round())
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: active
                                  ? const Border(
                                      left: BorderSide(
                                        color: FlownetColors.crimsonRed,
                                        width: 4,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (item.requiredPermission == null ||
                                      authService.hasPermission(
                                          item.requiredPermission!)) {
                                    context.go(item.route);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _collapsed ? 8 : 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: _collapsed
                                        ? MainAxisAlignment.center
                                        : MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        item.icon,
                                        color: active
                                            ? FlownetColors.crimsonRed
                                            : FlownetColors.textSecondary,
                                        size: 20,
                                      ),
                                      if (!_collapsed) ...[
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Logout button - separate from version display
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: _buildLogoutButton(),
                    ),
                    // Version display - only when expanded, separate from logout
                    if (!_collapsed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        child: SidebarVersionDisplay(
                          isSidebarCollapsed: _collapsed,
                        ),
                      ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      // Top navigation bar with user menu
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Spacer(),
                            // User menu and notifications
                            Row(
                              children: [
                                // Notifications
                                const NotificationCenterWidget(),
                                const SizedBox(width: 8),
                                // User menu
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.person_outline,
                                      color: FlownetColors.textSecondary),
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  elevation: 0,
                                  itemBuilder: (BuildContext context) {
                                    return [
                                      const PopupMenuItem<String>(
                                        value: 'profile',
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_outline,
                                                size: 20),
                                            SizedBox(width: 8),
                                            Text('Profile'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'settings',
                                        child: Row(
                                          children: [
                                            Icon(Icons.settings_outlined,
                                                size: 20),
                                            SizedBox(width: 8),
                                            Text('Settings'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'notifications',
                                        child: Row(
                                          children: [
                                            Icon(Icons.notifications_outlined,
                                                size: 20),
                                            SizedBox(width: 8),
                                            Text('Notifications'),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
                                  onSelected: (String value) {
                                    switch (value) {
                                      case 'profile':
                                        context.go('/profile');
                                        break;
                                      case 'settings':
                                        context.go('/settings');
                                        break;
                                      case 'notifications':
                                        context.go('/notifications');
                                        break;
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Main content area
                      Expanded(
                        child: widget.child,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mobile layout with drawer
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Image.asset(
            'assets/Icons/Red_Khono_Discs.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          centerTitle: false,
          actions: [
            // Profile Icon
            IconButton(
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.person_outline),
              tooltip: 'Profile',
              color: FlownetColors.pureWhite,
              iconSize: 20,
            ),
            // Settings Icon
            IconButton(
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              color: FlownetColors.pureWhite,
              iconSize: 20,
            ),
            const NotificationCenterWidget(),
            const SizedBox(width: 8),
            const _UserAvatarButton(),
          ],
        ),
        drawer: Drawer(
          backgroundColor: FlownetColors.charcoalBlack,
          child: SafeArea(
            child: Column(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Image.asset(
                      'assets/Icons/Red_Khono_Discs.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const Divider(color: FlownetColors.slate),
                Expanded(
                  child: ListView.builder(
                    itemCount: _navItems.length,
                    itemExtent: 56,
                    cacheExtent: 200,
                    addAutomaticKeepAlives: true,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final active = routeLocation.startsWith(item.route);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? FlownetColors.crimsonRed
                                  .withAlpha((0.1 * 255).round())
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          border: active
                              ? const Border(
                                  left: BorderSide(
                                    color: FlownetColors.crimsonRed,
                                    width: 4,
                                  ),
                                )
                              : null,
                        ),
                        child: ListTile(
                          leading: AppIcons.getIconWidget(
                            item.iconName,
                            fallbackIcon: item.icon,
                            isActive: active,
                            size: 24,
                            color: active
                                ? FlownetColors.crimsonRed
                                : FlownetColors.coolGray,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: active
                                  ? FlownetColors.crimsonRed
                                  : FlownetColors.pureWhite,
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (!routeLocation.startsWith(item.route)) {
                              context.go(item.route);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Logout button - separate from version display
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: FlownetColors.textSecondary,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: FlownetColors.pureWhite),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout(context);
                    },
                  ),
                ),
                // Version display - always show in mobile drawer, separate from logout
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: SidebarVersionDisplay(
                    isSidebarCollapsed: false, // Always show in mobile drawer
                  ),
                ),
              ],
            ),
          ),
        ),
        body: BackgroundImage(
          child: Column(
            children: [
              Expanded(child: widget.child),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext ctx) async {
    final router = GoRouter.of(ctx);
    await AuthService().signOut();
    if (!mounted) return;
    router.go('/');
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: FlownetColors.crimsonRed.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlownetColors.crimsonRed.withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: _collapsed
          ? IconButton(
              onPressed: () => _handleLogout(context),
              icon: AppIcons.getIconWidget(
                'logout',
                fallbackIcon: Icons.logout,
                isActive: true,
                size: 20,
                color: FlownetColors.crimsonRed,
              ),
              tooltip: 'Logout',
              padding: const EdgeInsets.all(12),
            )
          : TextButton.icon(
              onPressed: () => _handleLogout(context),
              icon: AppIcons.getIconWidget(
                'logout',
                fallbackIcon: Icons.logout,
                isActive: true,
                size: 20,
                color: FlownetColors.crimsonRed,
              ),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: FlownetColors.crimsonRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
            ),
    );
  }
}

class _UserAvatarButton extends StatelessWidget {
  const _UserAvatarButton();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => context.go('/profile?mode=view'),
        borderRadius: BorderRadius.circular(20),
        child: FutureBuilder<Uint8List?>(
          future: _loadAvatarBytes(user?.id),
          builder: (context, snapshot) {
            final hasImage =
                snapshot.hasData && (snapshot.data?.isNotEmpty ?? false);
            return CircleAvatar(
              radius: 16,
              backgroundImage: hasImage ? MemoryImage(snapshot.data!) : null,
              child: hasImage ? null : const Icon(Icons.person, size: 18),
            );
          },
        ),
      ),
    );
  }

  Future<Uint8List?> _loadAvatarBytes(String? userId) async {
    try {
      if (userId == null || userId.isEmpty) return null;
      final base = Uri.parse(ApiService.baseUrl);
      final url =
          '${base.scheme}://${base.host}:${base.port.toString()}/api/v1/profile/$userId/picture?t=${DateTime.now().millisecondsSinceEpoch}';
      final headers = await ApiService.getAuthHeaders();
      final resp = await http.get(Uri.parse(url), headers: headers);

      if (resp.statusCode == 200) {
        final bodyBytes = resp.bodyBytes;

        // Check if response is actually image data (not JSON)
        if (bodyBytes.isNotEmpty) {
          // Check file header to detect if it's an image
          final header = bodyBytes.take(4).toList();
          // Common image file signatures: PNG (0x89 0x50 0x4E 0x47), JPEG (0xFF 0xD8 0xFF 0xE0)
          final isImage = (header[0] == 0x89 &&
                  header[1] == 0x50 &&
                  header[2] == 0x4E &&
                  header[3] == 0x47) ||
              (header[0] == 0xFF &&
                  header[1] == 0xD8 &&
                  header[2] == 0xFF &&
                  header[3] == 0xE0);

          if (isImage) {
            return bodyBytes;
          } else {
            // Response is likely JSON, not an image
            debugPrint(
                '⚠️ Avatar endpoint returned non-image data for user $userId');
            return null;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String iconName;
  final String route;
  final String? requiredPermission;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.iconName,
    required this.route,
    this.requiredPermission,
  });
}
