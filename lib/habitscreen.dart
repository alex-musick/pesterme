import 'package:flutter/material.dart';
import 'habitcard.dart';

class HabitsScreen extends StatelessWidget {
  final VoidCallback? onPlusButtonPressed;

  const HabitsScreen({super.key, this.onPlusButtonPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: const [
          HabitCard(),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: onPlusButtonPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}
