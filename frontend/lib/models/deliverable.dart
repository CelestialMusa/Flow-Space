import 'dart:convert';
import 'package:flutter/material.dart';

class DoDItem {
  final String text;
  final bool isCompleted;

  DoDItem({required this.text, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
    'text': text,
    'isCompleted': isCompleted,
  };

  factory DoDItem.fromJson(Map<String, dynamic> json) {
    return DoDItem(
      text: json['text'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class AuditLogEntry {
  final int id;
  final String? userId;
  final String? userEmail;
  final String? userRole;
  final String action;
  final String? actionCategory;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final List<String>? changedFields;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    this.userId,
    this.userEmail,
    this.userRole,
    required this.action,
    this.actionCategory,
    this.entityType,
    this.entityId,
    this.oldValues,
    this.newValues,
    this.changedFields,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parseMap(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) return value;
      if (value is String) {
        try {
          return jsonDecode(value) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    List<String>? parseList(dynamic value) {
      if (value == null) return null;
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return AuditLogEntry(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      userEmail: json['user_email']?.toString() ?? json['userEmail']?.toString(),
      userRole: json['user_role']?.toString() ?? json['userRole']?.toString(),
      action: json['action']?.toString() ?? 'unknown',
      actionCategory: json['action_category']?.toString() ?? json['actionCategory']?.toString(),
      entityType: json['entity_type']?.toString() ?? json['entityType']?.toString(),
      entityId: json['entity_id']?.toString() ?? json['entityId']?.toString(),
      oldValues: parseMap(json['old_values'] ?? json['oldValues']),
      newValues: parseMap(json['new_values'] ?? json['newValues']),
      changedFields: parseList(json['changed_fields'] ?? json['changedFields']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'user_role': userRole,
      'action': action,
      'action_category': actionCategory,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_values': oldValues,
      'new_values': newValues,
      'changed_fields': changedFields,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum DeliverableStatus {
  draft,
  submitted,
  approved,
  changeRequested,
  rejected,
}

class Deliverable {
  final String id;
  final String title;
  final String description;
  final String priority;
  final DeliverableStatus status;
  final DateTime createdAt;
  final DateTime dueDate;
  final List<String> sprintIds;
  final List<DoDItem> definitionOfDone;
  final List<String> evidenceLinks;
  final String? clientComment;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? submittedBy;
  final DateTime? submittedAt;
  final String? assignedTo;
  final String? assignedToName;
  final String? createdBy;
  final String? createdByName;
  final String? ownerId;
  final String? ownerName;
  final String? ownerRole;
  final List<AuditLogEntry> auditLogs;

  const Deliverable({
    required this.id,
    required this.title,
    required this.description,
    this.priority = 'medium',
    required this.status,
    required this.createdAt,
    required this.dueDate,
    required this.sprintIds,
    required this.definitionOfDone,
    this.evidenceLinks = const [],
    this.clientComment,
    this.approvedAt,
    this.approvedBy,
    this.submittedBy,
    this.submittedAt,
    this.assignedTo,
    this.assignedToName,
    this.createdBy,
    this.createdByName,
    this.ownerId,
    this.ownerName,
    this.ownerRole,
    this.auditLogs = const [],
  });

  Deliverable copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    DeliverableStatus? status,
    DateTime? createdAt,
    DateTime? dueDate,
    List<String>? sprintIds,
    List<DoDItem>? definitionOfDone,
    List<String>? evidenceLinks,
    String? clientComment,
    DateTime? approvedAt,
    String? approvedBy,
    String? submittedBy,
    DateTime? submittedAt,
    String? assignedTo,
    String? assignedToName,
    String? createdBy,
    String? createdByName,
    String? ownerId,
    String? ownerName,
    String? ownerRole,
    List<AuditLogEntry>? auditLogs,
  }) {
    return Deliverable(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      sprintIds: sprintIds ?? this.sprintIds,
      definitionOfDone: definitionOfDone ?? this.definitionOfDone,
      evidenceLinks: evidenceLinks ?? this.evidenceLinks,
      clientComment: clientComment ?? this.clientComment,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerRole: ownerRole ?? this.ownerRole,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'sprintIds': sprintIds,
      'definitionOfDone': definitionOfDone.map((e) => e.toJson()).toList(),
      'evidenceLinks': evidenceLinks,
      'clientComment': clientComment,
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'submittedBy': submittedBy,
      'submittedAt': submittedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerRole': ownerRole,
    };
  }

  factory Deliverable.fromJson(Map<String, dynamic> json) {
    DeliverableStatus parseStatus(String? statusStr) {
      if (statusStr == null) return DeliverableStatus.draft;
      final normalized = statusStr.toLowerCase().replaceAll('_', '');
      for (var val in DeliverableStatus.values) {
        if (val.name.toLowerCase() == normalized) return val;
      }
      return DeliverableStatus.draft;
    }

    List<DoDItem> parseDoD(dynamic dodValue) {
      if (dodValue == null) return [];
      if (dodValue is List) {
        return dodValue.map((item) {
          if (item is Map<String, dynamic>) return DoDItem.fromJson(item);
          if (item is DoDItem) return item;
          return DoDItem(text: item.toString());
        }).toList();
      } else if (dodValue is String) {
        try {
          final decoded = jsonDecode(dodValue);
          if (decoded is List) {
            return decoded.map((item) {
              if (item is Map<String, dynamic>) return DoDItem.fromJson(item);
              return DoDItem(text: item.toString());
            }).toList();
          }
        } catch (_) {
          if (dodValue.trim().isNotEmpty) {
             return dodValue.split('\n')
               .map((s) => s.trim())
               .where((s) => s.isNotEmpty)
               .map((s) => DoDItem(text: s))
               .toList();
          }
        }
      }
      return [];
    }

    List<String> parseSprintIds(Map<String, dynamic> json) {
      if (json['sprintIds'] != null) {
        return List<String>.from(json['sprintIds']);
      }
      if (json['sprint_ids'] != null) {
        return List<String>.from(json['sprint_ids']);
      }
      if (json['sprint_id'] != null) {
        return [json['sprint_id'].toString()];
      }
      if (json['sprintId'] != null) {
        return [json['sprintId'].toString()];
      }
      return [];
    }
    
    final id = json['id']?.toString() ?? json['uuid']?.toString() ?? '';
    final title = json['title']?.toString() ?? json['name']?.toString() ?? '';
    final description = json['description']?.toString() ?? '';
    final priority = json['priority']?.toString() ?? 'medium';
    final status = parseStatus(json['status']?.toString() ?? json['review_status']?.toString());
    
    final createdStr = json['createdAt']?.toString() ?? json['created_at']?.toString();
    final createdAt = createdStr != null ? DateTime.parse(createdStr) : DateTime.now();
    
    final dueStr = json['dueDate']?.toString() ?? json['due_date']?.toString() ?? json['deadline']?.toString();
    final dueDate = dueStr != null ? DateTime.parse(dueStr) : DateTime.now().add(const Duration(days: 7));
    
    final sprintIds = parseSprintIds(json);
    
    final dodValue = json['definitionOfDone'] ?? json['definition_of_done'];
    final definitionOfDone = parseDoD(dodValue);
    
    final evidenceValue = json['evidenceLinks'] ?? json['evidence_links'];
    final evidenceLinks = evidenceValue != null ? List<String>.from(evidenceValue) : <String>[];
    
    String? ownerId = json['ownerId']?.toString() ?? json['owner_id']?.toString();
    String? ownerName = json['ownerName']?.toString() ?? json['owner_name']?.toString();
    String? ownerRole = json['ownerRole']?.toString() ?? json['owner_role']?.toString();
    
    if (json['owner'] != null && json['owner'] is Map) {
      final ownerMap = json['owner'] as Map;
      ownerId ??= ownerMap['id']?.toString();
      ownerRole ??= ownerMap['role']?.toString();
      if (ownerName == null) {
        final first = ownerMap['first_name']?.toString() ?? ownerMap['firstName']?.toString() ?? '';
        final last = ownerMap['last_name']?.toString() ?? ownerMap['lastName']?.toString() ?? '';
        final email = ownerMap['email']?.toString() ?? '';
        if (first.isNotEmpty || last.isNotEmpty) {
          ownerName = '$first $last'.trim();
        } else if (email.isNotEmpty) {
          ownerName = email;
        }
      }
    }

    final auditLogsJson = json['auditLogs'] ?? json['audit_logs'];
    List<AuditLogEntry> auditLogs = [];
    if (auditLogsJson != null && auditLogsJson is List) {
      auditLogs = auditLogsJson
          .map((e) {
            try {
              return AuditLogEntry.fromJson(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<AuditLogEntry>()
          .toList();
      auditLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Deliverable(
      id: id,
      title: title,
      description: description,
      priority: priority,
      status: status,
      createdAt: createdAt,
      dueDate: dueDate,
      sprintIds: sprintIds,
      definitionOfDone: definitionOfDone,
      evidenceLinks: evidenceLinks,
      clientComment: json['clientComment']?.toString() ?? json['client_comment']?.toString(),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'].toString()) : (json['approved_at'] != null ? DateTime.parse(json['approved_at'].toString()) : null),
      approvedBy: json['approvedBy']?.toString() ?? json['approved_by']?.toString(),
      submittedBy: json['submittedBy']?.toString() ?? json['submitted_by']?.toString(),
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt'].toString()) : (json['submitted_at'] != null ? DateTime.parse(json['submitted_at'].toString()) : null),
      assignedTo: json['assignedTo']?.toString() ?? json['assigned_to']?.toString(),
      assignedToName: json['assignedToName']?.toString() ?? json['assigned_to_name']?.toString(),
      createdBy: json['createdBy']?.toString() ?? json['created_by']?.toString(),
      createdByName: json['createdByName']?.toString() ?? json['created_by_name']?.toString(),
      ownerId: ownerId,
      ownerName: ownerName,
      ownerRole: ownerRole,
      auditLogs: auditLogs,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case DeliverableStatus.draft:
        return 'Draft';
      case DeliverableStatus.submitted:
        return 'Submitted';
      case DeliverableStatus.approved:
        return 'Approved';
      case DeliverableStatus.changeRequested:
        return 'Change Requested';
      case DeliverableStatus.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case DeliverableStatus.draft:
        return Colors.grey;
      case DeliverableStatus.submitted:
        return Colors.orange;
      case DeliverableStatus.approved:
        return Colors.green;
      case DeliverableStatus.changeRequested:
        return Colors.amber;
      case DeliverableStatus.rejected:
        return Colors.red;
    }
  }
}

class DeliverableCreate {
  final String title;
  final String description;
  final DateTime dueDate;
  final List<String> sprintIds;
  final List<String> definitionOfDone;
  final List<String> evidenceLinks;
  final String? ownerId;

  DeliverableCreate({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.sprintIds,
    required this.definitionOfDone,
    required this.evidenceLinks,
    this.ownerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'sprintIds': sprintIds,
      'definition_of_done': definitionOfDone,
      'evidence_links': evidenceLinks,
      if (ownerId != null) 'owner_id': ownerId,
    };
  }
}

class DeliverableUpdate {
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final String? status;
  final List<String>? sprintIds;
  final List<String>? definitionOfDone;
  final List<String>? evidenceLinks;
  final String? ownerId;

  DeliverableUpdate({
    this.title,
    this.description,
    this.dueDate,
    this.status,
    this.sprintIds,
    this.definitionOfDone,
    this.evidenceLinks,
    this.ownerId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (dueDate != null) data['due_date'] = dueDate!.toIso8601String();
    if (status != null) data['status'] = status;
    if (sprintIds != null) data['sprintIds'] = sprintIds;
    if (definitionOfDone != null) data['definition_of_done'] = definitionOfDone;
    if (evidenceLinks != null) data['evidence_links'] = evidenceLinks;
    if (ownerId != null) data['owner_id'] = ownerId;
    return data;
  }
}
