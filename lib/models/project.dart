import 'package:flutter/material.dart';

enum ProjectStatus {
  planning,
  active,
  onHold,
  completed,
  cancelled,
}

enum ProjectPriority {
  low,
  medium,
  high,
  critical,
}

enum ProjectRole {
  owner,
  contributor,
  viewer,
}

class ProjectMember {
  final String userId;
  final String userName;
  final String userEmail;
  final ProjectRole role;
  final DateTime assignedAt;

  const ProjectMember({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.assignedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'role': role.name,
      'assignedAt': assignedAt.toIso8601String(),
    };
  }

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      role: ProjectRole.values.firstWhere(
        (e) => e.name == json['role']?.toString(),
        orElse: () => ProjectRole.viewer,
      ),
      assignedAt: DateTime.parse(json['assignedAt']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}

class Project {
  final String id;
  final String name;
  final String key;
  final String description;
  final String? clientName;
  final ProjectStatus status;
  final ProjectPriority priority;
  final String projectType;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> tags;
  final List<ProjectMember> members;
  final List<String> deliverableIds;
  final List<String> sprintIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? ownerId;
  final String? key;
  final Map<String, dynamic> metadata;

  const Project({
    required this.id,
    required this.name,
    required this.key,
    required this.description,
    this.clientName,
    required this.status,
    required this.priority,
    required this.projectType,
    required this.startDate,
    this.endDate,
    this.tags = const [],
    this.members = const [],
    this.deliverableIds = const [],
    this.sprintIds = const [],
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.ownerId,
    this.key,
    this.metadata = const {},
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? clientName,
    ProjectStatus? status,
    ProjectPriority? priority,
    String? projectType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    List<ProjectMember>? members,
    List<String>? deliverableIds,
    List<String>? sprintIds,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedBy,
    String? ownerId,
    Map<String, dynamic>? metadata,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      key: key,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      projectType: projectType ?? this.projectType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? this.tags,
      members: members ?? this.members,
      deliverableIds: deliverableIds ?? this.deliverableIds,
      sprintIds: sprintIds ?? this.sprintIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      ownerId: ownerId ?? this.ownerId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'key': key,
      'description': description,
      'clientName': clientName,
      'status': status.name,
      'priority': priority.name,
      'projectType': projectType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'tags': tags,
      'members': members.map((m) => m.toJson()).toList(),
      'deliverableIds': deliverableIds,
      'sprintIds': sprintIds,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'ownerId': ownerId,
      'metadata': metadata,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      clientName: json['clientName']?.toString(),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => ProjectStatus.planning,
      ),
      priority: ProjectPriority.values.firstWhere(
        (e) => e.name == json['priority']?.toString(),
        orElse: () => ProjectPriority.medium,
      ),
      projectType: json['projectType']?.toString() ?? 'software',
      startDate: DateTime.parse(json['startDate']?.toString() ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']?.toString() ?? '') : null,
      tags: List<String>.from(json['tags'] ?? []),
      members: (json['members'] as List<dynamic>?)
          ?.map((m) => ProjectMember.fromJson(Map<String, dynamic>.from(m)))
          .toList() ?? [],
      deliverableIds: List<String>.from(json['deliverableIds'] ?? []),
      sprintIds: List<String>.from(json['sprintIds'] ?? []),
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']?.toString() ?? '') : null,
      updatedBy: json['updatedBy']?.toString(),
      ownerId: json['ownerId']?.toString(),
      key: json['key']?.toString(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  String get statusDisplayName {
    switch (status) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case ProjectPriority.low:
        return 'Low';
      case ProjectPriority.medium:
        return 'Medium';
      case ProjectPriority.high:
        return 'High';
      case ProjectPriority.critical:
        return 'Critical';
    }
  }

  Color get statusColor {
    switch (status) {
      case ProjectStatus.planning:
        return Colors.blue;
      case ProjectStatus.active:
        return Colors.green;
      case ProjectStatus.onHold:
        return Colors.orange;
      case ProjectStatus.completed:
        return Colors.purple;
      case ProjectStatus.cancelled:
        return Colors.red;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case ProjectPriority.low:
        return Colors.grey;
      case ProjectPriority.medium:
        return Colors.blue;
      case ProjectPriority.high:
        return Colors.orange;
      case ProjectPriority.critical:
        return Colors.red;
    }
  }

  bool get isOverdue {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!) && status != ProjectStatus.completed;
  }

  int get daysUntilEnd {
    if (endDate == null) return -1;
    return endDate!.difference(DateTime.now()).inDays;
  }

  bool get isActive {
    return status == ProjectStatus.active;
  }

  List<ProjectMember> get owners {
    return members.where((m) => m.role == ProjectRole.owner).toList();
  }

  List<ProjectMember> get contributors {
    return members.where((m) => m.role == ProjectRole.contributor).toList();
  }

  List<ProjectMember> get viewers {
    return members.where((m) => m.role == ProjectRole.viewer).toList();
  }

  int get totalMembers => members.length;

  bool hasMember(String userId) {
    return members.any((m) => m.userId == userId);
  }

  ProjectMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> get auditMetadata {
    return {
      'projectId': id,
      'projectName': name,
      'action': 'project_updated',
      'timestamp': DateTime.now().toIso8601String(),
      'memberCount': totalMembers,
      'deliverableCount': deliverableIds.length,
      'sprintCount': sprintIds.length,
      'status': status.name,
      'priority': priority.name,
    };
  }
}
