import 'package:flutter/material.dart';
import '../services/project_deliverable_service.dart';

class DeliverableSelector extends StatefulWidget {
  final String projectId;
  final List<String> initiallySelectedIds;
  final Function(List<String>) onSelectionChanged;
  final bool enabled;

  const DeliverableSelector({
    super.key,
    required this.projectId,
    this.initiallySelectedIds = const [],
    required this.onSelectionChanged,
    this.enabled = true,
  });

  @override
  State<DeliverableSelector> createState() => _DeliverableSelectorState();
}

class _DeliverableSelectorState extends State<DeliverableSelector> {
  List<Map<String, dynamic>> _availableDeliverables = [];
  final List<Map<String, dynamic>> _selectedDeliverables = [];
  Set<String> _selectedIds = {};
  bool _isLoading = false;
  String _searchQuery = '';
  String? _error;
  bool _showSearchResults = false;

  // Helper method to convert hex color string to Color
  Color _hexToColor(String hexString) {
    final hexCode = hexString.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initiallySelectedIds);
    _loadAvailableDeliverables();
  }

  Future<void> _loadAvailableDeliverables({String? search}) async {
    if (!widget.enabled) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deliverables = await ProjectDeliverableService.getAvailableDeliverables(
        widget.projectId,
        search: search,
      );
      
      setState(() {
        _availableDeliverables = deliverables;
        _isLoading = false;
        _showSearchResults = search != null && search.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _loadAvailableDeliverables();
    } else {
      _loadAvailableDeliverables(search: query);
    }
  }

  void _toggleSelection(Map<String, dynamic> deliverable) {
    if (!widget.enabled) return;
    
    final deliverableId = deliverable['id'] as String;
    
    setState(() {
      if (_selectedIds.contains(deliverableId)) {
        _selectedIds.remove(deliverableId);
        _selectedDeliverables.removeWhere((d) => d['id'] == deliverableId);
      } else {
        _selectedIds.add(deliverableId);
        _selectedDeliverables.add(deliverable);
      }
    });
    
    widget.onSelectionChanged(_selectedIds.toList());
  }

  void _removeSelectedDeliverable(Map<String, dynamic> deliverable) {
    if (!widget.enabled) return;
    
    final deliverableId = deliverable['id'] as String;
    
    setState(() {
      _selectedIds.remove(deliverableId);
      _selectedDeliverables.removeWhere((d) => d['id'] == deliverableId);
    });
    
    widget.onSelectionChanged(_selectedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        if (widget.enabled) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search deliverables...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchQuery = '';
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Selected deliverables
        if (_selectedDeliverables.isNotEmpty) ...[
          const Text(
            'Selected Deliverables',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _selectedDeliverables.map((deliverable) {
                return _buildSelectedDeliverableTile(deliverable);
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Available deliverables
        if (widget.enabled) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  _showSearchResults ? 'Search Results' : 'Available Deliverables',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        // Content
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          )
        else if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_availableDeliverables.isEmpty && !_showSearchResults)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No available deliverables',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All deliverables are already linked to this project',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (_availableDeliverables.isEmpty && _showSearchResults)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No deliverables found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search terms',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _availableDeliverables.map((deliverable) {
                return _buildAvailableDeliverableTile(deliverable);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedDeliverableTile(Map<String, dynamic> deliverable) {
    final status = deliverable['status'] as String?;
    final priority = deliverable['priority'] as String?;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.task_alt,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deliverable['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (deliverable['description'] != null && 
                    deliverable['description'].toString().isNotEmpty)
                  Text(
                    deliverable['description'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _hexToColor(ProjectDeliverableService.getStatusColor(status))
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _hexToColor(ProjectDeliverableService.getStatusColor(status))
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        ProjectDeliverableService.formatDeliverableStatus(status),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _hexToColor(ProjectDeliverableService.getStatusColor(status)),
                        ),
                      ),
                    ),
                    if (priority != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _hexToColor(ProjectDeliverableService.getPriorityColor(priority))
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _hexToColor(ProjectDeliverableService.getPriorityColor(priority))
                              .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          priority.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _hexToColor(ProjectDeliverableService.getPriorityColor(priority)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (widget.enabled)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => _removeSelectedDeliverable(deliverable),
              tooltip: 'Remove from selection',
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableDeliverableTile(Map<String, dynamic> deliverable) {
    final isSelected = _selectedIds.contains(deliverable['id'] as String);
    final status = deliverable['status'] as String?;
    final priority = deliverable['priority'] as String?;
    
    return InkWell(
      onTap: () => _toggleSelection(deliverable),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          color: isSelected ? Colors.blue.shade50 : null,
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleSelection(deliverable),
              activeColor: Colors.blue.shade600,
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.task_alt,
              color: Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deliverable['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? Colors.blue.shade800 : null,
                    ),
                  ),
                  if (deliverable['description'] != null && 
                      deliverable['description'].toString().isNotEmpty)
                    Text(
                      deliverable['description'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _hexToColor(ProjectDeliverableService.getStatusColor(status))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _hexToColor(ProjectDeliverableService.getStatusColor(status))
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          ProjectDeliverableService.formatDeliverableStatus(status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _hexToColor(ProjectDeliverableService.getStatusColor(status)),
                          ),
                        ),
                      ),
                      if (priority != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _hexToColor(ProjectDeliverableService.getPriorityColor(priority))
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _hexToColor(ProjectDeliverableService.getPriorityColor(priority))
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _hexToColor(ProjectDeliverableService.getPriorityColor(priority)),
                            ),
                          ),
                        ),
                      ],
                      if (deliverable['created_by_name'] != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'by ${deliverable['created_by_name']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
