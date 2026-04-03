import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'habit.dart';
import 'history.dart';
import 'calendar.dart';
import 'notification_service.dart';
import 'eventstore.dart';

/// Screen that displays all pending habits requiring approval.
/// This is the Approvals tab screen.
class ScheduleApprovalScreen extends StatefulWidget {
  const ScheduleApprovalScreen({super.key});

  @override
  State<ScheduleApprovalScreen> createState() =>
      _ScheduleApprovalScreenState();
}

class _ScheduleApprovalScreenState
    extends State<ScheduleApprovalScreen> {
  Map<int, Habit> _habits = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habitStore = HabitStore();
    final habits = await habitStore.load();
    setState(() {
      _habits = habits.getHabits();
      _loading = false;
    });
  }

  /// Get habits that have been scheduled but not yet approved/declined.
  List<Habit> _getPendingHabits() {
    return _habits.values.where((h) => h.nextScheduleTime != null).toList();
  }

  /// Format time for display in the UI.
  String _formatTime(DateTime time) {
    return time.toIso8601String();
    //Placeholder, format better later
  }

  /// Handle approval of a pre-habit notification.
  /// After approval, the habit will be added to the calendar and a follow-up
  /// notification will be scheduled.
  Future<void> _handleApproval(Habit habit) async {
    if (kDebugMode) {
      debugPrint('DEBUG: Habit approved');
    }
    setState(() {
      _loading = true;
    });

    if (habit.nextScheduleTime == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    DateTime? scheduleTime = habit.nextScheduleTime;
    habit.nextScheduleTime = null;
    HabitService.update(habit);

    await handlePreHabitApproval(habit, scheduleTime);

    if (mounted) {
      // Refresh the list after approval
      await _loadHabits();
    }
  }

  /// Handle decline of a pre-habit notification.
  /// After decline, a history event with status "declined" will be created.
  Future<void> _handleDecline(Habit habit) async {
    if (kDebugMode) {
      debugPrint('DEBUG: Habit Declined');
    }
    setState(() {
      _loading = true;
    });

    if (habit.nextScheduleTime == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    DateTime? scheduleTime = habit.nextScheduleTime;
    habit.nextScheduleTime = null;
    HabitService.update(habit);

    await handlePreHabitDecline(habit, scheduleTime);

    if (mounted) {
      // Refresh the list after decline
      await _loadHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Approvals'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pendingHabits = _getPendingHabits();

    if (pendingHabits.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Approvals'),
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
                'No habits pending approval',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Habits will appear here once scheduled',
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
        title: const Text('Approvals'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: pendingHabits.length,
        itemBuilder: (context, index) {
          final habit = pendingHabits[index];
          return _buildHabitListItem(habit);
        },
      ),
    );
  }

  /// Build a single habit list item with approve/decline buttons.
  Widget _buildHabitListItem(Habit habit) {
    final scheduledTime = habit.nextScheduleTime;
    final formattedTime = scheduledTime != null ? _formatTime(scheduledTime) : '';

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
                        habit.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (habit.tag.isNotEmpty)
                        Text(
                          habit.tag,
                          style: Theme.of(context).textTheme.bodySmall,
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
            const Divider(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Approve button (green)
                ElevatedButton(
                  onPressed: () => _handleApproval(habit),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 8),
                // Decline button (red)
                OutlinedButton(
                  onPressed: () => _handleDecline(habit),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Decline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> handlePreHabitApproval(Habit habit, DateTime? scheduledTime) async {
  // Cancel the pre-habit notification since the habit is no longer pending
  final notificationService = NotificationService();
  if (scheduledTime != null) {
    await notificationService.cancelPreHabitNotification(
      habitId: habit.id,
      scheduledTime: scheduledTime,
    );
  }
  
  final calendar = CalendarStore();

  if (scheduledTime == null) return;

  // Calculate end time based on duration
  final endTime = scheduledTime.add(Duration(minutes: habit.duration));

  // Create calendar event
  await calendar.createEvent(
    habitId: habit.id,
    title: habit.name,
    startTime: scheduledTime,
    endTime: endTime,
    notes: 'Scheduled habit session',
  );

  //Create FutureEvent
  final FutureEvent futureEvent = FutureEvent(habit.id, scheduledTime);
  FutureEventStore.save(futureEvent);

  // Schedule follow-up notification
  final followUpNotificationId = await notificationService.scheduleFollowUpNotification(
    habitId: habit.id,
    habitName: habit.name,
    scheduledTime: scheduledTime,
    duration: Duration(minutes: habit.duration),
  );

  // Store follow-up notification ID in habit
  habit.followUpNotificationId = followUpNotificationId;

  // Save habit with notification IDs
  HabitService.update(habit);
}

Future<void> handlePreHabitDecline(Habit habit, DateTime? scheduledTime) async {
  // Cancel the pre-habit notification since the habit is no longer pending
  final notificationService = NotificationService();
  if (scheduledTime != null) {
    await notificationService.cancelPreHabitNotification(
      habitId: habit.id,
      scheduledTime: scheduledTime,
    );
  }

  // Create history event with status "declined"
  final historyEvent = HistoryEvent(
    0,
    habit.id,
    habit.name,
    'declined',
    DateTime.now(),
  );
  await HistoryStore.save(historyEvent);
}

Future<void> handleFollowUpComplete(Habit habit) async {
  // Create history event with status "complete"
  final scheduledTime = habit.nextScheduleTime;
  if (scheduledTime == null) return;

  final historyEvent = HistoryEvent(
    0,
    habit.id,
    habit.name,
    'complete',
    scheduledTime,
  );
  await HistoryStore.save(historyEvent);
}

Future<void> handleFollowUpMissed(Habit habit) async {
  // Create history event with status "missed"
  final scheduledTime = habit.nextScheduleTime;
  if (scheduledTime == null) return;

  final historyEvent = HistoryEvent(
    0,
    habit.id,
    habit.name,
    'missed',
    scheduledTime,
  );
  await HistoryStore.save(historyEvent);
}
