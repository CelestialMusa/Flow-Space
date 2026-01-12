import 'dart:convert';
import 'package:http/http.dart' as http;
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

  /// Get all sprints for the current user
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

  /// Create a new sprint
  Future<Map<String, dynamic>> createSprint({
    required String name,
    String description = '',
    required DateTime startDate,
    required DateTime endDate,
    String? projectId,
    int plannedPoints = 0,
  }) async {
    try {
      final body = {
        'name': name,
        'description': description,
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

      final response = await http.put(
        Uri.parse('$_baseUrl/sprints/$sprintId'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Sprint $sprintId updated successfully');
          return data['data'];
        }
      }
      
      debugPrint('❌ Failed to update sprint: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error updating sprint: $e');
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

      final response = await http.post(
        Uri.parse('$_baseUrl/projects'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Project created successfully: ${data['data']['project_name']}');
          return data['data'];
        }
      }
      
      debugPrint('❌ Failed to create project: ${response.statusCode}');
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
      debugPrint('🔍 Headers: $_headers');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/projects'),
        headers: _headers,
      );

      debugPrint('🔍 Response status: ${response.statusCode}');
      debugPrint('🔍 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Fetched ${data['data'].length} projects');
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      
      debugPrint('❌ Failed to fetch projects: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching projects: $e');
      return [];
    }
  }

  // ===== TICKET MANAGEMENT =====

  /// Get all tickets for a sprint
  Future<List<Map<String, dynamic>>> getSprintTickets(String sprintId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sprints/$sprintId/tickets'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Fetched ${data['data'].length} tickets for sprint $sprintId');
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      
      debugPrint('❌ Failed to fetch tickets: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching tickets: $e');
      return [];
    }
  }

  /// Get sprint details by ID
  Future<Map<String, dynamic>?> getSprintDetails(String sprintId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sprints/$sprintId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Fetched sprint details for sprint $sprintId');
          return data['data'];
        }
      }
      
      debugPrint('❌ Failed to fetch sprint details: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching sprint details: $e');
      return null;
    }
  }

  /// Create a new ticket
  Future<Map<String, dynamic>?> createTicket({
    required String sprintId,
    required String title,
    required String description,
    String? assignee,
    required String priority,
    required String type,
  }) async {
    try {
      debugPrint('🎫 Creating ticket: $title for sprint $sprintId');
      
      final body = {
        'sprintId': sprintId,
        'title': title,
        'description': description,
        'assignee': assignee,
        'priority': priority,
        'type': type,
        'status': 'To Do',
      };

      final response = await _post('/tickets', body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Ticket "$title" created successfully');
          return data['data'];
        }
      }
      
      debugPrint('❌ Failed to create ticket: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creating ticket: $e');
      return null;
    }
  }

  /// Update ticket status (for drag and drop)
  Future<bool> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    try {
      final body = {'status': status};

      final response = await http.put(
        Uri.parse('$_baseUrl/tickets/$ticketId/status'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Ticket $ticketId status updated to $status');
          return true;
        }
      }
      
      debugPrint('❌ Failed to update ticket status: ${response.statusCode}');
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

      final response = await http.put(
        Uri.parse('$_baseUrl/tickets/$ticketId'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Ticket $ticketId updated successfully');
          return data['data'];
        }
      }
      
      debugPrint('❌ Failed to update ticket: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error updating ticket: $e');
      return null;
    }
  }

  // Send collaborator invitation email
  Future<Map<String, dynamic>?> sendCollaboratorInvitation({
    required String email,
    required String role,
    required String projectName,
  }) async {
    try {
      debugPrint('📧 Sending invitation to $email as $role for project $projectName');
      
      final response = await _post('/collaborators/invite', {
        'email': email,
        'role': role,
        'projectName': projectName,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Invitation sent successfully');
          return data;
        }
      }
      
      debugPrint('❌ Failed to send invitation: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error sending invitation: $e');
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

      final response = await http.put(
        Uri.parse('$_baseUrl/sprints/$sprintId/status'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Sprint $sprintId status updated to $status');
          
          // Send notification for sprint status change
          if (oldStatus != null && sprintName != null) {
            try {
              final token = _authService.accessToken;
              if (token != null) {
                _notificationService.setAuthToken(token);
                final user = _authService.currentUser;
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
      }

      debugPrint('❌ Failed to update sprint status: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating sprint status: $e');
      return false;
    }
  }
}
