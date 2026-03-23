import 'package:device_calendar_plus/device_calendar_plus.dart';

/// Model representing a calendar event created from a habit.
class CalendarEvent {
  String? eventId;
  int habitId;
  String title;
  DateTime startTime;
  DateTime endTime;
  int duration; // Duration in minutes
  String? notes;

  CalendarEvent({
    this.eventId,
    required this.habitId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.duration = 0,
    this.notes,
  });

  Map<String, Object?> toMap() {
    return {
      'eventId': eventId,
      'habitId': habitId,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration,
      'notes': notes,
    };
  }

  factory CalendarEvent.fromMap(Map<String, Object?> map) {
    return CalendarEvent(
      eventId: map['eventId'] as String?,
      habitId: map['habitId'] as int? ?? 0,
      title: map['title'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      duration: map['duration'] as int? ?? 0,
      notes: map['notes'] as String?,
    );
  }
}

/// Store for managing device calendar events.
class CalendarStore {
  static final CalendarStore _instance = CalendarStore._internal();
  factory CalendarStore() => _instance;
  CalendarStore._internal();

  final DeviceCalendar _calendar = DeviceCalendar.instance;
  String? _calendarId;

  /// Request permission to access the device calendar.
  /// Returns a Future that completes when permission is granted or denied.
  Future<bool> requestPermission() async {
    try {
      // Request access to the device calendar
      final permission = await _calendar.requestPermissions();

      if (permission == CalendarPermissionStatus.granted) {
        // Create a PesterMe calendar if it doesn't exist
        await _ensureCalendarExists();
        return true;
      } else {
        return false;
    }} catch (e) {
      return false;
    }
  }

  /// Ensure a "PesterMe" calendar exists after permission is granted.
  Future<void> _ensureCalendarExists() async {
    try {
      final calendars = await _calendar.listCalendars();
      final calendarExists = calendars.any((c) => c.name == 'PesterMe');

      if (!calendarExists) {
        // Create the PesterMe calendar
        final calendarId = await _calendar.createCalendar(
          name: 'PesterMe',
          colorHex: '#1976D2',
        );
        _calendarId = calendarId;
      } else {
        // Get the existing calendar ID
        final calendars = await _calendar.listCalendars();
        final calendar = calendars.firstWhere(
          (c) => c.name == 'PesterMe',
          orElse: () => Calendar(id: '', name: '', readOnly: true),
        );
        _calendarId = calendar.id;
      }
    } catch (e) {
      //PesterMe calendar check/creation failed
    }
  }

  /// Get all calendar events for the next *n* days.
  Future<List<CalendarEvent>> getEvents(int daySpan) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: daySpan));

      final events = await _calendar.listEvents(now, endDate);

      return events.map((e) => CalendarEvent(
        eventId: e.eventId,
        habitId: int.tryParse(e.eventId.split('_').last) ?? 0, //eventId format: *_habitId
        title: e.title,
        startTime: e.startDate,
        endTime: e.endDate,
        duration: e.endDate.difference(e.startDate).inMinutes,
        notes: e.description,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create a new calendar event from a habit.
  Future<bool> createEvent({
    required int habitId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      if (_calendarId == null) {
        return false;
      }

      // Create event using the calendar ID
      final eventId = await _calendar.createEvent(
        calendarId: _calendarId!,
        title: title,
        startDate: startTime,
        endDate: endTime,
        description: notes,
      );

      // Parse the eventId to extract habitId for later reference
      // Format: ${calendarId}_${habitId}_${timestamp}
      final parts = eventId.split('_');
      if (parts.length >= 3) {
        final parsedHabitId = int.tryParse(parts[1]);
        if (parsedHabitId != null && parsedHabitId != habitId) {
          // Event created but with wrong habitId - this shouldn't happen
          // Does nothing for now, error handling can be added if this is a problem
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a calendar event.
  Future<bool> deleteEvent(String eventId) async {
    try {
      if (_calendarId == null) {
        return false;
      }

      await _calendar.deleteEvent(eventId: eventId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update a calendar event.
  Future<bool> updateEvent({
    required String eventId,
    required int habitId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      if (_calendarId == null) {
        return false;
      }

      await _calendar.updateEvent(
        eventId: eventId,
        title: title,
        startDate: startTime,
        endDate: endTime,
        description: notes,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the current calendar ID (or null if permission not granted).
  String? get calendarId => _calendarId;
}
