import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'debug.dart';
import 'settings.dart';

/// Notification service for managing habit scheduling notifications.
///
/// This service handles:
/// - Pre-habit notifications (15 minutes before scheduled time)
/// - Follow-up notifications (at habit end time)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Notification channel IDs
  static const String _preHabitChannelId = 'pre_habit_channel';
  static const String _preHabitChannelName = 'Pre-Habit Reminders';

  static const String _followUpChannelId = 'follow_up_channel';
  static const String _followUpChannelName = 'Follow-Up Reminders';

  // Initialization flag
  bool _initialized = false;

  /// Initialize the notification service with proper channels.
  Future<bool?> initialize() async {
    if (_initialized) return true;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize FlutterLocalNotificationsPlugin
    final result = await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    _initialized = true;
    return result;
  }

  /// Schedule a pre-habit notification.
  /// Returns the notification ID.
  Future<int> schedulePreHabitNotification({
    required int habitId,
    required String habitName,
    required DateTime scheduledTime,
  }) async {
    final notificationId = habitId * 1000 + scheduledTime.minute;

    // Schedule notification 15 minutes before using zonedSchedule
    // Convert scheduledTime to TZDateTime for the notification
    final preHabitTime = tz.TZDateTime.from(
      DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        scheduledTime.minute,
      ).subtract(Duration(minutes: Settings.getHeadsUpTime())),
      tz.UTC,
    );

    if (debug) {
      String timeString = preHabitTime.toIso8601String();
      print('DEBUG: Secheduling notification for $timeString');
    }

    // Schedule notification 15 minutes before
    await _notifications.zonedSchedule(
      id: notificationId,
      title: 'You have free time!',
      body: 'Would you like to do $habitName at ${formatTime(scheduledTime)}?',
      scheduledDate: preHabitTime,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _preHabitChannelId,
          _preHabitChannelName,
          importance: Importance.high,
        ),
      ),
      payload: '$notificationId|$habitId|pre_habit',
      androidScheduleMode: AndroidScheduleMode.exact,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    return notificationId;
  }

  /// Schedule a follow-up notification.
  /// Returns the notification ID.
  Future<int> scheduleFollowUpNotification({
    required int habitId,
    required String habitName,
    required DateTime scheduledTime,
    required Duration duration,
  }) async {
    final notificationId = habitId * 1000 + scheduledTime.minute + 500;

    // Schedule follow-up notification at habit end time using zonedSchedule
    final followUpTime = tz.TZDateTime.from(
      scheduledTime.add(duration),
      tz.UTC,
    );

    // Schedule follow-up notification at habit end time
    await _notifications.zonedSchedule(
      id: notificationId,
      title: 'Follow up',
      body: 'Did you $habitName at ${formatTime(scheduledTime)}?',
      scheduledDate: followUpTime,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _followUpChannelId,
          _followUpChannelName,
          importance: Importance.high,
        ),
      ),
      payload: '$notificationId|$habitId|follow_up',
      androidScheduleMode: AndroidScheduleMode.exact,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    return notificationId;
  }

  /// Format time for display.
  String formatTime(DateTime time) {
    final hour = time.hour % 12;
    final displayHour = hour == 0 ? 12 : hour;
    final minute = time.minute;
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$displayHour:${minute.toString().padLeft(2, '0')} $ampm';
  }

  /// Cancel a scheduled notification by its ID.
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  /// Cancel the pre-habit notification for a habit.
  Future<void> cancelPreHabitNotification({
    required int habitId,
    required DateTime scheduledTime,
  }) async {
    if (debug) {
      print('DEBUG: Cancelling pre habit notification');
    }
    final notificationId = habitId * 1000 + scheduledTime.minute;
    await cancelNotification(notificationId);
  }

  /// Cancel the follow-up notification for a habit.
  Future<void> cancelFollowUpNotification({
    required int habitId,
    required DateTime scheduledTime,
  }) async {
    if (debug) {
      print('DEBUG: Cancelling follow up notification');
    }
    final notificationId = habitId * 1000 + scheduledTime.minute + 500;
    await cancelNotification(notificationId);
  }
}