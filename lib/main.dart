import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'habitscreen.dart';
import 'historyscreen.dart';
import 'habitbuilder.dart';
import 'habit.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'scheduler.dart';
import 'notification_service.dart';
import 'calendar.dart';
import 'schedule_approval_screen.dart';
import 'followup_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'settings.dart';
import 'settings_screen.dart';

bool launchedByNotification = false;
//Needs to be global due to async shenanigans
//Also, this being global makes sense anyway

Future<void> main() async {

  if (kDebugMode) {
    debugPrint('<<PESTERME: DEBUGGING FEATURES ENABLED>>');
  }

  WidgetsFlutterBinding.ensureInitialized();
  final habitStore = HabitStore();
  final loadedHabits = await habitStore.load();
  CalendarStore().requestPermission();
  Settings.load();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize workmanager
  await Workmanager().initialize(
    callbackDispatcher,
  );

  // Register workmanager task for background scheduling
  await Workmanager().registerPeriodicTask(
    "schedule_all",
    "schedule_all",
    frequency: Duration(hours: 1), // Hourly
    initialDelay: Duration(minutes: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep
  );

  final NotificationAppLaunchDetails? notificationAppLaunchDetails = await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
  try {
    if (notificationAppLaunchDetails!.didNotificationLaunchApp) {
      launchedByNotification = true;
      if (kDebugMode) {
        debugPrint('DEBUG: App launched by notification');
      }
    }
  } catch(e) {
    if (kDebugMode) {
        debugPrint('DEBUG: Caught notificationAppLaunchDetails error');
      }
  }

  runApp(
    ChangeNotifierProvider<Habits>(
      create: (_) => loadedHabits,
      child: MainApp(),
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
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _currentIndex = launchedByNotification ? 3 : 0;
  List<Widget> get _screens => <Widget>[
    HabitsScreen(onPlusButtonPressed: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HabitBuilder()),
      );
    }),
    HistoryScreen(),
    ScheduleApprovalScreen(),
    FollowUpScreen(),
    SettingsScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _screens.length > 1
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).colorScheme.primaryContainer,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Habits',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: 'Approvals',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle),
                  label: 'Follow-up',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }
}
