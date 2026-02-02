import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../services/backend_api_service.dart';
import '../services/api_service.dart';
import '../services/sign_off_report_service.dart';
import '../services/notification_service.dart';
import '../models/notification_item.dart';
import '../models/deliverable.dart';
import '../widgets/sprint_performance_chart.dart';
import '../services/approval_service.dart';
import '../services/dashboard_service.dart';
import '../models/approval_request.dart';
import '../theme/flownet_theme.dart';
import '../widgets/background_image.dart';
import '../widgets/sprint_performance_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'deliverables_metrics/deliverables_metrics_screen.dart';
import '../services/mock_data_service.dart';

class RoleDashboardScreen extends ConsumerStatefulWidget {
  const RoleDashboardScreen({super.key});

  @override
  ConsumerState<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends ConsumerState<RoleDashboardScreen> {
  User? _currentUser;
  final AuthService _authService = AuthService();
  late RealtimeService realtimeService;
  final SignOffReportService _reportService = SignOffReportService(AuthService());
  bool _isLoadingDashboardDeliverables = false;
  bool _isLoadingDashboardSprints = false;
  List<Map<String, dynamic>> _dashboardDeliverables = [];
  List<Map<String, dynamic>> _dashboardSprints = [];
  List<Map<String, dynamic>> _dashboardProjects = [];
  bool _isLoadingDashboardProjects = false;
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _filteredAuditLogs = [];
  final BackendApiService _backendService = BackendApiService();
  List<Map<String, dynamic>> _pendingReports = [];
  bool _isLoadingPendingReports = false;
  String? _pendingReportsError;
  Map<String, dynamic> _teamMetrics = {};
  bool _isLoadingTeamMetrics = false;
  
  // Missing variables
  String _selectedChartType = 'velocity';
  bool _isLoadingClientMetrics = false;
  Map<String, dynamic> _clientReviewMetrics = {};

  bool _isLoadingAuditLogs = false;
  String _searchQuery = '';
  String _sortField = 'timestamp';
  bool _sortAscending = false;
  String? _auditLogsError;
  bool _isLoadingMoreAuditLogs = false;
  final bool _hasMoreAuditLogs = true;
  
  // Additional fields for approval functionality
  String? _errorMessage;
  final ApprovalService _approvalService = ApprovalService(AuthService());
  final DashboardService _dashboardService = DashboardService();
  List<ApprovalRequest> _requests = [];
  
  Future<void> _loadData() async {
    // Placeholder implementation
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  void initState() {
    super.initState();
    realtimeService = RealtimeService();
    realtimeService.initialize(authToken: _authService.accessToken);
    _loadCurrentUser();
    _loadDashboardSprints();
    _loadDashboardDeliverables();
    _loadDashboardProjects();
    _loadReviewHistoryReports();
    _loadPendingReports();
    _loadClientReviewMetrics();
    _computeTeamMetrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    realtimeService.off('user_role_changed', _handleRoleChanged);
    realtimeService.offAll('sprint_created');
    realtimeService.offAll('sprint_updated');
    realtimeService.offAll('deliverable_created');
    realtimeService.offAll('deliverable_updated');
    realtimeService.offAll('approval_created');
    realtimeService.offAll('approval_updated');
    realtimeService.offAll('project_created');
    realtimeService.offAll('project_updated');
    // Do not call offAll for notification_received as it affects other widgets
    super.dispose();
  }

  void _handleRoleChanged(dynamic data) {
    _loadCurrentUser();
  }

  void _computeTeamMetrics() {
    if (!mounted) return;
    setState(() => _isLoadingTeamMetrics = true);
    try {
      final int totalDeliverables = _dashboardDeliverables.length;
      int completed = 0;
      int inProgress = 0;
      int overdue = 0;
      for (final d in _dashboardDeliverables) {
        final status = (d['status'] ?? d['state'] ?? '').toString().toLowerCase();
        if (status == 'completed' || status == 'done' || status == 'approved') completed++;
        if (status == 'in_progress' || status == 'in-progress' || status == 'progress') inProgress++;
        final dueStr = (d['due_date'] ?? d['dueDate'] ?? d['deadline'] ?? '').toString();
        final due = DateTime.tryParse(dueStr);
        if (due != null && due.isBefore(DateTime.now()) && status != 'completed' && status != 'done' && status != 'approved') {
          overdue++;
        }
      }
      int activeSprints = 0;
      for (final s in _dashboardSprints) {
        final status = (s['status'] ?? s['state'] ?? '').toString().toLowerCase();
        if (status == 'active' || status == 'in_progress' || status == 'in-progress') activeSprints++;
      }
      final pendingReviews = _pendingReports.length;
      String completionRateStr;
      if (totalDeliverables > 0) {
        final rate = (completed / totalDeliverables * 100).toStringAsFixed(1);
        completionRateStr = '$rate%';
      } else {
        completionRateStr = '-';
      }
      final m = <String, dynamic>{
        'deliverables': totalDeliverables,
        'completed': completed,
        'in_progress': inProgress,
        'overdue': overdue,
        'active_sprints': activeSprints,
        'pending_reviews': pendingReviews,
        'completion_rate': completionRateStr,
      };
      if (mounted) {
        setState(() {
          _teamMetrics = m;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _teamMetrics = {});
    } finally {
      if (mounted) setState(() => _isLoadingTeamMetrics = false);
    }
  }

  Future<void> _loadPendingReports() async {
    if (!mounted) return;
    setState(() => _isLoadingPendingReports = true);
    try {
      final resp = await _reportService.getSignOffReports(status: 'submitted');
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        final List<dynamic> items = raw is Map ? (raw['data'] ?? raw['reports'] ?? raw['items'] ?? []) : (raw is List ? raw : []);
        final list = items.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        setState(() {
          _pendingReports = list;
        });
        
        // Update team metrics with real data
        _updateTeamMetricsFromReports(list);
      } else {
        setState(() {
          _pendingReports = [];
          _pendingReportsError = resp.error ?? 'Failed to load pending reports';
        });
      }
    } catch (e) {
      setState(() {
        _pendingReports = [];
        _pendingReportsError = 'Error loading pending reports: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoadingPendingReports = false);
    }
  }

  Future<void> _loadClientReviewMetrics() async {
    if (!mounted) return;
    setState(() => _isLoadingClientMetrics = true);
    try {
      final resp = await _reportService.getSignOffReports();
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        final List<dynamic> items = raw is Map ? (raw['data'] ?? raw['reports'] ?? raw['items'] ?? []) : (raw is List ? raw : []);
        final list = items.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        
        // Calculate metrics from real data
        _calculateClientMetricsFromReports(list);
      } else {
        setState(() {
          _clientReviewMetrics = {};
          _pendingReportsError = resp.error ?? 'Failed to load client metrics';
        });
      }
    } catch (e) {
      setState(() {
        _clientReviewMetrics = {};
        _pendingReportsError = 'Error loading client metrics: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoadingClientMetrics = false);
    }
  }

  void _setupRealtimeListeners() {
    // Placeholder implementation for setting up realtime listeners
  }

  void _updateTeamMetricsFromReports(List<Map<String, dynamic>> reports) {
    if (!mounted) return;
    
    int draftCount = 0;
    int submittedCount = 0;
    int approvedCount = 0;
    int changeRequestedCount = 0;
    double totalSignoffTime = 0;
    int signoffTimeCount = 0;
    
    for (final report in reports) {
      final status = (report['status'] ?? '').toString().toLowerCase();
      switch (status) {
        case 'draft':
          draftCount++;
          break;
        case 'submitted':
          submittedCount++;
          break;
        case 'approved':
          approvedCount++;
          break;
        case 'change_requested':
        case 'change-requested':
          changeRequestedCount++;
          break;
      }
      
      // Calculate sign-off time
      final createdAt = DateTime.tryParse(report['created_at'] ?? '');
      final updatedAt = DateTime.tryParse(report['updated_at'] ?? '');
      if (createdAt != null && updatedAt != null && createdAt.isBefore(updatedAt)) {
        totalSignoffTime += updatedAt.difference(createdAt).inDays.toDouble();
        signoffTimeCount++;
      }
    }
    
    final averageSignoffTime = signoffTimeCount > 0 ? totalSignoffTime / signoffTimeCount : 0.0;
    
    setState(() {
      _teamMetrics.update('draftSignoffs', (_) => draftCount, ifAbsent: () => draftCount);
      _teamMetrics.update('submittedSignoffs', (_) => submittedCount, ifAbsent: () => submittedCount);
      _teamMetrics.update('approvedSignoffs', (_) => approvedCount, ifAbsent: () => approvedCount);
      _teamMetrics.update('changeRequestedSignoffs', (_) => changeRequestedCount, ifAbsent: () => changeRequestedCount);
      _teamMetrics.update('averageSignoffTime', (_) => averageSignoffTime, ifAbsent: () => averageSignoffTime);
    });
  }

  void _calculateClientMetricsFromReports(List<Map<String, dynamic>> reports) {
    if (!mounted) return;
    
    int onTimeCount = 0;
    int totalCount = 0;
    double satisfactionSum = 0;
    int satisfactionCount = 0;
    
    for (final report in reports) {
      totalCount++;
      
      // Check if delivered on time
      final dueDate = DateTime.tryParse(report['due_date'] ?? '');
      final completedAt = DateTime.tryParse(report['completed_at'] ?? report['updated_at'] ?? '');
      if (dueDate != null && completedAt != null && completedAt.isBefore(dueDate)) {
        onTimeCount++;
      }
      
      // Get satisfaction score if available
      final satisfaction = double.tryParse(report['satisfaction_score'] ?? '') ?? 0.0;
      if (satisfaction > 0) {
        satisfactionSum += satisfaction;
        satisfactionCount++;
      }
    }
    
    final onTimeDelivery = totalCount > 0 ? '${(onTimeCount / totalCount * 100).toStringAsFixed(1)}%' : '0%';
    final clientSatisfaction = satisfactionCount > 0 ? '${(satisfactionSum / satisfactionCount).toStringAsFixed(1)}/5.0' : 'N/A';
    const qualityScore = '92%'; // Placeholder - calculate from actual data
    const reworkRate = '8%'; // Placeholder - calculate from actual data
    
    setState(() {
      _clientReviewMetrics = {
        'onTimeDelivery': onTimeDelivery,
        'clientSatisfaction': clientSatisfaction,
        'qualityScore': qualityScore,
        'reworkRate': reworkRate,
      };
    });
  }


  Future<void> _loadDashboardSprints() async {
    setState(() => _isLoadingDashboardSprints = true);
    try {
      final items = await ApiService.getSprints();
      _dashboardSprints = items;
      _computeTeamMetrics();
    } finally {
      if (mounted) setState(() => _isLoadingDashboardSprints = false);
    }
  }
  
  Future<void> _loadDashboardDeliverables() async {
    if (!mounted) return;
    setState(() => _isLoadingDashboardDeliverables = true);
    try {
      // Try to fetch from API first
      final items = await ApiService.getDeliverables();
      _dashboardDeliverables = items;
    } catch (e) {
      // Fallback to mock data if API fails
      debugPrint('API failed, using mock data: $e');
      _dashboardDeliverables = MockDataService.getRecentDeliverables();
    } finally {
      _computeTeamMetrics();
      if (mounted) setState(() => _isLoadingDashboardDeliverables = false);
    }
  }
  Future<void> _loadDashboardProjects() async {
    setState(() => _isLoadingDashboardProjects = true);
    try {
      final resp = await _backendService.getProjects(page: 1, limit: 100);
      if (resp.isSuccess && resp.data != null) {
        final dynamic raw = resp.data;
        final List<dynamic> items = raw is Map ? (raw['items'] ?? raw['projects'] ?? raw['data'] ?? []) : (raw is List ? raw : []);
        if (mounted) {
          setState(() {
            _dashboardProjects = items.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
          });
        }
      }
      _computeTeamMetrics();
    } finally {
      if (mounted) setState(() => _isLoadingDashboardProjects = false);
    }
  }
  Future<void> _loadReviewHistoryReports() async {
    setState(() {
      _isLoadingAuditLogs = true;
      _auditLogsError = null;
    });
    try {
      final resp = await _backendService.getRealAuditLogs(skip: 0, limit: 50);
      if (resp.isSuccess && resp.data != null) {
        final dynamic raw = resp.data;
        final List<dynamic> items = raw is Map ? (raw['audit_logs'] ?? raw['items'] ?? raw['logs'] ?? raw['data'] ?? []) : (raw is List ? raw : []);
        final list = items.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        setState(() {
          _auditLogs = list;
          _filteredAuditLogs = _auditLogs;
        });
      } else {
        setState(() {
          _auditLogs = [];
          _filteredAuditLogs = _auditLogs;
          _auditLogsError = resp.error ?? 'Failed to load audit logs';
        });
      }
    } catch (e) {
      setState(() {
        _auditLogsError = 'Failed to load audit logs';
        _auditLogs = [];
        _filteredAuditLogs = _auditLogs;
      });
    } finally {
      if (mounted) setState(() => _isLoadingAuditLogs = false);
    }
  }
  

  Future<void> _loadCurrentUser() async {
    try {
      // Initialize AuthService first
      await _authService.initialize();
      
      // Get the current user from AuthService
      final user = await _authService.getCurrentUser();
      if (user != null && (user.isActive || user.isSystemAdmin)) {
        if (!mounted) return;
        setState(() {
          _currentUser = user;
        });
        debugPrint('✅ Loaded user: ${user.name} (${user.email}) - Role: ${user.role}');
        
        // Load audit logs after user is loaded
        _loadAuditLogs();
        
        // Initialize realtime service with valid token
        if (_authService.accessToken != null) {
          realtimeService.initialize(authToken: _authService.accessToken);
          _setupRealtimeListeners();
        }
      } else {
        if (!_authService.isAuthenticated) {
          debugPrint('❌ Inactive or no user found, redirecting to login');
          if (mounted) {
            final messenger = ScaffoldMessenger.of(context);
            final router = GoRouter.of(context);
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Your account is inactive. Please contact support.'),
                backgroundColor: Colors.red,
              ),
            );
            router.go('/');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading current user: $e');
      // If there's an error, redirect to login
      if (mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _loadAuditLogs({bool loadMore = false}) async {
    if (_isLoadingAuditLogs && !loadMore) return;
    if (_isLoadingMoreAuditLogs && loadMore) return;
    if (!loadMore && !_hasMoreAuditLogs) return;
    
    setState(() {
      _errorMessage = null;
    });

    try {
      final approvalsResponse = await _approvalService.getApprovalRequests();
      final dashboardResponse = await _dashboardService.getDashboardData();

      if (approvalsResponse.isSuccess && approvalsResponse.data != null) {
        setState(() {
          _requests =
              (approvalsResponse.data!['requests'] as List<dynamic>).cast<ApprovalRequest>();
        });
      } else {
        setState(() {
          _errorMessage =
              approvalsResponse.error ?? 'Failed to load approval data for dashboard';
        });
      }

      if (dashboardResponse.isSuccess && dashboardResponse.data != null) {
        // Dashboard data loaded successfully
      } else {
        setState(() {
          _errorMessage = _errorMessage ??
              (dashboardResponse.error ?? 'Failed to load dashboard stats');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading dashboard data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
_isLoadingAuditLogs = false;
          _isLoadingMoreAuditLogs = false;
        });
      }
    }
  }


  void _applySearchAndSort() {
    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(_auditLogs);
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((Map<String, dynamic> log) {
        final action = (log['action'] as String? ?? '').toLowerCase();
        final userEmail = (log['user_email'] as String? ?? '').toLowerCase();
        final entityName = (log['entity_name'] as String? ?? '').toLowerCase();
        final entityType = (log['entity_type'] as String? ?? '').toLowerCase();
        final userRole = (log['user_role'] as String? ?? '').toLowerCase();
        return action.contains(query) ||
               userEmail.contains(query) ||
               entityName.contains(query) ||
               entityType.contains(query) ||
               userRole.contains(query);
      }).toList();
    }
    
    // Apply sorting
    filtered.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final dynamic aValue = a[_sortField];
      final dynamic bValue = b[_sortField];
      
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return _sortAscending ? -1 : 1;
      if (bValue == null) return _sortAscending ? 1 : -1;
      
      if (aValue is String && bValue is String) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      
      if (aValue is DateTime && bValue is DateTime) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      
      if (aValue is String && bValue is DateTime) {
        try {
          final aDate = DateTime.parse(aValue);
          return _sortAscending ? aDate.compareTo(bValue) : bValue.compareTo(aDate);
        } catch (e) {
          return _sortAscending ? -1 : 1;
        }
      }
      
      if (aValue is DateTime && bValue is String) {
        try {
          final bDate = DateTime.parse(bValue);
          return _sortAscending ? aValue.compareTo(bDate) : bDate.compareTo(aValue);
        } catch (e) {
          return _sortAscending ? 1 : -1;
        }
      }
      
      return 0;
    });
    
    setState(() {
      _filteredAuditLogs = filtered;
    });
  }


  String? _getOwnerName(Map<String, dynamic> data) {
    if (data['ownerName'] != null) return data['ownerName'].toString();
    if (data['owner_name'] != null) return data['owner_name'].toString();
    
    if (data['owner'] != null && data['owner'] is Map) {
      final owner = data['owner'];
      final first = owner['first_name'] ?? owner['firstName'] ?? '';
      final last = owner['last_name'] ?? owner['lastName'] ?? '';
      if (first.toString().isNotEmpty || last.toString().isNotEmpty) {
        return '$first $last'.trim();
      }
      return owner['email']?.toString();
    }
    return null;
  }

  String? _getOwnerId(Map<String, dynamic> data) {
    return data['ownerId']?.toString() ?? 
           data['owner_id']?.toString() ?? 
           (data['owner'] != null && data['owner'] is Map ? data['owner']['id']?.toString() : null);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final rawName = currentUser?.name ?? '';
    final firstName = rawName.contains(' ')
        ? rawName.split(' ').first
        : rawName;

    final recentRequests = _requests.take(5).toList();

    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          currentUser != null
              ? '${currentUser.roleDisplayName} dashboard'
              : 'Dashboard',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BackgroundImage(
        withGlassEffect: false,
        overlayOpacity: 0.5,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentUser != null) ...[
                    _buildWelcomeSection(firstName, currentUser.roleDescription),
                    const SizedBox(height: 24),
                  ],
                  _buildMetricsCards(
                    _teamMetrics['totalRequests'] ?? 0,
                    _teamMetrics['pendingApproval'] ?? 0,
                    _teamMetrics['approved'] ?? 0,
                    _teamMetrics['rejected'] ?? 0,
                  ),
                  const SizedBox(height: 24),
                  _buildPerformanceSection(),
                  const SizedBox(height: 24),
                  _buildSignoffReportsSection(),
                  const SizedBox(height: 24),
                  _buildDeliverablesTable(recentRequests),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String firstName, String roleDescription) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FlownetColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FlownetColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: FlownetColors.surfaceHighlight,
                child: Icon(Icons.person, color: FlownetColors.textSecondary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $firstName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: FlownetColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        color: FlownetColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards(int total, int pending, int approved, int rejected) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FlownetColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FlownetColors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: FlownetColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  total.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: FlownetColors.pureWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FlownetColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 14,
                    color: FlownetColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pending.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FlownetColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Approved',
                  style: TextStyle(
                    fontSize: 14,
                    color: FlownetColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  approved.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FlownetColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rejected',
                  style: TextStyle(
                    fontSize: 14,
                    color: FlownetColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rejected.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignoffReportsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FlownetColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FlownetColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign-off Reports by Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: FlownetColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSignoffReportCard('Draft', _teamMetrics['draftSignoffs'] ?? 0, Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSignoffReportCard('Submitted', _teamMetrics['submittedSignoffs'] ?? 0, Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSignoffReportCard('Approved', _teamMetrics['approvedSignoffs'] ?? 0, Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSignoffReportCard('Change Requested', _teamMetrics['changeRequestedSignoffs'] ?? 0, Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Average Sign-off Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: FlownetColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FlownetColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FlownetColors.surfaceHighlight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: FlownetColors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  '${(_teamMetrics['averageSignoffTime'] ?? 0.0).toStringAsFixed(1)} days',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: FlownetColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignoffReportCard(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FlownetColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FlownetColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: FlownetColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: SprintPerformanceChart(sprints: _dashboardSprints.map((sprint) {
              return {
                'id': sprint['id'] ?? '',
                'name': sprint['name'] ?? 'Sprint',
                'start_date': sprint['start_date'] ?? DateTime.now().toIso8601String(),
                'end_date': sprint['end_date'] ?? DateTime.now().toIso8601String(),
                'planned_points': sprint['planned_points'] ?? 0,
                'completed_points': sprint['completed_points'] ?? 0,
                'status': sprint['status'] ?? 'active',
              };
            }).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverablesTable(List<ApprovalRequest> requests) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FlownetColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FlownetColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Approval Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: FlownetColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          if (requests.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: FlownetColors.textSecondary),
                    SizedBox(height: 16),
                    Text(
                      'No approval requests found',
                      style: TextStyle(
                        fontSize: 16,
                        color: FlownetColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: FlownetColors.surfaceHighlight)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Title', style: TextStyle(fontWeight: FontWeight.w600, color: FlownetColors.textPrimary)),
                      )),
                      Expanded(flex: 2, child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: FlownetColors.textPrimary)),
                      )),
                      Expanded(flex: 2, child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, color: FlownetColors.textPrimary)),
                      )),
                      Expanded(flex: 2, child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, color: FlownetColors.textPrimary)),
                      )),
                    ],
                  ),
                ),
                ...requests.map((request) => Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: FlownetColors.surfaceHighlight)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          request.title,
                          style: const TextStyle(fontSize: 14, color: FlownetColors.textPrimary),
                        ),
                      )),
                      Expanded(flex: 2, child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.status,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(request.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )),
                      Expanded(flex: 2, child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          request.priority,
                          style: const TextStyle(fontSize: 14, color: FlownetColors.textPrimary),
                        ),
                      )),
                      Expanded(flex: 2, child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _formatDate(request.requestedAt),
                          style: const TextStyle(fontSize: 14, color: FlownetColors.textPrimary),
                        ),
                      )),
                    ],
                  ),
                )),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildQuickLinkChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
        backgroundColor: FlownetColors.surfaceLight,
                side: const BorderSide(color: FlownetColors.surfaceHighlight),
      ),
    );
  }

  Widget _buildTeamMemberDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildWelcomeCard(),
          const SizedBox(height: 24),
          buildQuickActions(),
          const SizedBox(height: 24),
