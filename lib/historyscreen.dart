import 'package:flutter/material.dart';
import 'history.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final events = await HistoryStore.load();
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  /// Format time for display in the UI.
  String _formatTime(DateTime time) {
    // Format: "3:30 PM" or "12:00 PM"
    final formattedTime = time.toString();
    return formattedTime;
  }

  /// Get display color based on status.
  Color _getStatusColor(String status) {
    switch (status) {
      case 'complete':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'missed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get status label text.
  String _getStatusText(String status) {
    switch (status) {
      case 'complete':
        return 'Completed';
      case 'declined':
        return 'Declined';
      case 'missed':
        return 'Missed';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _events.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('History'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_events.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('History'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No history yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your habit history will appear here',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return _buildHistoryItem(event);
        },
      ),
    );
  }

  /// Build a single history list item.
  Widget _buildHistoryItem(HistoryEvent event) {
    final formattedTime = _formatTime(event.time);
    final statusColor = _getStatusColor(event.status);
    final statusText = _getStatusText(event.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.habitName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8.0,
                                  height: 8.0,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedTime,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}