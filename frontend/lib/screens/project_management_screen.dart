import 'package:flutter/material.dart';
import '../models/project_role.dart';
import '../services/project_member_service.dart';

class ProjectManagementScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectManagementScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _ProjectManagementScreenState createState() => _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  List<ProjectMember> _members = [];
  ProjectRole? _userRole;
  bool _isLoading = true;
  String? _error;

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

      // Load project members
      final members = await ProjectMemberService.getProjectMembers(widget.projectId);

      setState(() {
        _userRole = userRole;
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.projectName}'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (_userRole != null && ProjectMemberService.hasPermission(_userRole!, 'manage_team_members'))
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showAddMemberDialog,
              tooltip: 'Add Member',
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
          _buildUserRoleHeader(),
          Expanded(child: _buildMembersList()),
        ],
      ),
    );
  }

  Widget _buildUserRoleHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _userRole!.color.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(_userRole!.icon, color: _userRole!.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Role: ${_userRole!.displayName}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _userRole!.color,
                  ),
                ),
                Text(
                  _userRole!.description,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No members found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            if (_userRole != null && ProjectMemberService.hasPermission(_userRole!, 'manage_team_members'))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: _showAddMemberDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add First Member'),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildMemberCard(ProjectMember member) {
    final canManageMembers = _userRole != null && 
        ProjectMemberService.hasPermission(_userRole!, 'manage_team_members');
    final isCurrentUser = member.userId == 'current_user_id'; // You'll need to get current user ID

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.role.color.withValues(alpha: 0.2),
          child: member.role.userAvatar != null
              ? ClipOval(
                  child: Image.network(
                    member.role.userAvatar!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.person, color: member.role.color),
                  ),
                )
              : Icon(Icons.person, color: member.role.color),
        ),
        title: Text(
          member.userName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.userEmail),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: member.role.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: member.role.color.withValues(alpha: 0.3)),
              ),
              child: Text(
                member.role.displayName,
                style: TextStyle(
                  color: member.role.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: canManageMembers && !isCurrentUser
            ? PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onSelected: (value) => _handleMemberAction(value, member),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text('Change Role'),
                      ],
                    ),
                  ),
                  if (member.role != ProjectRole.owner) // Cannot remove owners
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle, size: 18, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          const Text('Remove from Project'),
                        ],
                      ),
                    ),
                ],
              )
            : null,
      ),
    );
  }

  void _handleMemberAction(String action, ProjectMember member) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(member);
        break;
      case 'remove':
        _showRemoveMemberDialog(member);
        break;
    }
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(
        projectId: widget.projectId,
        onMemberAdded: _loadProjectData,
      ),
    );
  }

  void _showChangeRoleDialog(ProjectMember member) {
    showDialog(
      context: context,
      builder: (context) => ChangeRoleDialog(
        projectId: widget.projectId,
        member: member,
        onRoleChanged: _loadProjectData,
      ),
    );
  }

  void _showRemoveMemberDialog(ProjectMember member) {
    showDialog(
      context: context,
      builder: (context) => RemoveMemberDialog(
        projectId: widget.projectId,
        member: member,
        onMemberRemoved: _loadProjectData,
      ),
    );
  }
}
