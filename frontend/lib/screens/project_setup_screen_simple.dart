// project_setup_screen_simple.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/project_service.dart';
import '../models/project.dart';

class ProjectSetupScreen extends StatefulWidget {
  const ProjectSetupScreen({super.key});

  @override
  State<ProjectSetupScreen> createState() => _ProjectSetupScreenState();
}

class _ProjectSetupScreenState extends State<ProjectSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _clientNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Generate project key from name
      final projectKey = _nameController.text.trim()
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .toUpperCase();

      final projectCreate = ProjectCreate(
        name: _nameController.text.trim(),
        key: projectKey,
        description: _descriptionController.text.trim(),
        clientName: _clientNameController.text.trim(),
        startDate: DateTime.parse(_startDateController.text.trim()),
        endDate: DateTime.parse(_endDateController.text.trim()),
      );

      // Call the ProjectService to create the project
      await ProjectService.createProject(projectCreate);
      
      // Check if widget is still mounted before using context
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to dashboard
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating project: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Project'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Project Setup',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill in the details below to create a new project',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              
              // Project Name Field
              const Text(
                'Project Name *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Enter project name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Project name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Description Field
              const Text(
                'Description *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Enter project description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Client Name Field
              const Text(
                'Client Name *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clientNameController,
                decoration: InputDecoration(
                  labelText: 'Enter client name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Client name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Client name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Start Date Field
              const Text(
                'Start Date *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _startDateController,
                decoration: InputDecoration(
                  labelText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Start date is required';
                  }
                  // Basic date format validation
                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim())) {
                    return 'Please use YYYY-MM-DD format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // End Date Field
              const Text(
                'End Date *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _endDateController,
                decoration: InputDecoration(
                  labelText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.event),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'End date is required';
                  }
                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim())) {
                    return 'Please use YYYY-MM-DD format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.purple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createProject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create Project'),
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
}
