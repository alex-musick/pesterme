class HistoryEvent {
  int habitId = 0;
  String habitName = '';
  String status = 'none';
  //none: don't consider/render. Complete: Completed. Declined: Never scheduled. Missed: Scheduled, but not completed.
  DateTime time = DateTime(0);
}