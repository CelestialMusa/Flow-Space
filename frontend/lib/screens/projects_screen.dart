// projects_screen_simple.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/project_provider.dart';
import '../services/project_service.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/projects/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: projects.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Projects',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final project = data[i];
                    return Card(
                      child: ListTile(
                        title: Text(project.name),
                        subtitle: Text(project.description.isNotEmpty ? project.description : 'No description'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              context.go('/projects/${project.id}');
                            } else if (value == 'delete') {
                              // Show confirmation dialog
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Project'),
                                  content: Text('Are you sure you want to delete "${project.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                try {
                                  await ProjectService.deleteProject(project.id);
                                  // Refresh the projects list
                                  ref.invalidate(projectsProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Project deleted')),
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
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                        onTap: () {
                          context.go('/projects/${project.id}');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
