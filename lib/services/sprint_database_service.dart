import 'notification_service.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'backend_api_service.dart';

class SprintDatabaseService {
  static const String _baseUrl = 'https://flow-space.onrender.com/api/v1';
  final NotificationService _notificationService = NotificationService();
  final ApiClient _apiClient = ApiClient();
  final BackendApiService _backendApiService = BackendApiService();
  
  // Get authentication token from ApiClient
  String? get _token => _apiClient.accessToken;

  // ===== SPRINT MANAGEMENT =====

  /// Get all sprints for current user
  Future<List<Map<String, dynamic>>> getSprints() async {
    try {
      debugPrint('🔍 Fetching sprints from: $_baseUrl/sprints');
      debugPrint('🔍 Auth token: ${_token != null ? "Present" : "Missing"}');
      
      final response = await _backendApiService.getSprints();
      
      if (response.isSuccess && response.data != null) {
        final data = response.data as List;
        debugPrint('✅ Fetched ${data.length} sprints from database');
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ Failed to fetch sprints: ${response.error ?? 'Unknown error'}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching sprints: $e');
      return [];
    }
  }

  /// Get sprint details
  Future<Map<String, dynamic>?> getSprintDetails(String sprintId) async {
    try {
      final response = await _backendApiService.getSprint(sprintId);
      
      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Fetched sprint details for $sprintId');
        return response.data as Map<String, dynamic>;
      }
      
      debugPrint('❌ Failed to fetch sprint details: ${response.error ?? 'Unknown error'}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching sprint details: $e');
      return null;
    }
  }

