import 'dart:collection';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Habit {
  static int nextId = 0;
  int id = -1;

  String name = '';
  String tag = '';

  int duration = -1; //duration in SECONDS
  int weeklyFreq = -1; //MAX Times per week
  int dailyFreq = -1; //Times per day. weeklyPeriod overrides this.
  
  //Two psuedo-bitfields representing weekdays. 0th position is sunday, 6th is saturday.
  //prefferedDays: which days are preffered first for scheduling.
  //allowedDays: which days are strictly and exclusivelly allowed for scheduling.
  //Both are ignored with value '0000000'.
  String prefferedDays = '0000000';
  String allowedDays = '0000000'; 

  int nextScheduleTime = -1; //Next scheduled time as unix timestamp

  Habit(this.name, this.tag, this.duration, this.weeklyFreq, this.dailyFreq, this.prefferedDays, this.allowedDays) {
    id = nextId++;
  }

  Map<String, Object?> toMap() {
    return {
      'id':id,
      'name':name,
      'tag':tag,
      'duration':duration,
      'weeklyFreq': weeklyFreq,
      'dailyFreq': dailyFreq,
      'prefferedDays': prefferedDays,
      'allowedDays': allowedDays
      };
  }

  String durationString() {
    var minutes = (duration / 60).toString();
    return '$minutes minutes';
  }

  String freqString() {
    return '${weeklyFreq}x weekly, ${dailyFreq}x daily';
  }

  String nextTime() { //This is a PLACEHOLDER and will expose the unix timestamp to the user; must be fixed!
    return nextScheduleTime.toString();
  }

}

class Habits extends ChangeNotifier {

  Map<int, Habit> habits = {};

  void addHabit(Habit newHabit) {
    habits[newHabit.id] = newHabit;
    notifyListeners();
  }

  void removeHabit(int id) {
    habits.remove(id);
    notifyListeners();
  }

  Map<int, Habit> getHabits() {
    return habits;
  }

}

class HabitStore {

  Future<void> saveAll(Habits habits) async {

    final database = await openDatabase(
      join(await getDatabasesPath(), 'habits.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE habits(id INTEGER PRIMARY KEY, name TEXT, tag TEXT, duration INTEGER, weeklyFreq INTEGER, dailyFreq INTEGER, prefferedDays TEXT, allowedDays TEXT, nextScheduleTime INTEGER)'
        );
      },
      version: 1
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
          'CREATE TABLE habits(id INTEGER PRIMARY KEY, name TEXT, tag TEXT, duration INTEGER, weeklyFreq INTEGER, dailyFreq INTEGER, prefferedDays TEXT, allowedDays TEXT, nextScheduleTime INTEGER)'
        );
      },
      version: 1
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
          'CREATE TABLE habits(id INTEGER PRIMARY KEY, name TEXT, tag TEXT, duration INTEGER, weeklyFreq INTEGER, dailyFreq INTEGER, prefferedDays TEXT, allowedDays TEXT, nextScheduleTime INTEGER)'
        );
      },
      version: 1
    );

    final List<Map<String, dynamic>> habitMaps = await database.query('habits');

    await database.close();

    Habits loadedHabits = Habits();
    for (var habitMap in habitMaps) {
      Habit habit = Habit(
        habitMap['name'],
        habitMap['tag'],
        habitMap['duration'],
        habitMap['weeklyFreq'],
        habitMap['dailyFreq'],
        habitMap['prefferedDays'],
        habitMap['allowedDays']
      );
      habit.id = habitMap['id'];
      loadedHabits.addHabit(habit);
    }

    return loadedHabits;
  }

  

}