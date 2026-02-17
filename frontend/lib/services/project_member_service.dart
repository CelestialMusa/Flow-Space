import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/project_role.dart';
import '../utils/project_permission_manager.dart';
import 'api_service.dart';

class ProjectMemberService {
  static Future<List<ProjectMember>> getProjectMembers(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/members'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> membersData = data['data'];
          return membersData.map((member) => ProjectMember.fromJson(member)).toList();
        }
      }
      throw Exception('Failed to load project members');
    } catch (e) {
      throw Exception('Error fetching project members: $e');
    }
  }

  static Future<ProjectMember> addProjectMember(String projectId, String userEmail, ProjectRole role) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/members'),
        headers: _getHeaders(),
        body: json.encode({
          'userEmail': userEmail,
          'role': role.name,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ProjectMember.fromJson(data['data']);
        }
      }
      
      if (response.statusCode == 403) {
        throw Exception('Only project owners can add members');
      } else if (response.statusCode == 404) {
        throw Exception('User not found or inactive');
      } else if (response.statusCode == 409) {
        throw Exception('User is already a member of this project');
      }
      
      throw Exception('Failed to add project member');
    } catch (e) {
      throw Exception('Error adding project member: $e');
    }
  }

  static Future<ProjectMember> updateMemberRole(String projectId, String memberId, ProjectRole newRole) async {
    try {
      final response = await http.put(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/members/$memberId'),
        headers: _getHeaders(),
        body: json.encode({
          'role': newRole.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ProjectMember.fromJson({
            'id': data['data']['id'],
            'user_id': data['data']['user_id'],
            'project_id': projectId,
            'role': data['data']['new_role'],
            'user_name': data['data']['user_name'],
            'user_email': data['data']['user_email'],
            'joined_at': DateTime.now().toIso8601String(),
          });
        }
      }
      
      if (response.statusCode == 403) {
        throw Exception('Only project owners can change member roles');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to update role');
      }
      
      throw Exception('Failed to update member role');
    } catch (e) {
      throw Exception('Error updating member role: $e');
    }
  }

  static Future<void> removeProjectMember(String projectId, String memberId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/members/$memberId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        }
      }
      
      if (response.statusCode == 403) {
        throw Exception('Only project owners can remove members');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to remove member');
      }
      
      throw Exception('Failed to remove project member');
    } catch (e) {
      throw Exception('Error removing project member: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserRoleInProject(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/projects/$projectId/user-role'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      
      throw Exception('Failed to fetch user role');
    } catch (e) {
      throw Exception('Error fetching user role: $e');
    }
  }

  static bool hasPermission(ProjectRole userRole, String permission) {
    return ProjectPermissionManager.hasPermission(userRole, permission);
  }

  static Map<String, String> _getHeaders() {
    final token = ApiService.accessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
