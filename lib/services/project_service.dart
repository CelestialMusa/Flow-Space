import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../config/api_config.dart';

class ProjectService {
  static const String _baseUrl = ApiConfig.baseUrl;

  static Future<List<Project>> getAllProjects({int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/projects?skip=$skip&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> projectsJson = data['data'];
          return projectsJson.map((json) => Project.fromJson(json)).toList();
        }
      }
      throw Exception('Failed to load projects');
    } catch (e) {
      throw Exception('Error fetching projects: $e');
    }
  }

  static Future<Project?> getProjectById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/projects/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return Project.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching project: $e');
    }
  }

  static Future<Project> createProject(Map<String, dynamic> projectData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.authToken}',
        },
        body: json.encode(projectData),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return Project.fromJson(data['data']);
        }
      }
      
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to create project');
    } catch (e) {
      throw Exception('Error creating project: $e');
    }
  }

  static Future<Project> updateProject(String id, Map<String, dynamic> projectData) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/projects/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.authToken}',
        },
        body: json.encode(projectData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return Project.fromJson(data['data']);
        }
      }
      
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to update project');
    } catch (e) {
      throw Exception('Error updating project: $e');
    }
  }

  static Future<bool> deleteProject(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/projects/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.authToken}',
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting project: $e');
    }
  }

  static String formatProjectStatus(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }

  static String formatProjectPriority(ProjectPriority priority) {
    switch (priority) {
      case ProjectPriority.low:
        return 'Low';
      case ProjectPriority.medium:
        return 'Medium';
      case ProjectPriority.high:
        return 'High';
      case ProjectPriority.critical:
        return 'Critical';
    }
  }

  static String formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatFullDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  static bool isProjectOverdue(Project project) {
    if (project.endDate == null) return false;
    return DateTime.now().isAfter(project.endDate!) && project.status != ProjectStatus.completed;
  }

  static int getDaysUntilEnd(Project project) {
    if (project.endDate == null) return -1;
    return project.endDate!.difference(DateTime.now()).inDays;
  }

  static double calculateProgress(Project project) {
    // This is a placeholder for progress calculation
    // In a real implementation, this would be based on deliverables, tasks, etc.
    if (project.status == ProjectStatus.completed) return 100.0;
    if (project.status == ProjectStatus.cancelled) return 0.0;
    
    // Simple progress based on status
    switch (project.status) {
      case ProjectStatus.planning:
        return 10.0;
      case ProjectStatus.active:
        return 50.0;
      case ProjectStatus.onHold:
        return 25.0;
      case ProjectStatus.completed:
        return 100.0;
      case ProjectStatus.cancelled:
        return 0.0;
    }
  }
}
