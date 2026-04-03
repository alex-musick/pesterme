import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'debug.dart';

class Settings {
  static int _headsUpTime = 15;
  static int _earliestHour = 8;
  static int _latestHour = 9;

  static Future<void> saveAll() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'settings.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY, headsUpTime INTEGER, earliestHour INTEGER, latestHour INTEGER)'
        );
      },
      version: 1
    );

    await database.insert(
      'settings',
      {
        'id':0, //Deliberately hardcoded, there should only ever be the one row
        'headsUpTime':_headsUpTime,
        'earliestHour':_earliestHour,
        'latestHour':_latestHour
      },
      conflictAlgorithm: ConflictAlgorithm.replace
    );

    await database.close();
  }

    static Future<void> load() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'settings.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY, headsUpTime INTEGER, earliestHour INTEGER, latestHour INTEGER)'
        );
      },
      version: 1
    );

    final List<Map<String, dynamic>> loadedSettingsList = await database.query('schedule');
    final Map<String, dynamic> loadedSettings = loadedSettingsList[0];

    await database.close();

    _headsUpTime = loadedSettings['headsUpTime'];
    _earliestHour = loadedSettings['earliestHour'];
    _latestHour = loadedSettings['latestHour'];

    return;
  }

  static int setheadsUpTime(int newHeadsUpTime) {
    if (newHeadsUpTime > 0 && newHeadsUpTime < 120) {
      _headsUpTime = newHeadsUpTime;
      saveAll();
      return 0;
    } else {
      if (debug) {
        print('DEBUG: Failed to set headsUpTime because it is out of range');
      }
      return 1;
    }
  }

  static int getHeadsUpTime() {
    return _headsUpTime;
  }

  static int setEarliestHour(int newEarliestHour) {
    if (newEarliestHour >= 0 && newEarliestHour < 24) {
      _earliestHour = newEarliestHour;
      saveAll();
      return 0;
    } else {
      if (debug) {
        print('DEBUG: Failed to set earliestHour because it is out of range');
      }
      return 1;
    }
  }

  static int getEarliestHour() {
    return _earliestHour;
  }

  static int setLatestHour(int newLatestHour) {
    if (newLatestHour >= _earliestHour && newLatestHour < 24) {
      _latestHour = newLatestHour;
      saveAll();
      return 0;
    } else {
      if (debug && newLatestHour !>= _earliestHour) {
        print('DEBUG: Failed to set latestHour because it is greater than earliestHour');
      } else if (debug) {
        print('DEBUG: Failed to set latestHour because it is out of range');
      }
      return 1;
    }
  }

  static int getLatestHour() {
    return _latestHour;
  }

}