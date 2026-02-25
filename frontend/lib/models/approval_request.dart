import 'package:flutter/material.dart';

enum ApprovalStatus {
  pending,
  approved,
  rejected,
  changeRequested,
}

class ApprovalRequest {
  final String id;
  final String title;
  final String description;
  final String requestedBy;
  final String requestedByName;
  final DateTime requestedAt;
  final ApprovalStatus status;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? reviewReason;
  final String priority;
  final String category;
  final String? deliverableId;
  final List<String>? evidenceLinks;
  final List<String>? definitionOfDone;
  final String? deliverableTitle;
  final String? deliverableDescription;

  const ApprovalRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.requestedBy,
    required this.requestedByName,
    required this.requestedAt,
    required this.status,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.reviewReason,
    required this.priority,
    required this.category,
    this.deliverableId,
    this.evidenceLinks,
    this.definitionOfDone,
    this.deliverableTitle,
    this.deliverableDescription,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      requestedBy: json['requestedBy']?.toString() ?? json['requested_by'] ?? '',
      requestedByName: json['requestedByName']?.toString() ?? json['requested_by_name'] ?? '',
      requestedAt: DateTime.parse(json['requestedAt'] ?? json['requested_at'] ?? DateTime.now().toIso8601String()),
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => ApprovalStatus.pending,
      ),
      reviewedBy: json['reviewedBy']?.toString() ?? json['reviewed_by'],
      reviewedByName: json['reviewedByName']?.toString() ?? json['reviewed_by_name'],
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
      reviewReason: json['reviewReason']?.toString() ?? json['review_reason'],
      priority: json['priority']?.toString() ?? 'medium',
      category: json['category']?.toString() ?? 'general',
      deliverableId: json['deliverableId']?.toString() ?? json['deliverable_id'],
      evidenceLinks: (json['evidenceLinks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
                   (json['evidence_links'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      definitionOfDone: (json['definitionOfDone'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
                      (json['definition_of_done'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      deliverableTitle: json['deliverableTitle']?.toString() ?? json['deliverable_title'],
      deliverableDescription: json['deliverableDescription']?.toString() ?? json['deliverable_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.name,
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewReason': reviewReason,
      'priority': priority,
      'category': category,
      'deliverableId': deliverableId,
      'evidenceLinks': evidenceLinks,
      'definitionOfDone': definitionOfDone,
      'deliverableTitle': deliverableTitle,
      'deliverableDescription': deliverableDescription,
    };
  }

  ApprovalRequest copyWith({
    String? id,
    String? title,
    String? description,
    String? requestedBy,
    String? requestedByName,
    DateTime? requestedAt,
    ApprovalStatus? status,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? reviewedAt,
    String? reviewReason,
    String? priority,
    String? category,
    String? deliverableId,
    List<String>? evidenceLinks,
    List<String>? definitionOfDone,
    String? deliverableTitle,
    String? deliverableDescription,
  }) {
    return ApprovalRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewReason: reviewReason ?? this.reviewReason,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      deliverableId: deliverableId ?? this.deliverableId,
      evidenceLinks: evidenceLinks ?? this.evidenceLinks,
      definitionOfDone: definitionOfDone ?? this.definitionOfDone,
      deliverableTitle: deliverableTitle ?? this.deliverableTitle,
      deliverableDescription: deliverableDescription ?? this.deliverableDescription,
    );
  }

  bool get isPending => status == ApprovalStatus.pending;
  bool get isApproved => status == ApprovalStatus.approved;
  bool get isRejected => status == ApprovalStatus.rejected;
  bool get isChangeRequested => status == ApprovalStatus.changeRequested;

  String get statusDisplayName {
    switch (status) {
      case ApprovalStatus.pending:
        return 'Pending';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
      case ApprovalStatus.changeRequested:
        return 'Change Requested';
    }
  }

  Color get statusColor {
    switch (status) {
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.rejected:
        return Colors.red;
      case ApprovalStatus.changeRequested:
        return Colors.amber;
    }
  }
}
