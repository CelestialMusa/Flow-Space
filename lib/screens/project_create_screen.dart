import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/project_service.dart';
import '../services/user_data_service.dart';
import '../models/user.dart';

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
  List<User> _availableUsers = [];
  final List<User> _selectedMembers = [];
  bool _isLoadingUsers = false;

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
    _loadUsers();
    if (_isEditing) {
      _loadProjectData();
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await UserDataService().getUsers();
      setState(() {
        _availableUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
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
        'members': _selectedMembers.map((user) => {
          'userId': user.id,
          'userName': user.name,
          'userEmail': user.email,
          'role': 'contributor'
        }).toList(),
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Project Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    hintText: 'Enter project name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
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
                      child: TextFormField(
                        controller: _keyController,
                        decoration: InputDecoration(
                          labelText: 'Project Key',
                          hintText: 'Auto-generated from project name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Project key is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _generateProjectKey,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Generate Key',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter project description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
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
                      child: TextFormField(
                        controller: _startDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          hintText: 'DD/MM/YYYY',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context, _startDateController),
                          ),
                        ),
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
                      child: TextFormField(
                        controller: _endDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          hintText: 'DD/MM/YYYY',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context, _endDateController),
                          ),
                        ),
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
                TextFormField(
                  controller: _clientController,
                  decoration: InputDecoration(
                    labelText: 'Client Name',
                    hintText: 'Enter client name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Client name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Project Type
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Project Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _projectTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Team Members
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Members',
                      style: TextStyle(
                        fontSize: 16,
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
                      child: Column(
                        children: [
                          if (_isLoadingUsers)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: _availableUsers.length,
                              itemBuilder: (context, index) {
                                final user = _availableUsers[index];
                                final isSelected = _selectedMembers.any((member) => member.id == user.id);
                                return CheckboxListTile(
                                  title: Text(user.name),
                                  subtitle: Text(user.email),
                                  value: isSelected,
                                  onChanged: (bool? selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedMembers.add(user);
                                      } else {
                                        _selectedMembers.removeWhere((member) => member.id == user.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Repository URL
                TextFormField(
                  controller: _repositoryController,
                  decoration: InputDecoration(
                    labelText: 'Repository URL',
                    hintText: 'https://github.com/username/repo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Documentation URL
                TextFormField(
                  controller: _documentationController,
                  decoration: InputDecoration(
                    labelText: 'Documentation URL',
                    hintText: 'https://docs.example.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/projects'),
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
      ),
    );
  }
}
