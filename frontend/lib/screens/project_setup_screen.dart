import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjectSetupScreen extends StatefulWidget {
  final String? projectId; // If provided, we're in edit mode
  final String? projectName; // If provided, we're in edit mode

  const ProjectSetupScreen({
    Key? key,
    this.projectId,
    this.projectName,
  }) : super(key: key);

  @override
  _ProjectSetupScreenState createState() => _ProjectSetupScreenState();
}

class _ProjectSetupScreenState extends State<ProjectSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _keyController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _repositoryUrlController = TextEditingController();
  final _documentationUrlController = TextEditingController();
  String _status = 'active';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  Project? _originalProject;

  // Validation state
  Map<String, String?> _validationErrors = {
    'name': null,
    'key': null,
    'description': null,
    'clientName': null,
    'startDate': null,
    'endDate': null,
  };

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty &&
           _keyController.text.trim().isNotEmpty &&
           _descriptionController.text.trim().isNotEmpty &&
           _clientNameController.text.trim().isNotEmpty &&
           _startDate != null &&
           _endDate != null &&
           _validationErrors.values.every((error) => error == null);
  }

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _loadProjectData();
    } else {
      _startDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _keyController.dispose();
    _clientNameController.dispose();
    _repositoryUrlController.dispose();
    _documentationUrlController.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validateProjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project name is required';
    }
    if (value.trim().length < 3) {
      return 'Project name must be at least 3 characters';
    }
    if (value.trim().length > 100) {
      return 'Project name must not exceed 100 characters';
    }
    return null;
  }

  String? _validateProjectKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project key is required';
    }
    final trimmedValue = value.trim().toUpperCase();
    if (trimmedValue.length < 2) {
      return 'Project key must be at least 2 characters';
    }
    if (trimmedValue.length > 20) {
      return 'Project key must not exceed 20 characters';
    }
    if (!RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(trimmedValue)) {
      return 'Project key must start with letter and contain only letters, numbers, and underscores';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (value.trim().length > 1000) {
      return 'Description must not exceed 1000 characters';
    }
    return null;
  }

  String? _validateClientName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Client name is required';
    }
    if (value.trim().length < 2) {
      return 'Client name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Client name must not exceed 100 characters';
    }
    return null;
  }

  String? _validateEndDate(DateTime? endDate) {
    if (endDate == null) {
      return 'End date is required';
    }
    if (_startDate != null && endDate.isBefore(_startDate!)) {
      return 'End date must be after start date';
    }
    return null;
  }

  void _updateValidationErrors() {
    setState(() {
      _validationErrors['name'] = _validateProjectName(_nameController.text);
      _validationErrors['key'] = _validateProjectKey(_keyController.text);
      _validationErrors['description'] = _validateDescription(_descriptionController.text);
      _validationErrors['clientName'] = _validateClientName(_clientNameController.text);
      _validationErrors['startDate'] = _startDate == null ? 'Start date is required' : null;
      _validationErrors['endDate'] = _validateEndDate(_endDate);
    });
  }

  void _generateProjectKey() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final key = name
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      _keyController.text = key.length > 20 ? key.substring(0, 20) : key;
      _updateValidationErrors();
    }
  }

  Future<void> _loadProjectData() async {
    if (widget.projectId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final project = await ProjectService.getProject(widget.projectId!);
      
      setState(() {
        _originalProject = project;
        _nameController.text = project.name;
        _descriptionController.text = project.description;
        _keyController.text = project.key;
        _clientNameController.text = project.clientName;
        _repositoryUrlController.text = project.repositoryUrl ?? '';
        _documentationUrlController.text = project.documentationUrl ?? '';
        _status = project.status;
        _startDate = project.startDate;
        _endDate = project.endDate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
        
        // If end date is before start date, adjust it
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = date;
        }
      });
      _updateValidationErrors();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate?.add(const Duration(days: 90)) ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
      _updateValidationErrors();
    }
  }

  Future<void> _saveProject() async {
    // Update validation errors before saving
    _updateValidationErrors();
    
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      Project savedProject;
      
      if (widget.projectId != null) {
        // Update existing project
        final projectUpdate = ProjectUpdate(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          key: _keyController.text.trim().toUpperCase(),
          clientName: _clientNameController.text.trim(),
          repositoryUrl: _repositoryUrlController.text.trim().isEmpty 
              ? null 
              : _repositoryUrlController.text.trim(),
          documentationUrl: _documentationUrlController.text.trim().isEmpty 
              ? null 
              : _documentationUrlController.text.trim(),
          status: _status,
          startDate: _startDate,
          endDate: _endDate,
        );
        
        savedProject = await ProjectService.updateProject(widget.projectId!, projectUpdate);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new project
        final projectCreate = ProjectCreate(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          key: _keyController.text.trim().toUpperCase(),
          clientName: _clientNameController.text.trim(),
          repositoryUrl: _repositoryUrlController.text.trim().isEmpty 
              ? null 
              : _repositoryUrlController.text.trim(),
          documentationUrl: _documentationUrlController.text.trim().isEmpty 
              ? null 
              : _documentationUrlController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate,
        );
        
        savedProject = await ProjectService.createProject(projectCreate);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context, savedProject);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetForm() async {
    if (_originalProject != null) {
      // Reset to original values
      setState(() {
        _nameController.text = _originalProject!.name;
        _descriptionController.text = _originalProject!.description;
        _keyController.text = _originalProject!.key;
        _clientNameController.text = _originalProject!.clientName;
        _repositoryUrlController.text = _originalProject!.repositoryUrl ?? '';
        _documentationUrlController.text = _originalProject!.documentationUrl ?? '';
        _status = _originalProject!.status;
        _startDate = _originalProject!.startDate;
        _endDate = _originalProject!.endDate;
      });
    } else {
      // Clear form for new project
      setState(() {
        _nameController.clear();
        _descriptionController.clear();
        _keyController.clear();
        _clientNameController.clear();
        _repositoryUrlController.clear();
        _documentationUrlController.clear();
        _status = 'active';
        _startDate = DateTime.now();
        _endDate = null;
      });
    }
    _updateValidationErrors();
  }

  bool _hasChanges() {
    if (_originalProject == null) {
      // For new project, check if any field has values
      return _nameController.text.isNotEmpty ||
             _descriptionController.text.isNotEmpty ||
             _keyController.text.isNotEmpty ||
             _clientNameController.text.isNotEmpty ||
             _repositoryUrlController.text.isNotEmpty ||
             _documentationUrlController.text.isNotEmpty ||
             _endDate != null;
    }

    // For existing project, check if any field has changed
    return _nameController.text.trim() != _originalProject!.name ||
           _descriptionController.text.trim() != _originalProject!.description ||
           _keyController.text.trim() != _originalProject!.key ||
           _clientNameController.text.trim() != _originalProject!.clientName ||
           _repositoryUrlController.text.trim() != (_originalProject!.repositoryUrl ?? '') ||
           _documentationUrlController.text.trim() != (_originalProject!.documentationUrl ?? '') ||
           _status != _originalProject!.status ||
           _startDate != _originalProject!.startDate ||
           _endDate != _originalProject!.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.projectId != null;
    final hasChanges = _hasChanges();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Project' : 'Create Project'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (isEditMode && hasChanges)
            TextButton(
              onPressed: _resetForm,
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.projectId != null ? _loadProjectData : null,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Information Section
            _buildSectionHeader('Project Information'),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Project Name *',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
                helperText: 'Enter a descriptive name for your project',
                errorText: _validationErrors['name'],
              ),
              onChanged: (value) {
                _updateValidationErrors();
                // Auto-generate project key when name changes
                if (widget.projectId == null) {
                  _generateProjectKey();
                }
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: 'Project Key *',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                helperText: 'Unique identifier (e.g., MY_PROJECT)',
                errorText: _validationErrors['key'],
                suffixIcon: widget.projectId == null 
                    ? IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _generateProjectKey,
                        tooltip: 'Generate from project name',
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => _updateValidationErrors(),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _clientNameController,
              decoration: InputDecoration(
                labelText: 'Client Name *',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.business),
                helperText: 'Name of the client or organization',
                errorText: _validationErrors['clientName'],
              ),
              onChanged: (value) => _updateValidationErrors(),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
                helperText: 'Provide a detailed description of the project',
                errorText: _validationErrors['description'],
              ),
              maxLines: 4,
              onChanged: (value) => _updateValidationErrors(),
            ),
            const SizedBox(height: 24),

            // Links Section
            _buildSectionHeader('Links & Resources'),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _repositoryUrlController,
              decoration: const InputDecoration(
                labelText: 'Repository URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
                helperText: 'Link to the project repository (e.g., GitHub, GitLab)',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                    return 'Please enter a valid URL';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _documentationUrlController,
              decoration: const InputDecoration(
                labelText: 'Documentation URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.library_books),
                helpText: 'Link to project documentation or wiki',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                    return 'Please enter a valid URL';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Schedule Section
            _buildSectionHeader('Schedule & Status'),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        errorText: _validationErrors['startDate'],
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Select start date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.event),
                        errorText: _validationErrors['endDate'],
                      ),
                      child: Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Select end date',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (isEditMode)
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'on_hold', child: Text('On Hold')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value ?? 'active';
                  });
                },
              ),
            const SizedBox(height: 24),

            // Validation Summary
            if (!_isFormValid())
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Please complete all required fields:',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._validationErrors.entries
                        .where((entry) => entry.value != null)
                        .map((entry) => Padding(
                          padding: const EdgeInsets.only(left: 28, top: 2),
                          child: Text(
                            '• ${entry.value}',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ))
                        .toList(),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isSaving || !_isFormValid()) ? null : _saveProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid() 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(isEditMode ? 'Save Changes' : 'Create Project'),
                  ),
                ),
              ],
            ),
            
            if (isEditMode)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Changes are automatically logged with timestamps and user information for audit purposes.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
