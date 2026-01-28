import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/glass_container.dart';
import '../theme/flownet_theme.dart';
import '../models/timeline_event.dart';

/// Modal for adding new timeline events
class AddEventModal extends StatefulWidget {
  final Function(TimelineEvent) onEventAdded;

  const AddEventModal({
    super.key,
    required this.onEventAdded,
  });

  @override
  State<AddEventModal> createState() => _AddEventModalState();
}

class _AddEventModalState extends State<AddEventModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _projectController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedPriority = 'medium';
  String _selectedColorTag = 'red';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: FlownetColors.crimsonRed,
              onPrimary: FlownetColors.pureWhite,
              surface: FlownetColors.graphiteGray,
              onSurface: FlownetColors.pureWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: FlownetColors.crimsonRed,
              onPrimary: FlownetColors.pureWhite,
              surface: FlownetColors.graphiteGray,
              onSurface: FlownetColors.pureWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final event = TimelineEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        priority: _selectedPriority,
        project: _projectController.text,
        colorTag: _selectedColorTag,
      );
      
      widget.onEventAdded(event);
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event added successfully'),
          backgroundColor: FlownetColors.emeraldGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        child: GlassContainer(
          padding: EdgeInsets.zero,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (fixed)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: FlownetColors.slate.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add New Event',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: FlownetColors.pureWhite,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: FlownetColors.pureWhite),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            labelStyle: const TextStyle(color: FlownetColors.coolGray),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FlownetColors.slate),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FlownetColors.slate),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FlownetColors.crimsonRed, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                          style: const TextStyle(color: FlownetColors.pureWhite),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: const TextStyle(color: FlownetColors.coolGray),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FlownetColors.slate),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FlownetColors.slate),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FlownetColors.crimsonRed, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                          style: const TextStyle(color: FlownetColors.pureWhite),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Date and Time Row
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _selectDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: FlownetColors.slate),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: FlownetColors.crimsonRed, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        DateFormat('MMM d, yyyy').format(_selectedDate),
                                        style: const TextStyle(color: FlownetColors.pureWhite),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _selectTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: FlownetColors.slate),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time, color: FlownetColors.crimsonRed, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedTime.format(context),
                                        style: const TextStyle(color: FlownetColors.pureWhite),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Project
                        TextFormField(
                          controller: _projectController,
                          decoration: InputDecoration(
                            labelText: 'Project',
                            labelStyle: const TextStyle(color: FlownetColors.coolGray),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FlownetColors.slate),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FlownetColors.slate),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: FlownetColors.crimsonRed, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                          style: const TextStyle(color: FlownetColors.pureWhite),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a project name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Priority
                        Text(
                          'Priority',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: FlownetColors.pureWhite,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPriorityChip('low', 'Low'),
                            const SizedBox(width: 8),
                            _buildPriorityChip('medium', 'Medium'),
                            const SizedBox(width: 8),
                            _buildPriorityChip('high', 'High'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Color Tag
                        Text(
                          'Color Tag',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: FlownetColors.pureWhite,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildColorChip('red', FlownetColors.crimsonRed),
                            _buildColorChip('blue', FlownetColors.electricBlue),
                            _buildColorChip('green', FlownetColors.emeraldGreen),
                            _buildColorChip('orange', FlownetColors.amberOrange),
                            _buildColorChip('purple', FlownetColors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions (fixed at bottom)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: FlownetColors.slate.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: FlownetColors.coolGray),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GlassContainer(
                        onTap: _submitForm,
                        borderRadius: 12.0,
                        opacity: 0.20,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: const Text(
                          'Add Event',
                          style: TextStyle(
                            color: FlownetColors.pureWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label) {
    final isSelected = _selectedPriority == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPriority = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? FlownetColors.crimsonRed.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? FlownetColors.crimsonRed : FlownetColors.slate,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? FlownetColors.crimsonRed : FlownetColors.coolGray,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildColorChip(String value, Color color) {
    final isSelected = _selectedColorTag == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedColorTag = value;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 1.0 : 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : FlownetColors.slate,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
