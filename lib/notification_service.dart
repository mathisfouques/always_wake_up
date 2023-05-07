import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:always_wake_up/ring_path.dart';
import 'package:audioplayers/audioplayers.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  void _startPlayingSound() async {
    if (!_isPlaying) {
      _isPlaying = true;
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource("loud_clock_alarm.aiff"), volume: 1);
    }
  }

  void _stopPlayingSound() async {
    if (_isPlaying) {
      _isPlaying = false;
      await _audioPlayer.stop();
    }
  }

  NotificationService({
    required this.alarms,
    required this.localNotifInstance,
  });

  stop() => _stopPlayingSound();

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
          requestCriticalPermission: true,
          notificationCategories: [
            const DarwinNotificationCategory(
              "bonjour",
              options: {DarwinNotificationCategoryOption.customDismissAction},
            )
          ],
          onDidReceiveLocalNotification: (id, title, body, payload) async {
            print("Did receive local notif");

            _startPlayingSound();
          },
        ),
      ),
      onDidReceiveNotificationResponse: (details) {
        print("received notification response");

        _stopPlayingSound();
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  List<Alarm> addAlarm(Alarm alarmToAdd) => alarms..add(alarmToAdd);

  List<Alarm> removeAlarm(Alarm alarmToRemove) =>
      alarms..removeWhere((element) => element.id == alarmToRemove.id);

  void fire() {
    localNotifInstance.show(
      Random().nextInt(100),
      "Bonjour",
      "Simple alarm",
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentSound: true,
          sound: "${RingPath.loudAlarm}.aiff",
          interruptionLevel: InterruptionLevel.critical,
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
          sound: "${RingPath.loudAlarm}.aiff",
          attachments: [],
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void setUpAlarms() async {
    Future.delayed(const Duration(seconds: 20))
        .then((value) => _startPlayingSound());

    for (int index in List.generate(2, (index) => index)) {
      localNotifInstance
          .zonedSchedule(
            index,
            "Alarme",
            "Bonjour",
            TZDateTime.from(
                DateTime.now().add(Duration(milliseconds: (index + 1) * 7800)),
                getLocation("Europe/Paris")),
            NotificationDetails(
              iOS: DarwinNotificationDetails(
                presentSound: true,
                presentAlert: index == 0,
                sound: "${RingPath.loudAlarm}.aiff",
                interruptionLevel: InterruptionLevel.critical,
                // attachments: [
                //   const DarwinNotificationAttachment("${RingPath.loudAlarm}.aiff"),
                // ],
              ),
            ),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          )
          .then((value) => print("ok"));
    }
  }

  void setUpRepeatingAlarm() {
    localNotifInstance.periodicallyShow(
      Random().nextInt(100),
      "Bonjour ",
      "repeating",
      RepeatInterval.everyMinute,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          sound: "${RingPath.loudAlarm}.aiff",
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
    );
  }
}
