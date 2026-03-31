import 'package:workmanager/workmanager.dart';
import "calendar.dart";
import "dart:async";
import 'habit.dart';
import 'history.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';
import 'debug.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "schedule_all":
        await scheduleAll();
        break;
      case "pre_habit_response":
        await handlePreHabitResponse(
          inputData?['notification_id']?.toString(),
          inputData?['action']?.toString(),
        );
        break;
      case "follow_up_response":
        await handleFollowUpResponse(
          inputData?['notification_id']?.toString(),
          inputData?['action']?.toString(),
        );
        break;
      default:
        // Handle unknown task types
        break;
    }

    return Future.value(true);
  });
}

//PRODUCTION FUNCTION -- Use for release builds
Future<int> scheduleAll() async {

  // if (debug) {
  //   print('DEBUG: Redirecting scheduleAll to scheduleAllDebug');
  //   return scheduleAllDebug();
  // }

  final calendar = CalendarStore(); //This is ugly since we already created one in main, but it works for now

  List<CalendarEvent> calendarEvents = await calendar.getEvents(7);
  List<HistoryEvent> historyEvents = await HistoryStore.load();
  List<DateTime> scheduledTimes = [];

  Map<int, Habit> habits;
  //Try loading from session.
  //If unavailable (e.g. running in background without widget tree), load from storage
  try {
    habits = HabitService.getAll();
  } catch (e) {
    var habitsObject = await HabitStore().load();
    habits = habitsObject.getHabits();
  }

  for (Habit habit in Map.from(habits).values) {
    if (habit.nextScheduleTime != null) {
      scheduledTimes.add(habit.nextScheduleTime!);
      continue;
    } else {
      habit.nextScheduleTime = schedule(habit, calendarEvents, historyEvents, scheduledTimes);
      if (habit.nextScheduleTime != null) {
        scheduledTimes.add(habit.nextScheduleTime!);
        await schedulePreHabitNotification(habit);
        HabitService.update(habit);
        continue;
      }
    }
  }

  return 0;
}

//DEBUG Function -- always schedules only habit[0] for now + 16 mins
Future<int> scheduleAllDebug() async {
  var habitsObject = await HabitStore().load();
  var habits = habitsObject.getHabits();
  Habit? habit;
  for (var loadedHabit in habits.values) {
    habit = loadedHabit;
    break;
  }
  habit!.nextScheduleTime = DateTime.now().add(Duration(minutes: 16));
  await schedulePreHabitNotification(habit);
  HabitService.update(habit);
  return 0;
}

Future<void> schedulePreHabitNotification(Habit habit) async {
  if (habit.nextScheduleTime == null) return;

  final notificationService = NotificationService();
  final notificationId = await notificationService.schedulePreHabitNotification(
    habitId: habit.id,
    habitName: habit.name,
    scheduledTime: habit.nextScheduleTime!,
  );

  // Store notification ID in habit for reference
  habit.notificationId = notificationId;
}

