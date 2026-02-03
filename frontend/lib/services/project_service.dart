import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/project.dart';
import 'api_service.dart';

class ProjectService {
  static Future<List<Project>> getProjects({int limit = 100, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/projects?limit=$limit&skip=$offset'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> projectsData = data['data'];
          return projectsData.map((project) => Project.fromJson(project)).toList();
        }
      }
      throw Exception('Failed to load projects');
    } catch (e) {
      throw Exception('Error fetching projects: $e');
    }
  }

  static Future<Project> getProject(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Project.fromJson(data['data']);
        }
      }
      throw Exception('Failed to load project');
    } catch (e) {
      throw Exception('Error fetching project: $e');
    }
  }

  static Future<Project> createProject(ProjectCreate projectCreate) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/projects'),
        headers: _getHeaders(),
        body: json.encode(projectCreate.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Project.fromJson(data['data']);
        }
      }
      
      if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid project data');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to create projects');
      }
      
      throw Exception('Failed to create project');
    } catch (e) {
      throw Exception('Error creating project: $e');
    }
  }

  static Future<Project> updateProject(String projectId, ProjectUpdate projectUpdate) async {
    try {
      final response = await http.put(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId'),
        headers: _getHeaders(),
        body: json.encode(projectUpdate.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Project.fromJson(data['data']);
        }
      }
      
      if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid project data');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to update this project');
      } else if (response.statusCode == 404) {
        throw Exception('Project not found');
      }
      
      throw Exception('Failed to update project');
    } catch (e) {
      throw Exception('Error updating project: $e');
    }
  }

  static Future<void> deleteProject(String projectId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 204) {
        return;
      }
      
      if (response.statusCode == 403) {
        throw Exception('You do not have permission to delete this project');
      } else if (response.statusCode == 404) {
        throw Exception('Project not found');
      }
      
      throw Exception('Failed to delete project');
    } catch (e) {
      throw Exception('Error deleting project: $e');
    }
  }

  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Add Authorization header if token is available
    if (ApiService.accessToken != null) {
      headers['Authorization'] = 'Bearer ${ApiService.accessToken}';
    }
    
    return headers;
  }

  // Helper method to format project status
  static String formatProjectStatus(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'on_hold':
        return 'On Hold';
      case 'cancelled':
        return 'Cancelled';
      case 'archived':
        return 'Archived';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  // Helper method to get status color
  static String getStatusColor(String? status) {
    if (status == null || status.isEmpty) return '#9E9E9E'; // Grey
    
    switch (status.toLowerCase()) {
      case 'active':
        return '#4CAF50'; // Green
      case 'completed':
        return '#2196F3'; // Blue
      case 'on_hold':
        return '#FF9800'; // Orange
      case 'cancelled':
        return '#F44336'; // Red
      case 'archived':
        return '#9E9E9E'; // Grey
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

  // Helper method to check if project is overdue
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

  // Helper method to get project status icon
  static String getStatusIcon(String? status) {
    if (status == null || status.isEmpty) return 'help_outline';
    
    switch (status.toLowerCase()) {
      case 'active':
        return 'play_arrow';
      case 'completed':
        return 'check_circle';
      case 'on_hold':
        return 'pause';
      case 'cancelled':
        return 'cancel';
      case 'archived':
        return 'archive';
      default:
        return 'help_outline';
    }
  }
}
