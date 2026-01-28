import 'dart:convert';
import 'package:flutter/material.dart';
import 'dod_item.dart';

export 'dod_item.dart';

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
    };
  }

  factory Deliverable.fromJson(Map<String, dynamic> json) {
    // Helper to parse status
    DeliverableStatus parseStatus(String? statusStr) {
      if (statusStr == null) return DeliverableStatus.draft;
      // Handle snake_case or camelCase
      final normalized = statusStr.toLowerCase().replaceAll('_', '');
      for (var val in DeliverableStatus.values) {
        if (val.name.toLowerCase() == normalized) return val;
      }
      return DeliverableStatus.draft;
    }

    // Helper to parse DoD items
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
          // Not JSON, split by newline
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

    // Handle sprintIds which might come as 'sprintIds' (List) or 'sprint_id' (String)
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
    
    // Handle camelCase and snake_case keys
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

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && status != DeliverableStatus.approved;
  }

  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }
}
