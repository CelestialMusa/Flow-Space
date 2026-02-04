import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class ProjectSetupScreen extends StatefulWidget {
  final String? projectId;

  const ProjectSetupScreen({super.key, this.projectId}) : super();

  @override
  ProjectSetupScreenState createState() => ProjectSetupScreenState();
}

class ProjectSetupScreenState extends State<ProjectSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _keyController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedProjectType = 'Fixed Scope';
  ProjectStatus _selectedStatus = ProjectStatus.planning;
  ProjectPriority _selectedPriority = ProjectPriority.medium;
  
  bool _isLoading = false;
  bool _isEditing = false;
  Project? _originalProject;

  final List<String> _projectTypes = [
    'Fixed Scope',
    'Time & Materials',
    'Support / Maintenance',
    'Internal',
  ];

  final Map<String, String?> _validationErrors = {
    'name': null,
    'key': null,
    'description': null,
    'clientName': null,
    'startDate': null,
    'endDate': null,
  };

  @override
  void initState() {
    super.initState();
    _isEditing = widget.projectId != null;
    if (_isEditing) {
      _loadProject();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _clientNameController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    if (widget.projectId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final project = await ProjectService.getProjectById(widget.projectId!);
      if (project != null) {
        setState(() {
          _originalProject = project;
          _nameController.text = project.name;
          _descriptionController.text = project.description;
          _clientNameController.text = project.clientName ?? '';
          _keyController.text = project.projectType;
          _selectedProjectType = project.projectType;
          _selectedStatus = project.status;
          _selectedPriority = project.priority;
          _startDate = project.startDate;
          _endDate = project.endDate;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading project: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  String? _validateField(String fieldName, String? value) {
    switch (fieldName) {
      case 'name':
        if (value == null || value.trim().isEmpty) {
          return 'Project name is required';
        }
        if (value.trim().length < 3) {
          return 'Project name must be at least 3 characters';
        }
        if (value.trim().length > 100) {
          return 'Project name must not exceed 100 characters';
        }
        if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(value.trim())) {
          return 'Project name can only contain letters, numbers, spaces, hyphens, and underscores';
        }
        break;
      case 'key':
        if (value == null || value.trim().isEmpty) {
          return 'Project key is required';
        }
        if (value.trim().length < 2) {
          return 'Project key must be at least 2 characters';
        }
        if (value.trim().length > 20) {
          return 'Project key must not exceed 20 characters';
        }
        if (!RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(value.trim())) {
          return 'Project key must start with letter and contain only uppercase letters, numbers, and underscores';
        }
        break;
      case 'description':
        if (value == null || value.trim().isEmpty) {
          return 'Description is required';
        }
        if (value.trim().length < 10) {
          return 'Description must be at least 10 characters';
        }
        if (value.trim().length > 1000) {
          return 'Description must not exceed 1000 characters';
        }
        break;
      case 'clientName':
        if (value == null || value.trim().isEmpty) {
          return 'Client name is required';
        }
        if (value.trim().length < 2) {
          return 'Client name must be at least 2 characters';
        }
        if (value.trim().length > 100) {
          return 'Client name must not exceed 100 characters';
        }
        break;
      case 'startDate':
        if (_startDate == null) {
          return 'Start date is required';
        }
        break;
      case 'endDate':
        if (_endDate == null) {
          return 'End date is required';
        }
        if (_startDate != null && _endDate!.isBefore(_startDate!)) {
          return 'End date must be after start date';
        }
        break;
    }
    return null;
  }

  void _validateFieldOnChange(String fieldName, String? value) {
    final error = _validateField(fieldName, value);
    setState(() {
      _validationErrors[fieldName] = error;
    });
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      _showValidationErrorSummary();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final projectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'clientName': _clientNameController.text.trim(),
        'projectType': _selectedProjectType,
        'status': _selectedStatus.name,
        'priority': _selectedPriority.name,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
      };

      Project? savedProject;
      
      if (_isEditing && widget.projectId != null) {
        savedProject = await ProjectService.updateProject(widget.projectId!, projectData);
        _showSuccessSnackBar('Project updated successfully');
      } else {
        savedProject = await ProjectService.createProject(projectData);
        _showSuccessSnackBar('Project created successfully');
      }

      if (mounted) {
        Navigator.of(context).pop(savedProject);
      }
    } catch (e) {
      _showErrorSnackBar('Error saving project: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showValidationErrorSummary() {
    final errors = <String>[];
    _validationErrors.forEach((field, error) {
      if (error != null) {
        errors.add(error);
      }
    });

    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Errors'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.map((error) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error)),
                ],
              ),
            ),).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projectId != null && _originalProject == null && !_isLoading) {
      _loadProject();
    }
    
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildForm(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Project',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Define basic project details so deliverables and sprints can be tracked correctly.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 18,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProjectInformationSection(),
              const SizedBox(height: 24),
              _buildTimelineSection(),
              const SizedBox(height: 24),
              _buildClientClassificationSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectInformationSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildModernNameField(),
          const SizedBox(height: 16),
          _buildModernDescriptionField(),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildModernDateFields(),
        ],
      ),
    );
  }

  Widget _buildClientClassificationSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client & Classification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildModernClientField(),
          const SizedBox(height: 16),
          _buildModernProjectTypeField(),
        ],
      ),
    );
  }

  Widget _buildModernNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Name*',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter project name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLength: 100,
          onChanged: (value) => _validateFieldOnChange('name', value),
          validator: (value) => _validateField('name', value),
        ),
      ],
    );
  }

  Widget _buildModernDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Description',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Enter project description',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 3,
          maxLength: 1000,
          onChanged: (value) => _validateFieldOnChange('description', value),
          validator: (value) => _validateField('description', value),
        ),
      ],
    );
  }

  Widget _buildModernDateFields() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Date*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, isStartDate: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Select start date',
                          style: TextStyle(
                            color: _startDate != null ? Colors.black87 : Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'End Date*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, isStartDate: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Select end date',
                          style: TextStyle(
                            color: _endDate != null ? Colors.black87 : Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernClientField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client*',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _clientNameController,
          decoration: InputDecoration(
            hintText: 'Select client',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ),
          onChanged: (value) => _validateFieldOnChange('clientName', value),
          validator: (value) => _validateField('clientName', value),
        ),
      ],
    );
  }

  Widget _buildModernProjectTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Type*',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProjectType,
              hint: Text('Choose project type', style: TextStyle(color: Colors.grey[500])),
              isExpanded: true,
              items: _projectTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    type,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProjectType = newValue!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saveProject,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save Project',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
