import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'habit.dart';
import 'scheduler.dart';

class HabitBuilder extends StatefulWidget {
  final Habit? habit;

  const HabitBuilder({super.key, this.habit});

  @override
  State<HabitBuilder> createState() => _HabitBuilderState();
}

class _HabitBuilderState extends State<HabitBuilder> {
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _durationController = TextEditingController();
  final _weeklyFreqController = TextEditingController();
  final _dailyFreqController = TextEditingController();

  // Use the passed habit if provided, otherwise create a default for new habits
  late final Habit _habitController;

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      // Loading existing habit data for editing
      _habitController = widget.habit!;
      _nameController.text = _habitController.name;
      _tagController.text = _habitController.tag;
      _durationController.text = _habitController.duration.toString();
      _weeklyFreqController.text = _habitController.weeklyFreq.toString();
      _dailyFreqController.text = _habitController.dailyFreq.toString();

      // Load day selections from habit
      _loadDaySelections(_habitController.prefferedDays, _preferredSelected);
      _loadDaySelections(_habitController.allowedDays, _allowedSelected);
    } else {
      // Creating new habit
      _habitController = Habit(
        '',
        '',
        0,
        0,
        0,
        '0000000',
        '0000000',
        null,
      );
    }
  }

  void _loadDaySelections(String bitString, List<bool> selected) {
    for (int i = 0; i < 7; i++) {
      selected[i] = bitString[i] == '1';
    }
  }

  static const List<String> _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<bool> _preferredSelected = List.filled(7, false);
  final List<bool> _allowedSelected = List.filled(7, false);

  bool get _isFormValid {
    // All fields except tag must be non-empty and numeric where appropriate.
    if (_nameController.text.trim().isEmpty) return false;
    if (_durationController.text.trim().isEmpty) return false;
    if (_weeklyFreqController.text.trim().isEmpty) return false;
    if (_dailyFreqController.text.trim().isEmpty) return false;
    // Ensure numeric values
    final duration = int.tryParse(_durationController.text.trim());
    final weekly = int.tryParse(_weeklyFreqController.text.trim());
    final daily = int.tryParse(_dailyFreqController.text.trim());
    if (duration == null || weekly == null || daily == null) return false;
    // Verify duration
    if (duration > 60) return false;
    return true;
  }

  String _daysToBitString(List<bool> selected) {
    // Black magic: convert list of bools to 7-char string of 0/1
    return selected.map((b) => b ? '1' : '0').join();
  }

  void _createHabit() {
    // Parse form values
    final name = _nameController.text.trim();
    final tag = _tagController.text.trim();
    final durationMinutes = int.parse(_durationController.text.trim());
    final weeklyFreq = int.parse(_weeklyFreqController.text.trim());
    final dailyFreq = int.parse(_dailyFreqController.text.trim());
    final preferred = _daysToBitString(_preferredSelected);
    final allowed = _daysToBitString(_allowedSelected);

    // Update or create the habit
    if (_habitController.id == -1) {
      // Creating new habit - generate new ID
      _habitController.id = Habit.nextId;
      Habit.nextId++;
    }

    // Update habit with form values
    _habitController.name = name;
    _habitController.tag = tag;
    _habitController.duration = durationMinutes;
    _habitController.weeklyFreq = weeklyFreq;
    _habitController.dailyFreq = dailyFreq;
    _habitController.prefferedDays = preferred;
    _habitController.allowedDays = allowed;

    //Save the habit
    HabitService.update(_habitController);

    if (kDebugMode) {
      debugPrint('DEBUG: calling scheduleAll immediately (not production behavior)');
      scheduleAll();
    }

    // Return to previous screen
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit != null ? 'Edit Habit' : 'Create Habit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isFormValid ? _createHabit : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                hintText: 'Habit Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'Tag',
                hintText: 'Tag',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration in minutes (max 60)',
                hintText: 'Duration in minutes (max 60)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weeklyFreqController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max times per week',
                hintText: 'Max times per week',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dailyFreqController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max times per day',
                hintText: 'Max times per day',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Preferred days', style: TextStyle(fontWeight: FontWeight.bold)),
            Column(
              children: List.generate(7, (index) {
                return CheckboxListTile(
                  title: Text(_dayNames[index]),
                  value: _preferredSelected[index],
                  onChanged: (bool? value) {
                    setState(() {
                      _preferredSelected[index] = value ?? false;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text('Allowed days', style: TextStyle(fontWeight: FontWeight.bold)),
            Column(
              children: List.generate(7, (index) {
                return CheckboxListTile(
                  title: Text(_dayNames[index]),
                  value: _allowedSelected[index],
                  onChanged: (bool? value) {
                    setState(() {
                      _allowedSelected[index] = value ?? false;
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
