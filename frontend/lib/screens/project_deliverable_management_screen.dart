import 'package:flutter/material.dart';
import '../models/project_role.dart';
import '../services/project_member_service.dart';
import '../services/project_deliverable_service.dart';
import '../widgets/deliverable_selector.dart';

class ProjectDeliverableManagementScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectDeliverableManagementScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ProjectDeliverableManagementScreenState createState() => ProjectDeliverableManagementScreenState();
}

class ProjectDeliverableManagementScreenState extends State<ProjectDeliverableManagementScreen> {
  List<Map<String, dynamic>> _linkedDeliverables = [];
  ProjectRole? _userRole;
  bool _isLoading = true;
  String? _error;
  List<String> _selectedDeliverableIds = [];

  // Helper method to convert hex color string to Color
  Color _hexToColor(String hexString) {
    final hexCode = hexString.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

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

      // Load linked deliverables
      final deliverables = await ProjectDeliverableService.getProjectDeliverables(widget.projectId);

      setState(() {
        _userRole = userRole;
        _linkedDeliverables = deliverables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _linkSelectedDeliverables() async {
    if (_selectedDeliverableIds.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ProjectDeliverableService.linkDeliverablesToProject(
        widget.projectId,
        _selectedDeliverableIds,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Deliverables linked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload data
      await _loadProjectData();
      
      // Clear selection
      setState(() {
        _selectedDeliverableIds = [];
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error linking deliverables: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unlinkDeliverable(String deliverableId, String deliverableTitle) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ProjectDeliverableService.unlinkDeliverableFromProject(
        widget.projectId,
        deliverableId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deliverableTitle unlinked from project'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadProjectData();

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unlinking deliverable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool get _canManageDeliverables {
    if (_userRole == null) return false;
    return ProjectMemberService.hasPermission(_userRole!, 'create_deliverables');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.projectName} Deliverables'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (_canManageDeliverables && _selectedDeliverableIds.isNotEmpty)
            TextButton.icon(
              onPressed: _linkSelectedDeliverables,
              icon: const Icon(Icons.link),
              label: Text('Link (${_selectedDeliverableIds.length})'),
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
                  if (_canManageDeliverables) ...[
                    _buildDeliverableSelector(),
                    const SizedBox(height: 24),
                  ],
                  _buildLinkedDeliverables(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              Icon(Icons.link, color: Colors.blue.shade800, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Deliverables',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      '${_linkedDeliverables.length} deliverables linked',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_canManageDeliverables)
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
          const SizedBox(height: 8),
          Text(
            _userRole!.description,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverableSelector() {
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
                'Link Deliverables to Project',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DeliverableSelector(
            projectId: widget.projectId,
            onSelectionChanged: (selectedIds) {
              setState(() {
                _selectedDeliverableIds = selectedIds;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedDeliverables() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text(
                'Linked Deliverables',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_linkedDeliverables.length} items',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_linkedDeliverables.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.link_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No deliverables linked yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _canManageDeliverables
                        ? 'Use the selector above to link deliverables to this project'
                        : 'Project owners and contributors can link deliverables',
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
            ..._linkedDeliverables.map((deliverable) {
              return _buildDeliverableCard(deliverable);
            }),
        ],
      ),
    );
  }

  Widget _buildDeliverableCard(Map<String, dynamic> deliverable) {
    final status = deliverable['status'] as String?;
    final priority = deliverable['priority'] as String?;
    final dueDate = deliverable['due_date'] as String?;
    
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
                        deliverable['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (deliverable['description'] != null && 
                          deliverable['description'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            deliverable['description'] as String,
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
                if (_canManageDeliverables)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    onSelected: (value) {
                      if (value == 'unlink') {
                        _showUnlinkDialog(deliverable);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'unlink',
                        child: Row(
                          children: [
                            Icon(Icons.link_off, size: 18, color: Colors.red),
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
                    color: _hexToColor(ProjectDeliverableService.getStatusColor(status))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _hexToColor(ProjectDeliverableService.getStatusColor(status))
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    ProjectDeliverableService.formatDeliverableStatus(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _hexToColor(ProjectDeliverableService.getStatusColor(status)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (priority != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _hexToColor(ProjectDeliverableService.getPriorityColor(priority))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _hexToColor(ProjectDeliverableService.getPriorityColor(priority))
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _hexToColor(ProjectDeliverableService.getPriorityColor(priority)),
                      ),
                    ),
                  ),
                const Spacer(),
                if (dueDate != null)
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        ProjectDeliverableService.formatDate(dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (deliverable['created_by_name'] != null || deliverable['assigned_to_name'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    if (deliverable['created_by_name'] != null) ...[
                      Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Created by ${deliverable['created_by_name']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (deliverable['created_by_name'] != null && deliverable['assigned_to_name'] != null)
                      const SizedBox(width: 16),
                    if (deliverable['assigned_to_name'] != null) ...[
                      Icon(Icons.assignment_ind, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned to ${deliverable['assigned_to_name']}',
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

  void _showUnlinkDialog(Map<String, dynamic> deliverable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Deliverable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to unlink "${deliverable['title']}" from this project?'),
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
                      'The deliverable will no longer be tracked with this project but will not be deleted.',
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
              _unlinkDeliverable(
                deliverable['id'] as String,
                deliverable['title'] as String,
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
