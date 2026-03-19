import 'package:workmanager/workmanager.dart';
import "calendar.dart";
import "dart:async";

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
  return 0;
}