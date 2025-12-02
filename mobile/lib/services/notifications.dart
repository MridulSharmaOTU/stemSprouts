import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher'); // Notification icon
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await _configureLocalTimeZone();
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    // Extract timezone name
    final timeZoneInfoString = (await FlutterTimezone.getLocalTimezone()).toString();
    final timeZoneName = timeZoneInfoString.split('(')[1].split(',').first;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> scheduleDailyNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Stem Sprouts Reminder',
        'Don\'t forget to get your daily dose of learning in!',
        _nextInstanceOfTenAM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_notification_channel_id',
            'Daily Notifications',
            channelDescription: 'Daily notifications to remind you to study',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  tz.TZDateTime _nextInstanceOfTenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
