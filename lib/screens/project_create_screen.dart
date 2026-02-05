import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/project_service.dart';

class ProjectCreateScreen extends StatefulWidget {
  final String? projectId;
  
  const ProjectCreateScreen({super.key, this.projectId});

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _clientController = TextEditingController();
  final _repositoryController = TextEditingController();
  final _documentationController = TextEditingController();
  String _selectedType = 'Software Development';
  bool _isLoading = false;
  bool _isEditing = false;

  final List<String> _projectTypes = [
    'Software Development',
    'Infrastructure',
    'Consulting',
    'Research & Development',
    'Training',
    'Support & Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.projectId != null;
    if (_isEditing) {
      _loadProjectData();
    }
  }

  Future<void> _loadProjectData() async {
    if (widget.projectId == null) return;
    
    try {
      final project = await ProjectService.getProjectById(widget.projectId!);
      if (project != null) {
        setState(() {
          _nameController.text = project.name;
          _keyController.text = project.id;
          _descriptionController.text = project.description;
          _clientController.text = project.clientName ?? '';
          _selectedType = project.projectType;
          _startDateController.text = '${project.startDate.day}/${project.startDate.month}/${project.startDate.year}';
          if (project.endDate != null) {
            _endDateController.text = '${project.endDate!.day}/${project.endDate!.month}/${project.endDate!.year}';
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _clientController.dispose();
    _repositoryController.dispose();
    _documentationController.dispose();
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

  void _generateProjectKey() {
    if (_nameController.text.trim().isNotEmpty) {
      final name = _nameController.text.trim();
      final key = name
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
          .split(' ')
          .where((word) => word.isNotEmpty)
          .map((word) => word[0].toUpperCase())
          .take(3)
          .join('');
      _keyController.text = key;
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final projectData = {
        'name': _nameController.text.trim(),
        'key': _keyController.text.trim(),
        'description': _descriptionController.text.trim(),
        'clientName': _clientController.text.trim(),
        'projectType': _selectedType,
        'startDate': _startDateController.text.trim(),
        'endDate': _endDateController.text.trim(),
        'repositoryUrl': _repositoryController.text.trim(),
        'documentationUrl': _documentationController.text.trim(),
        'status': 'planning',
        'priority': 'medium',
        'tags': [],
        'members': [],
        'deliverableIds': [],
        'sprintIds': [],
      };

      if (_isEditing) {
        await ProjectService.updateProject(widget.projectId!, projectData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await ProjectService.createProject(projectData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      if (mounted) {
        context.go('/projects');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Project' : 'Create Project'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Name
              _buildFormField(
                label: 'Project Name',
                controller: _nameController,
                hintText: 'Enter project name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project name is required';
                  }
                  return null;
                },
                onChanged: (_) => _generateProjectKey(),
              ),
              const SizedBox(height: 16),

              // Project Key
              Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      label: 'Project Key',
                      controller: _keyController,
                      hintText: 'Auto-generated from project name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Project key is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _generateProjectKey,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Generate Key',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              _buildFormField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
                hintText: 'Enter project description',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dates Row
              Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      label: 'Start Date',
                      controller: _startDateController,
                      hintText: 'DD/MM/YYYY',
                      readOnly: true,
                      suffixIcon: Icons.calendar_today,
                      onTap: () => _selectDate(context, _startDateController),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Start date is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFormField(
                      label: 'End Date',
                      controller: _endDateController,
                      hintText: 'DD/MM/YYYY',
                      readOnly: true,
                      suffixIcon: Icons.calendar_today,
                      onTap: () => _selectDate(context, _endDateController),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'End date is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Client Name
              _buildFormField(
                label: 'Client Name',
                controller: _clientController,
                hintText: 'Enter client name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Client name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Project Type
              _buildDropdownField(
                label: 'Project Type',
                value: _selectedType,
                items: _projectTypes,
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),

              // URLs Row
              Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      label: 'Repository URL',
                      controller: _repositoryController,
                      hintText: 'https://github.com/username/repo',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFormField(
                      label: 'Documentation URL',
                      controller: _documentationController,
                      hintText: 'https://docs.example.com',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/projects'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_isEditing ? 'Update Project' : 'Save Project'),
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    bool readOnly = false,
    IconData? suffixIcon,
    void Function()? onTap,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, size: 20),
                    onPressed: onTap,
                  )
                : null,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: items.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }
}
