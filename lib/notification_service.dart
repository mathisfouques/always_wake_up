import 'dart:async';
import 'dart:isolate';

import 'package:always_wake_up/ring_path.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:always_wake_up/alarm.dart';
import 'package:timezone/timezone.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print("Notification tapped in backghround");
}

/// Forks from the main repo to avoid the `Isolate.resolvePackageUri`
///
/// Initialize Time Zone database.
///
/// Throws [TimeZoneInitException] when something is worng.
///
/// ```dart
/// import 'package:timezone/standalone.dart';
///
/// initializeTimeZone().then(() {
///   final detroit = getLocation('America/Detroit');
///   final detroitNow = TZDateTime.now(detroit);
/// });
/// ```
Future<void> _initializeTimeZone([String? path]) {
  path ??= tzDataDefaultPath;

  return Isolate.run(getTimezoneData)
      .then(initializeDatabase)
      .catchError((dynamic e) {
    throw TimeZoneInitException(e.toString());
  });
}

class NotificationService {
  final List<Alarm> alarms;
  final FlutterLocalNotificationsPlugin localNotifInstance;

  NotificationService({
    required this.alarms,
    required this.localNotifInstance,
  });

  Future<void> init() async {
    await _initializeTimeZone()
        .catchError((e, stacktrace) => print("$e stacktrace : $stacktrace"));

    await localNotifInstance.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings("app_icon"),
        iOS: DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: false,
          requestAlertPermission: true,
          onDidReceiveLocalNotification: (id, title, body, payload) {
            print("Received local notif ios ");
          },
        ),
      ),
      onDidReceiveNotificationResponse: (details) {
        print("received notification response");
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  List<Alarm> addAlarm(Alarm alarmToAdd) => alarms..add(alarmToAdd);

  List<Alarm> removeAlarm(Alarm alarmToRemove) =>
      alarms..removeWhere((element) => element.id == alarmToRemove.id);

  void fire() {
    localNotifInstance.show(
      0,
      "Bonjour",
      "Simple alarm",
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentSound: true,
          sound: "${RingPath.loudAlarm}.aiff",
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
    );
  }

  void setUpAlarmForTommorrow(int hourOfDayIn24, int minuteOfDay) {
    final date = DateTime.now();
    final todayAtInformedTime =
        DateTime(date.year, date.month, date.day, hourOfDayIn24, minuteOfDay);
    final tommorrowAtInformedTime =
        DateTime(date.year, date.month, date.day, hourOfDayIn24, minuteOfDay)
            .add(const Duration(days: 1));

    localNotifInstance.zonedSchedule(
      2,
      "Alarme de mon appli less go",
      "Voici un message dans lequel il a fallu extremement reflechir. Je te souhaite un heureux dimanche cher monsieur.",
      TZDateTime.from(
        date.isBefore(todayAtInformedTime)
            ? todayAtInformedTime
            : tommorrowAtInformedTime,
        getLocation("Europe/Paris"),
      ),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentSound: true,
          sound: "${RingPath.loudAlarm}.caf",
          attachments: [],
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void setUpAlarms() async {
    await localNotifInstance.cancelAll();

    for (Alarm alarm in alarms) {
      if (alarm.isActive) {
        localNotifInstance.zonedSchedule(
          alarm.id,
          "Alarme",
          alarm.message,
          TZDateTime.from(DateTime.now().add(const Duration(seconds: 1)),
              getLocation("Europe/Paris")),
          const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentSound: true,
              sound: "${RingPath.loudAlarm}.caf",
              attachments: [],
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }
}
