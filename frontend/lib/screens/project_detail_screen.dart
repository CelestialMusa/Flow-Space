import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/project_provider.dart';
import '../services/project_service.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String id;
  const ProjectDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.go('/projects/$id/edit');
            },
          ),
        ],
      ),
      body: project.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (p) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(p.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      p.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Project Key
              Text(
                'Key: ${p.key}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              if (p.description.isNotEmpty) ...[
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(p.description),
                const SizedBox(height: 24),
              ],

              // Project Details Grid
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInfoRow('Client', p.clientName),
                      _buildInfoRow('Type', 'Software'), // Project type will be added in future update
                      _buildInfoRow('Start Date', _formatDate(p.startDate)),
                      if (p.endDate != null) 
                        _buildInfoRow('End Date', _formatDate(p.endDate!)),
                      _buildInfoRow('Created', _formatDate(p.createdAt)),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go('/projects/$id/edit');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Project'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Project'),
                            content: Text('Are you sure you want to delete "${p.name}"? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            await ProjectService.deleteProject(p.id);
                            if (context.mounted) {
                              context.pop();
                              ref.invalidate(projectsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Project deleted successfully')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error deleting project: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'on hold':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
