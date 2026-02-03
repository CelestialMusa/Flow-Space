import 'package:flutter/material.dart';
import '../models/project_role.dart';
import '../services/project_member_service.dart';
import '../services/project_sprint_service.dart';
import '../widgets/sprint_selector.dart';

class ProjectSprintManagementScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectSprintManagementScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _ProjectSprintManagementScreenState createState() => _ProjectSprintManagementScreenState();
}

class _ProjectSprintManagementScreenState extends State<ProjectSprintManagementScreen> {
  List<Map<String, dynamic>> _linkedSprints = [];
  ProjectRole? _userRole;
  bool _isLoading = true;
  String? _error;
  List<String> _selectedSprintIds = [];

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load user role first
      final userRoleData = await ProjectMemberService.getUserRoleInProject(widget.projectId);
      final userRole = userRoleData['isMember'] == true 
          ? ProjectRoleExtension.fromString(userRoleData['role'])
          : null;

      // Load linked sprints
      final sprints = await ProjectSprintService.getProjectSprints(widget.projectId);

      setState(() {
        _userRole = userRole;
        _linkedSprints = sprints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _linkSelectedSprints() async {
    if (_selectedSprintIds.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ProjectSprintService.linkSprintsToProject(
        widget.projectId,
        _selectedSprintIds,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Sprints linked successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reload data
      await _loadProjectData();
      
      // Clear selection
      setState(() {
        _selectedSprintIds = [];
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error linking sprints: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unlinkSprint(String sprintId, String sprintName) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ProjectSprintService.unlinkSprintFromProject(
        widget.projectId,
        sprintId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$sprintName unlinked from project'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadProjectData();

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unlinking sprint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get _canManageSprints {
    if (_userRole == null) return false;
    return ProjectMemberService.hasPermission(_userRole!, 'manage_sprints');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.projectName} Sprints'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (_canManageSprints && _selectedSprintIds.isNotEmpty)
            TextButton.icon(
              onPressed: _linkSelectedSprints,
              icon: const Icon(Icons.link),
              label: Text('Link (${_selectedSprintIds.length})'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
              onPressed: _loadProjectData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_userRole == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'You are not a member of this project',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact a project owner to be added',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjectData,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_canManageSprints) ...[
                    _buildSprintSelector(),
                    const SizedBox(height: 24),
                  ],
                  _buildLinkedSprints(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final activeSprints = _linkedSprints.where((s) => s['status'] == 'active').length;
    final completedSprints = _linkedSprints.where((s) => s['status'] == 'completed').length;
    final avgProgress = _linkedSprints.isNotEmpty
        ? (_linkedSprints.fold(0.0, (sum, s) => sum + (s['progress'] as int? ?? 0)) / _linkedSprints.length).round()
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sprint, color: Colors.blue.shade800, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Sprints',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      '${_linkedSprints.length} sprints linked',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_canManageSprints)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Can Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Active', activeSprints.toString(), Colors.green),
              const SizedBox(width: 8),
              _buildStatCard('Completed', completedSprints.toString(), Colors.blue),
              const SizedBox(width: 8),
              _buildStatCard('Avg Progress', '$avgProgress%', Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _userRole!.description,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSprintSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text(
                'Link Sprints to Project',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SprintSelector(
            projectId: widget.projectId,
            onSelectionChanged: (selectedIds) {
              setState(() {
                _selectedSprintIds = selectedIds;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedSprints() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.linked_services, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text(
                'Linked Sprints',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_linkedSprints.length} items',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_linkedSprints.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.sprint, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No sprints linked yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _canManageSprints
                        ? 'Use the selector above to link existing sprints or create new ones'
                        : 'Project owners and contributors can link sprints',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._linkedSprints.map((sprint) {
              return _buildSprintCard(sprint);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSprintCard(Map<String, dynamic> sprint) {
    final status = sprint['status'] as String?;
    final progress = sprint['progress'] as int? ?? 0;
    final ticketCount = sprint['ticket_count'] as int? ?? 0;
    final completedTickets = sprint['completed_tickets'] as int? ?? 0;
    final startDate = sprint['start_date'] as String?;
    final endDate = sprint['end_date'] as String?;
    final isOverdue = ProjectSprintService.isOverdue(endDate, status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        sprint['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sprint['description'] != null && 
                          sprint['description'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            sprint['description'] as String,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_canManageSprints)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    onSelected: (value) {
                      if (value == 'unlink') {
                        _showUnlinkDialog(sprint);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'unlink',
                        child: Row(
                          children: [
                            Icon(Icons.link_off, size: 18, color: Colors.red.shade600),
                            SizedBox(width: 8),
                            Text('Unlink from Project'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ProjectSprintService.getStatusColor(status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ProjectSprintService.getStatusColor(status)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        IconData(
                          ProjectSprintService.getStatusIcon(status).codePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                        size: 14,
                        color: ProjectSprintService.getStatusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ProjectSprintService.formatSprintStatus(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ProjectSprintService.getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 14, color: Colors.red.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Overdue',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (startDate != null && endDate != null)
                  Text(
                    ProjectSprintService.calculateDuration(startDate, endDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            if (progress > 0 || ticketCount > 0) ...[
              Row(
                children: [
                  Text(
                    'Progress: $progress%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completedTickets/$ticketCount tickets',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress / 100.0,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ProjectSprintService.getProgressColor(progress),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (sprint['created_by_name'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Created by ${sprint['created_by_name']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (startDate != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Started ${ProjectSprintService.formatDate(startDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showUnlinkDialog(Map<String, dynamic> sprint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Sprint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to unlink "${sprint['name']}" from this project?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The sprint will no longer be tracked with this project but will not be deleted.',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _unlinkSprint(
                sprint['id'] as String,
                sprint['name'] as String,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }
}
