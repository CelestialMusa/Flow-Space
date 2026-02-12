import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/project_service.dart';
import '../models/project.dart';
import '../providers/project_provider.dart';

class ProjectCreateScreen extends StatefulWidget {
  const ProjectCreateScreen({super.key});

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _clientController = TextEditingController();
  String _selectedType = 'software';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  DateTime? _parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Project Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Project Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: () => _selectDate(context, _startDateController),
                      decoration: const InputDecoration(
                        labelText: 'Start Date *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      onTap: () => _selectDate(context, _endDateController),
                      decoration: const InputDecoration(
                        labelText: 'End Date *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clientController,
                      decoration: const InputDecoration(
                        labelText: 'Client *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      items: const [
                        DropdownMenuItem(value: 'software', child: Text('Software')),
                        DropdownMenuItem(value: 'mobile', child: Text('Mobile')),
                        DropdownMenuItem(value: 'web', child: Text('Web')),
                        DropdownMenuItem(value: 'internal', child: Text('Internal')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Project Type *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      return ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              final projectCreate = ProjectCreate(
                                name: _nameController.text,
                                description: _descriptionController.text,
                                key: _nameController.text.toUpperCase().replaceAll(' ', '_'),
                                clientName: _clientController.text,
                                startDate: _parseDate(_startDateController.text) ?? DateTime.now(),
                              );

                              await ProjectService.createProject(projectCreate);

                              if (mounted) {
                                ref.invalidate(projectsProvider);
                                // ignore: use_build_context_synchronously
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error creating project: $e')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        },
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Project'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
