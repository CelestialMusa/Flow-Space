import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Project? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    try {
      final project = await ProjectService.getProject(widget.projectId);
      setState(() {
        _project = project;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project Details'),
        ),
        body: const Center(
          child: Text('Project not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_project!.name),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_project!.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _project!.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(_project!.status),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Project Key: ${_project!.key}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _project!.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Project Information
            _buildInfoSection(
              context,
              'Project Information',
              [
                _buildInfoRow(context, 'Client', _project!.clientName, Icons.business),
                _buildInfoRow(context, 'Created By', _project!.createdBy, Icons.person),
                _buildInfoRow(context, 'Created', _formatDate(_project!.createdAt), Icons.calendar_today),
              ],
            ),
            const SizedBox(height: 24),

            // Timeline
            _buildInfoSection(
              context,
              'Timeline',
              [
                _buildInfoRow(context, 'Start Date', _formatDate(_project!.startDate), Icons.play_arrow),
                if (_project!.endDate != null)
                  _buildInfoRow(context, 'End Date', _formatDate(_project!.endDate!), Icons.flag),
              ],
            ),
            const SizedBox(height: 24),

            // Additional Information
            if (_project!.repositoryUrl != null || _project!.documentationUrl != null)
              _buildInfoSection(
                context,
                'Links',
                [
                  if (_project!.repositoryUrl != null)
                    _buildInfoRow(context, 'Repository', _project!.repositoryUrl!, Icons.link),
                  if (_project!.documentationUrl != null)
                    _buildInfoRow(context, 'Documentation', _project!.documentationUrl!, Icons.description),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'on_hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
