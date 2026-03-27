import 'package:flutter/material.dart';
import 'habit.dart';
import 'history.dart';
import 'calendar.dart';
import 'notification_service.dart';

/// Screen that appears when user taps a notification.
/// Handles both pre-habit and follow-up notification responses.
class ScheduleApprovalScreen extends StatefulWidget {
  final String payload;

  const ScheduleApprovalScreen({
    super.key,
    required this.payload,
  });

  @override
  State<ScheduleApprovalScreen> createState() =>
      _ScheduleApprovalScreenState();
}

class _ScheduleApprovalScreenState
    extends State<ScheduleApprovalScreen> {
  // Keep habitId for potential future use (currently unused)
  late int _notificationId;
  late String _actionType; // 'pre_habit' or 'follow_up'
  late int? _habitId;
  late Habit? _habit;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _parsePayload();
  }

  void _parsePayload() {
    final parts = widget.payload.split('|');
    if (parts.length >= 3) {
      _notificationId = int.tryParse(parts[0]) ?? 0;
      // _habitId = int.tryParse(parts[1]) ?? 0; // Currently unused
      _actionType = parts[2];

      // Parse habitId from notification ID
      // Format: habitId * 1000 + minute (or + 500 for follow-up)
      int notificationIdForHabitId = _actionType == 'pre_habit'
          ? _notificationId
          : _notificationId - 500;
      _habitId = notificationIdForHabitId ~/ 1000;

      // Load habit data
      _loadHabitData();
    }
  }

  Future<void> _loadHabitData() async {
    final habitStore = HabitStore();
    final habits = await habitStore.load();
    final habit = habits.getHabits()[_habitId];

    if (habit != null) {
      setState(() {
        _habit = habit;
        _loading = false;
      });
    }
  }

  Future<void> _handleApproval(bool approved) async {
    setState(() {
      _loading = true;
    });

    if (_habit == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (_actionType == 'pre_habit') {
      if (approved) {
        await handlePreHabitApproval(_habit!);
      } else {
        await handlePreHabitDecline(_habit!);
      }
    } else if (_actionType == 'follow_up') {
      if (approved) {
        await handleFollowUpComplete(_habit!);
      } else {
        await handleFollowUpMissed(_habit!);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _actionType == 'pre_habit' ? 'Schedule Approval' : 'Follow Up',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final habitName = _habit?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _actionType == 'pre_habit' ? 'Schedule Approval' : 'Follow Up',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _actionType == 'pre_habit'
                    ? Icons.access_time
                    : Icons.check_circle,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _actionType == 'pre_habit' ? 'You have free time!' : 'Follow up',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _actionType == 'pre_habit'
                    ? 'Would you like to do $habitName?'
                    : 'Did you $habitName?',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _handleApproval(true),
                    child: const Text('Yes'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => _handleApproval(false),
                    child: const Text('No'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> handlePreHabitApproval(Habit habit) async {
  final calendar = CalendarStore();
  final scheduledTime = habit.nextScheduleTime;

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

  // Schedule follow-up notification
  final notificationService = NotificationService();
  final followUpNotificationId = await notificationService.scheduleFollowUpNotification(
    habitId: habit.id,
    habitName: habit.name,
    scheduledTime: scheduledTime,
    duration: Duration(minutes: habit.duration),
  );

  // Store follow-up notification ID in habit
  habit.followUpNotificationId = followUpNotificationId;

  // Save habit with notification IDs
  await HabitStore().save(habit);
}

Future<void> handlePreHabitDecline(Habit habit) async {
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