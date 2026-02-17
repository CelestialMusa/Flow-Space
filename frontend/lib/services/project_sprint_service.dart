import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import 'api_service.dart';

class ProjectSprintService {
  static Future<List<Map<String, dynamic>>> getProjectSprints(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/sprints'),
        headers: _getHeaders(),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        if (data is Map && data['success'] == true) {
          final List<dynamic> sprintsData = data['data'] ?? [];
          return sprintsData.cast<Map<String, dynamic>>();
        } else if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      throw Exception(data['error'] ?? data['message'] ?? 'Failed to load project sprints: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching project sprints: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableSprints(
    String projectId, {
    String? search,
  }
  ) async {
    try {
      String url = '${Environment.apiBaseUrl}/projects/$projectId/available-sprints';
      if (search != null && search.isNotEmpty) {
        url += '?search=${Uri.encodeComponent(search)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> sprintsData = data['data'];
          return sprintsData.cast<Map<String, dynamic>>();
        }
      }
      throw Exception('Failed to load available sprints');
    } catch (e) {
      throw Exception('Error fetching available sprints: $e');
    }
  }

  static Future<Map<String, dynamic>> linkSprintsToProject(
    String projectId,
    List<String> sprintIds,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/sprints'),
        headers: _getHeaders(),
        body: json.encode({
          'sprintIds': sprintIds,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      
      if (response.statusCode == 403) {
        throw Exception('Only project owners and contributors can link sprints');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid request');
      }
      
      throw Exception('Failed to link sprints to project');
    } catch (e) {
      throw Exception('Error linking sprints: $e');
    }
  }

  static Future<Map<String, dynamic>> createSprintForProject(
    String projectId,
    String name, {
    String? description,
    String? startDate,
    String? endDate,
  }
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/sprints/new'),
        headers: _getHeaders(),
        body: json.encode({
          'name': name,
          'description': description,
          'start_date': startDate,
          'end_date': endDate,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      
      if (response.statusCode == 403) {
        throw Exception('Only project owners and contributors can create sprints');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid request');
      }
      
      throw Exception('Failed to create sprint for project');
    } catch (e) {
      throw Exception('Error creating sprint: $e');
    }
  }

  static Future<void> unlinkSprintFromProject(
    String projectId,
    String sprintId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/sprints/$sprintId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        }
      }
      
      if (response.statusCode == 403) {
        throw Exception('Only project owners and contributors can unlink sprints');
      } else if (response.statusCode == 404) {
        throw Exception('Sprint not found in this project');
      }
      
      throw Exception('Failed to unlink sprint from project');
    } catch (e) {
      throw Exception('Error unlinking sprint: $e');
    }
  }

  static Map<String, String> _getHeaders() {
    final token = ApiService.accessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper method to format sprint status
  static String formatSprintStatus(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  // Helper method to get status color
  static String getStatusColor(String? status) {
    if (status == null || status.isEmpty) return '#9E9E9E'; // Grey
    
    switch (status.toLowerCase()) {
      case 'draft':
        return '#FF9800'; // Orange
      case 'active':
        return '#4CAF50'; // Green
      case 'completed':
        return '#2196F3'; // Blue
      case 'cancelled':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Helper method to format date
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'No date';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  // Helper method to get progress color
  static String getProgressColor(int progress) {
    if (progress >= 80) return '#4CAF50'; // Green
    if (progress >= 50) return '#FF9800'; // Orange
    if (progress >= 20) return '#FFC107'; // Amber
    return '#F44336'; // Red
  }

  // Helper method to calculate sprint duration
  static String calculateDuration(String? startDate, String? endDate) {
    if (startDate == null || startDate.isEmpty || endDate == null || endDate.isEmpty) {
      return 'No duration';
    }
    
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final duration = end.difference(start).inDays;
      
      if (duration == 0) return '1 day';
      if (duration == 1) return '1 day';
      return '$duration days';
    } catch (e) {
      return 'Invalid dates';
    }
  }

  // Helper method to check if sprint is overdue
  static bool isOverdue(String? endDate, String? status) {
    if (endDate == null || endDate.isEmpty || status == 'completed') return false;
    
    try {
      final end = DateTime.parse(endDate);
      final now = DateTime.now();
      return now.isAfter(end);
    } catch (e) {
      return false;
    }
  }

  // Helper method to get sprint status icon
  static String getStatusIcon(String? status) {
    if (status == null || status.isEmpty) return 'help_outline';
    
    switch (status.toLowerCase()) {
      case 'draft':
        return 'edit';
      case 'active':
        return 'play_arrow';
      case 'completed':
        return 'check_circle';
      case 'cancelled':
        return 'cancel';
      default:
        return 'help_outline';
    }
  }
}