Future<void> handlePreHabitResponse(String? notificationIdStr, String? action) async {
  if (notificationIdStr == null || action == null) return;

  // Parse notification ID to extract habit ID
  // Format: habitId * 1000 + minute
  final notificationId = int.tryParse(notificationIdStr);
  if (notificationId == null) return;

  final habitId = notificationId ~/ 1000;

  final habitStore = HabitStore();
  final habits = await habitStore.load();
  final habit = habits.getHabits()[habitId];

  if (habit == null) return;

  if (action == 'YES') {
    // User approved the habit session
    await handlePreHabitApproval(habit);
  } else {
    // User declined
    await handlePreHabitDecline(habit);
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

Future<void> handleFollowUpResponse(String? notificationIdStr, String? action) async {
  if (notificationIdStr == null || action == null) return;

  // Parse notification ID to extract habit ID
  // Format: habitId * 1000 + minute + 500
  final notificationId = int.tryParse(notificationIdStr);
  if (notificationId == null) return;

  final habitId = (notificationId - 500) ~/ 1000;

  final habitStore = HabitStore();
  final habits = await habitStore.load();
  final habit = habits.getHabits()[habitId];

  if (habit == null) return;

  if (action == 'YES') {
    // User completed the habit
    await handleFollowUpComplete(habit);
  } else {
    // User missed or declined
    await handleFollowUpMissed(habit);
  }
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


DateTime? schedule(Habit habit, List<CalendarEvent> calendarEvents, List<HistoryEvent> historyEvents, List<DateTime> scheduleTimes) {
  DateTime now = DateTime.now();
  List<int> allowedWeekdays = [];
  List<int> preferredWeekdays = [];

  //in habit, [0] = Sunday, [6] = Saturday
  //in DateTime, 1 = Monday, 6 = Saturday, 7 = Sunday.
  for (int i = 1; i <= 6; i++) {
    if (habit.allowedDays[i] == '1') {
      allowedWeekdays.add(i);
    }
    if (habit.prefferedDays[i] == '1') {
      preferredWeekdays.add(i);
    }
  }
  if (habit.allowedDays[0] == '1') {
      allowedWeekdays.add(7);
    }
  if (habit.prefferedDays[0] == '1') {
      preferredWeekdays.add(7);
    }

  //Handle empty preferences
  if (habit.allowedDays == '0000000') {
    allowedWeekdays = [1,2,3,4,5,6,7];
  }
  if (habit.prefferedDays == '0000000') {
    preferredWeekdays = [1,2,3,4,5,6,7];
  }

  if (!_needsScheduled(habit, now, historyEvents)) {
    return null;
  }

  DateTime? preferredTime = _findTime(habit, calendarEvents, scheduleTimes, now, preferredWeekdays);
  //Return the time on a preferred day if found. Else, return the time on an allowed day or null.
  if (preferredTime != null) {
    return preferredTime;
  } else {
    return _findTime(habit, calendarEvents, scheduleTimes, now, allowedWeekdays);
  }

}

DateTime? _findTime(Habit habit, List<CalendarEvent> calendarEvents, List<DateTime> scheduleTimes, DateTime now, List<int> allowedWeekdays) {
  DateTime targetDay = now.subtract(Duration(days: 1));
  DateTime targetTime = DateTime(0);
  bool foundTime = false;

  //This block is really, really inefficient. But n will be really small so it's fine for now.
  //A rewrite would use list lookups instead of iteration.
  while (!foundTime) {

    targetDay = targetDay.add(Duration(days: 1));
    if (targetDay.isAfter(now.add(Duration(days: 7)))) {
      break;
    }

    if (debug) {
      print('DEBUG: _findTime Outer Loop');
      print(targetDay.toIso8601String());
    }

    if (allowedWeekdays.contains(targetDay.weekday)) {
      targetTime = DateUtils.isSameDay(targetDay, now) ? now.add(Duration(minutes: 15)) : DateTime(targetDay.year, targetDay.month, targetDay.day, 8);

     bool foundMinute = false;
     while (!foundMinute) {
      if (debug) {
      print('DEBUG: _findTime foundMinute Loop');
      print(targetTime.toIso8601String());
    }
      //Exit the loop if targetTime is 7 days later.
      //If this happens, the loop has exhausted its possibilities without finding a valid minute.
      if (targetTime.isAfter(now.add(Duration(days: 7)))) {
      break;
    }
      while (true) { //This is very naughty but it's cleaner than making another loop variable
        if (debug) {
          print('DEBUG: _findTime while true loop');
          print(targetTime.toIso8601String());
        }
        bool foundConflict = false;
        for (CalendarEvent event in calendarEvents) {
            //No special handling needed for days without calendar events. The targetTime will just be unchanged.
            //Check if targetTime overlaps with the calendar event
            if (event.startTime.isBefore(targetTime) && !event.endTime.isBefore(targetTime) && !event.endTime.isAtSameMomentAs(targetTime)) {
              if (debug) {
                print('DEBUG: _findTime while true loop event conflict, endtime:');
                print(event.endTime.toIso8601String());
              }
              targetTime = event.endTime;
              foundConflict = true;
              break;
            }
          }
        if (foundConflict) {
          continue;
        } else {
          break;
        }
      }

      // Check for conflicts with already scheduled habits
      bool scheduleConflict = false;
      for (DateTime existingTime in scheduleTimes) {
        // Check if [targetTime, targetTime + duration] overlaps with [existingTime, existingTime + existingDuration]
        // Two intervals overlap if: start1 < end2 AND start2 < end1
        final habitEnd = targetTime.add(Duration(minutes: habit.duration));
        final existingEnd = existingTime.add(Duration(hours: 1));

        if (targetTime.isBefore(existingEnd) && existingTime.isBefore(habitEnd)) {
          scheduleConflict = true;
          break;
        }
      }

      if (scheduleConflict) {
        targetTime = targetTime.add(Duration(hours: 1));
        continue;
      }

      // If we get here, no conflicts were found
      foundMinute = true;
      break;
     }

      if (targetTime.isBefore(now.add(Duration(days: 7))) && foundMinute) {
        foundTime = true;
        break;
      }
      continue;
    }
  }

  return (foundTime && !targetTime.isAtSameMomentAs(DateTime(0)))? targetTime : null;

}

bool _needsScheduled(Habit habit, DateTime now, List<HistoryEvent> historyEvents) {

  if (habit.nextScheduleTime != null) {
    return false;
  }

  DateTime weekStart = now.subtract(Duration(days: now.weekday));
  weekStart = weekStart.subtract(Duration(days: 1));
  DateTime weekEnd = now.add(Duration(days: 7 - now.weekday));
  weekEnd = weekEnd.add(Duration(days: 1));

  int weekCount = 0;
  int dayCount = 0;
  for (HistoryEvent event in historyEvents) {
    if (event.habitId == habit.id && event.time.isAfter(weekStart) && event.time.isBefore(weekEnd) && event.status == 'complete') {
      weekCount++;
    }
    if (event.habitId == habit.id && event.time.day == now.day && event.status == 'complete') {
      dayCount++;
    }
  }

  if (habit.weeklyFreq != -1 && weekCount > habit.weeklyFreq) {
    return false;
  }

  if (habit.dailyFreq != -1 && dayCount > habit.dailyFreq) {
    return false;
  }

  return true;
}

