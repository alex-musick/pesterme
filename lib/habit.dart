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

  void saveAll(Habits habits) async {

    final database = openDatabase(
      join(await getDatabasesPath(), 'habits.db'),
      onCreate: (db, version) {
        'CREATE TABLE habits(id INTEGER PRIMARY KEY, name TEXT, tag TEXT, duration INTEGER, weeklyFreq INTEGER, dailyFreq INTEGER, prefferedDays TEXT, allowedDays TEXT, nextScheduleTime INTEGER)';
      },
      version: 1
    );

    var habitsList = habits.getHabits().values.toList(); //Get the habits from the map

    //Convert each habit to a map and save them to the db
    final db = await database;
    for (int i = 0; i < habitsList.length; i++) {

      var habitMap = habitsList[i].toMap();

      db.insert(
        'habits',
        habitMap,
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }

    return;

  }

}