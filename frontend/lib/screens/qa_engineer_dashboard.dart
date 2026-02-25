import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class QaEngineerDashboard extends StatefulWidget {
  const QaEngineerDashboard({super.key});

  @override
  State<QaEngineerDashboard> createState() => _QaEngineerDashboardState();
}

class _QaEngineerDashboardState extends State<QaEngineerDashboard> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QA Engineer Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome, QA Engineer!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Quality Assurance & Testing Hub',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
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
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.bug_report),
          label: 'Report Issue',
          backgroundColor: Colors.red,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Issue reporting coming soon')),
            );
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.checklist),
          label: 'Test Cases',
          backgroundColor: Colors.blue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Test case management coming soon')),
            );
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.assessment),
          label: 'Quality Reports',
          backgroundColor: Colors.orange,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quality reports coming soon')),
            );
          },
        ),
      ],
    );
  }
}