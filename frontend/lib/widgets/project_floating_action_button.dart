import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';

class ProjectFloatingActionButton extends StatelessWidget {
  const ProjectFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Colors.purple,
      foregroundColor: Colors.white,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.folder),
          label: 'New Project',
          backgroundColor: Colors.purple,
          onTap: () => context.go('/project-setup'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.task),
          label: 'New Deliverable',
          backgroundColor: Colors.blue,
          onTap: () => context.go('/deliverable-setup'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.timeline),
          label: 'New Sprint',
          backgroundColor: Colors.green,
          onTap: () => context.go('/sprint-console'),
        ),
      ],
    );
  }
}
