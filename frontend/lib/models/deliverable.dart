import 'package:flutter/material.dart';

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
  final DeliverableStatus status;
  final DateTime createdAt;
  final DateTime dueDate;
  final List<String> sprintIds;
  final List<String> definitionOfDone;
  final List<String> evidenceLinks;
  final String? clientComment;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? submittedBy;
  final DateTime? submittedAt;

  const Deliverable({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.dueDate,
    this.sprintIds = const [],
    this.definitionOfDone = const [],
    this.evidenceLinks = const [],
    this.clientComment,
    this.approvedAt,
    this.approvedBy,
    this.submittedBy,
    this.submittedAt,
  });

  factory Deliverable.fromJson(Map<String, dynamic> json) {
    return Deliverable(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: DeliverableStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => DeliverableStatus.draft,
      ),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      dueDate: DateTime.parse(json['due_date'] ?? json['dueDate'] ?? DateTime.now().toIso8601String()),
      sprintIds: (json['sprintIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
                (json['sprint_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      definitionOfDone: (json['definitionOfDone'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
                      (json['definition_of_done'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      evidenceLinks: (json['evidenceLinks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
                   (json['evidence_links'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      clientComment: json['clientComment']?.toString() ?? json['client_comment'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      approvedBy: json['approvedBy']?.toString() ?? json['approved_by'],
      submittedBy: json['submittedBy']?.toString() ?? json['submitted_by'],
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'sprint_ids': sprintIds,
      'definition_of_done': definitionOfDone,
      'evidence_links': evidenceLinks,
      'client_comment': clientComment,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'submitted_by': submittedBy,
      'submitted_at': submittedAt?.toIso8601String(),
    };
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
        return Colors.blue;
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

class DeliverableCreate {
  final String title;
  final String description;
  final DateTime dueDate;
  final List<String> definitionOfDone;
  final List<String> evidenceLinks;
  final List<String> sprintIds;

  const DeliverableCreate({
    required this.title,
    required this.description,
    required this.dueDate,
    this.definitionOfDone = const [],
    this.evidenceLinks = const [],
    this.sprintIds = const [],
  });
}

class DeliverableUpdate {
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final DeliverableStatus? status;
  final List<String>? definitionOfDone;
  final List<String>? evidenceLinks;
  final List<String>? sprintIds;
  final String? clientComment;

  const DeliverableUpdate({
    this.title,
    this.description,
    this.dueDate,
    this.status,
    this.definitionOfDone,
    this.evidenceLinks,
    this.sprintIds,
    this.clientComment,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (status != null) 'status': status!.name,
      if (definitionOfDone != null) 'definition_of_done': definitionOfDone,
      if (evidenceLinks != null) 'evidence_links': evidenceLinks,
      if (sprintIds != null) 'sprint_ids': sprintIds,
      if (clientComment != null) 'client_comment': clientComment,
    };
  }
}
