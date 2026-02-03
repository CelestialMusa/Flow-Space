import 'package:flutter/material.dart';
import '../models/project_role.dart';
import '../services/project_member_service.dart';

class AddMemberDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback onMemberAdded;

  const AddMemberDialog({
    super.key,
    required this.projectId,
    required this.onMemberAdded,
  });

  @override
  AddMemberDialogState createState() => AddMemberDialogState();
}

class AddMemberDialogState extends State<AddMemberDialog> {
  final _emailController = TextEditingController();
  ProjectRole _selectedRole = ProjectRole.contributor;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Team Member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProjectRole>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.assignment_ind),
              border: OutlineInputBorder(),
            ),
            items: ProjectRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Row(
                  children: [
                    Icon(role.icon, color: role.color, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(role.displayName),
                        Text(
                          role.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (ProjectRole? value) {
              setState(() {
                _selectedRole = value!;
              });
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addMember,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Member'),
        ),
      ],
    );
  }

  Future<void> _addMember() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter an email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ProjectMemberService.addProjectMember(
        widget.projectId,
        _emailController.text.trim(),
        _selectedRole,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onMemberAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedRole.displayName} added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

class ChangeRoleDialog extends StatefulWidget {
  final String projectId;
  final ProjectMember member;
  final VoidCallback onRoleChanged;

  const ChangeRoleDialog({
    super.key,
    required this.projectId,
    required this.member,
    required this.onRoleChanged,
  });

  @override
  ChangeRoleDialogState createState() => ChangeRoleDialogState();
}

class ChangeRoleDialogState extends State<ChangeRoleDialog> {
  ProjectRole? _selectedRole;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change Role for ${widget.member.userName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current role: ${widget.member.role.displayName}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProjectRole>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'New Role',
              prefixIcon: Icon(Icons.assignment_ind),
              border: OutlineInputBorder(),
            ),
            items: ProjectRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Row(
                  children: [
                    Icon(role.icon, color: role.color, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(role.displayName),
                        Text(
                          role.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (ProjectRole? value) {
              setState(() {
                _selectedRole = value!;
              });
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedRole == widget.member.role || _isLoading)
              ? null
              : _changeRole,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Change Role'),
        ),
      ],
    );
  }

  Future<void> _changeRole() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ProjectMemberService.updateMemberRole(
        widget.projectId,
        widget.member.id,
        _selectedRole!,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onRoleChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role changed to ${_selectedRole!.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
}

class RemoveMemberDialog extends StatefulWidget {
  final String projectId;
  final ProjectMember member;
  final VoidCallback onMemberRemoved;

  const RemoveMemberDialog({
    super.key,
    required this.projectId,
    required this.member,
    required this.onMemberRemoved,
  });

  @override
  RemoveMemberDialogState createState() => RemoveMemberDialogState();
}

class RemoveMemberDialogState extends State<RemoveMemberDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Remove Team Member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to remove ${widget.member.userName} from the project?'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone. The member will lose access to all project resources.',
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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _removeMember,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Remove'),
        ),
      ],
    );
  }

  Future<void> _removeMember() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ProjectMemberService.removeProjectMember(
        widget.projectId,
        widget.member.id,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onMemberRemoved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team member removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
