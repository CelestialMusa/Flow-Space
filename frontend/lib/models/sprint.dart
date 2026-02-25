import 'package:flutter/material.dart';

class Sprint {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int committedPoints;
  final int completedPoints;
  final int velocity;
  final double testPassRate;
  final int codeCoverage;
  final int escapedDefects;
  final int defectsOpened;
  final int defectsClosed;
  final Map<String, dynamic>? defectSeverityMix;
  final int codeReviewCompletion;
  final String? documentationStatus;
  final String? uatNotes;
  final int uatPassRate;
  final int risksIdentified;
  final String? risks;
  final int risksMitigated;
  final String? blockers;
  final String? decisions;
  final int defectCount;
  final int carriedOverPoints;
  final List<String> scopeChanges;
  final String? notes;
  final bool isActive;

  const Sprint({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.committedPoints,
    required this.completedPoints,
    required this.velocity,
    required this.testPassRate,
    this.codeCoverage = 0,
    this.escapedDefects = 0,
    this.defectsOpened = 0,
    this.defectsClosed = 0,
    this.defectSeverityMix,
    this.codeReviewCompletion = 0,
    this.documentationStatus,
    this.uatNotes,
    this.uatPassRate = 0,
    this.risksIdentified = 0,
    this.risks,
    this.risksMitigated = 0,
    this.blockers,
    this.decisions,
    this.defectCount = 0,
    this.carriedOverPoints = 0,
    this.scopeChanges = const [],
    this.notes,
    this.isActive = true,
  });

