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
  final int plannedPoints;
  final int addedDuringSprint;
  final int removedDuringSprint;

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
    required this.defectCount,
    this.carriedOverPoints = 0,
    this.scopeChanges = const [],
    this.notes,
    this.isActive = false,
    this.plannedPoints = 0,
    this.addedDuringSprint = 0,
    this.removedDuringSprint = 0,
  });

  factory Sprint.fromJson(Map<String, dynamic> json) {
    return Sprint(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? json['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? json['end_date']?.toString() ?? '') ?? DateTime.now(),
      committedPoints: json['committedPoints'] is int ? json['committedPoints'] : (json['committed_points'] is int ? json['committed_points'] : int.tryParse(json['committedPoints']?.toString() ?? json['committed_points']?.toString() ?? '') ?? 0),
      completedPoints: json['completedPoints'] is int ? json['completedPoints'] : (json['completed_points'] is int ? json['completed_points'] : int.tryParse(json['completedPoints']?.toString() ?? json['completed_points']?.toString() ?? '') ?? 0),
      velocity: json['velocity'] is int ? json['velocity'] : int.tryParse(json['velocity']?.toString() ?? '') ?? 0,
      testPassRate: json['testPassRate'] is double ? json['testPassRate'] : (json['test_pass_rate'] is double ? json['test_pass_rate'] : double.tryParse(json['testPassRate']?.toString() ?? json['test_pass_rate']?.toString() ?? '') ?? 0.0),
      codeCoverage: json['codeCoverage'] is int ? json['codeCoverage'] : (json['code_coverage'] is int ? json['code_coverage'] : int.tryParse(json['codeCoverage']?.toString() ?? json['code_coverage']?.toString() ?? '') ?? 0),
      escapedDefects: json['escapedDefects'] is int ? json['escapedDefects'] : (json['escaped_defects'] is int ? json['escaped_defects'] : int.tryParse(json['escapedDefects']?.toString() ?? json['escaped_defects']?.toString() ?? '') ?? 0),
      defectsOpened: json['defectsOpened'] is int ? json['defectsOpened'] : (json['defects_opened'] is int ? json['defects_opened'] : int.tryParse(json['defectsOpened']?.toString() ?? json['defects_opened']?.toString() ?? '') ?? 0),
      defectsClosed: json['defectsClosed'] is int ? json['defectsClosed'] : (json['defects_closed'] is int ? json['defects_closed'] : int.tryParse(json['defectsClosed']?.toString() ?? json['defects_closed']?.toString() ?? '') ?? 0),
      defectSeverityMix: json['defectSeverityMix'] is Map ? Map<String, dynamic>.from(json['defectSeverityMix']) : (json['defect_severity_mix'] is Map ? Map<String, dynamic>.from(json['defect_severity_mix']) : null),
      codeReviewCompletion: json['codeReviewCompletion'] is int ? json['codeReviewCompletion'] : (json['code_review_completion'] is int ? json['code_review_completion'] : int.tryParse(json['codeReviewCompletion']?.toString() ?? json['code_review_completion']?.toString() ?? '') ?? 0),
      documentationStatus: json['documentationStatus'] ?? json['documentation_status'],
      uatNotes: json['uatNotes'] ?? json['uat_notes'],
      uatPassRate: json['uatPassRate'] is int ? json['uatPassRate'] : (json['uat_pass_rate'] is int ? json['uat_pass_rate'] : int.tryParse(json['uatPassRate']?.toString() ?? json['uat_pass_rate']?.toString() ?? '') ?? 0),
      risksIdentified: json['risksIdentified'] is int ? json['risksIdentified'] : (json['risks_identified'] is int ? json['risks_identified'] : int.tryParse(json['risksIdentified']?.toString() ?? json['risks_identified']?.toString() ?? '') ?? 0),
      risks: json['risks'],
      risksMitigated: json['risksMitigated'] is int ? json['risksMitigated'] : (json['risks_mitigated'] is int ? json['risks_mitigated'] : int.tryParse(json['risksMitigated']?.toString() ?? json['risks_mitigated']?.toString() ?? '') ?? 0),
      blockers: json['blockers'],
      decisions: json['decisions'],
      defectCount: json['defectCount'] is int ? json['defectCount'] : (json['defect_count'] is int ? json['defect_count'] : int.tryParse(json['defectCount']?.toString() ?? json['defect_count']?.toString() ?? '') ?? 0),
      carriedOverPoints: json['carriedOverPoints'] is int ? json['carriedOverPoints'] : (json['carried_over_points'] is int ? json['carried_over_points'] : int.tryParse(json['carriedOverPoints']?.toString() ?? json['carried_over_points']?.toString() ?? '') ?? 0),
      scopeChanges: List<String>.from(json['scopeChanges'] ?? json['scope_changes'] ?? []),
      notes: json['notes'],
      isActive: json['isActive'] ?? json['is_active'] ?? false,
      plannedPoints: json['plannedPoints'] is int ? json['plannedPoints'] : (json['planned_points'] is int ? json['planned_points'] : int.tryParse(json['plannedPoints']?.toString() ?? json['planned_points']?.toString() ?? '') ?? 0),
      addedDuringSprint: json['addedDuringSprint'] is int ? json['addedDuringSprint'] : (json['added_during_sprint'] is int ? json['added_during_sprint'] : int.tryParse(json['addedDuringSprint']?.toString() ?? json['added_during_sprint']?.toString() ?? '') ?? 0),
      removedDuringSprint: json['removedDuringSprint'] is int ? json['removedDuringSprint'] : (json['removed_during_sprint'] is int ? json['removed_during_sprint'] : int.tryParse(json['removedDuringSprint']?.toString() ?? json['removed_during_sprint']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'committedPoints': committedPoints,
      'completedPoints': completedPoints,
      'velocity': velocity,
      'testPassRate': testPassRate,
      'codeCoverage': codeCoverage,
      'escapedDefects': escapedDefects,
      'defectsOpened': defectsOpened,
      'defectsClosed': defectsClosed,
      'defectSeverityMix': defectSeverityMix,
      'codeReviewCompletion': codeReviewCompletion,
      'documentationStatus': documentationStatus,
      'uatNotes': uatNotes,
      'uatPassRate': uatPassRate,
      'risksIdentified': risksIdentified,
      'risks': risks,
      'risksMitigated': risksMitigated,
      'blockers': blockers,
      'decisions': decisions,
      'defectCount': defectCount,
      'carriedOverPoints': carriedOverPoints,
      'scopeChanges': scopeChanges,
      'notes': notes,
      'isActive': isActive,
      'plannedPoints': plannedPoints,
      'addedDuringSprint': addedDuringSprint,
      'removedDuringSprint': removedDuringSprint,
    };
  }

  double get completionRate {
    if (committedPoints == 0) return 0.0;
    return (completedPoints / committedPoints) * 100;
  }

  String get statusText {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 'Planning';
    if (now.isAfter(endDate)) return 'Completed';
    return 'In Progress';
  }
}

class SprintCreate {
  final String? projectId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int plannedPoints;
  final int committedPoints;
  final int completedPoints;
  final int velocity;
  final double testPassRate;
  final double codeCoverage;
  final int defectCount;
  final int escapedDefects;
  final int defectsClosed;
  final int carriedOverPoints;
  final int addedDuringSprint;
  final int removedDuringSprint;
  final List<String> scopeChanges;
  final String? notes;
  final double codeReviewCompletion;
  final String? documentationStatus;
  final String? uatNotes;
  final double uatPassRate;
  final int risksIdentified;
  final int risksMitigated;
  final String? blockers;
  final String? decisions;
  final bool isActive;

  SprintCreate({
    this.projectId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.plannedPoints = 0,
    this.committedPoints = 0,
    this.completedPoints = 0,
    this.velocity = 0,
    this.testPassRate = 0.0,
    this.codeCoverage = 0.0,
    this.defectCount = 0,
    this.escapedDefects = 0,
    this.defectsClosed = 0,
    this.carriedOverPoints = 0,
    this.addedDuringSprint = 0,
    this.removedDuringSprint = 0,
    this.scopeChanges = const [],
    this.notes,
    this.codeReviewCompletion = 0.0,
    this.documentationStatus,
    this.uatNotes,
    this.uatPassRate = 0.0,
    this.risksIdentified = 0,
    this.risksMitigated = 0,
    this.blockers,
    this.decisions,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'planned_points': plannedPoints,
      'committed_points': committedPoints,
      'completed_points': completedPoints,
      'velocity': velocity,
      'test_pass_rate': testPassRate,
      'code_coverage': codeCoverage,
      'defect_count': defectCount,
      'escaped_defects': escapedDefects,
      'defects_closed': defectsClosed,
      'carried_over_points': carriedOverPoints,
      'added_during_sprint': addedDuringSprint,
      'removed_during_sprint': removedDuringSprint,
      'scope_changes': scopeChanges,
      'notes': notes,
      'code_review_completion': codeReviewCompletion,
      'documentation_status': documentationStatus,
      'uat_notes': uatNotes,
      'uat_pass_rate': uatPassRate,
      'risks_identified': risksIdentified,
      'risks_mitigated': risksMitigated,
      'blockers': blockers,
      'decisions': decisions,
      'is_active': isActive,
    };
  }
}

class SprintUpdate {
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? plannedPoints;
  final int? committedPoints;
  final int? completedPoints;
  final int? velocity;
  final double? testPassRate;
  final double? codeCoverage;
  final int? defectCount;
  final int? escapedDefects;
  final int? defectsClosed;
  final int? carriedOverPoints;
  final int? addedDuringSprint;
  final int? removedDuringSprint;
  final List<String>? scopeChanges;
  final String? notes;
  final double? codeReviewCompletion;
  final String? documentationStatus;
  final String? uatNotes;
  final double? uatPassRate;
  final int? risksIdentified;
  final int? risksMitigated;
  final String? blockers;
  final String? decisions;
  final bool? isActive;

  SprintUpdate({
    this.name,
    this.startDate,
    this.endDate,
    this.plannedPoints,
    this.committedPoints,
    this.completedPoints,
    this.velocity,
    this.testPassRate,
    this.codeCoverage,
    this.defectCount,
    this.escapedDefects,
    this.defectsClosed,
    this.carriedOverPoints,
    this.addedDuringSprint,
    this.removedDuringSprint,
    this.scopeChanges,
    this.notes,
    this.codeReviewCompletion,
    this.documentationStatus,
    this.uatNotes,
    this.uatPassRate,
    this.risksIdentified,
    this.risksMitigated,
    this.blockers,
    this.decisions,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (startDate != null) data['start_date'] = startDate!.toIso8601String();
    if (endDate != null) data['end_date'] = endDate!.toIso8601String();
    if (plannedPoints != null) data['planned_points'] = plannedPoints;
    if (committedPoints != null) data['committed_points'] = committedPoints;
    if (completedPoints != null) data['completed_points'] = completedPoints;
    if (velocity != null) data['velocity'] = velocity;
    if (testPassRate != null) data['test_pass_rate'] = testPassRate;
    if (codeCoverage != null) data['code_coverage'] = codeCoverage;
    if (defectCount != null) data['defect_count'] = defectCount;
    if (escapedDefects != null) data['escaped_defects'] = escapedDefects;
    if (defectsClosed != null) data['defects_closed'] = defectsClosed;
    if (carriedOverPoints != null) data['carried_over_points'] = carriedOverPoints;
    if (addedDuringSprint != null) data['added_during_sprint'] = addedDuringSprint;
    if (removedDuringSprint != null) data['removed_during_sprint'] = removedDuringSprint;
    if (scopeChanges != null) data['scope_changes'] = scopeChanges;
    if (notes != null) data['notes'] = notes;
    if (codeReviewCompletion != null) data['code_review_completion'] = codeReviewCompletion;
    if (documentationStatus != null) data['documentation_status'] = documentationStatus;
    if (uatNotes != null) data['uat_notes'] = uatNotes;
    if (uatPassRate != null) data['uat_pass_rate'] = uatPassRate;
    if (risksIdentified != null) data['risks_identified'] = risksIdentified;
    if (risksMitigated != null) data['risks_mitigated'] = risksMitigated;
    if (blockers != null) data['blockers'] = blockers;
    if (decisions != null) data['decisions'] = decisions;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}
