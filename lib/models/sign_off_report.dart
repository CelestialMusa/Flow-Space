import 'package:flutter/material.dart';

enum ReportStatus {
  draft,
  submitted,
  underReview,
  approved,
  changeRequested,
  rejected,
}

class SignOffReport {
  final String id;
  final String deliverableId;
  final String reportTitle;
  final String reportContent;
  final List<String> sprintIds;
  final String? sprintPerformanceData;
  final String? knownLimitations;
  final String? nextSteps;
  final ReportStatus status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? submittedAt;
  final String? submittedBy;
  final String? submittedByName;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewedByName;
  final String? clientComment;
  final String? changeRequestDetails;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? approvedByName;
  final String? digitalSignature;

  const SignOffReport({
    required this.id,
    required this.deliverableId,
    required this.reportTitle,
    required this.reportContent,
    required this.sprintIds,
    this.sprintPerformanceData,
    this.knownLimitations,
    this.nextSteps,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.submittedAt,
    this.submittedBy,
    this.submittedByName,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewedByName,
    this.clientComment,
    this.changeRequestDetails,
    this.approvedAt,
    this.approvedBy,
    this.approvedByName,
    this.digitalSignature,
  });

  SignOffReport copyWith({
    String? id,
    String? deliverableId,
    String? reportTitle,
    String? reportContent,
    List<String>? sprintIds,
    String? sprintPerformanceData,
    String? knownLimitations,
    String? nextSteps,
    ReportStatus? status,
    DateTime? createdAt,
    String? createdBy,
    DateTime? submittedAt,
    String? submittedBy,
    String? submittedByName,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewedByName,
    String? clientComment,
    String? changeRequestDetails,
    DateTime? approvedAt,
    String? approvedBy,
    String? approvedByName,
    String? digitalSignature,
  }) {
    return SignOffReport(
      id: id ?? this.id,
      deliverableId: deliverableId ?? this.deliverableId,
      reportTitle: reportTitle ?? this.reportTitle,
      reportContent: reportContent ?? this.reportContent,
      sprintIds: sprintIds ?? this.sprintIds,
      sprintPerformanceData: sprintPerformanceData ?? this.sprintPerformanceData,
      knownLimitations: knownLimitations ?? this.knownLimitations,
      nextSteps: nextSteps ?? this.nextSteps,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedByName: submittedByName ?? this.submittedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      clientComment: clientComment ?? this.clientComment,
      changeRequestDetails: changeRequestDetails ?? this.changeRequestDetails,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      digitalSignature: digitalSignature ?? this.digitalSignature,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deliverableId': deliverableId,
      'reportTitle': reportTitle,
      'reportContent': reportContent,
      'sprintIds': sprintIds,
      'sprintPerformanceData': sprintPerformanceData,
      'knownLimitations': knownLimitations,
      'nextSteps': nextSteps,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'submittedAt': submittedAt?.toIso8601String(),
      'submittedBy': submittedBy,
      'submittedByName': submittedByName,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'clientComment': clientComment,
      'changeRequestDetails': changeRequestDetails,
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'digitalSignature': digitalSignature,
    };
  }

  factory SignOffReport.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> content = json['content'] is Map
        ? Map<String, dynamic>.from(json['content'] as Map)
        : {};

    final String id = (json['id'] ?? json['report_id'] ?? '').toString();
    final String deliverableId = (json['deliverableId'] ?? json['deliverable_id'] ?? content['deliverableId'] ?? content['deliverable_id'] ?? '').toString();
    final String reportTitle = (json['reportTitle'] ?? json['report_title'] ?? content['reportTitle'] ?? content['title'] ?? '').toString();
    final String reportContent = (json['reportContent'] ?? json['content_text'] ?? content['reportContent'] ?? content['content'] ?? '').toString();

    List<String> sprintIds = [];
    final dynamic sIds = json['sprintIds'] ?? json['sprint_ids'] ?? content['sprintIds'] ?? content['sprints'];
    if (sIds is List) {
      sprintIds = sIds.map((e) => e.toString()).toList();
    }

    final String? sprintPerformanceData = (json['sprintPerformanceData'] ?? content['sprintPerformanceData'])?.toString();
    final String? knownLimitations = (json['knownLimitations'] ?? content['knownLimitations'] ?? content['limitations'])?.toString();
    final String? nextSteps = (json['nextSteps'] ?? content['nextSteps'])?.toString();