  /// Create a new sprint
  Future<Map<String, dynamic>> createSprint({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? projectId,
    int plannedPoints = 0,
  }) async {
    try {
      final body = {
        'name': name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'planned_points': plannedPoints,
        if (projectId != null) 'project_id': projectId,
      };

      debugPrint('🚀 Creating sprint with data: $body');
      final response = await _backendApiService.createSprint(body);

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Sprint "$name" created successfully');
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('❌ Failed to create sprint: ${response.error ?? 'Unknown error'}');
        throw Exception(response.error ?? 'Failed to create sprint');
      }
    } catch (e) {
      debugPrint('❌ Error creating sprint: $e');
      rethrow;
    }
  }

  /// Update sprint
  Future<Map<String, dynamic>?> updateSprint({
    required int sprintId,
    String? name,
    String? goal,
    String? state,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (goal != null) body['goal'] = goal;
      if (state != null) body['state'] = state;
      if (startDate != null) body['startDate'] = startDate.toIso8601String();
      if (endDate != null) body['endDate'] = endDate.toIso8601String();

      final response = await _backendApiService.updateSprint(sprintId.toString(), body);

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Sprint $sprintId updated successfully');
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('❌ Failed to update sprint: ${response.error ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error updating sprint: $e');
      return null;
    }
  }

  /// Update sprint status
  Future<bool> updateSprintStatus({
    required String sprintId,
    required String status,
    String? oldStatus,
    String? sprintName,
  }) async {
    try {
      final body = {'status': status};

      final response = await _backendApiService.updateSprintStatus(sprintId, body);

      if (response.isSuccess) {
        debugPrint('✅ Sprint $sprintId status updated to $status');
        
        // Send notification for sprint status change
        if (oldStatus != null && sprintName != null) {
          try {
            final token = _apiClient.accessToken;
            if (token != null) {
              _notificationService.setAuthToken(token);
              final user = _apiClient.currentUser;
              final userName = user?.name ?? 'Unknown User';
              
              await _notificationService.notifySprintStatusChange(
                sprintName: sprintName,
                oldStatus: oldStatus,
                newStatus: status,
                changedBy: userName,
              );
            }
          } catch (e) {
            debugPrint('❌ Error sending sprint status notification: $e');
          }
        }
        
        return true;
      }

      debugPrint('❌ Failed to update sprint status: ${response.error ?? 'Unknown error'}');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating sprint status: $e');
      return false;
    }
  }

  // ===== TICKET MANAGEMENT =====

  /// Update ticket status (for drag and drop)
  Future<bool> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    try {
      final body = {'status': status};

      final response = await _backendApiService.updateTicketStatus(ticketId, body);

      if (response.isSuccess) {
        debugPrint('✅ Ticket $ticketId status updated to $status');
        return true;
      }
      
      debugPrint('❌ Failed to update ticket status: ${response.error ?? 'Unknown error'}');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating ticket status: $e');
      return false;
    }
  }

  /// Update ticket details
  Future<Map<String, dynamic>?> updateTicket({
    required String ticketId,
    String? summary,
    String? description,
    String? assignee,
    String? priority,
    List<String>? labels,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (summary != null) body['summary'] = summary;
      if (description != null) body['description'] = description;
      if (assignee != null) body['assignee'] = assignee;
      if (priority != null) body['priority'] = priority;
      if (labels != null) body['labels'] = labels;

      final response = await _backendApiService.updateTicket(ticketId, body);

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Ticket $ticketId updated successfully');
        return response.data as Map<String, dynamic>;
      }
      
      debugPrint('❌ Failed to update ticket: ${response.error ?? 'Unknown error'}');
      return null;
    } catch (e) {
      debugPrint('❌ Error updating ticket: $e');
      return null;
    }
  }

  /// Create a new ticket
  Future<Map<String, dynamic>?> createTicket({
    required String title,
    required String description,
    required String sprintId,
    String? assignee,
    String priority = 'medium',
    String status = 'todo',
    List<String>? labels,
  }) async {
    try {
      final body = {
        'title': title,
        'description': description,
        'sprint_id': sprintId,
        if (assignee != null) 'assignee': assignee,
        'priority': priority,
        'status': status,
        if (labels != null) 'labels': labels,
      };

      debugPrint('🚀 Creating ticket with data: $body');
      final response = await _apiClient.post('/tickets', body: body);

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Ticket "$title" created successfully');
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('❌ Failed to create ticket: ${response.error ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating ticket: $e');
      return null;
    }
  }

  // ===== PROJECT MANAGEMENT =====

  /// Create a new project
  Future<Map<String, dynamic>?> createProject({
    required String name,
    String? key,
    String? description,
    String? projectType,
    DateTime? startDate,
    DateTime? endDate,
    String? clientEmail,
  }) async {
    try {
      final body = {
        'name': name,
        if (key != null) 'key': key,
        if (description != null) 'description': description,
        if (projectType != null) 'projectType': projectType,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (clientEmail != null) 'client_email': clientEmail,
      };

      final response = await _backendApiService.createProject(body);

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Project created successfully');
        return response.data as Map<String, dynamic>;
      }
      
      debugPrint('❌ Failed to create project: ${response.error ?? 'Unknown error'}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creating project: $e');
      return null;
    }
  }

  /// Get all projects
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      debugPrint('🔍 Fetching projects from: $_baseUrl/projects');
      debugPrint('🔍 Auth token: ${_token != null ? "Present" : "Missing"}');
      
      final response = await _backendApiService.getProjects();
      
      if (response.isSuccess && response.data != null) {
        final data = response.data as List;
        debugPrint('✅ Fetched ${data.length} projects');
        return data.cast<Map<String, dynamic>>();
      }
      
      debugPrint('❌ Failed to fetch projects: ${response.error ?? 'Unknown error'}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching projects: $e');
      return [];
    }
  }

  /// Get all tickets for a sprint
  Future<List<Map<String, dynamic>>> getSprintTickets(String sprintId) async {
    try {
      final response = await _backendApiService.getSprintTickets(sprintId);

      if (response.isSuccess && response.data != null) {
        final data = response.data as List;
        debugPrint('✅ Fetched ${data.length} tickets for sprint $sprintId');
        return data.cast<Map<String, dynamic>>();
      }
      
      debugPrint('❌ Failed to fetch tickets: ${response.error ?? 'Unknown error'}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching tickets: $e');
      return [];
    }
  }
}
