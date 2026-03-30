import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path/path.dart';

class HistoryEvent {
  static int nextId = 0;
  int id = 0;
  int habitId = 0;
  String habitName = '';
  String status = 'none';
  //none: don't consider/render. complete: Completed. declined: Never scheduled. missed: Scheduled, but not completed.
  DateTime time = DateTime(0);

  Map<String, Object?> toMap() {
    return {
      "id":id,
      "habitid": habitId,
      "habitname": habitName,
      "status": status,
      'time': time.toIso8601String()
    };
  }

  HistoryEvent(int id, int habitId, String habitName, String status, DateTime time) {
    nextId++;
  }
}

class HistoryStore {

  static Future<void> saveAll(List<HistoryEvent> events) async {

    final database = await openDatabase(
      join(await getDatabasesPath(), 'history.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE history(id INTEGER PRIMARY KEY, habitid INTEGER, habitname TEXT, status TEXT, time TEXT)'
        );
      },
      version: 1
    );

    //Convert each habit to a map and save them to the db
    for (int i = 0; i < events.length; i++) {

      var eventMap = events[i].toMap();

      await database.insert(
        'history',
        eventMap,
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
    await database.close();
  }

  static Future<void> save(HistoryEvent event) async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'history.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE history(id INTEGER PRIMARY KEY, habitid INTEGER, habitname TEXT, status TEXT, time TEXT)'
        );
      },
      version: 1
    );

    var eventMap = event.toMap();

    await database.insert(
      'history',
      eventMap,
      conflictAlgorithm: ConflictAlgorithm.replace
    );

    await database.close();
  }

  static Future<List<HistoryEvent>> load() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'history.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE history(id INTEGER PRIMARY KEY, habitid INTEGER, habitname TEXT, status TEXT, time TEXT)'
        );
      },
      version: 1
    );

    final List<Map<String, dynamic>> eventMaps = await database.query('history');

    await database.close();

    int maxId = 0;
    List<HistoryEvent> loadedEvents = [];
    for (var eventMap in eventMaps) {
      HistoryEvent event = HistoryEvent(
        eventMap['id'],
        eventMap['habitid'],
        eventMap['habitname'],
        eventMap['status'],
        DateTime.parse(eventMap['time'])
      );
      event.id = eventMap['id'];
      loadedEvents.add(event);
      if (event.id > maxId) {
        maxId = event.id;
      }
    }

    HistoryEvent.nextId = maxId + 1; //Update static nextId field of HistoryEvent class to avoid ID collisions
    return loadedEvents;
  }
}