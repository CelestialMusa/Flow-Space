import 'dart:async';
import 'package:flutter/material.dart';
import '../models/approval_request.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import '../utils/date_utils.dart' as du;
import 'package:go_router/go_router.dart';
import 'client_review_workflow_screen.dart';

class ApprovalRequestsScreen extends StatefulWidget {
  const ApprovalRequestsScreen({super.key});

  @override
  State<ApprovalRequestsScreen> createState() => _ApprovalRequestsScreenState();
}

class _ApprovalRequestsScreenState extends State<ApprovalRequestsScreen> {
  RealtimeService? _realtime;
  List<ApprovalRequest> _requests = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  String _selectedCategory = 'all';
  String _selectedSprintId = 'all';
  String _selectedDeliverableId = 'all';
  List<dynamic> _deliverables = [];
  List<Map<String, dynamic>> _sprints = [];

  String _formatSaDate(DateTime date) {
    return du.DateUtils.formatDateTime(date);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        // Initialize auth service when needed
        // Auth service will be initialized when user is authenticated
      } catch (_) {}
      try {
        // Get auth token when needed
        // Token will be retrieved from secure storage when user is authenticated
        const token = ''; // Placeholder
        if (token.isNotEmpty) {
          _realtime = RealtimeService();
          await _realtime!.initialize(authToken: token);
          _setupRealtimeListeners();
        }
      } catch (_) {}
      if (!mounted) return;
      await _loadFilters();
      await _loadApprovalRequests();
    });
  }

  Future<void> _loadApprovalRequests() async {
    setState(() => _isLoading = true);
    
    try {
      final statusParam = _selectedStatus != 'all' ? _selectedStatus : null;
      final priorityParam = _selectedPriority != 'all' ? _selectedPriority : null;
      final categoryParam = _selectedCategory != 'all' ? _selectedCategory : null;
      final deliverableParam = _selectedDeliverableId != 'all' ? _selectedDeliverableId : null;
      final response = await ApiService.getApprovalRequests(
        status: statusParam,
        type: categoryParam,
      );
      
      final list = response
          .map((item) => ApprovalRequest.fromJson(item))
          .toList();
      setState(() {
        _requests = list;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading approval requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeListeners() {
    _realtime?.on('approval_created', (_) => _loadApprovalRequests());
    _realtime?.on('approval_updated', (_) => _loadApprovalRequests());
    _realtime?.on('report_submitted', (_) => _loadApprovalRequests());
    _realtime?.on('report_approved', (_) => _loadApprovalRequests());
    _realtime?.on('report_change_requested', (_) => _loadApprovalRequests());
  }

  @override
  void dispose() {
    try {
      _realtime?.offAll('approval_created');
      _realtime?.offAll('approval_updated');
      _realtime?.offAll('report_submitted');
      _realtime?.offAll('report_approved');
      _realtime?.offAll('report_change_requested');
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final deliverables = await ApiService.getDeliverables();
      final sprints = await ApiService.getSprints();
      setState(() {
        _deliverables = deliverables;
        _sprints = sprints.map((sprint) => sprint.toJson()).toList();
      });
    } catch (_) {}
  }

  bool _deliverableMatchesSprintById(String deliverableId, String sprintId) {
    try {
      final d = _deliverables.firstWhere(
        (x) {
          if (x is Map<String, dynamic>) {
            return (x['id']?.toString() ?? '') == deliverableId;
          }
          try {
            return x.id?.toString() == deliverableId || x.id.toString() == deliverableId;
          } catch (_) {
            return false;
          }
        },
        orElse: () => null,
      );
      if (d == null) return false;
      if (d is Map<String, dynamic>) {
        final sid = d['sprint_id'] ?? d['sprintId'];
        if (sid != null) return sid.toString() == sprintId;
        final sids = d['sprintIds'];
        if (sids is List) return sids.map((e) => e.toString()).contains(sprintId);
        return false;
      }
      try {
        final sidField = d.sprintId;
        if (sidField != null) return sidField.toString() == sprintId;
      } catch (_) {}
      try {
        final sidsField = d.sprintIds;
        if (sidsField is List) return sidsField.map((e) => e.toString()).contains(sprintId);
      } catch (_) {}
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openAssociatedReport(ApprovalRequest request) async {
    try {
      String? reportId;
      final rid = request.id;
      if (rid.toLowerCase().startsWith('report:')) {
        final parts = rid.split(':');
        if (parts.length >= 2) {
          reportId = parts.sublist(1).join(':');
        }
      }

      if ((reportId == null || reportId.isEmpty) && request.category.toLowerCase().contains('sign-off')) {
        final did = request.deliverableId?.toString() ?? '';
        if (did.isNotEmpty) {
          // Implement report fetching logic
          // Report data will be fetched from the API service
        }
      }

      if (reportId != null && reportId.isNotEmpty) {
        if (!mounted) return;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientReviewWorkflowScreen(reportId: reportId!),
          ),
        );
        if (result == true) {
          await _loadApprovalRequests();
        }
      } else {
        if (!mounted) return;
        GoRouter.of(context).go('/report-repository');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to open associated report: $e');
    }
  }

  List<ApprovalRequest> get _filteredRequests {
    return _requests.where((request) {
      final matchesSearch = _searchQuery.isEmpty ||
          request.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          request.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _selectedStatus == 'all' || 
          (_selectedStatus == 'deliverable' 
              ? request.deliverableId != null 
              : request.status.name == _selectedStatus);
              
      final matchesPriority = _selectedPriority == 'all' || request.priority == _selectedPriority;
      final matchesCategory = _selectedCategory == 'all' || request.category == _selectedCategory;
      final matchesDeliverable = _selectedDeliverableId == 'all' || (request.deliverableId?.toString() == _selectedDeliverableId);
      final matchesSprint = _selectedSprintId == 'all' || (
        request.deliverableId != null && _deliverableMatchesSprintById(request.deliverableId!, _selectedSprintId)
      );
      
      return matchesSearch && matchesStatus && matchesPriority && matchesCategory && matchesDeliverable && matchesSprint;
    }).toList();
  }

  Future<void> _approveRequest(ApprovalRequest request) async {
    final reason = await _showReasonDialog('Approve Request', 'Enter reason for approval:');
    if (reason != null && reason.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final success = await ApiService.updateApprovalRequest(request.id, 'approved');
        if (success) {
          await _loadApprovalRequests();
          _showSuccessSnackBar('Request approved successfully');
        } else {
          _showErrorSnackBar('Failed to approve request');
        }
      } catch (e) {
        _showErrorSnackBar('Error approving request: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectRequest(ApprovalRequest request) async {
    final reason = await _showReasonDialog('Reject Request', 'Enter reason for rejection:');
    if (reason != null && reason.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final success = await ApiService.updateApprovalRequest(request.id, 'rejected');
        if (success) {
          await _loadApprovalRequests();
          _showSuccessSnackBar('Request rejected successfully');
        } else {
          _showErrorSnackBar('Failed to reject request');
        }
      } catch (e) {
        _showErrorSnackBar('Error rejecting request: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showReasonDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Requests'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApprovalRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : _buildRequestsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilter(),
                const SizedBox(width: 8),
                _buildPriorityFilter(),
                const SizedBox(width: 8),
                _buildCategoryFilter(),
                const SizedBox(width: 8),
                _buildSprintFilter(),
                const SizedBox(width: 8),
                _buildDeliverableFilter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'Search approval requests...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedStatus,
        onChanged: (value) {
          setState(() => _selectedStatus = value ?? '');
        },
        items: ['all', 'pending', 'approved', 'rejected'].map((status) {
          return DropdownMenuItem(
            value: status,
            child: Text(status.toUpperCase()),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedPriority,
        onChanged: (value) {
          setState(() => _selectedPriority = value ?? '');
        },
        items: ['all', 'low', 'medium', 'high', 'urgent'].map((priority) {
          return DropdownMenuItem(
            value: priority,
            child: Text(priority.toUpperCase()),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedCategory,
        onChanged: (value) {
          setState(() => _selectedCategory = value ?? '');
        },
        items: ['all', 'deliverable', 'sign-off', 'other'].map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category.toUpperCase()),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSprintFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedSprintId,
        onChanged: (value) {
          setState(() => _selectedSprintId = value ?? '');
        },
        items: [
          const DropdownMenuItem(value: 'all', child: Text('ALL SPRINTS')),
          ..._sprints.map((sprint) => DropdownMenuItem(
            value: sprint['id']?.toString() ?? '',
            child: Text(sprint['name']?.toString() ?? 'Unknown Sprint'),
          ),),
        ],
      ),
    );
  }

  Widget _buildDeliverableFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedDeliverableId,
        onChanged: (value) {
          setState(() => _selectedDeliverableId = value ?? '');
        },
        items: [
          const DropdownMenuItem(value: 'all', child: Text('ALL DELIVERABLES')),
          ..._deliverables.map((deliverable) => DropdownMenuItem(
            value: deliverable['id']?.toString() ?? '',
            child: Text(deliverable['title']?.toString() ?? 'Unknown Deliverable'),
          ),),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No approval requests found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or create new requests',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        final request = _filteredRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(ApprovalRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(request.status.name),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  request.requestedByName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatSaDate(request.requestedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            if (request.deliverableId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.assignment, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Deliverable ID: ${request.deliverableId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _openAssociatedReport(request),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View Report'),
                ),
                const SizedBox(width: 8),
                if (request.isPending) ...[
                  ElevatedButton.icon(
                    onPressed: () => _approveRequest(request),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor = Colors.white;
    
    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange;
        break;
      case 'approved':
        backgroundColor = Colors.green;
        break;
      case 'rejected':
        backgroundColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.black;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
