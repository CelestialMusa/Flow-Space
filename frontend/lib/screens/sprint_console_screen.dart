// ignore_for_file: unnecessary_null_comparison, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/project_sprint_service.dart';
import '../models/sprint.dart';

String initialStatusValue(String display) {
  final d = display.toLowerCase();
  if (d.contains('progress')) return 'in_progress';
  if (d.contains('complete')) return 'completed';
  if (d.contains('cancel')) return 'cancelled';
  return 'planning';
}

class SprintConsoleScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final String? projectName;

  const SprintConsoleScreen({super.key, this.projectId, this.projectName});

  @override
  ConsumerState<SprintConsoleScreen> createState() => _SprintConsoleScreenState();
}

class _SprintConsoleScreenState extends ConsumerState<SprintConsoleScreen> {
  List<Sprint> _sprints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  Future<void> _loadSprints() async {
    try {
      List<Sprint> sprints;
      
      if (widget.projectId != null) {
        // Load project-specific sprints
        final projectSprintsData = await ProjectSprintService.getProjectSprints(widget.projectId!);
        sprints = projectSprintsData.map((data) => Sprint.fromJson(data)).toList();
      } else {
        // Load all sprints
        sprints = await ApiService.getSprints(limit: 100);
      }
      
      setState(() {
        _sprints = sprints;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSprint() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateSprintScreen()),
    );
    if (result == true) {
      _loadSprints();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName != null 
            ? '${widget.projectName} Sprints' 
            : 'Sprint Console'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createSprint,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sprints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timeline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        widget.projectId != null 
                            ? 'No sprints linked to this project' 
                            : 'No sprints found',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.projectId != null 
                            ? 'Link existing sprints or create new ones for this project'
                            : 'Create your first sprint to get started',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createSprint,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Sprint'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sprints.length,
                  itemBuilder: (context, index) {
                    final sprint = _sprints[index];
                    final name = sprint.name;
                    final status = sprint.statusText.toLowerCase();
                    final planned = sprint.committedPoints;
                    final completed = sprint.completedPoints;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: planned > 0 ? completed / planned : 0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(_progressColor(completed, planned)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${planned > 0 ? ((completed / planned) * 100).toStringAsFixed(1) : '0.0'}% Complete',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withAlpha((0.3 * 255).round()),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/project-setup'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_business, size: 24),
          label: const Text('Create Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'planning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _progressColor(int completed, int planned) {
    if (planned == 0) return Colors.grey;
    final percentage = completed / planned;
    if (percentage >= 1.0) return Colors.green;
    if (percentage >= 0.8) return Colors.blue;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

class CreateSprintScreen extends StatefulWidget {
  const CreateSprintScreen({super.key});

  @override
  State<CreateSprintScreen> createState() => _CreateSprintScreenState();
}

class _CreateSprintScreenState extends State<CreateSprintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _plannedPointsController = TextEditingController();
  final _completedPointsController = TextEditingController();
  final _carriedOverPointsController = TextEditingController();
  final _testPassRateController = TextEditingController();
  final _codeCoverageController = TextEditingController();
  final _escapedDefectsController = TextEditingController();
  final _defectsOpenedController = TextEditingController();
  final _defectsClosedController = TextEditingController();
  final _risksIdentifiedController = TextEditingController();
  final _risksMitigatedController = TextEditingController();
  final _blockersController = TextEditingController();
  final _decisionsController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate?.add(const Duration(days: 14)) ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
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
      final create = SprintCreate(
        name: _nameController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        committedPoints: int.tryParse(_plannedPointsController.text) ?? 0,
        completedPoints: int.tryParse(_completedPointsController.text) ?? 0,
        velocity: 0,
        testPassRate: double.tryParse(_testPassRateController.text) ?? 0.0,
        codeCoverage: int.tryParse(_codeCoverageController.text) ?? 0,
        defectCount: int.tryParse(_defectsOpenedController.text) ?? 0,
        escapedDefects: int.tryParse(_escapedDefectsController.text) ?? 0,
        defectsClosed: int.tryParse(_defectsClosedController.text) ?? 0,
        carriedOverPoints: int.tryParse(_carriedOverPointsController.text) ?? 0,
        scopeChanges: [],
        risksIdentified: int.tryParse(_risksIdentifiedController.text) ?? 0,
        risksMitigated: int.tryParse(_risksMitigatedController.text) ?? 0,
        blockers: _blockersController.text,
        decisions: _decisionsController.text,
      );
      await ApiService.createSprint(create);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sprint created successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating sprint: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sprint'),
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
              ElevatedButton(
                onPressed: _saveSprint,
                child: const Text('Create Sprint'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}