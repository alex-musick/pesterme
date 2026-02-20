import 'package:flutter/material.dart';

class HabitCard extends StatefulWidget {
  const HabitCard(
    this.habitName,
    this.tag,
    this.duration,
    this.frequency,
    this.next, 
    {super.key}
  );

  final String habitName;
  final String tag;
  final String duration;
  final String frequency;
  final String next;

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  // placeholder values
  String habitName = 'Habit 1';
  String tag = 'Tag';
  String duration = '15 Minutes';
  String frequency = '2x Weekly';
  String next = '5PM Today';

  @override
  void initState() {
    super.initState();
    habitName = widget.habitName;
    tag = widget.tag;
    duration = widget.duration;
    frequency = widget.frequency;
    next = widget.next;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habitName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    tag,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(duration, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4.0),
                Text(frequency, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4.0),
                Text(next, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
