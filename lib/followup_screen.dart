import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'habit.dart';
import 'history.dart';
import 'eventstore.dart';

/// Screen that displays habits awaiting follow-up (scheduled time has passed).
/// User can mark them as completed or missed.
class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  List<FutureEvent> _events = [];
  Map<int, Habit> _habits = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // Load future events
    final loadedEvents = await FutureEventStore.load();

    // Load habits to get habit names
    final habitStore = HabitStore();
    final habits = await habitStore.load();

    // Filter events: scheduled time has passed and status is not complete/missed
    final now = DateTime.now();
    final filteredEvents = loadedEvents.where((event) {
      return event.time.isBefore(now);
    }).toList();

    setState(() {
      _events = filteredEvents;
      _habits = habits.getHabits();
      _loading = false;
    });
  }

  /// Get future events that are ready for follow-up.
  List<FutureEvent> _getPendingFollowUpEvents() {
    return _events;
  }

  /// Format time for display in the UI.
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// Handle completion of a follow-up.
  Future<void> _handleComplete(FutureEvent event) async {
    if (kDebugMode) {
      debugPrint('DEBUG: calling _handleComplete');
    }
    setState(() {
      _loading = true;
    });

    // Get habit to retrieve habit name
    final habit = _habits[event.habitId];
    final habitName = habit?.name ?? 'Unknown Habit';

    // Create history event with status "complete"
    final historyEvent = HistoryEvent(
      0,
      event.habitId,
      habitName,
      'complete',
      event.time,
    );
    await HistoryStore.save(historyEvent);

    // Delete the future event
    await FutureEventStore().delete(event);

    // Clear follow-up notification ID on the habit
    if (habit != null) {
      habit.followUpNotificationId = null;
      HabitService.update(habit);
    }

    if (mounted) {
      await _loadEvents();
    }
  }

  /// Handle missed follow-up.
  Future<void> _handleMissed(FutureEvent event) async {
    if (kDebugMode) {
      debugPrint('DEBUG: calling _handleMissed');
    }
    setState(() {
      _loading = true;
    });

    // Get habit to retrieve habit name
    final habit = _habits[event.habitId];
    final habitName = habit?.name ?? 'Unknown Habit';

    // Create history event with status "missed"
    final historyEvent = HistoryEvent(
      0,
      event.habitId,
      habitName,
      'missed',
      event.time,
    );
    await HistoryStore.save(historyEvent);

    // Delete the future event
    await FutureEventStore().delete(event);

    // Clear follow-up notification ID on the habit
    if (habit != null) {
      habit.followUpNotificationId = null;
      HabitService.update(habit);
    }

    if (mounted) {
      await _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _events.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Follow-up'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pendingEvents = _getPendingFollowUpEvents();

    if (pendingEvents.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Follow-up'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No habits awaiting follow-up',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Habits will appear here after scheduled time has passed',
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
        title: const Text('Follow-up'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: pendingEvents.length,
        itemBuilder: (context, index) {
          final event = pendingEvents[index];
          final habit = _habits[event.habitId];
          return _buildHabitListItem(event, habit);
        },
      ),
    );
  }

  /// Build a single habit list item with complete/missed buttons.
  Widget _buildHabitListItem(FutureEvent event, Habit? habit) {
    final formattedTime = _formatTime(event.time);
    final habitName = habit?.name ?? 'Unknown Habit';

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
                        habitName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (habit?.tag.isNotEmpty ?? false)
                        Text(
                          habit!.tag,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Complete button (green)
                ElevatedButton(
                  onPressed: () => _handleComplete(event),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Completed'),
                ),
                const SizedBox(width: 8),
                // Missed button (red)
                OutlinedButton(
                  onPressed: () => _handleMissed(event),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Missed'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
