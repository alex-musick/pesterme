import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Habit {
  static int nextId = 0;
  int id = -1;

  String name = '';
  String tag = '';

  int duration = -1; //duration in MINUTES
  int weeklyFreq = -1; //MAX Times per week
  int dailyFreq = -1; //Times per day. weeklyPeriod overrides this.

  //Two psuedo-bitfields representing weekdays. 0th position is sunday, 6th is saturday.
  //prefferedDays: which days are preffered first for scheduling.
  //allowedDays: which days are strictly and exclusivelly allowed for scheduling.
  //Both are ignored with value '0000000'.
  String prefferedDays = '0000000';
  String allowedDays = '0000000';

  DateTime? nextScheduleTime; //Next scheduled time as DateTime (ISO 8601 string in DB)

  int? notificationId; //Pre-habit notification ID
  int? followUpNotificationId; //Follow-up notification ID

    Habit(
    this.name,
    this.tag,
    this.duration,
    this.weeklyFreq,
    this.dailyFreq,
    this.prefferedDays,
    this.allowedDays,
    this.nextScheduleTime,
    [this.notificationId,
    this.followUpNotificationId]) : assert(nextScheduleTime != null || (notificationId == null && followUpNotificationId == null)) {
    id = nextId++;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
      'duration': duration,
      'weeklyFreq': weeklyFreq,
      'dailyFreq': dailyFreq,
      'prefferedDays': prefferedDays,
      'allowedDays': allowedDays,
      'nextScheduleTime': nextScheduleTime?.toIso8601String(),
    };
  }

  String durationString() {
    return '$duration minutes';
  }

  String freqString() {
    return '${weeklyFreq}x weekly, ${dailyFreq}x daily';
  }

  String nextTime() {
    if (nextScheduleTime == null) {
      return 'Not scheduled yet';
    }
    return nextScheduleTime.toString();
  }
}

class Habits extends ChangeNotifier {

  Map<int, Habit> habits = {};

  void addHabit(Habit newHabit) {
    habits[newHabit.id] = newHabit;
    Habit.nextId++;
    notifyListeners();
  }

  void removeHabit(int id) {
    habits.remove(id);
    notifyListeners();
  }

  Map<int, Habit> getHabits() {
    return habits;
  }

  void updateHabit(Habit updatedHabit) {
    removeHabit(updatedHabit.id);
    addHabit(updatedHabit);
    HabitStore().save(updatedHabit);
  }

}

class HabitStore {

  Future<void> saveAll(Habits habits) async {

    final database = await openDatabase(
      join(await getDatabasesPath(), 'habits.db'),
      onCreate: (db, version) {
        return db.execute(
         'CREATE TABLE habits(id INTEGER PRIMARY KEY, name TEXT, tag TEXT, duration INTEGER, weeklyFreq INTEGER, dailyFreq INTEGER, prefferedDays TEXT, allowedDays TEXT, nextScheduleTime TEXT, notificationId INTEGER, followUpNotificationId INTEGER)'
        );
      },
      version: 2
    );

    var habitsList = habits.getHabits().values.toList(); //Get the habits from the map

    //Convert each habit to a map and save them to the db
    for (int i = 0; i < habitsList.length; i++) {

      var habitMap = habitsList[i].toMap();

      await database.insert(
        'habits',
        habitMap,
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
    await database.close();
  }

  Future<void> save(Habit habit) async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'habits.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE habits(id INTEGER PRIMARY KEY, name TEXT, tag TEXT, duration INTEGER, weeklyFreq INTEGER, dailyFreq INTEGER, prefferedDays TEXT, allowedDays TEXT, nextScheduleTime TEXT, notificationId INTEGER, followUpNotificationId INTEGER)'
        );
      },
      version: 2
    );

    var habitMap = habit.toMap();

    await database.insert(
      'habits',
      habitMap,
      conflictAlgorithm: ConflictAlgorithm.replace
    );

    await database.close();
  }

  Future<Habits> load() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'habits.db'),
      onCreate: (db, version) {
        return db.execute(
            'CREATE TABLE habits(id INTEGER PRIMARY KEY, name TEXT, tag TEXT, duration INTEGER, weeklyFreq INTEGER, dailyFreq INTEGER, prefferedDays TEXT, allowedDays TEXT, nextScheduleTime TEXT, notificationId INTEGER, followUpNotificationId INTEGER)'
        );
      },
      version: 2
    );

    final List<Map<String, dynamic>> habitMaps = await database.query('habits');

    await database.close();

    int maxId = 0;
    Habits loadedHabits = Habits();
    for (var habitMap in habitMaps) {
      Habit habit = Habit(
        habitMap['name'],
        habitMap['tag'],
        habitMap['duration'],
        habitMap['weeklyFreq'],
        habitMap['dailyFreq'],
        habitMap['prefferedDays'],
        habitMap['allowedDays'],
        habitMap['nextScheduleTime'] != null ? DateTime.parse(habitMap['nextScheduleTime']) : null,
        habitMap['notificationId'] as int?,
        habitMap['followUpNotificationId'] as int?,
      );
      habit.id = habitMap['id'];
      loadedHabits.addHabit(habit);
      if (habit.id > maxId) {
        maxId = habit.id;
      }
    }

    Habit.nextId = maxId + 1; //Update static nextId field of Habit class to avoid ID collisions
    return loadedHabits;
  }

    Future<void> delete(Habit habit) async {

    final database = await openDatabase(
      join(await getDatabasesPath(), 'habits.db'),
      onCreate: (db, version) {
        return db.execute(
         'CREATE TABLE habits(id INTEGER PRIMARY KEY, name TEXT, tag TEXT, duration INTEGER, weeklyFreq INTEGER, dailyFreq INTEGER, prefferedDays TEXT, allowedDays TEXT, nextScheduleTime TEXT, notificationId INTEGER, followUpNotificationId INTEGER)'
        );
      },
      version: 2
    );

    await database.delete('habits', where: 'id = ?', whereArgs: [habit.id]);
    await database.close();
  }
}

class HabitService {
  //Provides a bridge to access the session habits from outside the widget tree.
  static Habits _habits = Habits();

  static void init(BuildContext context) {
    _habits = Provider.of<Habits>(context);
  }

  static Map<int,Habit> getAll() {
    return _habits.getHabits();
  }

  static void update(Habit habit) {
    return _habits.updateHabit(habit);
  }
}