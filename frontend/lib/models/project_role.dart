import 'package:flutter/material.dart';

enum ProjectRole {
  owner,
  contributor,
  viewer,
}

extension ProjectRoleExtension on ProjectRole {
  String get displayName {
    switch (this) {
      case ProjectRole.owner:
        return 'Owner';
      case ProjectRole.contributor:
        return 'Contributor';
      case ProjectRole.viewer:
        return 'Viewer';
    }
  }

  String get description {
    switch (this) {
      case ProjectRole.owner:
        return 'Full control over project settings and team management';
      case ProjectRole.contributor:
        return 'Can create and edit deliverables, manage sprints';
      case ProjectRole.viewer:
        return 'Read-only access to project content';
    }
  }

  Color get color {
    switch (this) {
      case ProjectRole.owner:
        return Colors.purple;
      case ProjectRole.contributor:
        return Colors.blue;
      case ProjectRole.viewer:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case ProjectRole.owner:
        return Icons.admin_panel_settings;
      case ProjectRole.contributor:
        return Icons.edit;
      case ProjectRole.viewer:
        return Icons.visibility;
    }
  }

  int get level {
    switch (this) {
      case ProjectRole.owner:
        return 3;
      case ProjectRole.contributor:
        return 2;
      case ProjectRole.viewer:
        return 1;
    }
  }

  static ProjectRole fromString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'owner':
        return ProjectRole.owner;
      case 'contributor':
        return ProjectRole.contributor;
      case 'viewer':
        return ProjectRole.viewer;
      default:
        throw ArgumentError('Invalid project role: $roleString');
    }
  }
}

class ProjectPermission {
  final String name;
  final String description;
  final List<ProjectRole> allowedRoles;

  const ProjectPermission({
    required this.name,
    required this.description,
    required this.allowedRoles,
  });
}

class ProjectPermissionManager {
  static const Map<String, ProjectPermission> _permissions = {
    'edit_project_setup': ProjectPermission(
      name: 'Edit Project Setup',
      description: 'Modify project settings, configuration, and metadata',
      allowedRoles: [ProjectRole.owner],
    ),
    'manage_team_members': ProjectPermission(
      name: 'Manage Team Members',
      description: 'Add, remove, and change roles of project members',
      allowedRoles: [ProjectRole.owner],
    ),
    'create_deliverables': ProjectPermission(
      name: 'Create Deliverables',
      description: 'Create new deliverables within the project',
      allowedRoles: [ProjectRole.owner, ProjectRole.contributor],
    ),
    'edit_deliverables': ProjectPermission(
      name: 'Edit Deliverables',
      description: 'Edit existing deliverables in the project',
      allowedRoles: [ProjectRole.owner, ProjectRole.contributor],
    ),
    'delete_deliverables': ProjectPermission(
      name: 'Delete Deliverables',
      description: 'Delete deliverables from the project',
      allowedRoles: [ProjectRole.owner, ProjectRole.contributor],
    ),
    'manage_sprints': ProjectPermission(
      name: 'Manage Sprints',
      description: 'Create, edit, and delete sprints',
      allowedRoles: [ProjectRole.owner, ProjectRole.contributor],
    ),
    'submit_for_review': ProjectPermission(
      name: 'Submit for Review',
      description: 'Submit deliverables for client review',
      allowedRoles: [ProjectRole.owner, ProjectRole.contributor],
    ),
    'view_analytics': ProjectPermission(
      name: 'View Analytics',
      description: 'View project analytics and reports',
      allowedRoles: [ProjectRole.owner, ProjectRole.contributor],
    ),
    'export_data': ProjectPermission(
      name: 'Export Data',
      description: 'Export project data and reports',
      allowedRoles: [ProjectRole.owner, ProjectRole.contributor],
    ),
    'view_project': ProjectPermission(
      name: 'View Project',
      description: 'View project content and details',
      allowedRoles: [ProjectRole.owner, ProjectRole.contributor, ProjectRole.viewer],
    ),
    'view_deliverables': ProjectPermission(
      name: 'View Deliverables',
      description: 'View deliverables in the project',
      allowedRoles: [ProjectRole.owner, ProjectRole.contributor, ProjectRole.viewer],
    ),
    'view_sprints': ProjectPermission(
      name: 'View Sprints',
      description: 'View sprints in the project',
      allowedRoles: [ProjectRole.owner, ProjectRole.contributor, ProjectRole.viewer],
    ),
  };

  static bool hasPermission(ProjectRole userRole, String permissionName) {
    final permission = _permissions[permissionName];
    if (permission == null) return false;
    return permission.allowedRoles.contains(userRole);
  }

  static List<ProjectPermission> getPermissionsForRole(ProjectRole userRole) {
    return _permissions.values
        .where((permission) => permission.allowedRoles.contains(userRole))
        .toList();
  }

  static List<String> getPermissionNamesForRole(ProjectRole userRole) {
    return _permissions.entries
        .where((entry) => entry.value.allowedRoles.contains(userRole))
        .map((entry) => entry.key)
        .toList();
  }

  static bool canManageRole(ProjectRole managerRole, ProjectRole targetRole) {
    // Only owners can manage other roles
    if (managerRole != ProjectRole.owner) return false;
    
    // Owners can manage any role except other owners (unless they're the last owner)
    return true;
  }
}

class ProjectMember {
  final String id;
  final String userId;
  final String projectId;
  final ProjectRole role;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final DateTime joinedAt;

  const ProjectMember({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.role,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.joinedAt,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String,
      role: ProjectRoleExtension.fromString(json['role'] as String),
      userName: json['user_name'] as String? ?? 'Unknown User',
      userEmail: json['user_email'] as String? ?? 'unknown@example.com',
      userAvatar: json['user_avatar'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'role': role.name,
      'user_name': userName,
      'user_email': userEmail,
      'user_avatar': userAvatar,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
