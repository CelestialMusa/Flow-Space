import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class ProjectDeliverableService {
  static Future<List<Map<String, dynamic>>> getProjectDeliverables(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/deliverables'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> deliverablesData = data['data'];
          return deliverablesData.cast<Map<String, dynamic>>();
        }
      }
      throw Exception('Failed to load project deliverables');
    } catch (e) {
      throw Exception('Error fetching project deliverables: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableDeliverables(
    String projectId, {
    String? search,
  }
  ) async {
    try {
      String url = '${Environment.apiBaseUrl}/projects/$projectId/available-deliverables';
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
          final List<dynamic> deliverablesData = data['data'];
          return deliverablesData.cast<Map<String, dynamic>>();
        }
      }
      throw Exception('Failed to load available deliverables');
    } catch (e) {
      throw Exception('Error fetching available deliverables: $e');
    }
  }

  static Future<Map<String, dynamic>> linkDeliverablesToProject(
    String projectId,
    List<String> deliverableIds,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/deliverables'),
        headers: _getHeaders(),
        body: json.encode({
          'deliverableIds': deliverableIds,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      
      if (response.statusCode == 403) {
        throw Exception('Only project owners and contributors can link deliverables');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid request');
      }
      
      throw Exception('Failed to link deliverables to project');
    } catch (e) {
      throw Exception('Error linking deliverables: $e');
    }
  }

  static Future<void> unlinkDeliverableFromProject(
    String projectId,
    String deliverableId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/deliverables/$deliverableId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        }
      }
      
      if (response.statusCode == 403) {
        throw Exception('Only project owners and contributors can unlink deliverables');
      } else if (response.statusCode == 404) {
        throw Exception('Deliverable not found in this project');
      }
      
      throw Exception('Failed to unlink deliverable from project');
    } catch (e) {
      throw Exception('Error unlinking deliverable: $e');
    }
  }

  static Map<String, String> _getHeaders() {
    // This should get the auth token from your storage
    // For now, returning basic headers
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Add Authorization header when you have token management
      // 'Authorization': 'Bearer $token',
    };
  }

  // Helper method to format deliverable status
  static String formatDeliverableStatus(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'in_progress':
      case 'in progress':
        return 'In Progress';
      case 'completed':
      case 'done':
        return 'Completed';
      case 'pending':
      case 'to do':
      case 'todo':
        return 'Pending';
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
      case 'in_progress':
      case 'in progress':
        return '#2196F3'; // Blue
      case 'completed':
      case 'done':
        return '#4CAF50'; // Green
      case 'pending':
      case 'to do':
      case 'todo':
        return '#9C27B0'; // Purple
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

  // Helper method to get priority color
  static String getPriorityColor(String? priority) {
    if (priority == null || priority.isEmpty) return '#9E9E9E'; // Grey
    
    switch (priority.toLowerCase()) {
      case 'high':
        return '#F44336'; // Red
      case 'medium':
        return '#FF9800'; // Orange
      case 'low':
        return '#4CAF50'; // Green
      default:
        return '#9E9E9E'; // Grey
    }
  }
}
