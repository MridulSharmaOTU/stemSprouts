import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();
  static const MethodChannel _alarmChannel = MethodChannel('stem_sprouts/alarm_permissions');

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Notification icon
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

  Future<NotificationScheduleResult> scheduleDailyNotification() async {
    bool canUseExactAlarm = await _canUseExactAlarms();

    if (!canUseExactAlarm && Platform.isAndroid) {
      try {
        final bool permissionGranted = await _alarmChannel.invokeMethod<bool>('requestExactAlarmPermission') ?? false;
        if (permissionGranted) {
          canUseExactAlarm = await _canUseExactAlarms();
        }
      } catch (err, stack) {
        debugPrint('Failed to request exact alarm permission: $err');
        debugPrint('$stack');
      }
    }

    final AndroidScheduleMode scheduleMode =
        canUseExactAlarm ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _scheduleNotification(scheduleMode);
      return NotificationScheduleResult(
        scheduled: true,
        requiresUserAction: !canUseExactAlarm,
        message: canUseExactAlarm
            ? 'Daily reminder scheduled successfully.'
            : 'Daily reminder scheduled inexactly. Enable exact alarms for more reliable alerts.',
      );
    } on PlatformException catch (err, stack) {
      debugPrint('Exact alarm scheduling failed, attempting fallback: $err');
      debugPrint('$stack');

      if (canUseExactAlarm) {
        try {
          await _scheduleNotification(AndroidScheduleMode.inexactAllowWhileIdle);
          return NotificationScheduleResult(
            scheduled: true,
            requiresUserAction: true,
            message: 'Exact alarms unavailable. Scheduled an inexact reminder instead.',
          );
        } on PlatformException catch (fallbackErr, fallbackStack) {
          debugPrint('Inexact fallback also failed: $fallbackErr');
          debugPrint('$fallbackStack');
        }
      }

      return NotificationScheduleResult(
        scheduled: false,
        requiresUserAction: true,
        message: 'Unable to schedule reminder. Please enable exact alarms in system settings.',
      );
    }
  }

  Future<void> _scheduleNotification(AndroidScheduleMode androidScheduleMode) async {
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
      androidScheduleMode: androidScheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<bool> _canUseExactAlarms() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final bool? canSchedule = await _alarmChannel.invokeMethod<bool>('canScheduleExactAlarms');
      return canSchedule ?? true;
    } catch (err, stack) {
      debugPrint('Failed to check exact alarm capability: $err');
      debugPrint('$stack');
      return true;
    }
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

class NotificationScheduleResult {
  const NotificationScheduleResult({
    required this.scheduled,
    required this.requiresUserAction,
    this.message,
  });

  final bool scheduled;
  final bool requiresUserAction;
  final String? message;
}
