import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/sprint_database_service.dart';
import '../services/project_service.dart';
import '../models/project.dart';

class CreateSprintScreen extends StatefulWidget {
  final String? projectId;
  final String? projectName;

  const CreateSprintScreen({super.key, this.projectId, this.projectName});

  @override
  State<CreateSprintScreen> createState() => _CreateSprintScreenState();
}

class _CreateSprintScreenState extends State<CreateSprintScreen> {
  final SprintDatabaseService _sprintService = SprintDatabaseService();

  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _plannedPointsController = TextEditingController();
  
  // Project selection
  List<Project> _projects = [];
  Project? _selectedProject;
  bool _isLoadingProjects = false;
  String? _selectedProjectId;
  final TextEditingController _committedPointsController = TextEditingController();
  final TextEditingController _completedPointsController = TextEditingController();
  final TextEditingController _carriedOverPointsController = TextEditingController();
  final TextEditingController _addedDuringSprintController = TextEditingController();
  final TextEditingController _removedDuringSprintController = TextEditingController();
  final TextEditingController _testPassRateController = TextEditingController();
  final TextEditingController _codeCoverageController = TextEditingController();
  final TextEditingController _escapedDefectsController = TextEditingController();
  final TextEditingController _defectsOpenedController = TextEditingController();
  final TextEditingController _defectsClosedController = TextEditingController();
  final TextEditingController _defectSeverityMixController = TextEditingController();
  final TextEditingController _codeReviewCompletionController = TextEditingController();
  final TextEditingController _documentationStatusController = TextEditingController();
  final TextEditingController _uatNotesController = TextEditingController();
  final TextEditingController _uatPassRateController = TextEditingController();
  final TextEditingController _risksIdentifiedController = TextEditingController();
  final TextEditingController _risksController = TextEditingController();
  final TextEditingController _risksMitigatedController = TextEditingController();
  final TextEditingController _blockersController = TextEditingController();
  final TextEditingController _decisionsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
    if (widget.projectId == null) {
      _loadProjects();
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoadingProjects = true);
    try {
      final projects = await ProjectService.getAllProjects(limit: 1000);
      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
        // If projectId was passed, try to find and select it
        if (widget.projectId != null) {
          try {
            _selectedProject = _projects.firstWhere(
              (p) => p.id == widget.projectId,
            );
            _selectedProjectId = _selectedProject?.id;
          } catch (_) {
            // Project not found in list, that's okay
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingProjects = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: $e')),
        );
      }
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveSprint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    try {
      // Parse JSON for severity mix
      Map<String, dynamic>? severityMix;
      if (_defectSeverityMixController.text.isNotEmpty) {
        try {
          severityMix = jsonDecode(_defectSeverityMixController.text) as Map<String, dynamic>;
        } catch (_) {
          // If not valid JSON, we could try to parse simple key:value format or just ignore
          // For now, let's just ignore if it fails
        }
      }

      // Use selected project ID if no projectId was passed
      final projectIdToUse = _selectedProjectId ?? widget.projectId;
      
      if (projectIdToUse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a project')),
        );
        return;
      }

      await _sprintService.createSprint(
        name: _nameController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        projectId: projectIdToUse,
        plannedPoints: int.tryParse(_plannedPointsController.text) ?? 0,
        committedPoints: int.tryParse(_committedPointsController.text),
        completedPoints: int.tryParse(_completedPointsController.text),
        carriedOverPoints: int.tryParse(_carriedOverPointsController.text),
        testPassRate: double.tryParse(_testPassRateController.text),
        codeCoverage: int.tryParse(_codeCoverageController.text),
        escapedDefects: int.tryParse(_escapedDefectsController.text),
        defectsOpened: int.tryParse(_defectsOpenedController.text),
        defectsClosed: int.tryParse(_defectsClosedController.text),
        defectSeverityMix: severityMix,
        codeReviewCompletion: int.tryParse(_codeReviewCompletionController.text),
        documentationStatus: _documentationStatusController.text.isNotEmpty ? _documentationStatusController.text : null,
        uatNotes: _uatNotesController.text.isNotEmpty ? _uatNotesController.text : null,
        uatPassRate: int.tryParse(_uatPassRateController.text),
        risksIdentified: int.tryParse(_risksIdentifiedController.text),
        risks: _risksController.text.isNotEmpty ? _risksController.text : null,
        risksMitigated: int.tryParse(_risksMitigatedController.text),
        blockers: _blockersController.text.isNotEmpty ? _blockersController.text : null,
        decisions: _decisionsController.text.isNotEmpty ? _decisionsController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sprint created successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating sprint: $e');
      if (mounted) {
        final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Error creating sprint';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isEmpty ? 'Error creating sprint' : (msg.length > 150 ? '${msg.substring(0, 150)}...' : msg)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _plannedPointsController.dispose();
    _committedPointsController.dispose();
    _completedPointsController.dispose();
    _carriedOverPointsController.dispose();
    _addedDuringSprintController.dispose();
    _removedDuringSprintController.dispose();
    _testPassRateController.dispose();
    _codeCoverageController.dispose();
    _escapedDefectsController.dispose();
    _defectsOpenedController.dispose();
    _defectsClosedController.dispose();
    _defectSeverityMixController.dispose();
    _codeReviewCompletionController.dispose();
    _documentationStatusController.dispose();
    _uatNotesController.dispose();
    _uatPassRateController.dispose();
    _risksIdentifiedController.dispose();
    _risksController.dispose();
    _risksMitigatedController.dispose();
    _blockersController.dispose();
    _decisionsController.dispose();
    super.dispose();
  }

  Widget _buildNumberField(TextEditingController controller, String label, {bool isDouble = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🟢 CreateSprintScreen.build() called - projectId: ${widget.projectId}, projectName: ${widget.projectName}');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName == null
            ? 'Create Sprint'
            : 'Create Sprint - ${widget.projectName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project selection dropdown (only show if no project was pre-selected)
              if (widget.projectId == null) ...[
                _isLoadingProjects
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : DropdownButtonFormField<Project>(
                        initialValue: _selectedProject,
                        decoration: const InputDecoration(
                          labelText: 'Project *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.folder),
                        ),
                        hint: const Text('Select a project'),
                        items: _projects.map((project) {
                          return DropdownMenuItem<Project>(
                            value: project,
                            child: Text(project.name),
                          );
                        }).toList(),
                        onChanged: (Project? project) {
                          setState(() {
                            _selectedProject = project;
                            _selectedProjectId = project?.id;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a project';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 16),
              ] else if (widget.projectName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Project: ${widget.projectName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Sprint Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timeline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a sprint name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
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
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
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
              TextFormField(
                controller: _plannedPointsController,
                decoration: const InputDecoration(
                  labelText: 'Planned Points',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assessment),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              ExpansionTile(
                title: const Text('Outcomes', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildNumberField(_committedPointsController, 'Committed Pts')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumberField(_completedPointsController, 'Completed Pts')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(_carriedOverPointsController, 'Carried Over Points'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildNumberField(_defectsOpenedController, 'Defects Opened')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumberField(_defectsClosedController, 'Defects Closed')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildNumberField(_testPassRateController, 'Pass Rate %', isDouble: true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumberField(_codeCoverageController, 'Coverage %')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _uatNotesController,
                          decoration: const InputDecoration(
                            labelText: 'UAT Notes',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              ExpansionTile(
                title: const Text('Quality Signals', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        _buildNumberField(_escapedDefectsController, 'Escaped Defects'),
                        const SizedBox(height: 16),
                        _buildNumberField(_codeReviewCompletionController, 'Code Review Completion %'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _documentationStatusController,
                          decoration: const InputDecoration(
                            labelText: 'Documentation Status',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                         _buildNumberField(_uatPassRateController, 'UAT Pass Rate %'),
                      ],
                    ),
                  ),
                ],
              ),

              ExpansionTile(
                title: const Text('Notes & Risks', style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                         TextFormField(
                          controller: _risksController,
                          decoration: const InputDecoration(
                            labelText: 'Risks (Free-text)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _blockersController,
                          decoration: const InputDecoration(
                            labelText: 'Blockers',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _decisionsController,
                          decoration: const InputDecoration(
                            labelText: 'Decisions',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSprint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Create Sprint',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
