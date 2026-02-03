import 'package:flutter/material.dart';
import '../services/deliverable_service.dart' as deliverable_service;

class DeliverableDetailScreen extends StatefulWidget {
  final String deliverableId;

  const DeliverableDetailScreen({
    super.key,
    required this.deliverableId,
  });

  @override
  DeliverableDetailScreenState createState() => DeliverableDetailScreenState();
}

class DeliverableDetailScreenState extends State<DeliverableDetailScreen> {
  deliverable_service.Deliverable? _deliverable;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeliverable();
  }

  Future<void> _loadDeliverable() async {
    try {
      final service = deliverable_service.DeliverableService();
      final response = await service.getDeliverables();
      
      if (response.isSuccess && response.data != null) {
        final List<deliverable_service.Deliverable> deliverables = 
            response.data!['deliverables'] as List<deliverable_service.Deliverable>;
        
        final deliverable = deliverables.firstWhere(
          (d) => d.id == widget.deliverableId,
          orElse: () => throw Exception('Deliverable not found'),
        );
        
        setState(() {
          _deliverable = deliverable;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load deliverable';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'approved':
        return 'Approved';
      case 'change_requested':
        return 'Change Requested';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'change_requested':
        return Colors.amber;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_deliverable?.title ?? 'Deliverable Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDeliverable,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_deliverable == null) {
      return const Center(
        child: Text('Deliverable not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildDescription(),
          const SizedBox(height: 24),
          _buildStatusSection(),
          const SizedBox(height: 24),
          _buildMetadata(),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _deliverable!.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_deliverable!.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor(_deliverable!.status).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _formatStatus(_deliverable!.status),
                style: TextStyle(
                  color: _getStatusColor(_deliverable!.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _deliverable!.priority,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    if (_deliverable!.description == null || _deliverable!.description!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No description provided'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(_deliverable!.description!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusItem('Current Status', _formatStatus(_deliverable!.status)),
            if (_deliverable!.dueDate != null)
              _buildStatusItem('Due Date', _formatDate(_deliverable!.dueDate!)),
            _buildStatusItem('Created At', _formatDate(_deliverable!.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metadata',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusItem('Created By', _deliverable!.createdByName ?? _deliverable!.createdBy),
            if (_deliverable!.assignedToName != null)
              _buildStatusItem('Assigned To', _deliverable!.assignedToName!),
            if (_deliverable!.sprintName != null)
              _buildStatusItem('Sprint', _deliverable!.sprintName!),
            _buildStatusItem('Created At', _formatDate(_deliverable!.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Edit deliverable
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Share deliverable
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
