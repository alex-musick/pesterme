class Habit {
  String name = '';
  String tag = '';

  int duration = 0; //duration in SECONDS
  int weeklyPeriod = 1; //MAX Times per week
  int dailyPeriod = 1; //Times per day. weeklyPeriod overrides this.
  
  List<String> prefferedDays = []; //Valid values: Sun,Mon,Tue,Wed,Thu,Fri,Sat. Days which are preferred for scheduling.
  List<String> alloweddDays = []; //Valid values: Sun,Mon,Tue,Wed,Thu,Fri,Sat. Days which are allowed for scheduling. Weekdays not in this list will never be used for this habit.

  int nextScheduleTime = -1; //Next scheduled time as unix timestamp

}