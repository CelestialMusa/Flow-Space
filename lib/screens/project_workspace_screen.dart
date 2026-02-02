import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/deliverable.dart';
import '../models/sprint.dart';
import '../models/user.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ProjectWorkspaceScreen extends ConsumerStatefulWidget {
  final String? projectId;
  
  const ProjectWorkspaceScreen({
    super.key,
    this.projectId,
  });

  @override
  ConsumerState<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends ConsumerState<ProjectWorkspaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _tagsController = TextEditingController();
  
  ProjectStatus _selectedStatus = ProjectStatus.planning;
  ProjectPriority _selectedPriority = ProjectPriority.medium;
  String _selectedProjectType = 'software';
  DateTime? _startDate;
  DateTime? _endDate;
  
  List<ProjectMember> _members = [];
  List<String> _deliverableIds = [];
  List<String> _sprintIds = [];
  List<Deliverable> _availableDeliverables = [];
  List<Sprint> _availableSprints = [];
  List<User> _availableUsers = [];
  
  bool _isLoading = false;
  bool _isEditing = false;
  Project? _currentProject;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _isEditing = true;
      _loadProject();
    }
    _loadAvailableData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _clientNameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    if (widget.projectId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final project = await ApiService.getProject(widget.projectId!);
      if (project != null) {
        setState(() {
          _currentProject = project;
          _nameController.text = project.name;
          _descriptionController.text = project.description;
          _clientNameController.text = project.clientName ?? '';
          _selectedStatus = project.status;
          _selectedPriority = project.priority;
          _selectedProjectType = project.projectType;
          _startDate = project.startDate;
          _endDate = project.endDate;
          _tagsController.text = project.tags.join(', ');
          _members = project.members;
          _deliverableIds = project.deliverableIds;
          _sprintIds = project.sprintIds;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load project: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvailableData() async {
    try {
      final deliverables = await ApiService.getDeliverables();
      final sprints = await ApiService.getSprints();
      final users = await ApiService.getUsers();
      
      setState(() {
        _availableDeliverables = deliverables.map((d) => Deliverable.fromJson(d)).toList();
        _availableSprints = sprints.map((s) => Sprint.fromJson(s)).toList();
        _availableUsers = users.map((u) => User.fromJson(u)).toList();
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load available data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final project = Project(
        id: _isEditing ? _currentProject!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        clientName: _clientNameController.text.trim().isEmpty ? null : _clientNameController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        projectType: _selectedProjectType,
        startDate: _startDate ?? DateTime.now(),
        endDate: _endDate,
        tags: _tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
        members: _members,
        deliverableIds: _deliverableIds,
        sprintIds: _sprintIds,
        createdBy: AuthService().currentUser?.id ?? 'unknown',
        createdAt: _isEditing ? _currentProject!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        updatedBy: AuthService().currentUser?.id ?? 'unknown',
      );

      if (_isEditing) {
        await ApiService.updateProject(project);
        _showSuccessSnackBar('Project updated successfully');
      } else {
        await ApiService.createProjectModel(project);
        _showSuccessSnackBar('Project created successfully');
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save project: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMember() {
    showDialog(
      context: context,
      builder: (context) => _AddMemberDialog(
        availableUsers: _availableUsers,
        onAdd: (user, role) {
          setState(() {
            if (!_members.any((m) => m.userId == user.id)) {
              _members.add(ProjectMember(
                userId: user.id,
                userName: user.name,
                userEmail: user.email,
                role: role,
                assignedAt: DateTime.now(),
              ));
            }
          });
        },
      ),
    );
  }

  void _removeMember(String userId) {
    setState(() {
      _members.removeWhere((m) => m.userId == userId);
    });
  }

  void _addDeliverable() {
    showDialog(
      context: context,
      builder: (context) => _SelectDeliverablesDialog(
        availableDeliverables: _availableDeliverables,
        selectedIds: _deliverableIds,
        onSelect: (ids) {
          setState(() {
            _deliverableIds = ids;
          });
        },
      ),
    );
  }

  void _addSprint() {
    showDialog(
      context: context,
      builder: (context) => _SelectSprintsDialog(
        availableSprints: _availableSprints,
        selectedIds: _sprintIds,
        onSelect: (ids) {
          setState(() {
            _sprintIds = ids;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Project' : 'Create New Project',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface.withAlpha(200),
                colorScheme.surface.withAlpha(100),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surface.withAlpha(240),
                    colorScheme.surface.withAlpha(220),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(colorScheme),
                      const SizedBox(height: 24),
                      _buildMetadataSection(colorScheme),
                      const SizedBox(height: 24),
                      _buildDatesSection(colorScheme),
                      const SizedBox(height: 24),
                      _buildMembersSection(colorScheme),
                      const SizedBox(height: 24),
                      _buildDeliverablesSection(colorScheme),
                      const SizedBox(height: 24),
                      _buildSprintsSection(colorScheme),
                      const SizedBox(height: 32),
                      _buildActionButtons(colorScheme),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection(ColorScheme colorScheme) {
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.primary.withAlpha(20),
          colorScheme.secondary.withAlpha(10),
        ],
      ),
      border: Border.all(
        color: colorScheme.primary.withAlpha(40),
        width: 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Project Name *',
              hintText: 'Enter project name',
              prefixIcon: Icon(Icons.work_outline, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surface.withAlpha(100),
            ),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Project name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe the project goals and objectives',
              prefixIcon: Icon(Icons.description_outlined, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surface.withAlpha(100),
            ),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _clientNameController,
            decoration: InputDecoration(
              labelText: 'Client Name',
              hintText: 'Enter client or customer name',
              prefixIcon: Icon(Icons.business_outlined, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surface.withAlpha(100),
            ),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(ColorScheme colorScheme) {
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.secondary.withAlpha(20),
          colorScheme.tertiary.withAlpha(10),
        ],
      ),
      border: Border.all(
        color: colorScheme.secondary.withAlpha(40),
        width: 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Project Metadata',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<ProjectStatus>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(Icons.flag_outlined, color: colorScheme.secondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.secondary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surface.withAlpha(100),
            ),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
            items: ProjectStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProjectPriority>(
            initialValue: _selectedPriority,
            decoration: InputDecoration(
              labelText: 'Priority',
              prefixIcon: Icon(Icons.priority_high_outlined, color: colorScheme.secondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.secondary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surface.withAlpha(100),
            ),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
            items: ProjectPriority.values.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Text(priority.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPriority = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedProjectType,
            decoration: InputDecoration(
              labelText: 'Project Type',
              prefixIcon: Icon(Icons.category_outlined, color: colorScheme.secondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.secondary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surface.withAlpha(100),
            ),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
            items: const [
              DropdownMenuItem(value: 'software', child: Text('Software')),
              DropdownMenuItem(value: 'hardware', child: Text('Hardware')),
              DropdownMenuItem(value: 'research', child: Text('Research')),
              DropdownMenuItem(value: 'consulting', child: Text('Consulting')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedProjectType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: 'Tags (comma-separated)',
              hintText: 'e.g. mobile, frontend, urgent',
              prefixIcon: Icon(Icons.tag_outlined, color: colorScheme.secondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.secondary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surface.withAlpha(100),
              helperText: 'Enter tags separated by commas',
            ),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection(ColorScheme colorScheme) {
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.tertiary.withAlpha(20),
          colorScheme.primary.withAlpha(10),
        ],
      ),
      border: Border.all(
        color: colorScheme.tertiary.withAlpha(40),
        width: 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range_outlined,
                color: colorScheme.tertiary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Project Dates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withAlpha(50),
              ),
              color: colorScheme.surface.withAlpha(100),
            ),
            child: ListTile(
              leading: Icon(Icons.calendar_today, color: colorScheme.tertiary),
              title: Text(
                'Start Date',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                _startDate != null ? _startDate!.toString().split(' ')[0] : 'Not set',
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(180),
                ),
              ),
              trailing: Icon(Icons.arrow_drop_down, color: colorScheme.tertiary),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withAlpha(50),
              ),
              color: colorScheme.surface.withAlpha(100),
            ),
            child: ListTile(
              leading: Icon(Icons.event_outlined, color: colorScheme.tertiary),
              title: Text(
                'End Date',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                _endDate != null ? _endDate!.toString().split(' ')[0] : 'Not set',
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(180),
                ),
              ),
              trailing: Icon(Icons.arrow_drop_down, color: colorScheme.tertiary),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(ColorScheme colorScheme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: _addMember,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_members.isEmpty)
            const Text('No members added yet')
          else
            ..._members.map((member) => ListTile(
              title: Text(member.userName),
              subtitle: Text('${member.userEmail} • ${member.role.name}'),
              trailing: IconButton(
                onPressed: () => _removeMember(member.userId),
                icon: const Icon(Icons.remove, color: Colors.red),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildDeliverablesSection(ColorScheme colorScheme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Linked Deliverables',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: _addDeliverable,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_deliverableIds.isEmpty)
            const Text('No deliverables linked yet')
          else
            ..._deliverableIds.map((id) {
              final deliverable = _availableDeliverables.firstWhere(
                (d) => d.id == id,
                orElse: () => Deliverable(
                  id: id,
                  title: 'Unknown',
                  description: '',
                  status: DeliverableStatus.draft,
                  createdAt: DateTime.now(),
                  dueDate: DateTime.now(),
                  sprintIds: [],
                  definitionOfDone: [],
                ),
              );
              return ListTile(
                title: Text(deliverable.title),
                subtitle: Text(deliverable.statusDisplayName),
                trailing: IconButton(
                  onPressed: () {
                    setState(() {
                      _deliverableIds.remove(id);
                    });
                  },
                  icon: const Icon(Icons.remove, color: Colors.red),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSprintsSection(ColorScheme colorScheme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Associated Sprints',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: _addSprint,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_sprintIds.isEmpty)
            const Text('No sprints associated yet')
          else
            ..._sprintIds.map((id) {
              final sprint = _availableSprints.firstWhere(
                (s) => s.id == id,
                orElse: () => Sprint(
                  id: id,
                  name: 'Unknown',
                  startDate: DateTime.now(),
                  endDate: DateTime.now(),
                  committedPoints: 0,
                  completedPoints: 0,
                  velocity: 0,
                  testPassRate: 0.0,
                  defectCount: 0,
                ),
              );
              return ListTile(
                title: Text(sprint.name),
                subtitle: Text(sprint.statusText),
                trailing: IconButton(
                  onPressed: () {
                    setState(() {
                      _sprintIds.remove(id);
                    });
                  },
                  icon: const Icon(Icons.remove, color: Colors.red),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.primary.withAlpha(30),
          colorScheme.secondary.withAlpha(20),
        ],
      ),
      border: Border.all(
        color: colorScheme.primary.withAlpha(50),
        width: 1.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                      ),
                    )
                  : _isEditing 
                  ? const Text(
                      'Update Project',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : const Text(
                      'Create Project',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colorScheme.outline),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  final List<User> availableUsers;
  final Function(User, ProjectRole) onAdd;

  const _AddMemberDialog({
    required this.availableUsers,
    required this.onAdd,
  });

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  User? _selectedUser;
  ProjectRole _selectedRole = ProjectRole.contributor;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Team Member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<User>(
            initialValue: _selectedUser,
            decoration: const InputDecoration(
              labelText: 'Select User',
              border: OutlineInputBorder(),
            ),
            items: widget.availableUsers.map((user) {
              return DropdownMenuItem(
                value: user,
                child: Text('${user.name} (${user.email})'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUser = value;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProjectRole>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
            ),
            items: ProjectRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedUser != null
              ? () {
                  widget.onAdd(_selectedUser!, _selectedRole);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _SelectDeliverablesDialog extends StatefulWidget {
  final List<Deliverable> availableDeliverables;
  final List<String> selectedIds;
  final Function(List<String>) onSelect;

  const _SelectDeliverablesDialog({
    required this.availableDeliverables,
    required this.selectedIds,
    required this.onSelect,
  });

  @override
  State<_SelectDeliverablesDialog> createState() => _SelectDeliverablesDialogState();
}

class _SelectDeliverablesDialogState extends State<_SelectDeliverablesDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Deliverables'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: widget.availableDeliverables.length,
          itemBuilder: (context, index) {
            final deliverable = widget.availableDeliverables[index];
            final isSelected = _selectedIds.contains(deliverable.id);
            
            return CheckboxListTile(
              title: Text(deliverable.title),
              subtitle: Text(deliverable.statusDisplayName),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(deliverable.id);
                  } else {
                    _selectedIds.remove(deliverable.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSelect(_selectedIds.toList());
            Navigator.of(context).pop();
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}

class _SelectSprintsDialog extends StatefulWidget {
  final List<Sprint> availableSprints;
  final List<String> selectedIds;
  final Function(List<String>) onSelect;

  const _SelectSprintsDialog({
    required this.availableSprints,
    required this.selectedIds,
    required this.onSelect,
  });

  @override
  State<_SelectSprintsDialog> createState() => _SelectSprintsDialogState();
}

class _SelectSprintsDialogState extends State<_SelectSprintsDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Sprints'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: widget.availableSprints.length,
          itemBuilder: (context, index) {
            final sprint = widget.availableSprints[index];
            final isSelected = _selectedIds.contains(sprint.id);
            
            return CheckboxListTile(
              title: Text(sprint.name),
              subtitle: Text(sprint.statusText),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(sprint.id);
                  } else {
                    _selectedIds.remove(sprint.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSelect(_selectedIds.toList());
            Navigator.of(context).pop();
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
