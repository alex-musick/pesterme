import 'package:flutter/material.dart';
import 'settings.dart';

/// Screen that displays settings for habit scheduling preferences.
/// User can adjust heads-up time and allowed scheduling hours.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _headsUpTime = Settings.getHeadsUpTime();
  int _earliestHour = Settings.getEarliestHour();
  int _latestHour = Settings.getLatestHour();

  // Heads-up time options: 15, 30, 45, ... 120 minutes
  final List<String> _headsUpOptions = List.generate(
    120 ~/ 15 + 1,
    (index) => '${(index + 1) * 15} min',
  );

  // Hour options in 12-hour format
  final List<String> _hourOptions = [
    '12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM', '6 AM', '7 AM', '8 AM', '9 AM', '10 AM', '11 AM',
    '12 PM', '1 PM', '2 PM', '3 PM', '4 PM', '5 PM', '6 PM', '7 PM', '8 PM', '9 PM', '10 PM', '11 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          _buildSettingsSection(
            title: 'Heads-up Time',
            subtitle: 'Minutes before habit session you\'ll receive a reminder',
            child: DropdownButtonFormField<int>(
              initialValue: _headsUpTime,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Heads-up Time',
              ),
              items: _headsUpOptions.map((String value) {
                final minutes = int.parse(value.split(' ')[0]);
                return DropdownMenuItem<int>(
                  value: minutes,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  Settings.setheadsUpTime(newValue);
                  setState(() {
                    _headsUpTime = newValue;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            title: 'Earliest Allowed Hour',
            subtitle: 'Earliest time habits can be scheduled',
            child: DropdownButtonFormField<int>(
              value: _earliestHour,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Earliest Allowed Hour',
              ),
              items: _hourOptions.map((String value) {
                return DropdownMenuItem<int>(
                  value: _get12HourTo24Hour(value),
                  child: Text(value),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  Settings.setEarliestHour(newValue);
                  setState(() {
                    _earliestHour = newValue;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            title: 'Latest Allowed Hour',
            subtitle: 'Latest time habits can be scheduled',
            child: DropdownButtonFormField<int>(
              value: _latestHour,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Latest Allowed Hour',
              ),
              items: _hourOptions.map((String value) {
                return DropdownMenuItem<int>(
                  value: _get12HourTo24Hour(value),
                  child: Text(value),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  Settings.setLatestHour(newValue);
                  setState(() {
                    _latestHour = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build a settings section with title, subtitle, and child widget.
  Widget _buildSettingsSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  /// Convert 12-hour format to 24-hour format.
  int _get12HourTo24Hour(String time12) {
    final parts = time12.split(' ');
    final hour12 = int.parse(parts[0]);
    final amPm = parts[1];

    int hour24;
    if (amPm == 'AM') {
      hour24 = hour12 == 12 ? 0 : hour12;
    } else {
      hour24 = hour12 == 12 ? 12 : hour12 + 12;
    }

    return hour24;
  }
}
