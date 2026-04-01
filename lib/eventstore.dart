import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path/path.dart';

class FutureEvent {
  static int nextId = 0;
  int id = 0;
  int habitId = 0;
  DateTime time = DateTime(0);

  FutureEvent(this.habitId, this.time) {
    id = nextId++;
  }
}

class FutureEventStore {

  static Future<void> save(FutureEvent event) async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'schedule.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE schedule(id INTEGER PRIMARY KEY, habitId INTEGER, time TEXT)'
        );
      },
      version: 1
    );

    await database.insert(
      'schedule',
      {
        'id': event.id,
        'habitId': event.habitId,
        'time': event.time
      },
      conflictAlgorithm: ConflictAlgorithm.replace
    );

    await database.close();
  }

  static Future<List<FutureEvent>> load() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'schedule.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE schedule(id INTEGER PRIMARY KEY, habitId INTEGER, time TEXT)'
        );
      },
      version: 1
    );

    final List<Map<String, dynamic>> futureEvents = await database.query('schedule');

    await database.close();

    int maxId = 0;
    List<FutureEvent> loadedEvents = [];

    for (var eventMap in futureEvents) {
      FutureEvent newEvent = FutureEvent(
        eventMap['habitId'],
        DateTime.parse(eventMap['time'])
      );
      newEvent.id = eventMap['id'];
      loadedEvents.add(newEvent);
      if (eventMap['id'] > maxId) {
        maxId = eventMap['id'];
      }
    }

    FutureEvent.nextId = maxId + 1; //Update static nextId field of FutureEvent class to avoid ID collisions
    return loadedEvents;
  }

  Future<void> delete(FutureEvent event) async {

    final database = await openDatabase(
      join(await getDatabasesPath(), 'schedule.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE schedule(id INTEGER PRIMARY KEY, habitId INTEGER, time TEXT)'
        );
      },
      version: 1
    );

    await database.delete('schedule', where: 'id = ?', whereArgs: [event.id]);
    await database.close();
  }
}