<<<<<<< HEAD
          _buildKanbanLinkCard(),
          const SizedBox(height: 24),
          _buildMyDeliverables(),
          const SizedBox(height: 24),
          _buildReviewMetrics(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
=======
          buildMyDeliverables(),
          const SizedBox(height: 24),
          buildRecentActivity(),
>>>>>>> origin/Busisiwe
        ],
      ),
    );
  }

Widget buildDeliveryLeadDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildWelcomeCard(),
          const SizedBox(height: 24),
          buildReminderQuickActions(),
          const SizedBox(height: 24),
          buildTeamMetrics(),
          const SizedBox(height: 24),
<<<<<<< HEAD
          _buildReviewMetrics(),
          const SizedBox(height: 24),
          _buildSprintOverview(),
          const SizedBox(height: 24),
          _buildKanbanLinkCard(),
          const SizedBox(height: 24),
          _buildDeliverablesOverview(),
=======
          buildSprintOverview(),
          const SizedBox(height: 24),
          buildDeliverablesOverview(),
>>>>>>> origin/Busisiwe
          const SizedBox(height: 24),
          buildProjectsOverview(),
          const SizedBox(height: 24),
          buildPendingReviews(),
          const SizedBox(height: 24),
          buildTeamPerformance(),
        ],
      ),
    );
  }

  Widget buildClientReviewerDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildWelcomeCard(),
          const SizedBox(height: 24),
          buildReviewMetrics(),
          const SizedBox(height: 24),
          buildPendingApprovals(),
          const SizedBox(height: 24),
          buildRecentSubmissions(),
          const SizedBox(height: 24),
          buildReviewHistory(),
        ],
      ),
    );
  }

  Widget buildSystemAdminDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildWelcomeCard(),
          const SizedBox(height: 24),
          buildAdminFeatures(),
          const SizedBox(height: 24),
          buildReminderQuickActions(),
        ],
      ),
    );
  }


  Widget buildReminderQuickActions() {
    final canShow = _currentUser != null && (_currentUser!.isDeliveryLead || _currentUser!.isSystemAdmin);
    if (!canShow) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< HEAD
            _buildCardHeader(Icons.notifications_active, 'Quick Actions', route: '/approval-requests'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildActionButton(
                  icon: Icons.assignment,
                  label: 'Send Reminder',
                  onTap: () => context.push('/send-reminder'),
                ),
                _buildActionButton(
                  icon: Icons.trending_up,
                  label: 'Trigger Escalation',
                  onTap: _triggerEscalation,
                ),
                _buildActionButton(
                  icon: Icons.analytics_outlined,
                  label: 'Deliverables Overview',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeliverablesMetricsScreen()),
=======
buildCardHeader(Icons.notifications_active, 'Approval Reminders', route: '/approval-requests'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
Expanded(
                  child: buildActionButton(
                    icon: Icons.assignment,
                    label: 'Send Reminder For Report',
                    onTap: () => context.push('/send-reminder'),
>>>>>>> origin/Busisiwe
                  ),
                ),
                _buildQuickLinkChip(
                  icon: Icons.folder_outlined,
                  label: 'Repository',
                  onTap: () => context.go('/repository'),
                ),
                _buildQuickLinkChip(
                  icon: Icons.timer_outlined,
                  label: 'Sprint console',
                  onTap: () => context.go('/sprint-console'),
                ),
                _buildQuickLinkChip(
                  icon: Icons.assessment_outlined,
                  label: 'Reports',
                  onTap: () => context.go('/report-repository'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  Future<void> _triggerEscalation() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Trigger Escalation'),
          content: const Text('This will check for stalled approvals and send escalation notifications. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Trigger'),
            ),
          ],
        ),
      );

      if (result != true) return;

      final resp = await _backendService.triggerEscalation(force: true);
      if (resp.isSuccess) {
        messenger.showSnackBar(const SnackBar(content: Text('Escalation process triggered successfully')));
      } else {
        messenger.showSnackBar(SnackBar(content: Text('Failed to trigger escalation: ${resp.error}')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildRoleSpecificFAB() {
=======
Widget buildRoleSpecificFAB() {
>>>>>>> origin/Busisiwe
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: const Text('Create Deliverable'),
                  onTap: () {
                    context.go('/deliverable-setup');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Open Sprint Console'),
                  onTap: () {
                    context.go('/sprint-console');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Role Management'),
                  onTap: () {
                    context.go('/role-management');
                  },
                ),
              ],
            ),
          ),
        );
      },
      backgroundColor: _currentUser?.roleColor ?? Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget buildWelcomeCard() {
    return Card(
      child: ListTile(
        leading: FutureBuilder<Uint8List?>(
          future: loadAvatarBytes(_currentUser!.id),
          builder: (context, snapshot) {
            final hasImage = snapshot.hasData && (snapshot.data?.isNotEmpty ?? false);
            return CircleAvatar(
              backgroundImage: hasImage ? MemoryImage(snapshot.data!) : null,
              child: hasImage ? null : Icon(_currentUser?.roleIcon ?? Icons.person),
            );
          },
        ),
        title: Text('Welcome, ${_currentUser?.name ?? 'User'}'),
        subtitle: Text('${_currentUser?.roleDisplayName ?? 'Member'} Dashboard'),
      ),
    );
  }

Future<Uint8List?> loadAvatarBytes(String userId) async {
    try {
      final base = Uri.parse(ApiService.baseUrl);
      final url = '${base.scheme}://${base.host}:${base.port.toString()}/api/v1/profile/$userId/picture?t=${DateTime.now().millisecondsSinceEpoch}';
      final headers = await ApiService.getAuthHeaders();
      final resp = await http.get(Uri.parse(url), headers: headers);
      
      if (resp.statusCode == 200) {
        final bodyBytes = resp.bodyBytes;
        
        // Check if response is actually image data (not JSON)
        if (bodyBytes.isNotEmpty) {
          // Check file header to detect if it's an image
          final header = bodyBytes.take(4).toList();
          // Common image file signatures: PNG (0x89 0x50 0x4E 0x47), JPEG (0xFF 0xD8 0xFF 0xE0)
          final isImage = (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) ||
                          (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF && header[3] == 0xE0);
          
          if (isImage) {
            return bodyBytes;
          } else {
            // Response is likely JSON, not an image
            debugPrint('⚠️ Avatar endpoint returned non-image data for user $userId');
            return null;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Widget buildQuickActions() {
    final canCreate = _authService.canCreateDeliverable();
<<<<<<< HEAD

    // Helper for cards
    Widget buildCard(IconData icon, String label, VoidCallback onTap) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildActionButton(
            icon: icon,
            label: label,
            onTap: onTap,
          ),
        ),
      );
    }

    final actions = [
      buildCard(
        Icons.assignment_outlined,
        'Create Deliverable',
        () => context.go('/deliverable-setup'),
      ),
      buildCard(
        Icons.flag_outlined,
        'Open Sprint Console',
        () => context.go('/sprint-console'),
      ),
      if (canCreate)
        buildCard(
          Icons.description_outlined,
          'Build Report',
          () {
            final first = _dashboardDeliverables.isNotEmpty ? _dashboardDeliverables.first : null;
            final id = first != null ? (first['id']?.toString() ?? first['uuid']?.toString() ?? '') : '';
            if (id.isNotEmpty) context.go('/report-builder/$id');
          },
        ),
      buildCard(
        Icons.analytics_outlined,
        'Deliverables Overview',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DeliverablesMetricsScreen()),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.map((w) => SizedBox(width: width, child: w)).toList(),
        );
      },
=======
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: buildActionButton(
                icon: Icons.assignment_outlined,
                label: 'Create Deliverable',
                onTap: () => context.go('/deliverable-setup'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: buildActionButton(
                icon: Icons.flag_outlined,
                label: 'Open Sprint Console',
                onTap: () => context.go('/sprint-console'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (canCreate)
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: buildActionButton(
                  icon: Icons.description_outlined,
                  label: 'Build Report',
                  onTap: () {
                    final first = _dashboardDeliverables.isNotEmpty ? _dashboardDeliverables.first : null;
                    final id = first != null ? (first['id']?.toString() ?? first['uuid']?.toString() ?? '') : '';
                    if (id.isNotEmpty) context.go('/report-builder/$id');
                  },
                ),
              ),
            ),
          ),
      ],
>>>>>>> origin/Busisiwe
    );
  }

  Widget buildMyDeliverables() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingDashboardDeliverables
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCardHeader(Icons.assignment_outlined, 'My Deliverables', route: '/repository'),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final uid = _currentUser?.id.toString() ?? '';
                    final my = _dashboardDeliverables.where((d) {
                      final assigned = (d['assigned_to'] ?? d['assignedTo'] ?? '').toString();
                      final created = (d['created_by'] ?? d['createdBy'] ?? '').toString();
                      return assigned == uid || created == uid;
                    }).toList();
                    if (my.isEmpty) {
                      return const Text('No deliverables yet');
                    }
                    return Column(
                      children: my.take(5).map((d) {
                        final title = d['title'] ?? d['name'] ?? d['deliverableName'] ?? 'Untitled Deliverable';
                        final status = (d['status'] ?? d['reviewStatus'] ?? '').toString();
                        final id = (d['id']?.toString() ?? d['uuid']?.toString() ?? '');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.assignment_turned_in, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(status.isNotEmpty ? '$title • $status' : title)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
<<<<<<< HEAD
                                  _priorityChip((d['priority'] ?? '').toString()),
                                  _dueDateChip(d['due_date'] ?? d['dueDate'] ?? d['deadline']),
                                  _ownerChip(_getOwnerName(d), _getOwnerId(d)),
=======
                                  priorityChip((d['priority'] ?? '').toString()),
                                  dueDateChip(d['due_date'] ?? d['dueDate'] ?? d['deadline']),
>>>>>>> origin/Busisiwe
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: id.isEmpty ? null : () => updateDeliverableStatus(id, 'in_progress'),
                                    icon: const Icon(Icons.play_circle_outline, size: 18),
                                    label: const Text('Start'),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton.icon(
                                    onPressed: id.isEmpty ? null : () => updateDeliverableStatus(id, 'completed'),
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text('Complete'),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton.icon(
                                    onPressed: id.isEmpty ? null : () => context.go('/report-builder/$id'),
                                    icon: const Icon(Icons.description_outlined, size: 18),
                                    label: const Text('Report'),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton.icon(
                                    onPressed: id.isEmpty ? null : () => editDeliverable(d),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: const Text('Edit'),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                onPressed: () {
                                  if (id.isNotEmpty) {
                                    try {
                                      final deliverable = Deliverable.fromJson(d);
                                      context.push('/deliverable-detail', extra: deliverable);
                                    } catch (e) {
                                      debugPrint('Error parsing deliverable for navigation: $e');
                                      context.go('/repository');
                                    }
                                  } else {
                                    context.go('/repository');
                                  }
                                },
                                icon: const Icon(Icons.open_in_new),
                                tooltip: 'Open',
                              ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget buildDeliverablesOverview() {
    // Filter out completed deliverables for the overview
    final overviewDeliverables = _dashboardDeliverables.where((d) {
      final status = (d['status'] ?? d['reviewStatus'] ?? '').toString().toLowerCase();
      return status != 'completed';
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingDashboardDeliverables
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCardHeader(Icons.assignment_outlined, 'Deliverables Overview (${overviewDeliverables.length})', route: '/deliverables'),
                  const SizedBox(height: 8),
                  if (overviewDeliverables.isEmpty)
                    const Text('No active deliverables'),
                  ...overviewDeliverables.take(6).map((d) {
                    final title = d['title'] ?? d['name'] ?? d['deliverableName'] ?? 'Untitled Deliverable';
                    final status = (d['status'] ?? d['reviewStatus'] ?? '').toString();
                    final id = (d['id']?.toString() ?? d['uuid']?.toString() ?? '');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
<<<<<<< HEAD
                      child: InkWell(
                        onTap: () {
                          if (id.isNotEmpty) {
                            try {
                              final deliverable = Deliverable.fromJson(d);
                              context.push('/deliverable-detail', extra: deliverable);
                            } catch (e) {
                              debugPrint('Error parsing deliverable for navigation: $e');
                            }
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.assignment_outlined, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(status.isNotEmpty ? '$title • $status' : title)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _priorityChip((d['priority'] ?? '').toString()),
                                  _dueDateChip(d['due_date'] ?? d['dueDate'] ?? d['deadline']),
                                  _ownerChip(_getOwnerName(d), _getOwnerId(d)),
                                ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: id.isEmpty ? null : () => _editDeliverable(d),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: id.isEmpty ? null : () => _updateDeliverableStatus(id, 'completed'),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('Complete'),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    if (id.isNotEmpty) {
                                      try {
                                        final deliverable = Deliverable.fromJson(d);
                                        context.push('/deliverable-detail', extra: deliverable);
                                      } catch (e) {
                                        debugPrint('Error parsing deliverable for navigation: $e');
                                        context.go('/deliverables');
                                      }
                                    } else {
                                      context.go('/deliverables');
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new),
                                  tooltip: 'Open',
                                ),
                              ],
                            ),
                          ],
                        ),
=======
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(status.isNotEmpty ? '$title • $status' : title)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              priorityChip((d['priority'] ?? '').toString()),
                              dueDateChip(d['due_date'] ?? d['dueDate'] ?? d['deadline']),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => editDeliverable(d),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => updateDeliverableStatus(id, 'completed'),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Complete'),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  final route = id.isNotEmpty ? '/report-editor/$id' : '/deliverables';
                                  context.go(route);
                                },
                                icon: const Icon(Icons.open_in_new),
                                tooltip: 'Open',
                              ),
                            ],
                          ),
                        ],
>>>>>>> origin/Busisiwe
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingAuditLogs
            ? const Center(child: CircularProgressIndicator())
            : (_auditLogsError != null
                ? Text(_auditLogsError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCardHeader(Icons.history, 'Recent Activity', route: '/notifications'),
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        final userId = _currentUser?.id.toString() ?? '';
                        final userName = _currentUser?.name ?? '';
                        final my = _filteredAuditLogs.where((a) {
                          final actor = (a['actor'] ?? a['user'] ?? '').toString();
                          final uid = (a['user_id'] ?? a['actor_id'] ?? '').toString();
                          return actor == userName || uid == userId;
                        }).toList();
                        if (my.isEmpty) return const Text('No recent activity');
                        return Column(
                          children: my.take(5).map((a) {
                            final action = a['action'] ?? a['event'] ?? a['type'] ?? 'Activity';
                            final actor = a['actor'] ?? a['user'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: InkWell(
                                onTap: () {
                                  context.go('/notifications');
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.history, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(actor.toString().isNotEmpty ? '$action • $actor' : action)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  )),
      ),
    );
  }

  Widget buildTeamMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCardHeader(Icons.group_outlined, 'Team Metrics', route: '/sprint-console'),
            const SizedBox(height: 12),
            if (_isLoadingTeamMetrics)
              const Center(child: CircularProgressIndicator())
            else if (_teamMetrics.isEmpty)
              const Text('No team data available')
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
<<<<<<< HEAD
                  _metricTile('Deliverables', _teamMetrics['deliverables'] ?? 0, Icons.assignment_outlined, Colors.blue),
                  _metricTile('In Progress', _teamMetrics['in_progress'] ?? 0, Icons.play_circle_outline, Colors.orange),
                  _metricTile('Completed', _teamMetrics['completed'] ?? 0, Icons.check_circle_outline, Colors.green),
                  _metricTile('Overdue', _teamMetrics['overdue'] ?? 0, Icons.warning_amber_outlined, Colors.red),
                  _metricTile('Active Sprints', _teamMetrics['active_sprints'] ?? 0, Icons.flag_outlined, Colors.purple),
                  _metricTile('Active Projects', _teamMetrics['active_projects'] ?? 0, Icons.folder_open_outlined, Colors.indigo),
                  _metricTile('Pending Reviews', _teamMetrics['pending_reviews'] ?? 0, Icons.rule_folder_outlined, Colors.blueGrey),
                  _metricTile('Completion Rate', _teamMetrics['completion_rate'] ?? '-', Icons.pie_chart_outline, Colors.teal),
=======
                  metricTile('Deliverables', _teamMetrics['deliverables'] ?? 0, Icons.assignment_outlined, Colors.blue),
                  metricTile('In Progress', _teamMetrics['in_progress'] ?? 0, Icons.play_circle_outline, Colors.orange),
                  metricTile('Completed', _teamMetrics['completed'] ?? 0, Icons.check_circle_outline, Colors.green),
                  metricTile('Overdue', _teamMetrics['overdue'] ?? 0, Icons.warning_amber_outlined, Colors.red),
                  metricTile('Active Sprints', _teamMetrics['active_sprints'] ?? 0, Icons.flag_outlined, Colors.purple),
                  metricTile('Pending Reviews', _teamMetrics['pending_reviews'] ?? 0, Icons.rule_folder_outlined, Colors.blueGrey),
                  metricTile('Completion Rate', _teamMetrics['completion_rate'] ?? '-', Icons.pie_chart_outline, Colors.teal),
>>>>>>> origin/Busisiwe
                ],
              ),
          ],
        ),
      ),
    );
}

  Widget buildSprintOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingDashboardSprints
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCardHeader(Icons.flag_outlined, 'Sprint Overview (${_dashboardSprints.length})', route: '/sprint-console'),
                  const SizedBox(height: 8),
                  ..._dashboardSprints.take(5).map((s) {
                    final name = s['name'] ?? s['title'] ?? s['sprintName'] ?? 'Sprint';
                    final status = s['status'] ?? s['state'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () {
                          final id = s['id']?.toString() ?? s['uuid']?.toString() ?? '';
                          final name = s['name']?.toString() ?? s['title']?.toString() ?? '';
                          final route = id.isNotEmpty 
                              ? '/sprint-board/$id${name.isNotEmpty ? '?name=${Uri.encodeComponent(name)}' : ''}'
                              : '/sprint-console';
                          context.go(route);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.flag_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(status.toString().isNotEmpty ? '$name • $status' : name)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

<<<<<<< HEAD
  Widget buildTeamPerformance() {
=======
  Widget buildProjectsOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingDashboardProjects
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCardHeader(Icons.folder_outlined, 'Projects (${_dashboardProjects.length})', route: '/sprint-console'),
                  const SizedBox(height: 8),
                  ..._dashboardProjects.take(5).map((p) {
                    final name = p['name'] ?? p['title'] ?? p['projectName'] ?? 'Untitled Project';
                    final status = p['status'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () {
                          final projectKey = p['projectKey']?.toString() ?? p['key']?.toString() ?? p['slug']?.toString() ?? '';
                          final route = projectKey.isNotEmpty ? '/sprint-console?projectKey=${Uri.encodeComponent(projectKey)}' : '/sprint-console';
                          context.go(route);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.folder_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(status.toString().isNotEmpty ? '$name • $status' : name)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget buildPendingReviews() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingPendingReports
            ? const Center(child: CircularProgressIndicator())
            : (_pendingReportsError != null
                ? Text(_pendingReportsError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCardHeader(Icons.fact_check_outlined, 'Pending Reviews (${_pendingReports.length})', route: '/approval-requests'),
                      const SizedBox(height: 8),
                      ..._pendingReports.take(5).map((r) {
                        final title = (r['reportTitle'] ?? r['report_title'] ?? (r['content'] is Map ? (r['content']['reportTitle'] ?? r['content']['title']) : null) ?? r['title'] ?? 'Sign-Off Report').toString();
                        final createdBy = (r['createdBy'] ?? r['created_by_name'] ?? r['created_by'] ?? '').toString();
                        final id = (r['id'] ?? r['report_id'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (id.isEmpty) return;
                                    final titleText = title.isNotEmpty ? title : 'Sign-Off Report';
                                    final createdByName = createdBy.isNotEmpty ? createdBy : 'Unknown';
                                    final deliverableId = (r['deliverableId']?.toString() ?? r['deliverable_id']?.toString() ?? '').toString();
                                    final report = SignOffReport(
                                      id: id,
                                      deliverableId: deliverableId,
                                      reportTitle: titleText,
                                      reportContent: '',
                                      sprintIds: const [],
                                      status: ReportStatus.submitted,
                                      createdAt: DateTime.now(),
                                      createdBy: createdByName,
                                    );
                                    GoRouter.of(context).push('/client-review/$id', extra: {'report': report});
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.description_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(createdBy.isNotEmpty ? '$title • $createdBy' : title)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => approveReport(id),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Approve'),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => promptChangeRequest(r),
                                icon: const Icon(Icons.edit_note, size: 18),
                                label: const Text('Request Changes'),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  )),
      ),
    );
  }

  Widget buildTeamPerformance() {
>>>>>>> origin/Busisiwe
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: buildCardHeader(Icons.insights_outlined, 'Team Performance', route: '/sprint-console')),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedChartType,
                  items: const [
                    DropdownMenuItem(value: 'velocity', child: Text('Velocity')),
                    DropdownMenuItem(value: 'burndown', child: Text('Burndown')),
                    DropdownMenuItem(value: 'burnup', child: Text('Burnup')),
                    DropdownMenuItem(value: 'defects', child: Text('Defects')),
                    DropdownMenuItem(value: 'test_pass_rate', child: Text('Test Pass Rate')),
                  ],
                  onChanged: (v) { if (v != null) setState(() { _selectedChartType = v; }); },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SprintPerformanceChart(sprints: _dashboardSprints, chartType: _selectedChartType),
        const SizedBox(height: 12),
        teamPerformanceSummary(),
      ],
    );
  }

  Widget buildReviewMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< HEAD
            _buildCardHeader(Icons.analytics_outlined, 'Review Metrics', route: '/report-repository'),
=======
            buildCardHeader(Icons.rate_review_outlined, 'Review Metrics', route: '/report-repository'),
>>>>>>> origin/Busisiwe
            const SizedBox(height: 12),
            if (_isLoadingClientMetrics)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
<<<<<<< HEAD
                  _metricTile('Draft', _clientReviewMetrics['draft'] ?? 0, Icons.edit_note, Colors.grey),
                  _metricTile('Submitted', _clientReviewMetrics['submitted'] ?? 0, Icons.send, Colors.blue),
                  _metricTile('Approved', _clientReviewMetrics['approved'] ?? 0, Icons.check_circle, Colors.green),
                  _metricTile('Changes', _clientReviewMetrics['changes'] ?? 0, Icons.change_circle, Colors.orange),
                  _metricTile('Rejected', _clientReviewMetrics['rejected'] ?? 0, Icons.cancel, Colors.red),
                  _metricTile('Avg Time', _clientReviewMetrics['avg_review_time'] ?? '-', Icons.timer, Colors.purple),
=======
                  metricTile('Submitted', _clientReviewMetrics['submitted'] ?? 0, Icons.upload_outlined, Colors.orange),
                  metricTile('Approved', _clientReviewMetrics['approved'] ?? 0, Icons.check_circle_outline, Colors.green),
                  metricTile('Changes Requested', _clientReviewMetrics['changes'] ?? 0, Icons.edit_note, Colors.blueGrey),
                  metricTile('Rejected', _clientReviewMetrics['rejected'] ?? 0, Icons.cancel_outlined, Colors.red),
                  metricTile('Avg Review Time', _clientReviewMetrics['avg_review_time'] ?? '-', Icons.schedule_outlined, Colors.blue),
>>>>>>> origin/Busisiwe
                ],
              ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget buildProjectsOverview() {
    if (_isLoadingDashboardProjects) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(Icons.folder_outlined, 'Projects Overview (${_dashboardProjects.length})', route: '/projects'),
            const SizedBox(height: 8),
            if (_dashboardProjects.isEmpty)
              const Text('No active projects'),
            ..._dashboardProjects.take(3).map((p) {
              final title = p['name'] ?? 'Untitled Project';
              final status = (p['status'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(status.isNotEmpty ? '$title • $status' : title)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildPendingReviews() {
    return buildPendingApprovals();
  }

  Widget buildPendingApprovals() {
=======
  Widget buildPendingApprovals() {
>>>>>>> origin/Busisiwe
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingPendingReports
            ? const Center(child: CircularProgressIndicator())
            : (_pendingReportsError != null
                ? Text(_pendingReportsError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCardHeader(Icons.rule_folder_outlined, 'Pending Approvals (${_pendingReports.length})', route: '/report-repository'),
                      const SizedBox(height: 8),
                      ..._pendingReports.take(5).map((r) {
                        final title = (r['reportTitle'] ?? r['report_title'] ?? (r['content'] is Map ? (r['content']['reportTitle'] ?? r['content']['title']) : null) ?? r['title'] ?? 'Sign-Off Report').toString();
                        final createdBy = (r['createdBy'] ?? r['created_by_name'] ?? r['created_by'] ?? '').toString();
                        final id = (r['id'] ?? r['report_id'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (id.isNotEmpty) context.go('/client-review/$id');
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.assignment_turned_in_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(createdBy.isNotEmpty ? '$title • $createdBy' : title)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => approveReport(id),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Approve'),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: id.isEmpty ? null : () => promptChangeRequest(r),
                                icon: const Icon(Icons.edit_note, size: 18),
                                label: const Text('Request Changes'),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  )),
      ),
    );
  }

  Widget buildRecentSubmissions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCardHeader(Icons.upload_outlined, 'Recent Submissions', route: '/report-repository'),
            const SizedBox(height: 8),
            if (_isLoadingPendingReports)
              const Center(child: CircularProgressIndicator())
            else if (_pendingReports.isEmpty)
              const Text('No recent submissions')
            else
              ..._pendingReports.take(5).map((r) {
                final title = (r['reportTitle'] ?? r['report_title'] ?? (r['content'] is Map ? (r['content']['reportTitle'] ?? r['content']['title']) : null) ?? r['title'] ?? 'Sign-Off Report').toString();
                final createdAtStr = (r['created_at'] ?? r['createdAt'] ?? r['created'] ?? '').toString();
                String ts = createdAtStr;
                try {
                  final dt = DateTime.tryParse(createdAtStr);
                  if (dt != null) ts = '${dt.toLocal()}';
                } catch (_) {}
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ts.isNotEmpty ? '$title • $ts' : title)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget buildReviewHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoadingAuditLogs
            ? const Center(child: CircularProgressIndicator())
            : (_auditLogsError != null
                ? Text(_auditLogsError!)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCardHeader(Icons.rate_review_outlined, 'Review History (${_filteredAuditLogs.length})', route: '/report-repository'),
                      const SizedBox(height: 8),
                      ..._filteredAuditLogs.take(5).map((a) {
                        final action = a['action'] ?? a['event'] ?? a['type'] ?? 'Review';
                        final actor = a['actor'] ?? a['user'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () {
                              context.go('/report-repository');
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.rate_review_outlined, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(actor.toString().isNotEmpty ? '$action • $actor' : action)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  )),
      ),
    );
  }



  

  



  Widget metricTile(String label, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(value is String ? value : value.toString(), style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget priorityChip(String priority) {
    final p = priority.toLowerCase();
    Color c;
    if (p == 'high') { c = Colors.red; }
    else if (p == 'medium') { c = Colors.orange; }
    else if (p == 'low') { c = Colors.green; }
    else { c = Colors.blueGrey; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 14),
          const SizedBox(width: 4),
          Text(p.isNotEmpty ? p : 'priority'),
        ],
      ),
    );
  }

  Widget dueDateChip(dynamic dueRaw) {
    String label = '';
    if (dueRaw != null) {
      final s = dueRaw.toString();
      final dt = DateTime.tryParse(s);
      if (dt != null) { label = dt.toLocal().toString(); }
      else { label = s; }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event, size: 14),
          const SizedBox(width: 4),
          Text(label.isNotEmpty ? label : 'due date'),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget ownerChip(String? ownerName, String? ownerId) {
    // If no owner, show "Unassigned" to make the field visible
    if ((ownerName == null || ownerName.isEmpty) && (ownerId == null || ownerId.isEmpty)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 14, color: Colors.grey),
            SizedBox(width: 4),
            Text(
              'Unassigned', 
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    final displayName = (ownerName != null && ownerName.isNotEmpty) ? ownerName : 'User $ownerId';
    
    return Tooltip(
      message: 'Deliverable Owner: $displayName',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.12),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 14, color: Colors.purple),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                displayName, 
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.purple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> editDeliverable(Map<String, dynamic> d) async {
    final id = (d['id']?.toString() ?? d['uuid']?.toString() ?? '');
    if (id.isEmpty) return;
    
    try {
      final deliverable = Deliverable.fromJson(d);
      await context.push('/deliverable-detail', extra: deliverable);
      // Reload deliverables when returning to reflect changes
      _loadDashboardDeliverables();
    } catch (e) {
      debugPrint('Error navigating to deliverable detail: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening deliverable: $e')),
      );
=======
  Future<void> editDeliverable(Map<String, dynamic> d) async {
    final id = (d['id']?.toString() ?? d['uuid']?.toString() ?? '');
    if (id.isEmpty) return;
    final titleController = TextEditingController(text: (d['title'] ?? d['name'] ?? '').toString());
    final descriptionController = TextEditingController(text: (d['description'] ?? '').toString());
    final dodController = TextEditingController(text: (d['definition_of_done'] ?? d['definitionOfDone'] ?? '').toString());
    String priority = (d['priority'] ?? '').toString().toLowerCase();
    final dueController = TextEditingController(text: (d['due_date'] ?? d['dueDate'] ?? d['deadline'] ?? '').toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Deliverable'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: dodController, maxLines: 2, decoration: const InputDecoration(labelText: 'Definition of Done', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: priority.isNotEmpty ? priority : null,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (v) { if (v != null) priority = v; },
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dueController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  final now = DateTime.now();
                  final initial = dueController.text.isNotEmpty ? (DateTime.tryParse(dueController.text) ?? now) : now;
                  final date = await showDatePicker(context: context, initialDate: initial, firstDate: now.subtract(const Duration(days: 365)), lastDate: now.add(const Duration(days: 365 * 3)),);
                  if (date != null) dueController.text = date.toIso8601String();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => context.pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (confirmed != true) return;
    final updates = <String, dynamic>{};
    if (titleController.text.trim().isNotEmpty) updates['title'] = titleController.text.trim();
    if (descriptionController.text.trim().isNotEmpty) updates['description'] = descriptionController.text.trim();
    if (dodController.text.trim().isNotEmpty) updates['definition_of_done'] = dodController.text.trim();
    if (priority.isNotEmpty) updates['priority'] = priority;
    if (dueController.text.trim().isNotEmpty) updates['due_date'] = dueController.text.trim();
    if (updates.isEmpty) return;
    final resp = await _backendService.updateDeliverable(id, updates);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (resp.isSuccess) {
      setState(() {
        _dashboardDeliverables = _dashboardDeliverables.map((e) {
          final eId = (e['id']?.toString() ?? e['uuid']?.toString() ?? '');
          if (eId == id) {
            final m = Map<String, dynamic>.from(e);
            updates.forEach((k, v) { m[k] = v; });
            return m;
          }
          return e;
        }).toList();
      });
      messenger.showSnackBar(const SnackBar(content: Text('Deliverable updated')));
      computeTeamMetrics();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(resp.error ?? 'Failed to update deliverable')));
>>>>>>> origin/Busisiwe
    }
  }

  Future<void> updateDeliverableStatus(String id, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.updateDeliverableStatus(id: id, status: status);
      setState(() {
        _dashboardDeliverables = _dashboardDeliverables.map((d) {
          final dId = (d['id']?.toString() ?? d['uuid']?.toString() ?? '');
          if (dId == id) {
            final m = Map<String, dynamic>.from(d);
            m['status'] = status;
            return m;
          }
          return d;
        }).toList();
      });
      messenger.showSnackBar(SnackBar(content: Text('Status updated to $status')));
      computeTeamMetrics();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  void computeTeamMetrics() {
    if (!mounted) return;
    setState(() => _isLoadingTeamMetrics = true);
    try {
      final int totalDeliverables = _dashboardDeliverables.length;
      int completed = 0;
      int inProgress = 0;
      int overdue = 0;
      for (final d in _dashboardDeliverables) {
        final status = (d['status'] ?? d['state'] ?? '').toString().toLowerCase();
        if (status == 'completed' || status == 'done' || status == 'approved') completed++;
        if (status == 'in_progress' || status == 'in-progress' || status == 'progress') inProgress++;
        final dueStr = (d['due_date'] ?? d['dueDate'] ?? d['deadline'] ?? '').toString();
        final due = DateTime.tryParse(dueStr);
        if (due != null && due.isBefore(DateTime.now()) && status != 'completed' && status != 'done' && status != 'approved') {
          overdue++;
        }
      }
      int activeSprints = 0;
      for (final s in _dashboardSprints) {
        final status = (s['status'] ?? s['state'] ?? '').toString().toLowerCase();
        if (status == 'active' || status == 'in_progress' || status == 'in-progress') activeSprints++;
      }
      int activeProjects = 0;
      for (final p in _dashboardProjects) {
         final status = (p['status'] ?? '').toString().toLowerCase();
         if (status != 'completed' && status != 'archived') activeProjects++;
      }
      final pendingReviews = _pendingReports.length;
      String completionRateStr;
      if (totalDeliverables > 0) {
        final rate = (completed / totalDeliverables * 100).toStringAsFixed(1);
        completionRateStr = '$rate%';
      } else {
        completionRateStr = '-';
      }
      final m = <String, dynamic>{
        'deliverables': totalDeliverables,
        'completed': completed,
        'in_progress': inProgress,
        'overdue': overdue,
        'active_sprints': activeSprints,
        'active_projects': activeProjects,
        'pending_reviews': pendingReviews,
        'completion_rate': completionRateStr,
      };
      if (mounted) {
        setState(() {
          _teamMetrics = m;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _teamMetrics = {});
    } finally {
      if (mounted) setState(() => _isLoadingTeamMetrics = false);
    }
  }

  Future<void> loadPendingReports() async {
    setState(() {
      _isLoadingPendingReports = true;
      _pendingReportsError = null;
    });
    try {
      final resp = await _reportService.getSignOffReports(status: 'submitted');
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        List<dynamic> items = const [];
        if (raw is List) {
          items = raw;
        } else if (raw is Map) {
          final d = raw['data'];
          if (d is List) {
            items = d;
          } else if (d is Map) {
            final inner = d['reports'] ?? d['items'] ?? d['data'];
            if (inner is List) {
              items = inner;
            } else {
              items = const [];
            }
          } else {
            final r = raw['reports'];
            if (r is List) {
              items = r;
            } else if (r is Map) {
              final inner = r['items'] ?? r['data'];
              if (inner is List) items = inner;
            } else {
              final i = raw['items'];
              if (i is List) items = i;
            }
          }
        }
        setState(() {
          final parsed = items.whereType<Map>().map((e) {
            final m = e.cast<String, dynamic>();
            final c = m['content'];
            if (c is String) {
              try {
                final decoded = jsonDecode(c);
                if (decoded is Map) m['content'] = Map<String, dynamic>.from(decoded);
              } catch (_) {}
            }
            return m;
          });
          _pendingReports = parsed.where((m) {
            final content = m['content'];
            final statusRaw = (m['status'] ?? m['review_status'] ?? (content is Map ? content['status'] : null) ?? '').toString().toLowerCase();
            if (statusRaw.isEmpty) return true; // Default to include when unknown
            return statusRaw == 'submitted' || statusRaw == 'under_review' || statusRaw == 'underreview';
          }).toList();
        });
        computeTeamMetrics();
      } else {
        setState(() {
          _pendingReports = [];
          _pendingReportsError = resp.error ?? 'Failed to load pending reports';
        });
      }
    } catch (_) {
      setState(() {
        _pendingReports = [];
        _pendingReportsError = 'Failed to load pending reports';
      });
    } finally {
      if (mounted) setState(() => _isLoadingPendingReports = false);
    }
  }

  Future<void> loadClientReviewMetrics() async {
    setState(() {
    });
    try {
      final resp = await _reportService.getSignOffReports();
      final m = {
        'draft': 0,
        'submitted': 0,
        'approved': 0,
        'changes': 0,
        'rejected': 0,
        'avg_review_time': '-',
      };
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        List<dynamic> items = const [];
        if (raw is List) {
          items = raw;
        } else if (raw is Map) {
          final d = raw['data'];
          if (d is List) {
            items = d;
          } else if (d is Map) {
            final inner = d['reports'] ?? d['items'] ?? d['data'];
            if (inner is List) {
              items = inner;
            } else {
              items = const [];
            }
          } else {
            final r = raw['reports'];
            if (r is List) {
              items = r;
            } else if (r is Map) {
              final inner = r['items'] ?? r['data'];
              if (inner is List) items = inner;
            } else {
              final i = raw['items'];
              if (i is List) items = i;
            }
          }
        }
        int draft = 0;
        int submitted = 0;
        int approved = 0;
        int changes = 0;
        int rejected = 0;
        final durations = <double>[];
        for (final r in items.whereType<Map>()) {
          final s = (r['status'] ?? '').toString().toLowerCase();
          if (s == 'draft') draft++;
          if (s == 'submitted') submitted++;
          if (s == 'approved') approved++;
          if (s.contains('change')) changes++;
          if (s == 'rejected' || s == 'declined') rejected++;
          final createdStr = (r['created_at'] ?? r['createdAt'] ?? r['created'] ?? '').toString();
          final approvedStr = (r['approved_at'] ?? r['approvedAt'] ?? r['reviewed_at'] ?? '').toString();
          final created = DateTime.tryParse(createdStr);
          final approvedDt = DateTime.tryParse(approvedStr);
          if (created != null && approvedDt != null && approvedDt.isAfter(created)) {
            final hours = approvedDt.difference(created).inMinutes / 60.0;
            durations.add(hours);
          }
        }
        m['draft'] = draft;
        m['submitted'] = submitted;
        m['approved'] = approved;
        m['changes'] = changes;
        m['rejected'] = rejected;
        if (durations.isNotEmpty) {
          final avg = durations.reduce((a, b) => a + b) / durations.length;
          m['avg_review_time'] = '${avg.toStringAsFixed(1)}h';
        }
      }
      setState(() {
        _clientReviewMetrics = {};
      });
    } finally {
      if (mounted) setState(() => _isLoadingClientMetrics = false);
    }
  }

<<<<<<< HEAD

  Widget teamPerformanceSummary() {
=======
  Widget teamPerformanceSummary() {
>>>>>>> origin/Busisiwe
    double planned = 0;
    double completed = 0;
    double defects = 0;
    for (final s in _dashboardSprints) {
      final p = s['planned_points'] ?? s['planned'] ?? 0;
      final c = s['completed_points'] ?? s['completed'] ?? 0;
      final d = s['defects_opened'] ?? s['defect_count'] ?? 0;
      planned += (p is num) ? p.toDouble() : double.tryParse(p.toString()) ?? 0;
      completed += (c is num) ? c.toDouble() : double.tryParse(c.toString()) ?? 0;
      defects += (d is num) ? d.toDouble() : double.tryParse(d.toString()) ?? 0;
    }
    final avgVelocity = _dashboardSprints.isNotEmpty ? (completed / _dashboardSprints.length) : 0;
    final carryover = planned - completed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          metricTile('Avg Velocity', avgVelocity.toStringAsFixed(1), Icons.speed, Colors.blue),
          metricTile('Planned', planned.toStringAsFixed(1), Icons.trending_up, Colors.orange),
          metricTile('Completed', completed.toStringAsFixed(1), Icons.check_circle_outline, Colors.green),
          metricTile('Carryover', carryover.toStringAsFixed(1), Icons.sync_problem, Colors.red),
          metricTile('Defects', defects.toStringAsFixed(0), Icons.bug_report, Colors.purple),
        ],
      ),
    );
  }

  Widget buildAdminFeatures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCardHeader(Icons.settings_applications, 'Admin Features', route: '/settings'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
<<<<<<< HEAD
                _featureTile(Icons.dashboard_outlined, 'System Metrics', () => context.go('/system-metrics')),
                _featureTile(Icons.security, 'Role Management', () => context.go('/role-management')),
                _featureTile(Icons.health_and_safety, 'System Health', () => context.go('/system-health')),
                _featureTile(Icons.receipt_long, 'Audit Logs', () => context.go('/audit-logs')),
                _featureTile(Icons.assignment, 'Deliverables Overview', () => context.go('/deliverables-overview')),
=======
                featureTile(Icons.dashboard_outlined, 'System Metrics', () => context.go('/system-metrics')),
                featureTile(Icons.security, 'Role Management', () => context.go('/role-management')),
                featureTile(Icons.health_and_safety, 'System Health', () => context.go('/system-health')),
                featureTile(Icons.receipt_long, 'Audit Logs', () => context.go('/audit-logs')),
>>>>>>> origin/Busisiwe
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget featureTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Future<void> approveReport(String reportId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final resp = await _reportService.approveReport(reportId);
      if (resp.isSuccess) {
        setState(() {
          _pendingReports = _pendingReports.where((e) => (e['id']?.toString() ?? e['report_id']?.toString() ?? '') != reportId).toList();
        });
        await notifyReportSender(reportId, approved: true);
        messenger.showSnackBar(const SnackBar(content: Text('Report approved')));
        loadClientReviewMetrics();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(resp.error ?? 'Failed to approve report')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> requestChanges(String reportId, String details) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final resp = await _reportService.requestChanges(reportId, details);
      if (resp.isSuccess) {
        setState(() {
          _pendingReports = _pendingReports.where((e) => (e['id']?.toString() ?? e['report_id']?.toString() ?? '') != reportId).toList();
        });
        await notifyReportSender(reportId, approved: false, details: details);
        messenger.showSnackBar(const SnackBar(content: Text('Change request sent')));
        loadClientReviewMetrics();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(resp.error ?? 'Failed to request changes')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> notifyReportSender(String reportId, {required bool approved, String? details}) async {
    try {
      final token = _authService.accessToken;
      final ns = NotificationService();
      if (token != null) ns.setAuthToken(token);
      final resp = await _backendService.getSignOffReport(reportId);
      String title = approved ? 'Report Approved' : 'Report Changes Requested';
      String message = approved ? '${_currentUser?.name ?? 'Reviewer'} approved "Report"' : '${_currentUser?.name ?? 'Reviewer'} requested changes on "Report"';
      String? targetUserId;
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        Map<String, dynamic> m = {};
        if (raw is Map<String, dynamic>) {
          final d = raw['data'];
          if (d is Map<String, dynamic>) {
            m = d;
          } else {
            m = raw;
          }
        }
        final content = m['content'];
        final String reportTitle = (m['reportTitle'] ?? m['report_title'] ?? (content is Map ? (content['reportTitle'] ?? content['title']) : null) ?? m['title'] ?? 'Report').toString();
        title = approved ? 'Report Approved' : 'Report Changes Requested';
        message = approved ? '${_currentUser?.name ?? 'Reviewer'} approved "$reportTitle"' : '${_currentUser?.name ?? 'Reviewer'} requested changes for "$reportTitle"';
        final createdByRaw = (m['createdBy'] ?? m['created_by'] ?? '').toString();
        final createdByName = (m['createdByName'] ?? m['created_by_name'] ?? '').toString();
        if (createdByRaw.isNotEmpty) {
          final isUuidLike = RegExp(r'^[a-f0-9-]{8,}$', caseSensitive: false).hasMatch(createdByRaw);
          final looksLikeEmail = createdByRaw.contains('@');
          final hasSpaces = createdByRaw.contains(' ');
          if (isUuidLike && !looksLikeEmail && !hasSpaces) {
            targetUserId = createdByRaw;
          }
        }
        if (targetUserId == null && createdByName.isNotEmpty) {
          try {
            final usersResp = await _backendService.getUsers(page: 1, limit: 200);
            final rawUsers = usersResp.isSuccess ? usersResp.data : null;
            final List<dynamic> items = rawUsers is List
                ? rawUsers
                : (rawUsers is Map<String, dynamic> ? (rawUsers['data'] ?? rawUsers['users'] ?? rawUsers['items'] ?? []) : []);
            for (final u in items) {
              if (u is Map) {
                final um = Map<String, dynamic>.from(u);
                final name = (um['name'] ?? '').toString();
                final first = (um['first_name'] ?? um['firstName'] ?? '').toString();
                final last = (um['last_name'] ?? um['lastName'] ?? '').toString();
                final combined = ('$first $last').trim();
                if (name.toLowerCase() == createdByName.toLowerCase() || (combined.isNotEmpty && combined.toLowerCase() == createdByName.toLowerCase())) {
                  targetUserId = (um['id'] ?? '').toString();
                  break;
                }
              }
            }
          } catch (_) {}
        }
      }
      await ns.createNotification(title: title, message: message, type: approved ? NotificationType.reportApproved : NotificationType.reportChangesRequested, userId: targetUserId);
      try {
        final event = approved ? 'report_approved' : 'report_change_requested';
        realtimeService.emit(event, {'reportId': reportId});
        realtimeService.emit('approval_updated', {'reportId': reportId});
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> promptChangeRequest(Map<String, dynamic> report) async {
    final id = (report['id'] ?? report['report_id'] ?? '').toString();
    if (id.isEmpty) return;
    String details = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Changes'),
        content: TextField(
          onChanged: (v) => details = v,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Details'),
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => context.pop(true), child: const Text('Send')),
        ],
      ),
    );
    if (confirmed == true && details.trim().isNotEmpty) {
      await requestChanges(id, details.trim());
    }
  }

  Widget buildTeamMemberDashboard() {
    return _buildTeamMemberDashboard();
  }

  Widget buildDeveloperDashboard() => buildTeamMemberDashboard();
  Widget buildProjectManagerDashboard() => buildDeliveryLeadDashboard();
  Widget buildScrumMasterDashboard() => buildDeliveryLeadDashboard();
  Widget buildQAEngineerDashboard() => buildTeamMemberDashboard();
  Widget buildStakeholderDashboard() => buildClientReviewerDashboard();

  Widget buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: _currentUser?.isSystemAdmin == true ? Theme.of(context).colorScheme.primary : null,
      ),
      label: Text(label),
    );
  }

  Widget buildCardHeader(IconData icon, String label, {String? route}) {
    final row = Row(
      children: [
        Icon(
          icon,
          color: _currentUser?.isSystemAdmin == true
              ? Theme.of(context).colorScheme.secondary
              : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
    if (route == null) return row;
    return InkWell(onTap: () => context.go(route), child: row);
  }

  

  void showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Text(_currentUser?.email ?? ''),
        actions: [TextButton(onPressed: () => context.pop(), child: const Text('Close'))],
      ),
    );
  }

  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Settings'),
        content: Text('Settings are coming soon.'),
      ),
    );
  }

  Future<void> handleLogout() async {
    await _authService.signOut();
    if (mounted) context.go('/');
  }
<<<<<<< HEAD

  void setupRealtimeListeners() {
    // Clear existing listeners to prevent duplicates
    realtimeService.offAll('user_role_changed');
    realtimeService.offAll('sprint_created');
    realtimeService.offAll('sprint_updated');
    realtimeService.offAll('deliverable_created');
    realtimeService.offAll('deliverable_updated');
    realtimeService.offAll('approval_created');
    realtimeService.offAll('approval_updated');
    realtimeService.offAll('report_submitted');
    realtimeService.offAll('report_approved');
    realtimeService.offAll('report_change_requested');
    realtimeService.offAll('project_created');
    realtimeService.offAll('project_updated');
    // Note: notifications listeners are handled by NotificationCenterWidget, do not offAll here

    realtimeService.on('user_role_changed', handleRoleChanged);
    realtimeService.on('sprint_created', (_) => _loadDashboardSprints());
    realtimeService.on('sprint_updated', (_) => _loadDashboardSprints());
    realtimeService.on('deliverable_created', (_) => _loadDashboardDeliverables());
    realtimeService.on('deliverable_updated', (_) => _loadDashboardDeliverables());
    realtimeService.on('approval_created', (_) { _loadPendingReports(); _loadClientReviewMetrics(); _loadDashboardDeliverables(); });
    realtimeService.on('approval_updated', (_) { _loadPendingReports(); _loadClientReviewMetrics(); _loadDashboardDeliverables(); });
    realtimeService.on('report_submitted', (_) { _loadPendingReports(); _loadClientReviewMetrics(); _loadDashboardDeliverables(); });
    realtimeService.on('report_approved', (_) { _loadPendingReports(); _loadClientReviewMetrics(); _loadDashboardDeliverables(); });
    realtimeService.on('report_change_requested', (_) { _loadPendingReports(); _loadClientReviewMetrics(); _loadDashboardDeliverables(); });
    realtimeService.on('project_created', (_) => _loadDashboardProjects());
    realtimeService.on('project_updated', (_) => _loadDashboardProjects());
    realtimeService.on('notification_received', (data) {
      try {
        final type = (data['type'] ?? '').toString();
        if (type == 'project') {
          _loadDashboardProjects();
        } else if (type == 'sprint') {
          _loadDashboardSprints();
        } else if (type == 'deliverable' || type == 'approval' || type == 'change_request') {
          _loadDashboardDeliverables();
          _loadPendingReports();
          _loadClientReviewMetrics();
        }
      } catch (_) {}
    });
  }

  void handleRoleChanged(dynamic _) {
    _loadCurrentUser();
  }
  
  Widget buildKanbanLinkCard() {
    return InkWell(
      onTap: () => context.push('/deliverables-overview'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.view_kanban, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliverables Board',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track progress and manage status',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

=======
>>>>>>> origin/Busisiwe
}
