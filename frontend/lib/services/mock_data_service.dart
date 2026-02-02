import 'dart:math';
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/sprint.dart';
import '../models/deliverable.dart';

class MockDataService {
  static final Random _random = Random();

  static List<Project> getMockProjects() {
    return [
      Project(
        id: '1',
        name: 'Mobile App Development',
        key: 'MOB',
        description: 'Development of a cross-platform mobile application',
        clientName: 'Tech Corp',
        repositoryUrl: 'https://github.com/example/mobile-app',
        documentationUrl: 'https://docs.example.com/mobile-app',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 60)),
        status: 'in_progress',
        createdBy: 'system',
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Project(
        id: '2',
        name: 'Web Platform Redesign',
        key: 'WEB',
        description: 'Complete redesign of the web platform',
        clientName: 'Design Agency',
        repositoryUrl: 'https://github.com/example/web-platform',
        documentationUrl: 'https://docs.example.com/web-platform',
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 45)),
        status: 'in_progress',
        createdBy: 'system',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Project(
        id: '3',
        name: 'API Integration Project',
        key: 'API',
        description: 'Integration with third-party APIs and services',
        clientName: 'StartupXYZ',
        repositoryUrl: 'https://github.com/example/api-integration',
        documentationUrl: 'https://docs.example.com/api-integration',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().subtract(const Duration(days: 10)),
        status: 'completed',
        createdBy: 'system',
        createdAt: DateTime.now().subtract(const Duration(days: 65)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  static List<Sprint> getMockSprints() {
    final now = DateTime.now();
    return [
      Sprint(
        id: '1',
        name: 'Sprint 1 - Foundation',
        startDate: now.subtract(const Duration(days: 21)),
        endDate: now.subtract(const Duration(days: 7)),
        committedPoints: 40,
        completedPoints: 35,
        velocity: 35,
        testPassRate: 85.0,
        defectCount: 3,
        isActive: false,
      ),
      Sprint(
        id: '2',
        name: 'Sprint 2 - Core Features',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 14)),
        committedPoints: 45,
        completedPoints: 20,
        velocity: 40,
        testPassRate: 90.0,
        defectCount: 2,
        isActive: true,
      ),
      Sprint(
        id: '3',
        name: 'Sprint 3 - Advanced Features',
        startDate: now.add(const Duration(days: 14)),
        endDate: now.add(const Duration(days: 28)),
        committedPoints: 50,
        completedPoints: 0,
        velocity: 42,
        testPassRate: 0.0,
        defectCount: 0,
        isActive: false,
      ),
    ];
  }

  static List<Deliverable> getMockDeliverables() {
    final now = DateTime.now();
    return [
      Deliverable(
        id: '1',
        title: 'User Authentication Module',
        description: 'Complete user authentication and authorization system',
        status: DeliverableStatus.approved,
        createdAt: now.subtract(const Duration(days: 20)),
        dueDate: now.subtract(const Duration(days: 5)),
        sprintIds: ['1'],
        definitionOfDone: [
          'Unit tests written with >90% coverage',
          'Integration tests passing',
          'Security review completed',
          'Documentation updated',
        ],
        evidenceLinks: ['https://example.com/auth-tests'],
        approvedAt: now.subtract(const Duration(days: 3)),
        approvedBy: 'client@example.com',
        submittedBy: 'developer@example.com',
        submittedAt: now.subtract(const Duration(days: 4)),
      ),
      Deliverable(
        id: '2',
        title: 'Dashboard UI',
        description: 'Responsive dashboard with real-time data visualization',
        status: DeliverableStatus.submitted,
        createdAt: now.subtract(const Duration(days: 10)),
        dueDate: now.add(const Duration(days: 5)),
        sprintIds: ['2'],
        definitionOfDone: [
          'UI design implemented',
          'Mobile responsive',
          'Performance optimized',
          'Accessibility compliant',
        ],
        evidenceLinks: ['https://example.com/dashboard-demo'],
        submittedBy: 'frontend@example.com',
        submittedAt: now.subtract(const Duration(days: 1)),
      ),
      Deliverable(
        id: '3',
        title: 'API Documentation',
        description: 'Comprehensive API documentation with examples',
        status: DeliverableStatus.draft,
        createdAt: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 10)),
        sprintIds: ['2'],
        definitionOfDone: [
          'All endpoints documented',
          'Request/response examples',
          'Error handling guide',
          'Authentication guide',
        ],
        evidenceLinks: [],
      ),
    ];
  }

  static List<Map<String, dynamic>> getMockDashboardStats() {
    return [
      {
        'title': 'Total Projects',
        'value': '12',
        'change': '+2',
        'changeType': 'increase',
        'icon': 'business',
        'color': Colors.blue,
      },
      {
        'title': 'Active Sprints',
        'value': '5',
        'change': '+1',
        'changeType': 'increase',
        'icon': 'speed',
        'color': Colors.green,
      },
      {
        'title': 'Pending Approvals',
        'value': '3',
        'change': '-1',
        'changeType': 'decrease',
        'icon': 'pending_actions',
        'color': Colors.orange,
      },
      {
        'title': 'Team Velocity',
        'value': '42',
        'change': '+5',
        'changeType': 'increase',
        'icon': 'trending_up',
        'color': Colors.purple,
      },
    ];
  }

  static List<Map<String, dynamic>> getMockRecentActivities() {
    final now = DateTime.now();
    return [
      {
        'id': '1',
        'type': 'sprint_completed',
        'title': 'Sprint 1 completed',
        'description': 'Foundation sprint completed with 87.5% completion rate',
        'timestamp': now.subtract(const Duration(hours: 2)),
        'user': 'John Doe',
        'avatar': 'https://ui-avatars.com/api/?name=John+Doe&background=random',
      },
      {
        'id': '2',
        'type': 'deliverable_submitted',
        'title': 'Dashboard UI submitted',
        'description': 'New dashboard UI submitted for client review',
        'timestamp': now.subtract(const Duration(hours: 5)),
        'user': 'Jane Smith',
        'avatar': 'https://ui-avatars.com/api/?name=Jane+Smith&background=random',
      },
      {
        'id': '3',
        'type': 'project_created',
        'title': 'New project created',
        'description': 'Mobile App Development project initialized',
        'timestamp': now.subtract(const Duration(days: 1)),
        'user': 'Mike Johnson',
        'avatar': 'https://ui-avatars.com/api/?name=Mike+Johnson&background=random',
      },
    ];
  }

  static int generateRandomId() {
    return _random.nextInt(10000);
  }

  static String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
    ),);
  }
}
