/// Timeline Event Model
/// Represents an event in the calendar/timeline
class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time; // Format: "HH:mm"
  final String priority; // 'low' | 'medium' | 'high'
  final String project;
  final String colorTag; // 'red' | 'blue' | 'green' | 'orange' | 'purple'

  TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.priority,
    required this.project,
    required this.colorTag,
  });

  /// Get full DateTime from date and time
  DateTime get dateTime {
    final timeParts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'priority': priority,
      'project': project,
      'colorTag': colorTag,
    };
  }

  /// Create from JSON
  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      priority: json['priority'] as String,
      project: json['project'] as String,
      colorTag: json['colorTag'] as String,
    );
  }

  /// Create a copy with updated fields
  TimelineEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    String? priority,
    String? project,
    String? colorTag,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      priority: priority ?? this.priority,
      project: project ?? this.project,
      colorTag: colorTag ?? this.colorTag,
    );
  }
}

