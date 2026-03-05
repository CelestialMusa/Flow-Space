import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/project.dart';
import '../services/api_service.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Project? _project;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final project = await ApiService.getProject(widget.projectId);
      if (mounted) {
        setState(() {
          _project = project;
          _isLoading = false;
          if (project == null) _error = 'Project not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load project: $e';
        });
      }
    }
  }

  String _statusLabel(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.planning: return 'Planning';
      case ProjectStatus.active: return 'Active';
      case ProjectStatus.onHold: return 'On Hold';
      case ProjectStatus.completed: return 'Completed';
      case ProjectStatus.cancelled: return 'Cancelled';
    }
  }

  String _priorityLabel(ProjectPriority p) {
    switch (p) {
      case ProjectPriority.low: return 'Low';
      case ProjectPriority.medium: return 'Medium';
      case ProjectPriority.high: return 'High';
      case ProjectPriority.critical: return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'Project not found', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _project!;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/project-workspace/${p.id}');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.description.isNotEmpty) ...[
              Text(p.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
            ],
            _row('Key', p.key),
            if (p.clientName != null && p.clientName!.isNotEmpty) _row('Client', p.clientName!),
            _row('Status', _statusLabel(p.status)),
            _row('Priority', _priorityLabel(p.priority)),
            _row('Type', p.projectType),
            _row('Start', _formatDate(p.startDate)),
            if (p.endDate != null) _row('End', _formatDate(p.endDate!)),
            if (p.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Tags', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: p.tags.map((t) => Chip(label: Text(t))).toList(),
              ),
            ],
            if (p.members.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Members', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...p.members.map((m) => ListTile(
                dense: true,
                leading: const CircleAvatar(child: Icon(Icons.person, size: 20)),
                title: Text(m.userName),
                subtitle: Text(m.userEmail),
                trailing: Text(m.role.name),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
