import 'package:flutter/material.dart';
import '../services/deliverable_service.dart' as deliverable_service;

class DeliverablesOverviewScreen extends StatefulWidget {
  const DeliverablesOverviewScreen({super.key});

  @override
  DeliverablesOverviewScreenState createState() => DeliverablesOverviewScreenState();
}

class DeliverablesOverviewScreenState extends State<DeliverablesOverviewScreen> {
  List<deliverable_service.Deliverable> _serviceDeliverables = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDeliverables();
  }

  Future<void> _loadDeliverables() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = deliverable_service.DeliverableService();
      final response = await service.getDeliverables();
      
      if (response.isSuccess && response.data != null) {
        final List<deliverable_service.Deliverable> deliverables = 
            response.data!['deliverables'] as List<deliverable_service.Deliverable>;
        
        setState(() {
          _serviceDeliverables = deliverables;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to load deliverables'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading deliverables: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<deliverable_service.Deliverable> get _filteredDeliverables {
    var filtered = _serviceDeliverables;

    // Filter by status
    if (_selectedStatus != 'All') {
      filtered = filtered.where((d) => 
        d.status.toLowerCase() == _selectedStatus.toLowerCase(),
      ).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((d) =>
        d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (d.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false),
      ).toList();
    }

    return filtered;
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
        title: const Text('Deliverables Overview'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliverables,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDeliverables.isEmpty
                    ? _buildEmptyState()
                    : _buildDeliverablesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to deliverable setup screen
          Navigator.pushNamed(context, '/deliverable-setup');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Draft', 'Submitted', 'Approved', 'Change Requested', 'Rejected'].map((status) {
            final isSelected = _selectedStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? status : 'All';
                  });
                },
                backgroundColor: isSelected ? null : Colors.grey[200],
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search deliverables...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No deliverables found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first deliverable to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverablesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredDeliverables.length,
      itemBuilder: (context, index) {
        final deliverable = _filteredDeliverables[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            title: Text(
              deliverable.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (deliverable.description != null) ...[
                  Text(
                    deliverable.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Chip(
                      label: Text(
                        _formatStatus(deliverable.status),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getStatusColor(deliverable.status).withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: _getStatusColor(deliverable.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        deliverable.priority,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (deliverable.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Due: ${_formatDate(deliverable.dueDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isOverdue(deliverable.dueDate!) ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    // Navigate to edit screen
                    break;
                  case 'delete':
                    _showDeleteConfirmation(deliverable);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              // Navigate to deliverable details
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }

  void _showDeleteConfirmation(deliverable_service.Deliverable deliverable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deliverable'),
        content: Text('Are you sure you want to delete "${deliverable.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDeliverable(deliverable.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDeliverable(String id) async {
    try {
      final service = deliverable_service.DeliverableService();
      final response = await service.deleteDeliverable(id);
      
      if (response.isSuccess) {
        setState(() {
          _serviceDeliverables.removeWhere((d) => d.id == id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deliverable deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to delete deliverable'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting deliverable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
