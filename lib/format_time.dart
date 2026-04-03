String formatTime(DateTime time) {
  final int year = time.year;
  final int month = time.month;
  final int day = time.day;
  final int hour = time.hour;
  final int minute = time.minute;
  return '${year}-${month}-${day} ${hour}:${minute}';
  //Flutter complains that these braces are unnecessary, but they seperate the variables from each other for interpretation
}