    final String statusStr = (json['status'] ?? json['review_status'] ?? content['status'] ?? '').toString();
    final ReportStatus status = _parseStatus(statusStr);

    final String createdAtStr = (json['createdAt'] ?? json['created_at'] ?? '').toString();
    final DateTime createdAt = createdAtStr.isNotEmpty ? DateTime.parse(createdAtStr) : DateTime.now();

    final String createdBy = (json['createdBy'] ?? json['created_by'] ?? content['createdBy'] ?? '').toString();

    final String submittedAtStr = (json['submittedAt'] ?? json['submitted_at'] ?? '').toString();
    final DateTime? submittedAt = submittedAtStr.isNotEmpty ? DateTime.parse(submittedAtStr) : null;
    final String? submittedBy = (json['submittedBy'] ?? json['submitted_by'] ?? content['submittedBy'])?.toString();
    final String? submittedByName = (json['submittedByName'] ?? json['submitted_by_name'] ?? content['submittedByName'])?.toString();

    final String reviewedAtStr = (json['reviewedAt'] ?? json['approved_at'] ?? json['rejected_at'] ?? '').toString();
    final DateTime? reviewedAt = reviewedAtStr.isNotEmpty ? DateTime.parse(reviewedAtStr) : null;
    final String? reviewedBy = (json['reviewedBy'] ?? json['approved_by'] ?? json['rejected_by'] ?? content['reviewedBy'])?.toString();
    final String? reviewedByName = (json['reviewedByName'] ?? json['reviewed_by_name'] ?? content['reviewedByName'])?.toString();

    final String? clientComment = (json['clientComment'] ?? content['clientComment'] ?? json['comments'])?.toString();
    final String? changeRequestDetails = (json['changeRequestDetails'] ?? content['changeRequestDetails'])?.toString();

    final String approvedAtStr = (json['approvedAt'] ?? json['approved_at'] ?? '').toString();
    final DateTime? approvedAt = approvedAtStr.isNotEmpty ? DateTime.parse(approvedAtStr) : null;
    final String? approvedBy = (json['approvedBy'] ?? json['approved_by'] ?? content['approvedBy'])?.toString();
    final String? approvedByName = (json['approvedByName'] ?? json['approved_by_name'] ?? content['approvedByName'])?.toString();
    final String? digitalSignature = (json['digitalSignature'] ?? json['signature'] ?? content['digitalSignature'])?.toString();

    return SignOffReport(
      id: id,
      deliverableId: deliverableId,
      reportTitle: reportTitle,
      reportContent: reportContent,
      sprintIds: sprintIds,
      sprintPerformanceData: sprintPerformanceData,
      knownLimitations: knownLimitations,
      nextSteps: nextSteps,
      status: status,
      createdAt: createdAt,
      createdBy: createdBy,
      submittedAt: submittedAt,
      submittedBy: submittedBy,
      submittedByName: submittedByName,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      reviewedByName: reviewedByName,
      clientComment: clientComment,
      changeRequestDetails: changeRequestDetails,
      approvedAt: approvedAt,
      approvedBy: approvedBy,
      approvedByName: approvedByName,
      digitalSignature: digitalSignature,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case ReportStatus.draft:
        return 'Draft';
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.approved:
        return 'Approved';
      case ReportStatus.changeRequested:
        return 'Change Requested';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case ReportStatus.draft:
        return Colors.grey;
      case ReportStatus.submitted:
        return Colors.blue;
      case ReportStatus.underReview:
        return Colors.orange;
      case ReportStatus.approved:
        return Colors.green;
      case ReportStatus.changeRequested:
        return Colors.amber;
      case ReportStatus.rejected:
        return Colors.red;
    }
  }

  bool get isApproved => status == ReportStatus.approved;
  bool get isPendingReview => status == ReportStatus.submitted || status == ReportStatus.underReview;
  bool get needsChanges => status == ReportStatus.changeRequested;

  static ReportStatus _parseStatus(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'submitted':
        return ReportStatus.submitted;
      case 'under_review':
      case 'underreview':
        return ReportStatus.underReview;
      case 'approved':
        return ReportStatus.approved;
      case 'change_requested':
      case 'changerequested':
        return ReportStatus.changeRequested;
      case 'rejected':
        return ReportStatus.rejected;
      case 'draft':
      default:
        return ReportStatus.draft;
    }
  }
}
