import 'package:flutter/material.dart';
import '../models/deliverable.dart';
import '../services/deliverable_service.dart';
import '../theme/flownet_theme.dart';

class DeliverableDetailScreen extends StatefulWidget {
  final Deliverable deliverable;

  const DeliverableDetailScreen({super.key, required this.deliverable});

  @override
  State<DeliverableDetailScreen> createState() => _DeliverableDetailScreenState();
}

class _DeliverableDetailScreenState extends State<DeliverableDetailScreen> {
  late List<DoDItem> _definitionOfDone;
  late TextEditingController _descriptionController;
  late TextEditingController _evidenceLinksController;
  final DeliverableService _deliverableService = DeliverableService();
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _definitionOfDone = widget.deliverable.definitionOfDone.map((e) => DoDItem(text: e.text, isCompleted: e.isCompleted)).toList();
    _descriptionController = TextEditingController(text: widget.deliverable.description);
    _evidenceLinksController = TextEditingController(text: widget.deliverable.evidenceLinks.join(', '));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _evidenceLinksController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final evidenceLinks = _evidenceLinksController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final response = await _deliverableService.updateDeliverable(
        id: widget.deliverable.id,
        definitionOfDone: _definitionOfDone,
        description: _descriptionController.text,
        evidenceLinks: evidenceLinks,
      );
      if (response.isSuccess) {
        if (mounted) {
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes saved successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.error ?? "Unknown error"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.background,
      appBar: AppBar(
        title: Text(widget.deliverable.title, style: const TextStyle(color: FlownetColors.pureWhite)),
        backgroundColor: FlownetColors.background,
        iconTheme: const IconThemeData(color: FlownetColors.pureWhite),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
            tooltip: _isEditing ? 'View Mode' : 'Edit Mode',
          ),
          IconButton(
            icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: FlownetColors.pureWhite))
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            _buildInfoRow('Status', widget.deliverable.status.name),
            _buildInfoRow('Priority', widget.deliverable.priority),
            if (widget.deliverable.assignedTo != null)
              _buildInfoRow('Assigned To', widget.deliverable.assignedTo!),
            const SizedBox(height: 24),

            // Description
            Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: FlownetColors.electricBlue)),
            const SizedBox(height: 8),
            _isEditing
                ? TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: FlownetColors.pureWhite, fontSize: 16),
                    maxLines: null,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: FlownetColors.graphiteGray,
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.electricBlue)),
                    ),
                  )
                : Text(
                    _descriptionController.text,
                    style: const TextStyle(color: FlownetColors.pureWhite, fontSize: 16),
                  ),
            const SizedBox(height: 24),

            // Definition of Done Checklist
            Text('Definition of Done (Checklist)', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: FlownetColors.electricBlue)),
            const SizedBox(height: 8),
            if (_definitionOfDone.isEmpty)
              const Text('No Definition of Done items.', style: TextStyle(color: Colors.grey))
            else
              Card(
                color: FlownetColors.graphiteGray,
                child: Column(
                  children: _definitionOfDone.map((item) {
                    return CheckboxListTile(
                      title: Text(item.text, style: const TextStyle(color: FlownetColors.pureWhite)),
                      value: item.isCompleted,
                      checkColor: FlownetColors.charcoalBlack,
                      activeColor: FlownetColors.electricBlue,
                      onChanged: (val) {
                        setState(() {
                          final index = _definitionOfDone.indexOf(item);
                          _definitionOfDone[index] = DoDItem(text: item.text, isCompleted: val ?? false);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            
            const SizedBox(height: 24),
            // Evidence Links
            if (_isEditing || _evidenceLinksController.text.isNotEmpty) ...[
               Text('Evidence Links', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: FlownetColors.electricBlue)),
               const SizedBox(height: 8),
               if (_isEditing)
                 TextFormField(
                    controller: _evidenceLinksController,
                    style: const TextStyle(color: FlownetColors.pureWhite, fontSize: 16),
                    maxLines: null,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: FlownetColors.graphiteGray,
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: FlownetColors.electricBlue)),
                      hintText: 'Comma separated links',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  )
               else
                 ..._evidenceLinksController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).map((link) => Padding(
                   padding: const EdgeInsets.symmetric(vertical: 4),
                   child: Row(
                     children: [
                       const Icon(Icons.link, color: FlownetColors.electricBlue, size: 16),
                       const SizedBox(width: 8),
                       Expanded(child: Text(link, style: const TextStyle(color: FlownetColors.pureWhite))),
                     ],
                   ),
                 )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: FlownetColors.pureWhite),
            ),
          ),
        ],
      ),
    );
  }
}
