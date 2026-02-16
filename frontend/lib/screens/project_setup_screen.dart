import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjectSetupScreen extends StatefulWidget {
  final String? projectId;

  const ProjectSetupScreen({super.key, this.projectId});

  @override
  State<ProjectSetupScreen> createState() => _ProjectSetupScreenState();
}

class _ProjectSetupScreenState extends State<ProjectSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientNameController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedProjectType = 'Fixed Scope';
  
  bool _isSaving = false;

  final Map<String, String?> _validationErrors = {
    'name': null,
    'description': null,
    'clientName': null,
    'startDate': null,
    'endDate': null,
  };

  bool get isEditMode => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _loadProject();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _clientNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    if (widget.projectId == null) return;
    
    setState(() => _isSaving = true);
    try {
      final project = await ProjectService.getProject(widget.projectId!);
      setState(() {
        _nameController.text = project.name;
        _descriptionController.text = project.description;
        _clientNameController.text = project.clientName;
        _startDate = project.startDate;
        _endDate = project.endDate;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
      _updateValidationErrors();
    }
  }

  void _updateValidationErrors() {
    setState(() {
      _validationErrors['name'] = _nameController.text.trim().isEmpty ? 'Project name is required' : null;
      _validationErrors['description'] = _descriptionController.text.trim().isEmpty ? 'Description is required' : null;
      _validationErrors['clientName'] = _clientNameController.text.trim().isEmpty ? 'Client name is required' : null;
      _validationErrors['startDate'] = _startDate == null ? 'Start date is required' : null;
      _validationErrors['endDate'] = _endDate == null ? 'End date is required' : 
          (_startDate != null && _endDate!.isBefore(_startDate!) ? 'End date must be after start date' : null);
    });
  }

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty &&
           _descriptionController.text.trim().isNotEmpty &&
           _clientNameController.text.trim().isNotEmpty &&
           _startDate != null &&
           _endDate != null &&
           _validationErrors.values.every((error) => error == null);
  }

  Future<void> _saveProject() async {
    if (!_isFormValid()) return;
    
    setState(() => _isSaving = true);
    
    try {
      Project savedProject;
      if (widget.projectId != null) {
        // Update existing project
        final projectUpdate = ProjectUpdate(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          clientName: _clientNameController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate,
        );
        savedProject = await ProjectService.updateProject(widget.projectId!, projectUpdate);
      } else {
        // Create new project
        final projectCreate = ProjectCreate(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          key: _nameController.text.trim().toUpperCase().replaceAll(' ', '_'),
          clientName: _clientNameController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate,
        );
        savedProject = await ProjectService.createProject(projectCreate);
      }

      if (mounted) {
        Navigator.of(context).pop(savedProject);
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business_center,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditMode ? 'Edit Project' : 'Create New Project',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            isEditMode 
                                ? 'Update project information and settings'
                                : 'Fill in the details below to create a new project',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project Information Section
                        _buildSectionHeader('Project Information', Icons.info_outline),
                        const SizedBox(height: 16),
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildDescriptionField(),
                        const SizedBox(height: 16),
                        _buildClientNameField(),
                        
                        const SizedBox(height: 24),
                        
                        // Timeline Section
                        _buildSectionHeader('Timeline', Icons.calendar_today),
                        const SizedBox(height: 16),
                        _buildDateFields(),
                        
                        const SizedBox(height: 24),
                        
                        // Additional Settings
                        _buildSectionHeader('Additional Settings', Icons.settings),
                        const SizedBox(height: 16),
                        _buildProjectTypeField(),
                        
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Project Name',
        hintText: 'Enter project name',
        prefixIcon: Icon(Icons.business, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorText: _validationErrors['name'],
      ),
      style: theme.textTheme.bodyLarge,
      onChanged: (value) {
        setState(() {
          _validationErrors['name'] = null;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Project name is required';
        }
        if (value.trim().length < 3) {
          return 'Project name must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Describe the project scope and objectives',
        prefixIcon: Icon(Icons.description, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorText: _validationErrors['description'],
      ),
      maxLines: 4,
      style: theme.textTheme.bodyLarge,
      onChanged: (value) {
        setState(() {
          _validationErrors['description'] = null;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Description is required';
        }
        if (value.trim().length < 10) {
          return 'Description must be at least 10 characters';
        }
        return null;
      },
    );
  }

  Widget _buildClientNameField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextFormField(
      controller: _clientNameController,
      decoration: InputDecoration(
        labelText: 'Client Name',
        hintText: 'Enter client or company name',
        prefixIcon: Icon(Icons.account_balance, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorText: _validationErrors['clientName'],
      ),
      style: theme.textTheme.bodyLarge,
      onChanged: (value) {
        setState(() {
          _validationErrors['clientName'] = null;
        });
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Client name is required';
        }
        return null;
      },
    );
  }

  Widget _buildDateFields() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, isStartDate: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _validationErrors['startDate'] != null 
                      ? colorScheme.error 
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Select date',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _startDate != null 
                                ? colorScheme.onSurface 
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, isStartDate: false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _validationErrors['endDate'] != null 
                      ? colorScheme.error 
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Select date',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _endDate != null 
                                ? colorScheme.onSurface 
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectTypeField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return DropdownButtonFormField<String>(
      initialValue: _selectedProjectType,
      decoration: InputDecoration(
        labelText: 'Project Type',
        prefixIcon: Icon(Icons.category, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      items: ['Fixed Scope', 'Time & Materials', 'Retainer', 'Agile']
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedProjectType = value!;
        });
      },
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            side: BorderSide(color: colorScheme.outline),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProject,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                  ),
                )
              : Text(isEditMode ? 'Update Project' : 'Create Project'),
        ),
      ],
    );
  }
}
