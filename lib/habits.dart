import 'package:flutter/material.dart';

class HabitsScreen extends StatelessWidget {
  final VoidCallback? onPlusButtonPressed;

  const HabitsScreen({super.key, this.onPlusButtonPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Center(
        child: Text(
          'To get started, press the plus button!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: onPlusButtonPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}
