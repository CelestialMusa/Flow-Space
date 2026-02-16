// system_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';

class SystemAdminDashboard extends StatefulWidget {
  const SystemAdminDashboard({super.key});

  @override
  State<SystemAdminDashboard> createState() => _SystemAdminDashboardState();
}

class _SystemAdminDashboardState extends State<SystemAdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Admin Dashboard'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'System Administrator',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'System Management & Administration',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 32),
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Admin Functions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.people, color: Colors.red),
                      title: Text('User Management'),
                      subtitle: Text('Manage user accounts and roles'),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.history, color: Colors.red),
                      title: Text('Audit Trail'),
                      subtitle: Text('View system logs and history'),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.settings, color: Colors.red),
                      title: Text('System Settings'),
                      subtitle: Text('Configure system parameters'),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.person_add),
          label: 'Add User',
          backgroundColor: Colors.blue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User management coming soon')),
            );
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.folder),
          label: 'New Project',
          backgroundColor: Colors.purple,
          onTap: () => context.go('/project-setup'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.task),
          label: 'New Deliverable',
          backgroundColor: Colors.green,
          onTap: () => context.go('/deliverable-setup'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.timeline),
          label: 'New Sprint',
          backgroundColor: Colors.orange,
          onTap: () => context.go('/sprint-console'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.settings),
          label: 'System Settings',
          backgroundColor: Colors.grey,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('System settings coming soon')),
            );
          },
        ),
      ],
    );
  }
}
