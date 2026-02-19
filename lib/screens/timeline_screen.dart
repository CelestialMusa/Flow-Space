import 'package:flutter/material.dart';
import '../models/timeline_event.dart';
import 'add_event_modal.dart';

class TimelineScreen extends StatefulWidget {
  final String? projectId;

  const TimelineScreen({super.key, this.projectId}) : super();

  @override
  TimelineScreenState createState() => TimelineScreenState();
}

class TimelineScreenState extends State<TimelineScreen> {
  List<TimelineEvent> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    // Sample events with proper TimelineEvent constructor
    final sampleEvents = [
      TimelineEvent(
        id: '1',
        title: 'Project Kickoff',
        description: 'Initial project meeting and planning',
        type: TimelineEventType.meeting,
        date: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 31)),
        projectId: widget.projectId,
      ),
      TimelineEvent(
        id: '2',
        title: 'Sprint 1 Start',
        description: 'First sprint begins',
        type: TimelineEventType.milestone,
        date: DateTime.now().subtract(const Duration(days: 20)),
        createdAt: DateTime.now().subtract(const Duration(days: 21)),
        projectId: widget.projectId,
      ),
      TimelineEvent(
        id: '3',
        title: 'Feature Development',
        description: 'Core feature implementation',
        type: TimelineEventType.task,
        date: DateTime.now().subtract(const Duration(days: 15)),
        startTime: DateTime.now().subtract(const Duration(days: 15, hours: 9)),
        endTime: DateTime.now().subtract(const Duration(days: 15, hours: 17)),
        createdAt: DateTime.now().subtract(const Duration(days: 16)),
        projectId: widget.projectId,
      ),
      TimelineEvent(
        id: '4',
        title: 'Code Review',
        description: 'Review and feedback session',
        type: TimelineEventType.review,
        date: DateTime.now().subtract(const Duration(days: 10)),
        startTime: DateTime.now().subtract(const Duration(days: 10, hours: 14)),
        endTime: DateTime.now().subtract(const Duration(days: 10, hours: 15)),
        createdAt: DateTime.now().subtract(const Duration(days: 11)),
        projectId: widget.projectId,
      ),
      TimelineEvent(
        id: '5',
        title: 'Deployment',
        description: 'Deploy to staging environment',
        type: TimelineEventType.deployment,
        date: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        projectId: widget.projectId,
      ),
    ];

    setState(() {
      _events = sampleEvents;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectId != null ? 'Project Timeline' : 'Timeline'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(
                  child: Text(
                    'No events scheduled',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return _buildEventCard(event);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventCard(TimelineEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.typeIcon,
                  color: event.typeColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (event.isCompleted)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  event.formattedDateTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: event.typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.typeDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: event.typeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addEvent() {
    showDialog(
      context: context,
      builder: (context) => AddEventModal(
        projectId: widget.projectId,
        onEventAdded: (event) {
          setState(() {
            _events.add(event);
            _events.sort((a, b) {
              if (a.date == null && b.date == null) return 0;
              if (a.date == null) return 1;
              if (b.date == null) return -1;
              return a.date!.compareTo(b.date!);
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}
