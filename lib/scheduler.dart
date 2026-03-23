import 'package:workmanager/workmanager.dart';
import "calendar.dart";
import "dart:async";
import 'habit.dart';

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
  var events = await calendar.getEvents();
  var habits = HabitService.getAll();
  List<DateTime> scheduledTimes;

  return 0;
}

DateTime? schedule(Habit habit, List<CalendarEvent> events, List<DateTime> scheduleTimes) {
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

DateTime? _findTime(Habit habit, List<CalendarEvent> events, List<DateTime> scheduleTimes, DateTime now, List<int> allowedWeekdays) {
  int targetDay = now.weekday;
  if (allowedWeekdays.contains(targetDay)) {
    
  }
}