import 'package:workmanager/workmanager.dart';
import "calendar.dart";
import "dart:async";
import 'habit.dart';
import 'history.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "schedule_all":
        await scheduleAll();
        break;
      default:
        // Handle unknown task types
        break;
    }
    
    return Future.value(true);
  });
}

Future<int> scheduleAll() async {
  final calendar = CalendarStore(); //This is ugly since we already created one in main, but it works for now
  var calendarEvents = await calendar.getEvents(7);
  var habits = HabitService.getAll();
  var historyEvents = HistoryStore.load();
  List<DateTime> scheduledTimes = [];

  return 0;
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
}

DateTime? _findTime(Habit habit, List<CalendarEvent> calendarEvents, List<DateTime> scheduleTimes, DateTime now, List<int> allowedWeekdays) {
  DateTime targetDay = now.subtract(Duration(days: 1));
  DateTime targetTime = DateTime(0);
  bool foundTime = false;
  
  //This block is really, really inefficient. But n will be really small so it's fine for now.
  //A rewrite would use list lookups instead of iteration.
  while (!foundTime) {

    targetDay.add(Duration(days: 1));
    if (targetDay.isAfter(now.add(Duration(days: 7)))) {
      break;
    }

    if (allowedWeekdays.contains(targetDay.weekday)) {
      targetTime = DateUtils.isSameDay(targetDay, now) ? now.add(Duration(minutes: 15)) : DateTime(targetDay.year, targetDay.month, targetDay.day, 8);

     bool foundMinute = false;
     while (!foundMinute) {
      //Exit the loop if targetTime is 7 days later.
      //If this happens, the loop has exhausted its possibilities without finding a valid minute.
      if (targetTime.isAfter(now.add(Duration(days: 7)))) {
      break;
    }
      for (CalendarEvent event in calendarEvents) {
          //No special handling needed for days without calendar events. The targetTime will just be unchanged.
          //Check if targetTime overlaps with the calendar event
          if (event.startTime.isBefore(targetTime) && !event.endTime.isBefore(targetTime)) {
            targetTime = event.endTime;
            continue;
          }
        }

        for (DateTime habitTime in scheduleTimes) {
          //Check for conflicts with habits that were already scheduled
          if (habitTime.isAfter(targetTime) && !habitTime.add(Duration(minutes: habit.duration)).isAfter(targetTime)) {
            targetTime.add(Duration(hours: 1));
            continue;
          }
        }
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

  return foundTime? targetTime : null;

}

bool _checkIfNeedsScheduled(Habit habit, DateTime now, List<HistoryEvent> historyEvents) {
  
  if (habit.nextScheduleTime != null) {
    return false;
  }
  
  DateTime weekStart = now.subtract(Duration(days: now.weekday));
  weekStart.subtract(Duration(days: 1));
  DateTime weekEnd = now.add(Duration(days: 7 - now.weekday));
  weekEnd.add(Duration(days: 1));

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