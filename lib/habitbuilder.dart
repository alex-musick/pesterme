import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'habit.dart';

class HabitBuilder extends StatefulWidget {
  const HabitBuilder({super.key});

  @override
  State<HabitBuilder> createState() => _HabitBuilderState();
}

class _HabitBuilderState extends State<HabitBuilder> {
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _durationController = TextEditingController();
  final _weeklyFreqController = TextEditingController();
  final _dailyFreqController = TextEditingController();

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
    return true;
  }

  String _daysToBitString(List<bool> selected) {
    // Black magic: convert list of bools to 7-char string of 0/1
    return selected.map((b) => b ? '1' : '0').join();
  }

  void _createHabit() {
    final name = _nameController.text.trim();
    final tag = _tagController.text.trim();
    final durationMinutes = int.parse(_durationController.text.trim());
    final weeklyFreq = int.parse(_weeklyFreqController.text.trim());
    final dailyFreq = int.parse(_dailyFreqController.text.trim());
    final preferred = _daysToBitString(_preferredSelected);
    final allowed = _daysToBitString(_allowedSelected);

    final habit = Habit(
      name,
      tag,
      durationMinutes * 60, // the user supplies duration in minutes, but it is tracked internally as seconds for easy use with unix timestamps.
      weeklyFreq,
      dailyFreq,
      preferred,
      allowed,
    );

    // Add to the Habits provider
    final habits = Provider.of<Habits>(context, listen: false);
    habits.addHabit(habit);

    // Return to previous screen
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _durationController.dispose();
    _weeklyFreqController.dispose();
    _dailyFreqController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Habit'),
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
                labelText: 'Duration in minutes',
                hintText: 'Duration in minutes',
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
