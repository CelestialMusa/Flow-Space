class Project {
  final String id;
  final String name;
  final String description;
  final String key;
  final String clientName;
  final String? repositoryUrl;
  final String? documentationUrl;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.key,
    required this.clientName,
    this.repositoryUrl,
    this.documentationUrl,
    this.status = 'active',
    required this.startDate,
    this.endDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      key: json['key'] as String,
      clientName: json['client_name'] as String? ?? '',
      repositoryUrl: json['repository_url'] as String?,
      documentationUrl: json['documentation_url'] as String?,
      status: json['status'] as String? ?? 'active',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'key': key,
      'client_name': clientName,
      'repository_url': repositoryUrl,
      'documentation_url': documentationUrl,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? key,
    String? clientName,
    String? repositoryUrl,
    String? documentationUrl,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      key: key ?? this.key,
      clientName: clientName ?? this.clientName,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      documentationUrl: documentationUrl ?? this.documentationUrl,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProjectCreate {
  final String name;
  final String description;
  final String key;
  final String clientName;
  final String? repositoryUrl;
  final String? documentationUrl;
  final DateTime startDate;
  final DateTime? endDate;

  ProjectCreate({
    required this.name,
    required this.description,
    required this.key,
    required this.clientName,
    this.repositoryUrl,
    this.documentationUrl,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'key': key,
      'client_name': clientName,
      'repository_url': repositoryUrl,
      'documentation_url': documentationUrl,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}

class ProjectUpdate {
  final String? name;
  final String? description;
  final String? key;
  final String? clientName;
  final String? repositoryUrl;
  final String? documentationUrl;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;

  ProjectUpdate({
    this.name,
    this.description,
    this.key,
    this.clientName,
    this.repositoryUrl,
    this.documentationUrl,
    this.status,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (key != null) data['key'] = key;
    if (clientName != null) data['client_name'] = clientName;
    if (repositoryUrl != null) data['repository_url'] = repositoryUrl;
    if (documentationUrl != null) data['documentation_url'] = documentationUrl;
    if (status != null) data['status'] = status;
    if (startDate != null) data['start_date'] = startDate!.toIso8601String();
    if (endDate != null) data['end_date'] = endDate?.toIso8601String();
    return data;
  }
}
