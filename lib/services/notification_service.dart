import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  final Set<int> _scheduledNoteIds = {};

  static const String meowChannelId = 'student_pal_meow_v1';
  static const String meowChannelName = 'Student Pal Alerts';
  static const String meowSoundName = 'meow';

  bool _checkInitialized() {
    if (!_isInitialized) {
      debugPrint('[NotificationService] Not initialized — skipping.');
      return false;
    }
    return true;
  }

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName.toString()));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          meowChannelId,
          meowChannelName,
          description: 'Student Pal class and assignment alerts',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(meowSoundName),
          enableVibration: true,
          enableLights: true,
          showBadge: true,
          bypassDnd: true,
        ),
      );

      await androidPlugin?.requestExactAlarmsPermission();
    }

    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (!_checkInitialized()) return;
    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> scheduleClassAlerts({
    required int id,
    required String subject,
    required DateTime startTime,
  }) async {
    if (!_checkInitialized()) return;
    await _notifications.cancel(id: id * 10);
    await _notifications.cancel(id: id * 10 + 1);

    final now = DateTime.now();

    final tenMinBefore = startTime.subtract(const Duration(minutes: 10));
    if (tenMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: id * 10,
        title: 'Class Starting Soon',
        body: '$subject starts in 10 minutes',
        scheduledTime: tenMinBefore,
      );
    }

    final oneMinBefore = startTime.subtract(const Duration(minutes: 1));
    if (oneMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: id * 10 + 1,
        title: 'Class Starting Now',
        body: '$subject starts in 1 minute',
        scheduledTime: oneMinBefore,
      );
    }
  }

  Future<void> scheduleAssignmentAlerts({
    required int id,
    required String title,
    required DateTime deadline,
  }) async {
    final baseId = 1000 + id * 4;
    await _notifications.cancel(id: baseId);
    await _notifications.cancel(id: baseId + 1);
    await _notifications.cancel(id: baseId + 2);
    await _notifications.cancel(id: baseId + 3);

    final now = DateTime.now();

    final threeDaysBefore = deadline.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId,
        title: 'Assignment Due in 3 Days',
        body: '$title is due in 3 days',
        scheduledTime: threeDaysBefore,
      );
    }

    final tenHoursBefore = deadline.subtract(const Duration(hours: 10));
    if (tenHoursBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 1,
        title: 'Assignment Due in 10 Hours',
        body: '$title is due in 10 hours',
        scheduledTime: tenHoursBefore,
      );
    }

    final threeHoursBefore = deadline.subtract(const Duration(hours: 3));
    if (threeHoursBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 2,
        title: 'Assignment Due in 3 Hours',
        body: '$title is due in 3 hours',
        scheduledTime: threeHoursBefore,
      );
    }

    final oneHourBefore = deadline.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 3,
        title: 'Assignment Due in 1 Hour',
        body: '$title is due in 1 hour',
        scheduledTime: oneHourBefore,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    debugPrint("Scheduling Notification $id for $scheduledTime: $title");

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          meowChannelId,
          meowChannelName,
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          sound: RawResourceAndroidNotificationSound(meowSoundName),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_checkInitialized()) return;
    await _notifications.cancel(id: id * 10);
    await _notifications.cancel(id: id * 10 + 1);
  }

  Future<void> cancelAssignmentNotifications(int id) async {
    final baseId = 1000 + id * 4;
    await _notifications.cancel(id: baseId);
    await _notifications.cancel(id: baseId + 1);
    await _notifications.cancel(id: baseId + 2);
    await _notifications.cancel(id: baseId + 3);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> sendTestNotification() async {
    await _showImmediateNotification(
      id: 9999,
      title: "Test Alert",
      body: "If you see this, local notifications are working!",
    );
  }

  Future<void> _showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    debugPrint("Showing immediate notification $id: $title");

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          meowChannelId,
          meowChannelName,
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          sound: RawResourceAndroidNotificationSound(meowSoundName),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleNoteReminders({
    required int noteId,
    required String noteTitle,
    required DateTime reminderTime,
  }) async {
    if (!_checkInitialized()) return;
    final now = DateTime.now();
    final id = noteId + 2000;

    if (reminderTime.isAfter(now)) {
      await _scheduleNotification(
        id: id,
        title: 'Study Reminder',
        body: 'Time to review: $noteTitle',
        scheduledTime: reminderTime,
      );
    }
    _scheduledNoteIds.add(id);
  }

  Future<void> cancelNoteReminder(int noteId) async {
    if (!_checkInitialized()) return;
    final id = noteId + 2000;
    await _notifications.cancel(id: id);
    _scheduledNoteIds.remove(id);
  }

  Future<void> cancelAllNoteReminders() async {
    for (final id in _scheduledNoteIds) {
      await _notifications.cancel(id: id);
    }
    _scheduledNoteIds.clear();
  }
}