  factory Sprint.fromJson(Map<String, dynamic> json) {
    return Sprint(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startDate: DateTime.parse(json['start_date'] ?? json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? json['endDate'] ?? DateTime.now().toIso8601String()),
      committedPoints: json['committedPoints'] ?? json['committed_points'] ?? 0,
      completedPoints: json['completedPoints'] ?? json['completed_points'] ?? 0,
      velocity: json['velocity'] ?? 0,
      testPassRate: (json['testPassRate'] ?? json['test_pass_rate'] ?? 0).toDouble(),
      codeCoverage: json['codeCoverage'] ?? json['code_coverage'] ?? 0,
      escapedDefects: json['escapedDefects'] ?? json['escaped_defects'] ?? 0,
      defectsOpened: json['defectsOpened'] ?? json['defects_opened'] ?? 0,
      defectsClosed: json['defectsClosed'] ?? json['defects_closed'] ?? 0,
      defectSeverityMix: json['defectSeverityMix'] ?? json['defect_severity_mix'],
      codeReviewCompletion: json['codeReviewCompletion'] ?? json['code_review_completion'] ?? 0,
      documentationStatus: json['documentationStatus'] ?? json['documentation_status'],
      uatNotes: json['uatNotes'] ?? json['uat_notes'],
      uatPassRate: json['uatPassRate'] ?? json['uat_pass_rate'] ?? 0,
      risksIdentified: json['risksIdentified'] ?? json['risks_identified'] ?? 0,
      risks: json['risks'],
      risksMitigated: json['risksMitigated'] ?? json['risks_mitigated'] ?? 0,
      blockers: json['blockers'],
      decisions: json['decisions'],
      defectCount: json['defectCount'] ?? json['defect_count'] ?? 0,
      carriedOverPoints: json['carriedOverPoints'] ?? json['carried_over_points'] ?? 0,
      scopeChanges: (json['scopeChanges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
                  (json['scope_changes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      notes: json['notes'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'committed_points': committedPoints,
      'completed_points': completedPoints,
      'velocity': velocity,
      'test_pass_rate': testPassRate,
      'code_coverage': codeCoverage,
      'escaped_defects': escapedDefects,
      'defects_opened': defectsOpened,
      'defects_closed': defectsClosed,
      'defect_severity_mix': defectSeverityMix,
      'code_review_completion': codeReviewCompletion,
      'documentation_status': documentationStatus,
      'uat_notes': uatNotes,
      'uat_pass_rate': uatPassRate,
      'risks_identified': risksIdentified,
      'risks': risks,
      'risks_mitigated': risksMitigated,
      'blockers': blockers,
      'decisions': decisions,
      'defect_count': defectCount,
      'carried_over_points': carriedOverPoints,
      'scope_changes': scopeChanges,
      'notes': notes,
      'is_active': isActive,
    };
  }

  double get completionRate {
    if (committedPoints == 0) return 0.0;
    return (completedPoints / committedPoints) * 100;
  }

  bool get isCompleted {
    return DateTime.now().isAfter(endDate);
  }

  bool get isInProgress {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  int get daysRemaining {
    if (isCompleted) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  Color get statusColor {
    if (isCompleted) {
      return completionRate >= 100 ? Colors.green : Colors.orange;
    } else if (isInProgress) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  String get statusText {
    if (isCompleted) {
      return completionRate >= 100 ? 'Completed' : 'Overdue';
    } else if (isInProgress) {
      return 'In Progress';
    } else {
      return 'Not Started';
    }
  }
}

class SprintCreate {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int committedPoints;
  final int completedPoints;
  final int velocity;
  final double testPassRate;
  final int codeCoverage;
  final int escapedDefects;
  final int defectsOpened;
  final int defectsClosed;
  final Map<String, dynamic>? defectSeverityMix;
  final int codeReviewCompletion;
  final String? documentationStatus;
  final String? uatNotes;
  final int uatPassRate;
  final int risksIdentified;
  final String? risks;
  final int risksMitigated;
  final String? blockers;
  final String? decisions;
  final int defectCount;
  final int carriedOverPoints;
  final List<String> scopeChanges;
  final String? notes;

  const SprintCreate({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.committedPoints = 0,
    this.completedPoints = 0,
    this.velocity = 0,
    this.testPassRate = 0,
    this.codeCoverage = 0,
    this.escapedDefects = 0,
    this.defectsOpened = 0,
    this.defectsClosed = 0,
    this.defectSeverityMix,
    this.codeReviewCompletion = 0,
    this.documentationStatus,
    this.uatNotes,
    this.uatPassRate = 0,
    this.risksIdentified = 0,
    this.risks,
    this.risksMitigated = 0,
    this.blockers,
    this.decisions,
    this.defectCount = 0,
    this.carriedOverPoints = 0,
    this.scopeChanges = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'committed_points': committedPoints,
      'completed_points': completedPoints,
      'velocity': velocity,
      'test_pass_rate': testPassRate,
      'code_coverage': codeCoverage,
      'escaped_defects': escapedDefects,
      'defects_opened': defectsOpened,
      'defects_closed': defectsClosed,
      'defect_severity_mix': defectSeverityMix,
      'code_review_completion': codeReviewCompletion,
      'documentation_status': documentationStatus,
      'uat_notes': uatNotes,
      'uat_pass_rate': uatPassRate,
      'risks_identified': risksIdentified,
      'risks': risks,
      'risks_mitigated': risksMitigated,
      'blockers': blockers,
      'decisions': decisions,
      'defect_count': defectCount,
      'carried_over_points': carriedOverPoints,
      'scope_changes': scopeChanges,
      'notes': notes,
    };
  }
}

class SprintUpdate {
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? committedPoints;
  final int? completedPoints;
  final int? velocity;
  final double? testPassRate;
  final int? codeCoverage;
  final int? escapedDefects;
  final int? defectsOpened;
  final int? defectsClosed;
  final Map<String, dynamic>? defectSeverityMix;
  final int? codeReviewCompletion;
  final String? documentationStatus;
  final String? uatNotes;
  final int? uatPassRate;
  final int? risksIdentified;
  final String? risks;
  final int? risksMitigated;
  final String? blockers;
  final String? decisions;
  final int? defectCount;
  final int? carriedOverPoints;
  final List<String>? scopeChanges;
  final String? notes;

  const SprintUpdate({
    this.name,
    this.startDate,
    this.endDate,
    this.committedPoints,
    this.completedPoints,
    this.velocity,
    this.testPassRate,
    this.codeCoverage,
    this.escapedDefects,
    this.defectsOpened,
    this.defectsClosed,
    this.defectSeverityMix,
    this.codeReviewCompletion,
    this.documentationStatus,
    this.uatNotes,
    this.uatPassRate,
    this.risksIdentified,
    this.risks,
    this.risksMitigated,
    this.blockers,
    this.decisions,
    this.defectCount,
    this.carriedOverPoints,
    this.scopeChanges,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (committedPoints != null) 'committed_points': committedPoints,
      if (completedPoints != null) 'completed_points': completedPoints,
      if (velocity != null) 'velocity': velocity,
      if (testPassRate != null) 'test_pass_rate': testPassRate,
      if (codeCoverage != null) 'code_coverage': codeCoverage,
      if (escapedDefects != null) 'escaped_defects': escapedDefects,
      if (defectsOpened != null) 'defects_opened': defectsOpened,
      if (defectsClosed != null) 'defects_closed': defectsClosed,
      if (defectSeverityMix != null) 'defect_severity_mix': defectSeverityMix,
      if (codeReviewCompletion != null) 'code_review_completion': codeReviewCompletion,
      if (documentationStatus != null) 'documentation_status': documentationStatus,
      if (uatNotes != null) 'uat_notes': uatNotes,
      if (uatPassRate != null) 'uat_pass_rate': uatPassRate,
      if (risksIdentified != null) 'risks_identified': risksIdentified,
      if (risks != null) 'risks': risks,
      if (risksMitigated != null) 'risks_mitigated': risksMitigated,
      if (blockers != null) 'blockers': blockers,
      if (decisions != null) 'decisions': decisions,
      if (defectCount != null) 'defect_count': defectCount,
      if (carriedOverPoints != null) 'carried_over_points': carriedOverPoints,
      if (scopeChanges != null) 'scope_changes': scopeChanges,
      if (notes != null) 'notes': notes,
    };
  }
}
