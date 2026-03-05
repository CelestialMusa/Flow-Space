import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../models/release_readiness.dart';
import '../models/dod_item.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../widgets/ai_readiness_gate_widget.dart';
import '../services/deliverable_service.dart';
import '../services/backend_api_service.dart';
import '../services/api_client.dart';
import '../config/environment.dart';

// Enhanced deliverable setup screen with AI readiness gates

class EnhancedDeliverableSetupScreen extends ConsumerStatefulWidget {
  const EnhancedDeliverableSetupScreen({super.key});

  @override
  ConsumerState<EnhancedDeliverableSetupScreen> createState() => _EnhancedDeliverableSetupScreenState();
}

class _EnhancedDeliverableSetupScreenState extends ConsumerState<EnhancedDeliverableSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _evidenceController = TextEditingController();
  
  DateTime? _dueDate;
  final List<String> _selectedSprints = [];
  final List<DoDItem> _definitionOfDone = [];
  final List<String> _evidenceLinks = [];
  final List<PlatformFile> _attachedFiles = [];
  final List<ReadinessItem> _readinessItems = [];
  final DeliverableService _deliverableService = DeliverableService();
  final ApiClient _apiClient = ApiClient();
  ReadinessStatus _currentReadinessStatus = ReadinessStatus.red;
  bool _hasInternalApproval = false;
  List<Map<String, dynamic>> _availableSprints = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _projects = [];
  String? _ownerId;
  String? _selectedProjectId;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    try {
      final ri = GoRouter.of(context).routeInformationProvider.value;
      final Uri uri = ri.uri;
      final sprintId = uri.queryParameters['sprintId'];
      final projectId = uri.queryParameters['projectId'];
      if (sprintId != null && sprintId.isNotEmpty && !_selectedSprints.contains(sprintId)) {
        _selectedSprints.add(sprintId);
      }
      if (projectId != null && projectId.isNotEmpty) {
        _selectedProjectId = projectId;
      }
    } catch (_) {}
    _initializeReadinessItems();
    _loadSprints();
    _loadUsers();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final backendApiService = BackendApiService();
      final response = await backendApiService.getProjects();
      
      if (response.isSuccess && response.data != null) {
        List<dynamic> projectsList = [];
        if (response.data is List) {
          projectsList = response.data as List;
        } else if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          projectsList = data['data'] as List? ?? data['projects'] as List? ?? [];
        }
        
        setState(() {
          _projects = projectsList
              .where((p) => p != null)
              .map((p) => p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{})
              .where((m) => m.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading projects: $e');
    }
  }

  void _initializeReadinessItems() {
    _readinessItems.addAll([
      const ReadinessItem(
        id: 'dod-complete',
        category: 'Definition of Done',
        description: 'All DoD items are completed',
        isRequired: true,
        isCompleted: false,
      ),
      const ReadinessItem(
        id: 'evidence-attached',
        category: 'Evidence',
        description: 'Demo links, repos, and test summaries are attached',
        isRequired: true,
        isCompleted: false,
      ),
      const ReadinessItem(
        id: 'sprint-metrics',
        category: 'Sprint Performance',
        description: 'Sprint metrics are captured and reviewed',
        isRequired: true,
        isCompleted: false,
      ),
      const ReadinessItem(
        id: 'quality-gates',
        category: 'Quality Gates',
        description: 'Test pass rate > 90% and critical defects resolved',
        isRequired: true,
        isCompleted: false,
      ),
      const ReadinessItem(
        id: 'documentation',
        category: 'Documentation',
        description: 'User guides and technical documentation are complete',
        isRequired: false,
        isCompleted: false,
      ),
    ]);
  }

  Future<void> _loadUsers() async {
    try {
      final backendApiService = BackendApiService();
      final response = await backendApiService.getUsers(limit: 100);
      
      if (response.isSuccess && response.data != null) {
        List<dynamic> usersList = [];
        if (response.data is List) {
          usersList = response.data as List;
        } else if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          usersList = data['data'] as List? ?? data['users'] as List? ?? [];
        }
        
        setState(() {
          _users = usersList
              .where((u) => u != null)
              .map((u) => u is Map ? Map<String, dynamic>.from(u) : <String, dynamic>{})
              .where((m) => m.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  Future<void> _loadSprints() async {
    try {
      final response = await BackendApiService().getSprints();
      if (response.isSuccess && response.data != null) {
        List<dynamic> sprintsList = [];
        if (response.data is List) {
          sprintsList = response.data as List;
        } else if (response.data is Map) {
          final data = Map<String, dynamic>.from(response.data as Map);
          sprintsList = data['data'] as List? ?? data['sprints'] as List? ?? [];
        }
        setState(() {
          _availableSprints = sprintsList
              .where((s) => s != null)
              .map((s) => s is Map<String, dynamic> ? s : Map<String, dynamic>.from(s as Map))
              .where((m) => m.isNotEmpty)
              .toList();
        });
      } else {
        setState(() {
          _availableSprints = [];
        });
      }
    } catch (_) {
      setState(() {
        _availableSprints = [];
      });
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  void _addDoDItem() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text('Add Definition of Done Item'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter DoD item...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _definitionOfDone.add(DoDItem(text: controller.text));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addEvidenceLink() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text('Add Evidence Link'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter evidence URL...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _evidenceLinks.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> get dodCards {
    if (_definitionOfDone.isEmpty) {
      return [
        const Card(
          color: FlownetColors.graphiteGray,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No Definition of Done items added'),
          ),
        ),
      ];
    }
    return _definitionOfDone.map((item) {
      return Card(
        color: FlownetColors.graphiteGray,
        child: CheckboxListTile(
          value: item.isCompleted,
          title: Text(item.text, style: const TextStyle(color: FlownetColors.pureWhite)),
          checkColor: FlownetColors.charcoalBlack,
          activeColor: FlownetColors.electricBlue,
          onChanged: (bool? value) {
            setState(() {
              final index = _definitionOfDone.indexOf(item);
              if (index != -1) {
                _definitionOfDone[index] = DoDItem(text: item.text, isCompleted: value ?? false);
              }
            });
          },
          secondary: IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                _definitionOfDone.remove(item);
              });
            },
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      );
    }).toList();
  }

  List<Widget> get evidenceCards {
    final List<Widget> cards = [];
    
    if (_evidenceLinks.isEmpty && _attachedFiles.isEmpty) {
      cards.add(const Card(
        color: FlownetColors.graphiteGray,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No evidence links or files added'),
        ),
      ));
    } else {
      cards.addAll(_evidenceLinks.map((url) {
        return Card(
          color: FlownetColors.graphiteGray,
          child: ListTile(
            leading: const Icon(Icons.link, color: Colors.blue),
            title: Text(url),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _evidenceLinks.remove(url);
                });
              },
            ),
          ),
        );
      }));
      
      cards.addAll(_attachedFiles.map((file) {
        return Card(
          color: FlownetColors.graphiteGray,
          child: ListTile(
            leading: const Icon(Icons.attach_file, color: Colors.orange),
            title: Text(file.name),
            subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _attachedFiles.remove(file);
                });
              },
            ),
          ),
        );
      }));
    }
    return cards;
  }


  Future<void> _addDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _requestInternalApproval(String comment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Request Internal Approval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You are requesting internal approval to proceed despite readiness issues. '
              'An internal approver will review and decide whether to allow submission.',
            ),
            const SizedBox(height: 16),
            Text(
              comment,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Request Approval'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      setState(() {
        _hasInternalApproval = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internal approval requested. You can now proceed with submission.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<List<String>> _uploadFiles() async {
    final List<String> uploadedUrls = [];
    if (_attachedFiles.isEmpty) return uploadedUrls;

    for (var file in _attachedFiles) {
      if (file.path == null && file.bytes == null) continue;
      
      try {
        // Upload to /files/upload
        final response = await _apiClient.uploadFile(
          '/files/upload', 
          file.path ?? '', 
          file.name, 
          'application/octet-stream', // Or determine mime type
          fields: {
            'prefix': 'deliverables',
          },
          fileBytes: file.bytes,
        );
        
        if (response.isSuccess && response.data != null) {
          // Parse response to get URL
          // The backend returns uploadResult which usually has filename or url
          final data = response.data;
          String? url;
          if (data is Map) {
              url = data['url']?.toString() ?? data['location']?.toString() ?? data['filename']?.toString();
              // Construct full URL if it's just a filename
              if (url != null && !url.startsWith('http')) {
                 // Assuming uploads are served from /uploads
                 // Strip /api/v1 from base url
                 final baseUrl = Environment.apiBaseUrl.replaceAll('/api/v1', '');
                 url = '$baseUrl/uploads/$url';
              }
           }
          
          if (url != null) {
            uploadedUrls.add(url);
          }
        }
      } catch (e) {
        debugPrint('Error uploading file ${file.name}: $e');
      }
    }
    return uploadedUrls;
  }

  Future<void> _submitDeliverable() async {
    // Validate form first - check if form key is initialized
    if (_formKey.currentState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Form not initialized. Please refresh the page.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Additional validation: title must not be empty or just whitespace
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Title cannot be empty'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      // Focus on title field
      FocusScope.of(context).requestFocus(FocusNode());
      return;
    }

    // Additional validation: description must not be empty or just whitespace
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Description cannot be empty'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if blocked by readiness gate
    if (_currentReadinessStatus == ReadinessStatus.red && !_hasInternalApproval) {
      _showReadinessDialog();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Use trimmed values
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      debugPrint('📦 Creating deliverable: $title');
      
      // Final validation before API call
      if (title.isEmpty) {
        throw Exception('Title cannot be empty');
      }
      if (description.isEmpty) {
        throw Exception('Description cannot be empty');
      }
      
      // Convert arrays to JSON strings for backend
      // Send definition_of_done as a JSON array (not a joined string)
      // The backend expects JSON format for the JSON column
      
      // Upload files first
      final uploadedUrls = await _uploadFiles();
      final allEvidenceLinks = [..._evidenceLinks, ...uploadedUrls];
      
      // Use DeliverableService to create deliverable
      final response = await _deliverableService.createDeliverable(
        title: title,
        description: description.isEmpty ? null : description,
        definitionOfDone: _definitionOfDone.isEmpty ? null : _definitionOfDone,
        priority: 'Medium',
        status: 'Draft',
        dueDate: _dueDate,
        sprintIds: _selectedSprints,
        evidenceLinks: allEvidenceLinks,
        ownerId: _ownerId,
        projectId: _selectedProjectId,
      );
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        if (response.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Deliverable "$title" created successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Navigate to dashboard instead of popping (safer)
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.go('/dashboard');
              }
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to create deliverable: ${response.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating deliverable: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating deliverable: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showReadinessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: const Text('Release Readiness Check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The deliverable is not ready for submission. Please complete the required items:'),
            const SizedBox(height: 16),
            ..._readinessItems.where((item) => item.isRequired && !item.isCompleted).map(
              (item) => ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(item.description),
                subtitle: Text(item.category),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        title: const FlownetLogo(showText: true),
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Deliverable',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: FlownetColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Contributing Sprints moved to bottom


              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Deliverable Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                onChanged: (value) {
                  // Trigger rebuild so AI widget can analyze
                  setState(() {});
                  // Trigger AI analysis when title changes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && value.trim().isNotEmpty) {
                      setState(() {}); // Force widget rebuild to trigger AI analysis
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                onChanged: (value) {
                  debugPrint('📝 Title changed to: "$value"');
                  // Trigger rebuild so AI widget can analyze
                  setState(() {
                    // Force rebuild with new key
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String?>(
                // ignore: deprecated_member_use
                value: _users.any((u) => u['id']?.toString() == _ownerId) ? _ownerId : null,
                decoration: const InputDecoration(
                  labelText: 'Owner',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  helperText: 'Select the team member responsible for this deliverable',
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(_users.isEmpty ? 'Unassigned (Loading...)' : 'Unassigned'),
                  ),
                  ..._users.map((user) {
                    String name = user['name'] ?? '';
                    if (name.isEmpty) {
                      final first = user['first_name'] ?? user['firstName'] ?? '';
                      final last = user['last_name'] ?? user['lastName'] ?? '';
                      if (first.isNotEmpty || last.isNotEmpty) {
                        name = '$first $last'.trim();
                      }
                    }
                    if (name.isEmpty) {
                      name = user['email'] ?? 'Unknown';
                    }
                    
                    final role = user['role']?.toString() ?? '';
                    if (role.isNotEmpty) {
                      name = '$name ($role)';
                    }
                    
                    return DropdownMenuItem<String?>(
                      value: user['id'].toString(),
                      child: Text(name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _ownerId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String?>(
                // ignore: deprecated_member_use
                value: _projects.any((p) => p['id']?.toString() == _selectedProjectId) ? _selectedProjectId : null,
                decoration: const InputDecoration(
                  labelText: 'Assign Project *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                  helperText: 'Select the project this deliverable belongs to',
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(_projects.isEmpty ? 'No projects available' : 'Select Project'),
                  ),
                  ..._projects.map((project) {
                    final name = project['name'] ?? project['key'] ?? 'Unknown Project';
                    return DropdownMenuItem<String?>(
                      value: project['id'].toString(),
                      child: Text(name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProjectId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please assign a project';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDate != null
                        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                        : 'Select due date',
                  ),
                ),
              ),
              const SizedBox(height: 24),


              _buildSectionHeader('Definition of Done'),
              const SizedBox(height: 16),
              ...dodCards,
              ElevatedButton.icon(
                onPressed: _addDoDItem,
                icon: const Icon(Icons.add),
                label: const Text('Add DoD Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlownetColors.electricBlue,
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('Evidence & Artifacts'),
              const SizedBox(height: 16),
              ...evidenceCards,
              ElevatedButton.icon(
                onPressed: _addEvidenceLink,
                icon: const Icon(Icons.add),
                label: const Text('Add Evidence Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlownetColors.electricBlue,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlownetColors.electricBlue,
                ),
              ),
              const SizedBox(height: 24),

              // Contributing Sprints (Moved from top)
              _buildSectionHeader('Contributing Sprints'),
              const SizedBox(height: 16),
              Card(
                color: FlownetColors.graphiteGray,
                child: ExpansionTile(
                  title: Text(
                    'Select Sprints (${_selectedSprints.length} selected)',
                    style: const TextStyle(color: FlownetColors.pureWhite),
                  ),
                  iconColor: FlownetColors.electricBlue,
                  collapsedIconColor: FlownetColors.pureWhite,
                  children: _availableSprints.map((sprint) {
                    final idStr = (sprint['id'] ?? '').toString();
                    final isSelected = _selectedSprints.contains(idStr);
                    return CheckboxListTile(
                      title: Text(sprint['name']?.toString() ?? '', style: const TextStyle(color: FlownetColors.pureWhite)),
                      subtitle: Text('${sprint['start_date']} - ${sprint['end_date']}', style: const TextStyle(color: Colors.grey)),
                      value: isSelected,
                      checkColor: FlownetColors.charcoalBlack,
                      activeColor: FlownetColors.electricBlue,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            if (!_selectedSprints.contains(idStr)) {
                              _selectedSprints.add(idStr);
                            }
                          } else {
                            _selectedSprints.remove(idStr);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // AI-Powered Release Readiness Gate
              _buildSectionHeader('AI Release Readiness Gate'),
              const SizedBox(height: 16),
              
              Builder(
                builder: (context) {
                  debugPrint('📋 Creating AIReadinessGateWidget with title: "${_titleController.text}"');
                  return AIReadinessGateWidget(
                key: ValueKey('ai-gate-${_titleController.text}-${_definitionOfDone.length}-${_evidenceLinks.length}'),
                deliverableId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                deliverableTitle: _titleController.text,
                deliverableDescription: _descriptionController.text,
                definitionOfDone: _definitionOfDone.map((e) => e.text).toList(),
                evidenceLinks: _evidenceLinks,
                sprintIds: _selectedSprints,
                knownLimitations: null,
                onStatusChanged: (status) {
                  setState(() {
                    _currentReadinessStatus = status;
                  });
                },
                onInternalApprovalRequested: (comment) {
                  _requestInternalApproval(comment);
                },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || (_currentReadinessStatus == ReadinessStatus.red && !_hasInternalApproval)) 
                      ? null 
                      : _submitDeliverable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentReadinessStatus == ReadinessStatus.green 
                        ? Colors.green 
                        : _currentReadinessStatus == ReadinessStatus.amber 
                            ? Colors.orange 
                            : _hasInternalApproval
                                ? Colors.blue
                                : Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentReadinessStatus == ReadinessStatus.green 
                              ? 'Create Deliverable' 
                              : _currentReadinessStatus == ReadinessStatus.amber 
                                  ? 'Create with Acknowledged Issues' 
                                  : _hasInternalApproval
                                      ? 'Create with Internal Approval'
                                      : 'Complete Required Items First',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: FlownetColors.pureWhite,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }
}
