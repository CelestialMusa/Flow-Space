import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/project.dart';
import '../models/deliverable.dart';
import '../models/sprint.dart';
import '../models/user.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_data_service.dart';
import '../services/project_service.dart';

class ProjectWorkspaceScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const ProjectWorkspaceScreen({
    super.key,
    this.projectId,
  });

  @override
  ConsumerState<ProjectWorkspaceScreen> createState() =>
      _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState
    extends ConsumerState<ProjectWorkspaceScreen> {
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
  User? _selectedOwner;

  bool _isLoading = false;
  bool _isEditing = false;
  Project? _currentProject;
  List<Project> _projects = [];
  bool _showProjectsList = false;

  @override
  void initState() {
    super.initState();
    // Show projects list only if projectId is null or empty (not 'new')
    _showProjectsList = widget.projectId == null || widget.projectId == '';
    _initData();
  }

  @override
  void didUpdateWidget(ProjectWorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When returning from create form (projectId was 'new', now list) refetch so new project appears
    final wasCreateForm = oldWidget.projectId == 'new';
    final isListNow = widget.projectId == null || widget.projectId == '';
    if (wasCreateForm && isListNow) {
      _showProjectsList = true;
      _loadProjects();
    } else if (widget.projectId != oldWidget.projectId) {
      _showProjectsList = widget.projectId == null || widget.projectId == '';
      if (_showProjectsList) {
        _loadProjects();
      }
    }
  }

  Future<void> _initData() async {
    if (_showProjectsList) {
      await _loadProjects();
    } else {
      await _loadAvailableData();
      // If projectId is 'new', show create form (not editing)
      // If projectId is an actual ID, load the project for editing
      if (widget.projectId != null && widget.projectId != 'new') {
        _isEditing = true;
        await _loadProject();
      }
      // If projectId is 'new', _isEditing stays false, showing create form
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final projects = await ProjectService.getAllProjects(limit: 1000);
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _projects = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load projects. Tap refresh to retry.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    if (widget.projectId == null || widget.projectId == 'new') return;

    setState(() => _isLoading = true);
    try {
      final project = await ApiService.getProject(widget.projectId!);
      if (project != null) {
        // First populate base fields
        setState(() {
          _currentProject = project;
          _nameController.text = project.name;
          _descriptionController.text = project.description;
          _clientNameController.text = project.clientName ?? '';
          _selectedStatus = project.status;
          _selectedPriority = project.priority;
          const validProjectTypes = ['software', 'hardware', 'research', 'consulting', 'other'];
          _selectedProjectType = validProjectTypes.contains(project.projectType) ? project.projectType : 'other';
          _startDate = project.startDate;
          _endDate = project.endDate;
          _tagsController.text = project.tags.join(', ');
          _members = project.members;

          // Prefer IDs from project payload when present
          _deliverableIds = project.deliverableIds;
          _sprintIds = project.sprintIds;

          // Set selected owner
          try {
            // Prefer ownerId from project if available (frontend model update pending in other files)
            // or fallback to finding member with owner role
            if (project.ownerId != null) {
              _selectedOwner =
                  _availableUsers.firstWhere((u) => u.id == project.ownerId);
            } else {
              final ownerMember =
                  _members.firstWhere((m) => m.role == ProjectRole.owner);
              _selectedOwner =
                  _availableUsers.firstWhere((u) => u.id == ownerMember.userId);
            }
          } catch (_) {}
        });

        // If backend did not send deliverableIds, derive from deliverables that reference this project
        if (_deliverableIds.isEmpty && _availableDeliverables.isNotEmpty) {
          final derivedDeliverables = _availableDeliverables
              .where((d) => d.projectId == project.id)
              .map((d) => d.id)
              .toList();
          if (derivedDeliverables.isNotEmpty) {
            setState(() {
              _deliverableIds = derivedDeliverables;
            });
          }
        }

        // If backend did not send sprintIds, fetch sprints linked to this project
        if (_sprintIds.isEmpty) {
          try {
            final sprintMaps = await ApiService.getSprints(projectId: project.id);
            final ids = sprintMaps
                .map((s) => s['id']?.toString())
                .where((id) => id != null && id.isNotEmpty)
                .cast<String>()
                .toList();
            if (ids.isNotEmpty) {
              setState(() {
                _sprintIds = ids;
              });
            }
          } catch (_) {}
        }
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
      final users = await UserDataService().getUsers(limit: 1000);

      setState(() {
        _availableDeliverables =
            deliverables.map((d) => Deliverable.fromJson(d)).toList();
        _availableSprints = sprints.map((s) => Sprint.fromJson(s)).toList();
        _availableUsers = users;

        // Set default owner if creating new project
        if (!_isEditing && _selectedOwner == null) {
          final currentUserId = AuthService().currentUser?.id;
          if (currentUserId != null) {
            try {
              _selectedOwner =
                  _availableUsers.firstWhere((u) => u.id == currentUserId);
            } catch (_) {}
          }
        }
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
      // Derive a sensible project key if creating a new project
      String deriveProjectKey() {
        if (_isEditing && _currentProject != null) {
          return _currentProject!.key;
        }
        final name = _nameController.text.trim();
        if (name.isEmpty) return 'PRJ';
        final parts =
            name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
        final key = parts.map((p) => p[0]).take(4).join().toUpperCase();
        return key.isEmpty ? 'PRJ' : key;
      }

      final project = Project(
        id: _isEditing
            ? _currentProject!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        key: deriveProjectKey(),
        description: _descriptionController.text,
        clientName: _clientNameController.text.trim().isEmpty
            ? null
            : _clientNameController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        projectType: _selectedProjectType,
        startDate: _startDate ?? DateTime.now(),
        endDate: _endDate,
        tags: _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        members: _members,
        deliverableIds: _deliverableIds,
        sprintIds: _sprintIds,
        createdBy: AuthService().currentUser?.id ?? 'unknown',
        createdAt: _isEditing ? _currentProject!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        updatedBy: AuthService().currentUser?.id ?? 'unknown',
        ownerId: _selectedOwner?.id,
      );

      bool saved = false;
      if (_isEditing) {
        saved = await ApiService.updateProject(project);
        if (saved) _showSuccessSnackBar('Project updated successfully');
      } else {
        saved = await ApiService.createProjectModel(project);
        if (saved) _showSuccessSnackBar('Project created successfully');
      }

      if (mounted && saved) {
        // Only navigate after a successful save so the list will show the new/updated project
        try {
          context.go('/project-workspace');
        } catch (e) {
          try {
            context.go('/dashboard');
          } catch (_) {}
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save project: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openMemberSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => _SelectMembersDialog(
        availableUsers: _availableUsers,
        selectedUserIds: _members.map((m) => m.userId).toList(),
        onSelect: (selectedUsers) {
          setState(() {
            // Keep existing members who are still selected
            final existingMembers = _members
                .where((m) => selectedUsers.any((u) => u.id == m.userId))
                .toList();

            // Add new members
            for (var user in selectedUsers) {
              if (!existingMembers.any((m) => m.userId == user.id)) {
                existingMembers.add(ProjectMember(
                  userId: user.id,
                  userName: user.name,
                  userEmail: user.email,
                  role: ProjectRole.contributor, // Default role
                  assignedAt: DateTime.now(),
                ));
              }
            }
            _members = existingMembers;
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

  Future<void> _sendDueDateReminder() async {
    if (!_isEditing || _currentProject == null) {
      return;
    }
    if (_selectedOwner == null) {
      _showErrorSnackBar('Assign a project owner before sending a reminder.');
      return;
    }
    if (_endDate == null) {
      _showErrorSnackBar('Set an end date before sending a reminder.');
      return;
    }
    final now = DateTime.now();
    if (_endDate!.isAfter(now)) {
      _showErrorSnackBar('Reminder is only available when the project has reached or passed its end date.');
      return;
    }
    if (_selectedStatus == ProjectStatus.completed || _selectedStatus == ProjectStatus.cancelled) {
      _showErrorSnackBar('Project is already completed or cancelled.');
      return;
    }
    setState(() {
      _isSendingReminder = true;
    });
    try {
      final backend = ref.read(backendApiServiceProvider);
      final response = await backend.remindProjectOwner(_currentProject!.id);
      if (response.isSuccess) {
        _showSuccessSnackBar('Reminder sent to project owner.');
      } else {
        _showErrorSnackBar(response.error ?? 'Failed to send reminder.');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send reminder: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingReminder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          _showProjectsList
              ? 'Project Workspace'
              : (_isEditing ? 'Edit Project' : 'Create New Project'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
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
        actions: _showProjectsList
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context.go('/project-workspace/new'),
                  tooltip: 'Create New Project',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadProjects,
                  tooltip: 'Refresh Projects',
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : _showProjectsList
              ? _buildProjectsList(colorScheme)
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

  Widget _buildProjectsList(ColorScheme colorScheme) {
    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colorScheme.primary.withAlpha(128)),
                        ),
                        child: Icon(
                          Icons.folder_outlined,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Projects',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View and manage your projects and their sprints',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Projects List
            if (_projects.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 64,
                      color: colorScheme.onSurface.withAlpha(128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No projects yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first project to get started',
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/project-workspace/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Project'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Projects',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      final project = _projects[index];
                      return _buildProjectCard(project, colorScheme);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: InkWell(
          onTap: () => context.go('/project-workspace/${project.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (project.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            project.description,
                            style: TextStyle(
                              color: colorScheme.onSurface.withAlpha(230),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          _getProjectStatusColor(project.status).withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getProjectStatusColor(project.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      project.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getProjectStatusColor(project.status),
                      ),
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

  Color _getProjectStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return Colors.green;
      case ProjectStatus.completed:
        return Colors.blue;
      case ProjectStatus.onHold:
        return Colors.orange;
      case ProjectStatus.cancelled:
        return Colors.red;
      case ProjectStatus.planning:
        return Colors.grey;
    }
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
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(50)),
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
              prefixIcon:
                  Icon(Icons.description_outlined, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(50)),
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
              prefixIcon:
                  Icon(Icons.business_outlined, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(50)),
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
          const SizedBox(height: 16),
          DropdownButtonFormField<User>(
            // ignore: deprecated_member_use
            value: _selectedOwner,
            // Allow owner selection for System Admins or during editing
            onChanged: (value) {
              setState(() {
                _selectedOwner = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Project Owner *',
              prefixIcon:
                  Icon(Icons.person_outline, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(50)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: _isEditing
                  ? colorScheme.surface.withAlpha(100)
                  : colorScheme.surface
                      .withAlpha(50), // Visual cue for disabled state
            ),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
            items: _availableUsers.map((user) {
              return DropdownMenuItem(
                value: user,
                child: Text(user.name),
              );
            }).toList(),
            validator: (value) {
              if (value == null) {
                return 'Project owner is required';
              }
              return null;
            },
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
              prefixIcon:
                  Icon(Icons.flag_outlined, color: colorScheme.secondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(50)),
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
              prefixIcon: Icon(Icons.priority_high_outlined,
                  color: colorScheme.secondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(50)),
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
            // ignore: deprecated_member_use
            value: const ['software', 'hardware', 'research', 'consulting', 'other'].contains(_selectedProjectType)
                ? _selectedProjectType
                : null,
            decoration: InputDecoration(
              labelText: 'Project Type',
              prefixIcon:
                  Icon(Icons.category_outlined, color: colorScheme.secondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(50)),
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
              prefixIcon:
                  Icon(Icons.tag_outlined, color: colorScheme.secondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(100)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withAlpha(50)),
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
                _startDate != null
                    ? _startDate!.toString().split(' ')[0]
                    : 'Not set',
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(180),
                ),
              ),
              trailing:
                  Icon(Icons.arrow_drop_down, color: colorScheme.tertiary),
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
                _endDate != null
                    ? _endDate!.toString().split(' ')[0]
                    : 'Not set',
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(180),
                ),
              ),
              trailing:
                  Icon(Icons.arrow_drop_down, color: colorScheme.tertiary),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? DateTime.now().add(const Duration(days: 30)),
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
          const SizedBox(height: 8),
          if (_isEditing && _currentProject != null && _selectedOwner != null && _endDate != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isSendingReminder ? null : _sendDueDateReminder,
                icon: _isSendingReminder
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      )
                    : Icon(
                        Icons.notifications_active_outlined,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                label: Text(
                  'Remind Project Owner',
                  style: TextStyle(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(ColorScheme colorScheme) {
    final currentUserId = AuthService().currentUser?.id;
    final isOwner =
        _selectedOwner?.id != null && _selectedOwner!.id == currentUserId;
    // Allow member assignment if it's a new project or if the current user is the owner
    // User requirement: "only the project owner can assign users to projects."
    final canAssignMembers = !_isEditing || isOwner;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Team Members',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!canAssignMembers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Only the project owner can assign members.',
                style: TextStyle(
                    color: colorScheme.error, fontStyle: FontStyle.italic),
              ),
            ),
          InkWell(
            onTap: canAssignMembers ? _openMemberSelectionDialog : null,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Assign Members',
                prefixIcon: Icon(Icons.group_add_outlined,
                    color: canAssignMembers
                        ? colorScheme.primary
                        : colorScheme.outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabled: canAssignMembers,
                filled: true,
                fillColor: canAssignMembers
                    ? colorScheme.surface.withAlpha(100)
                    : colorScheme.surface.withAlpha(50),
                suffixIcon: Icon(Icons.arrow_drop_down,
                    color: canAssignMembers
                        ? colorScheme.primary
                        : colorScheme.outline),
              ),
              child: _members.isEmpty
                  ? Text('Select members...',
                      style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(100)))
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _members
                          .map((member) => Chip(
                                label: Text(member.userName),
                                onDeleted: canAssignMembers
                                    ? () => _removeMember(member.userId)
                                    : null,
                              ))
                          .toList(),
                    ),
            ),
          ),
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
                onTap: () {
                  GoRouter.of(context).push('/deliverable-detail', extra: deliverable);
                },
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
                onTap: () {
                  final projectId = widget.projectId;
                  final sprintId = sprint.id;
                  
                  if (sprintId.isNotEmpty) {
                    final queryParams = <String, String>{
                      'sprintId': sprintId,
                    };
                    if (projectId != null && projectId.isNotEmpty && projectId != 'new') {
                      queryParams['projectId'] = projectId;
                    }
                    final uri = Uri(path: '/sprint-console', queryParameters: queryParams);
                    context.go(uri.toString());
                  } else {
                    context.go('/sprint-console');
                  }
                },
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary),
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
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/sprint-console');
                }
              },
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

class _SelectMembersDialog extends StatefulWidget {
  final List<User> availableUsers;
  final List<String> selectedUserIds;
  final Function(List<User>) onSelect;

  const _SelectMembersDialog({
    required this.availableUsers,
    required this.selectedUserIds,
    required this.onSelect,
  });

  @override
  State<_SelectMembersDialog> createState() => _SelectMembersDialogState();
}

class _SelectMembersDialogState extends State<_SelectMembersDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedUserIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Team Members'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: widget.availableUsers.length,
          itemBuilder: (context, index) {
            final user = widget.availableUsers[index];
            final isSelected = _selectedIds.contains(user.id);

            return CheckboxListTile(
              title: Text(user.name),
              subtitle: Text(user.email),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIds.add(user.id);
                  } else {
                    _selectedIds.remove(user.id);
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
            final selectedUsers = widget.availableUsers
                .where((u) => _selectedIds.contains(u.id))
                .toList();
            widget.onSelect(selectedUsers);
            Navigator.of(context).pop();
          },
          child: const Text('Select'),
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
  State<_SelectDeliverablesDialog> createState() =>
      _SelectDeliverablesDialogState();
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
