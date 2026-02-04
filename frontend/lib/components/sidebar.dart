// ignore_for_file: use_super_parameters, deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/api_auth_riverpod_provider.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final String route;
  final String tooltip;
  final List<String> allowedRoles; // Roles that can see this item

  const SidebarItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.tooltip,
    this.allowedRoles = const [], // Empty means all roles can see
  });
}

class SidebarDivider {
  const SidebarDivider();
}

class Sidebar extends ConsumerStatefulWidget {
  final bool isCollapsed;
  final String currentRoute;
  final Function(bool)? onToggle;

  const Sidebar({
    super.key,
    required this.isCollapsed,
    required this.currentRoute,
    this.onToggle,
  });

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  List<dynamic> _sidebarItems = [];

  @override
  void initState() {
    super.initState();
    _buildSidebarItems();
    
    // Listen for user changes and rebuild sidebar
    ref.listen(apiCurrentUserProvider, (previous, next) {
      if (previous?.id != next?.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _buildSidebarItems();
        });
      }
    });
    
    // Force rebuild for testing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildSidebarItems();
    });
  }

  void _buildSidebarItems() {
    final user = ref.watch(apiCurrentUserProvider);
    final userRole = user?.role.name ?? 'teamMember';
    
    debugPrint('🔍 Sidebar Debug - User: ${user?.firstName} ${user?.lastName}, Role: ${user?.role}, Role Name: $userRole');

    setState(() {
      _sidebarItems = [
        // Common items for all roles
        const SidebarDivider(),
        const SidebarItem(
          title: 'Dashboard',
          icon: Icons.dashboard,
          route: '/dashboard',
          tooltip: 'Main Dashboard',
        ),
        
        // Projects tab - temporarily available to all users for testing
        const SidebarItem(
          title: 'Projects',
          icon: Icons.folder,
          route: '/projects',
          tooltip: 'Manage Projects',
        ),
        // Show Create Project to all users
        SidebarItem(
          title: 'Create Project',
          icon: Icons.add_circle,
          route: '/project-setup',
          tooltip: 'Create New Project',
        ),
        if (_canAccessRole('systemAdmin', userRole) || _canAccessRole('deliveryLead', userRole)) 
          const SidebarItem(
            title: 'Deliverables',
            icon: Icons.task,
            route: '/deliverable-setup',
            tooltip: 'Manage Deliverables',
            allowedRoles: ['systemAdmin', 'deliveryLead'],
          ),
        
        if (_canAccessRole('systemAdmin', userRole) || _canAccessRole('deliveryLead', userRole) || _canAccessRole('qaEngineer', userRole))
          const SidebarItem(
            title: 'Sprints',
            icon: Icons.timeline,
            route: '/sprint-console',
            tooltip: 'Sprint Console',
            allowedRoles: ['systemAdmin', 'deliveryLead', 'qaEngineer'],
          ),
        
        if (_canAccessRole('systemAdmin', userRole) || _canAccessRole('deliveryLead', userRole))
          const SidebarItem(
            title: 'Sign-off Builder',
            icon: Icons.description,
            route: '/signoff-builder',
            tooltip: 'Build Sign-off Reports',
            allowedRoles: ['systemAdmin', 'deliveryLead'],
          ),
        
        if (_canAccessRole('client', userRole) || _canAccessRole('clientReviewer', userRole))
          const SidebarItem(
            title: 'Client Review',
            icon: Icons.visibility,
            route: '/client-review',
            tooltip: 'Client Review Dashboard',
            allowedRoles: ['client', 'clientReviewer'],
          ),
        
        if (_canAccessRole('systemAdmin', userRole))
          const SidebarItem(
            title: 'Audit Trail',
            icon: Icons.history,
            route: '/audit-trail',
            tooltip: 'Audit Trail Logs',
            allowedRoles: ['systemAdmin'],
          ),
        
        if (_canAccessRole('systemAdmin', userRole) || _canAccessRole('deliveryLead', userRole))
          const SidebarItem(
            title: 'Repository',
            icon: Icons.storage,
            route: '/repository',
            tooltip: 'Signed Reports Repository',
            allowedRoles: ['systemAdmin', 'deliveryLead'],
          ),
        
        // User-specific items
        const SidebarDivider(),
        const SidebarItem(
          title: 'Profile',
          icon: Icons.person,
          route: '/profile',
          tooltip: 'User Profile',
        ),
        
        if (_canAccessRole('systemAdmin', userRole))
          const SidebarItem(
            title: 'Settings',
            icon: Icons.settings,
            route: '/settings',
            tooltip: 'System Settings',
            allowedRoles: ['systemAdmin'],
          ),
        
        const SidebarItem(
          title: 'Notifications',
          icon: Icons.notifications,
          route: '/notifications',
          tooltip: 'Notifications',
        ),
      ];
    });
  }

  bool _canAccessRole(String requiredRole, String userRole) {
    // Role hierarchy: systemAdmin > deliveryLead > qaEngineer > clientReviewer > client > teamMember
    final roleHierarchy = {
      'systemAdmin': 6,
      'deliveryLead': 5,
      'qaEngineer': 4,
      'clientReviewer': 3,
      'client': 2,
      'teamMember': 1,
    };
    
    final userLevel = roleHierarchy[userRole] ?? 0;
    final requiredLevel = roleHierarchy[requiredRole] ?? 0;
    
    return userLevel >= requiredLevel;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(width: 1, color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          // Header with toggle button
          _buildHeader(),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _sidebarItems.map((item) {
                if (item is SidebarDivider) {
                  // Don't show divider when sidebar is collapsed
                  return widget.isCollapsed ? const SizedBox.shrink() : const Divider(height: 1, indent: 16, endIndent: 16);
                } else {
                  return _buildNavItem(item);
                }
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: widget.isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.isCollapsed)
            const Row(
              children: [
                Icon(Icons.dashboard, size: 24),
                SizedBox(width: 12),
                Text(
                  'Khonology',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          IconButton(
            icon: Icon(
              widget.isCollapsed ? Icons.menu_open : Icons.menu,
              size: 20,
            ),
            onPressed: widget.onToggle != null ? () => widget.onToggle!(!widget.isCollapsed) : null,
            tooltip: widget.isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(dynamic item) {
    final sidebarItem = item as SidebarItem;
    final isActive = widget.currentRoute == sidebarItem.route;
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: sidebarItem.tooltip,
      preferBelow: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: ListTile(
          leading: Icon(
            sidebarItem.icon,
            color: isActive ? colorScheme.primary : colorScheme.onSurface,
            size: 20,
          ),
          title: !widget.isCollapsed
              ? Text(
                  sidebarItem.title,
                  style: TextStyle(
                    color: isActive ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                )
              : null,
          minLeadingWidth: 0,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 16 : 12,
          ),
          onTap: () {
            if (widget.currentRoute != sidebarItem.route) {
              context.go(sidebarItem.route);
            }
          },
        ),
      ),
    );
  }
}