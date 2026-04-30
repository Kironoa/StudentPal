import 'dart:io';
import 'package:alarm/alarm.dart';
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
  String? _permissionError;
  String? get permissionError => _permissionError;

  static const String meowChannelId = 'student_pal_meow_v1';
  static const String meowChannelName = 'Student Pal Alerts';
  static const String meowSoundName = 'meow';

  // Timezone helper from reference code
  @pragma('vm:entry-point')
  static void _setLocalTimezone() {
    final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final offsetHours = offsetMinutes / 60;
    final Map<double, String> offsetMap = {
      8.0: 'Asia/Manila',
      -5.0: 'America/New_York',
      -6.0: 'America/Chicago',
      -7.0: 'America/Denver',
      -8.0: 'America/Los_Angeles',
      0.0: 'Europe/London',
      1.0: 'Europe/Paris',
      5.5: 'Asia/Kolkata',
      7.0: 'Asia/Bangkok',
      9.0: 'Asia/Tokyo',
      10.0: 'Australia/Sydney',
      3.0: 'Europe/Moscow',
      -3.0: 'America/Sao_Paulo',
    };
    final tzName = offsetMap[offsetHours] ?? 'UTC';
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  bool _checkInitialized() {
    if (!_isInitialized) {
      debugPrint('[NotificationService] Not initialized — skipping.');
      return false;
    }
    return true;
  }

  @pragma('vm:entry-point')
  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName.toString()));
    } catch (e) {
      _setLocalTimezone(); // Use the reference code's timezone mapping
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

    // Initialize alarm package
    await Alarm.init();

    _isInitialized = true;
  }

  @pragma('vm:entry-point')
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

  @pragma('vm:entry-point')
  Future<String?> checkAlarmPermission() async {
    // Alarm.hasPermission() removed - not available in alarm 5.0.0+
    if (Platform.isAndroid) {
      // Exact logic from user's Task 2 requirement
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final bool? canSchedule = await androidImplementation?.requestExactAlarmsPermission();
      if (canSchedule == true) {
        _permissionError = null;
        return null;
      }
    } else {
      // Non-Android platforms - assume permission is handled
      _permissionError = null;
      return null;
    }
    _permissionError =
        "Please enable 'Alarms & Reminders' in settings so your class alerts can wake your device.";
    return _permissionError;
  }

  @pragma('vm:entry-point')
  Future<String?> scheduleClassAlerts({
    required int id,
    required String subject,
    required DateTime startTime,
  }) async {
    if (!_checkInitialized()) return 'Not initialized';

    // Check alarm permission first
    final permissionError = await checkAlarmPermission();
    if (permissionError != null) return permissionError;

    // Cancel existing alerts
    await _notifications.cancel(id: id * 10);
    await Alarm.stop(id * 10 + 1); // Cancel existing alarm if any

    final now = DateTime.now();

    // 10 minutes before - use local notification
    final tenMinBefore = startTime.subtract(const Duration(minutes: 10));
    if (tenMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: id * 10,
        title: 'Class Starting Soon',
        body: '$subject starts in 10 minutes',
        scheduledTime: tenMinBefore,
      );
    }

    // Class Starting Now - use Alarm for foreground service (wakes device)
    final oneMinBefore = startTime.subtract(const Duration(minutes: 1));
    if (oneMinBefore.isAfter(now)) {
      final alarmSettings = AlarmSettings(
        id: id * 10 + 1,
        dateTime: oneMinBefore,
        assetAudioPath: 'assets/meow.wav', // Using meow.wav for class alarms
        loopAudio: true,
        vibrate: true,
        androidFullScreenIntent: true,
        volume: 1,
        fadeDuration: 3,
        notificationSettings: const NotificationSettings(
          title: 'Class Starting Now!',
          body: 'Your class is about to start.',
          stopButton: 'Stop',
          icon: 'mipmap/ic_launcher',
        ),
      );

      try {
        await Alarm.set(alarmSettings: alarmSettings);
      } catch (e) {
        return 'Failed to schedule class alert. Please check alarm permissions in settings.';
      }
    }

    return null;
  }

  @pragma('vm:entry-point')
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

    // 3 Days Before - use alarmClock for reliability
    final threeDaysBefore = deadline.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId,
        title: 'Assignment Due in 3 Days',
        body: '$title is due in 3 days',
        scheduledTime: threeDaysBefore,
        scheduleMode: AndroidScheduleMode.alarmClock,
      );
    }

    // 10 Hours Before - use alarmClock for reliability
    final tenHoursBefore = deadline.subtract(const Duration(hours: 10));
    if (tenHoursBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 1,
        title: 'Assignment Due in 10 Hours',
        body: '$title is due in 10 hours',
        scheduledTime: tenHoursBefore,
        scheduleMode: AndroidScheduleMode.alarmClock,
      );
    }

    // 3 Hours Before
    final threeHoursBefore = deadline.subtract(const Duration(hours: 3));
    if (threeHoursBefore.isAfter(now)) {
      await _scheduleNotification(
        id: baseId + 2,
        title: 'Assignment Due in 3 Hours',
        body: '$title is due in 3 hours',
        scheduledTime: threeHoursBefore,
      );
    }

    // 1 Hour Before
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
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle,
  }) async {
    debugPrint("Scheduling Notification $id for $scheduledTime: $title");

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(
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
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
    );
  }

  @pragma('vm:entry-point')
  Future<void> cancelNotification(int id) async {
    if (!_checkInitialized()) return;
    await _notifications.cancel(id: id * 10);
    await Alarm.stop(id * 10 + 1); // Also stop the alarm
    await _notifications.cancel(id: id * 10 + 1);
  }

  @pragma('vm:entry-point')
  Future<void> cancelAssignmentNotifications(int id) async {
    final baseId = 1000 + id * 4;
    await _notifications.cancel(id: baseId);
    await _notifications.cancel(id: baseId + 1);
    await _notifications.cancel(id: baseId + 2);
    await _notifications.cancel(id: baseId + 3);
  }

  @pragma('vm:entry-point')
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    await Alarm.stopAll(); // Stop all alarms
  }

  @pragma('vm:entry-point')
  Future<void> sendTestNotification() async {
    await _showImmediateNotification(
      id: 9999,
      title: "Test Alert",
      body: "If you see this, local notifications are working!",
    );
  }

  @pragma('vm:entry-point')
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
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          meowChannelId,
          meowChannelName,
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          sound: RawResourceAndroidNotificationSound(meowSoundName),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  @pragma('vm:entry-point')
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

  @pragma('vm:entry-point')
  Future<void> cancelNoteReminder(int noteId) async {
    if (!_checkInitialized()) return;
    final id = noteId + 2000;
    await _notifications.cancel(id: id);
    _scheduledNoteIds.remove(id);
  }

  @pragma('vm:entry-point')
  Future<void> cancelAllNoteReminders() async {
    for (final id in _scheduledNoteIds) {
      await _notifications.cancel(id: id);
    }
    _scheduledNoteIds.clear();
  }
}
