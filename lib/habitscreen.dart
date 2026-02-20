import 'package:flutter/material.dart';
import 'main.dart';
import 'habitcard.dart';
import 'package:provider/provider.dart';
import 'habit.dart';

class HabitsScreen extends StatelessWidget {
  final VoidCallback? onPlusButtonPressed;

  const HabitsScreen({super.key, this.onPlusButtonPressed});

  @override
  Widget build(BuildContext context) {

    var globalHabits = Provider.of<Habits>(context).getHabits();

    if (globalHabits.isEmpty) {
      return Scaffold(
      
      body: const Center(
        child: Text('Press the + button to get started!'),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: onPlusButtonPressed,
        child: const Icon(Icons.add),
      ),
    );
    }

    List<HabitCard> habitCards = [];
    for (Habit habit in globalHabits.values) {
      var newHabit = HabitCard(habit.name, habit.tag, habit.durationString(), habit.freqString(), habit.nextTime());
      habitCards.add(newHabit);
    }

    return Scaffold(
      
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: habitCards,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: onPlusButtonPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}
