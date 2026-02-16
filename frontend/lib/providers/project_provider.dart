import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/project_service.dart';
import '../models/project.dart';

// Provider for all projects
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  return ProjectService.getAllProjects();
});

// Provider for a single project
final projectDetailProvider = FutureProvider.family<Project, String>((ref, projectId) async {
  final projects = await ProjectService.getAllProjects();
  final project = projects.firstWhere((p) => p.id == projectId);
  return project;
});

// Provider to force refresh projects
final projectsRefreshProvider = Provider<void>((ref) {
  // This provider can be watched and invalidated to trigger refresh
});
