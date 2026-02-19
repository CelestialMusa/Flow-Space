import 'package:flutter/material.dart';
import '../services/project_sprint_service.dart';

class SprintSelector extends StatefulWidget {
  final String projectId;
  final List<String> initiallySelectedIds;
  final Function(List<String>) onSelectionChanged;
  final bool enabled;

  const SprintSelector({
    super.key,
    required this.projectId,
    this.initiallySelectedIds = const [],
    required this.onSelectionChanged,
    this.enabled = true,
  });

  @override
  State<SprintSelector> createState() => _SprintSelectorState();
}

class _SprintSelectorState extends State<SprintSelector> {
  List<Map<String, dynamic>> _availableSprints = [];
  final List<Map<String, dynamic>> _selectedSprints = [];
  Set<String> _selectedIds = {};
  bool _isLoading = false;
  String? _error;
  bool _showSearchResults = false;
  bool _showCreateForm = false;

  // Helper method to convert hex color string to Color
  Color _hexToColor(String hexString) {
    final hexCode = hexString.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  // Form controllers for new sprint
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initiallySelectedIds);
    _loadAvailableSprints();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSprints({String? search}) async {
    if (!widget.enabled) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sprints = await ProjectSprintService.getAvailableSprints(
        widget.projectId,
        search: search,
      );
      
      setState(() {
        _availableSprints = sprints;
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
    if (query.isEmpty) {
      _loadAvailableSprints();
    } else {
      _loadAvailableSprints(search: query);
    }
  }

  void _toggleSelection(Map<String, dynamic> sprint) {
    if (!widget.enabled) return;
    
    final sprintId = sprint['id'] as String;
    
    setState(() {
      if (_selectedIds.contains(sprintId)) {
        _selectedIds.remove(sprintId);
        _selectedSprints.removeWhere((s) => s['id'] == sprintId);
      } else {
        _selectedIds.add(sprintId);
        _selectedSprints.add(sprint);
      }
    });
    
    widget.onSelectionChanged(_selectedIds.toList());
  }

  void _removeSelectedSprint(Map<String, dynamic> sprint) {
    if (!widget.enabled) return;
    
    final sprintId = sprint['id'] as String;
    
    setState(() {
      _selectedIds.remove(sprintId);
      _selectedSprints.removeWhere((s) => s['id'] == sprintId);
    });
    
    widget.onSelectionChanged(_selectedIds.toList());
  }

  Future<void> _createNewSprint() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sprint name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newSprint = await ProjectSprintService.createSprintForProject(
        widget.projectId,
        _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
      );

      // Add to selected sprints
      setState(() {
        _selectedIds.add(newSprint['id'] as String);
        _selectedSprints.add(newSprint);
        _isLoading = false;
        _showCreateForm = false;
      });

      // Clear form
      _nameController.clear();
      _descriptionController.clear();
      _startDateController.clear();
      _endDateController.clear();

      widget.onSelectionChanged(_selectedIds.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sprint "${newSprint['name']}" created and linked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating sprint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(TextEditingController controller, {bool isStartDate = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T')[0];
        
        // If end date is before start date, adjust it
        if (isStartDate && _endDateController.text.isNotEmpty) {
          final endDate = DateTime.parse(_endDateController.text);
          if (endDate.isBefore(picked)) {
            _endDateController.text = picked.toIso8601String().split('T')[0];
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action buttons
        if (widget.enabled) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search sprints...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showCreateForm = !_showCreateForm;
                  });
                },
                icon: Icon(_showCreateForm ? Icons.close : Icons.add),
                label: Text(_showCreateForm ? 'Cancel' : 'New Sprint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Create new sprint form
        if (_showCreateForm) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Create New Sprint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Sprint Name *',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startDateController,
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: () => _selectDate(_startDateController, isStartDate: true),
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _endDateController,
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          prefixIcon: const Icon(Icons.event),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: () => _selectDate(_endDateController),
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createNewSprint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Create Sprint'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showCreateForm = false;
                        });
                        _nameController.clear();
                        _descriptionController.clear();
                        _startDateController.clear();
                        _endDateController.clear();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Selected sprints
        if (_selectedSprints.isNotEmpty) ...[
          const Text(
            'Selected Sprints',
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
              children: _selectedSprints.map((sprint) {
                return _buildSelectedSprintTile(sprint);
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Available sprints
        if (widget.enabled) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  _showSearchResults ? 'Search Results' : 'Available Sprints',
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
        else if (_availableSprints.isEmpty && !_showSearchResults)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.directions_run, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No available sprints',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All sprints are already linked to this project or create a new one',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (_availableSprints.isEmpty && _showSearchResults)
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
                  'No sprints found',
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
              children: _availableSprints.map((sprint) {
                return _buildAvailableSprintTile(sprint);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedSprintTile(Map<String, dynamic> sprint) {
    final status = sprint['status'] as String?;
    final progress = sprint['progress'] as int? ?? 0;
    
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
            Icons.directions_run,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sprint['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (sprint['description'] != null && 
                    sprint['description'].toString().isNotEmpty)
                  Text(
                    sprint['description'] as String,
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
                        color: _hexToColor(ProjectSprintService.getStatusColor(status))
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _hexToColor(ProjectSprintService.getStatusColor(status))
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        ProjectSprintService.formatSprintStatus(status),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _hexToColor(ProjectSprintService.getStatusColor(status)),
                        ),
                      ),
                    ),
                    if (progress > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _hexToColor(ProjectSprintService.getProgressColor(progress))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _hexToColor(ProjectSprintService.getProgressColor(progress))
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$progress%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _hexToColor(ProjectSprintService.getProgressColor(progress)),
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
              onPressed: () => _removeSelectedSprint(sprint),
              tooltip: 'Remove from selection',
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableSprintTile(Map<String, dynamic> sprint) {
    final isSelected = _selectedIds.contains(sprint['id'] as String);
    final status = sprint['status'] as String?;
    final ticketCount = sprint['ticket_count'] as int? ?? 0;
    
    return InkWell(
      onTap: () => _toggleSelection(sprint),
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
              onChanged: (value) => _toggleSelection(sprint),
              activeColor: Colors.blue.shade600,
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.directions_run,
              color: Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sprint['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? Colors.blue.shade800 : null,
                    ),
                  ),
                  if (sprint['description'] != null && 
                      sprint['description'].toString().isNotEmpty)
                    Text(
                      sprint['description'] as String,
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
                          color: _hexToColor(ProjectSprintService.getStatusColor(status))
                            .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _hexToColor(ProjectSprintService.getStatusColor(status))
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          ProjectSprintService.formatSprintStatus(status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _hexToColor(ProjectSprintService.getStatusColor(status)),
                          ),
                        ),
                      ),
                      if (ticketCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$ticketCount tickets',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                      if (sprint['created_by_name'] != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'by ${sprint['created_by_name']}',
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
