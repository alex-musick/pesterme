import 'package:flutter/material.dart';
import 'habitscreen.dart';
import 'historyscreen.dart';
import 'habitbuilder.dart';
import 'habit.dart';
import 'calendar.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final calendarStore = CalendarStore();
  await calendarStore.requestPermission();
  final habitStore = HabitStore();
  final loadedHabits = await habitStore.load();

  runApp(
    ChangeNotifierProvider<Habits>(
      create: (_) => loadedHabits,
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    HabitService.init(context);
    return MaterialApp(
      home: _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage({super.key});

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _currentIndex = 0;
  List<Widget> get _screens => <Widget>[
    HabitsScreen(onPlusButtonPressed: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HabitBuilder()),
      );
    }),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _screens.length > 1
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Habits',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
              ],
            )
          : null,
    );
  }
}
