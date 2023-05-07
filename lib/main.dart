import 'package:always_wake_up/alarm.dart';
import 'package:always_wake_up/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlwaysWakeUp',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Always wake up ! '),
        ),
        body: const HomeBody(),
      ),
    );
  }
}

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final NotificationService notificationService = NotificationService(
    alarms: [
      Alarm(
        id: 1,
        date: DateTime.now().add(const Duration(seconds: 10)),
        message: "Voici une premiere alarme",
        soundPath: "",
        daysToFire: [],
        isActive: true,
      )
    ],
    localNotifInstance: FlutterLocalNotificationsPlugin(),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: notificationService.init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        } else {
          return Container(
            alignment: Alignment.center,
            child: Column(
              children: [
                SimpleButton(
                  title: "Fire one",
                  onPressed: () {
                    notificationService.fire();
                  },
                ),
                SimpleButton(
                  title: "Setup alarms",
                  onPressed: () {
                    notificationService.setUpAlarms();
                  },
                ),
                SimpleButton(
                  title: "Setup alarm for tommorrow",
                  onPressed: () {
                    notificationService.setUpAlarmForTommorrow(8, 30);
                  },
                ),
                SimpleButton(
                  title: "Setup alarm repeatedly",
                  onPressed: () {
                    notificationService.setUpRepeatingAlarm();
                  },
                ),
                SimpleButton(
                  title: "Stop playing sound.",
                  onPressed: () {
                    notificationService.stop();
                  },
                )
              ],
            ),
          );
        }
      },
    );
  }
}

class SimpleButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const SimpleButton({super.key, required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: Text(title));
  }
}
