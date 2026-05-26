import 'dart:async';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/helper/time_helper.dart';
import 'package:mobile_app/models/class_model.dart';
import 'package:mobile_app/models/assignment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class WidgetUpdateService {
  static final WidgetUpdateService _instance = WidgetUpdateService._internal();
  factory WidgetUpdateService() => _instance;
  WidgetUpdateService._internal();

  static const int _alarmId = 99999;

  static const String _keyCurrentSubject = 'widget_current_subject';
  static const String _keyCurrentTime = 'widget_current_time';
  static const String _keyCurrentVisible = 'widget_current_visible';

  static const String _keyNextSubject = 'widget_next_subject';
  static const String _keyNextCountdown = 'widget_next_countdown';
  static const String _keyNextVisible = 'widget_next_visible';

  static const String _keyScheduleCount = 'widget_schedule_count';
  static const String _keyScheduleVisible = 'widget_schedule_visible';

  static const String _keyAssignmentsCount = 'widget_assignments_count';
  static const String _keyAssignmentsVisible = 'widget_assignments_visible';

  static const String _keyErrorMessage = 'widget_error_message';
  static const String _keyHasError = 'widget_has_error';

  Future<void> startPeriodicUpdates({int? userId}) async {
    debugPrint('[WidgetUpdateService] startPeriodicUpdates(userId=$userId)');
    await _persistUserIdForBackground(userId);
    await _initBackgroundService(userId: userId);
    await _scheduleAlarmChain(userId: userId);
  }

  Future<void> stopPeriodicUpdates() async {
    debugPrint('[WidgetUpdateService] stopPeriodicUpdates');
    final service = FlutterBackgroundService();
    service.invoke('stop');
    AndroidAlarmManager.cancel(_alarmId);
  }

  Future<void> refreshWidget({int? userId}) async {
    debugPrint('[WidgetUpdateService] refreshWidget(userId=$userId) — main isolate');
    await _performWidgetUpdate(userId);
  }

  Future<void> performOneTimeUpdate({int? userId}) async {
    debugPrint('[WidgetUpdateService] performOneTimeUpdate(userId=$userId)');
    await _performWidgetUpdate(userId);
  }

  Future<void> _persistUserIdForBackground(int? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setInt('userId', userId);
        await prefs.setBool('isLoggedIn', true);
        debugPrint('[WidgetUpdateService] Persisted userId=$userId for background isolates');
      }
    } catch (e, st) {
      debugPrint('[WidgetUpdateService] FAILED to persist userId for background: $e\n$st');
    }
  }

  Future<void> _initBackgroundService({int? userId}) async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: false,
        notificationChannelId: 'widget_update_channel',
        initialNotificationTitle: 'Student Pal Widget',
        initialNotificationContent: 'Keeping your widget up to date',
        foregroundServiceNotificationId: 8888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    final isRunning = await service.isRunning();
    debugPrint('[WidgetUpdateService] Background service running=$isRunning');
    if (!isRunning) {
      await service.startService();
    }

    await Future.delayed(const Duration(milliseconds: 800));
    service.invoke('setUserId', {'userId': userId});
  }

  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    debugPrint('[WidgetUpdateService] _onStart — bindings initialised');

    int? userId;
    Timer? timer;
    final completer = Completer<void>();

    service.on('stop').listen((_) async {
      debugPrint('[WidgetUpdateService] Stop signal received');
      timer?.cancel();
      await service.stopSelf();
    });

    service.on('setUserId').listen((event) async {
      if (event != null && event['userId'] != null) {
        userId = event['userId'] as int;
        debugPrint('[WidgetUpdateService] userId set to $userId via setUserId event');
      }
      if (!completer.isCompleted) completer.complete();
      await _performWidgetUpdate(userId);
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 60), (_) async {
        await _performWidgetUpdate(userId);
      });
    });

    await completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('[WidgetUpdateService] Timeout waiting for setUserId event');
    });

    if (userId == null) {
      debugPrint('[WidgetUpdateService] No userId received — attempting update with null');
      await _performWidgetUpdate(null);
      timer ??= Timer.periodic(const Duration(seconds: 60), (_) async {
        await _performWidgetUpdate(userId);
      });
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    debugPrint('[WidgetUpdateService] _onIosBackground — bindings initialised');
    await _performWidgetUpdate(null);
    return true;
  }

  @pragma('vm:entry-point')
  static Future<void> _alarmCallback() async {
    DartPluginRegistrant.ensureInitialized();
    debugPrint('[WidgetUpdateService] _alarmCallback — plugin registrant initialised (isolate)');
    try {
      await _performWidgetUpdate(null);
    } catch (e, st) {
      debugPrint('[WidgetUpdateService] _alarmCallback TOP-LEVEL CRASH: $e\n$st');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _performWidgetUpdate(int? userId) async {
    int step = 0;

    try {
      step = 1;
      debugPrint('[WidgetUpdateService] === WIDGET UPDATE START (step 1) ===');

      step = 2;
      if (userId == null) {
        try {
          debugPrint('[WidgetUpdateService] Step 2 — reading userId from SharedPreferences');
          final prefs = await SharedPreferences.getInstance();
          final storedUserId = prefs.getInt('userId');
          final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
          debugPrint('[WidgetUpdateService] SP read: storedUserId=$storedUserId, isLoggedIn=$isLoggedIn');
          if (!isLoggedIn || storedUserId == null) {
            debugPrint('[WidgetUpdateService] Not logged in — showing empty state');
            await _setErrorState('Welcome to StudentPal!', true);
            return;
          }
          userId = storedUserId;
        } catch (e, st) {
          debugPrint('[WidgetUpdateService] STEP 2 FAILED — SharedPreferences in isolate: $e\n$st');
          await _setErrorState('SP init failed', true);
          return;
        }
      }

      step = 3;
      debugPrint('[WidgetUpdateService] Step 3 — userId resolved to $userId');

      step = 4;
      DatabaseHelper db;
      try {
        debugPrint('[WidgetUpdateService] Step 4 — initialising DatabaseHelper');
        db = DatabaseHelper();
        final d = await db.database;
        debugPrint('[WidgetUpdateService] DB handle obtained: path=${d.path}');
      } catch (e, st) {
        debugPrint('[WidgetUpdateService] STEP 4 FAILED — DB init: $e\n$st');
        await _setErrorState('DB init failed', true);
        return;
      }

      step = 5;
      try {
        debugPrint('[WidgetUpdateService] Step 5 — fetching user $userId');
        final userData = await db.getUser(userId);
        if (userData == null) {
          debugPrint('[WidgetUpdateService] User $userId not found in DB');
          await _setErrorState('Unable to load your data', true);
          return;
        }
        debugPrint('[WidgetUpdateService] User found: ${userData['username']}');
      } catch (e, st) {
        debugPrint('[WidgetUpdateService] STEP 5 FAILED — user lookup: $e\n$st');
        await _setErrorState('User lookup failed', true);
        return;
      }

      step = 6;
      try {
        debugPrint('[WidgetUpdateService] Step 6 — clearing previous error flags');
        await HomeWidget.saveWidgetData(_keyHasError, false);
        await HomeWidget.saveWidgetData(_keyErrorMessage, '');
      } catch (e, st) {
        debugPrint('[WidgetUpdateService] Step 6 warning — HomeWidget write: $e\n$st');
      }

      step = 7;
      List<ClassModel> allClasses;
      try {
        debugPrint('[WidgetUpdateService] Step 7 — loading classes for userId=$userId');
        allClasses = await db.getAllClassModels(userId);
        debugPrint('[WidgetUpdateService] Loaded ${allClasses.length} classes');
      } catch (e, st) {
        debugPrint('[WidgetUpdateService] STEP 7 FAILED — class load: $e\n$st');
        await _setErrorState('Could not load schedule', true);
        return;
      }

      step = 8;
      if (allClasses.isEmpty) {
        debugPrint('[WidgetUpdateService] Step 8 — no classes, showing empty grid');
        await _setEmptyGrid('No classes scheduled');
        return;
      }

      step = 9;
      final now = DateTime.now();
      final todayIndex = now.weekday;
      final dayMap = {
        1: 'MON',
        2: 'TUE',
        3: 'WED',
        4: 'THU',
        5: 'FRI',
        6: 'SAT',
        7: 'SUN'
      };
      final todayAbbrev = dayMap[todayIndex]!;
      debugPrint('[WidgetUpdateService] Step 9 — today=$todayAbbrev, processing ${allClasses.length} classes');

      step = 10;
      ClassModel? currentClass;
      for (final classItem in allClasses) {
        final classDays = classItem.days.toUpperCase();
        if (_dayMatches(classDays, todayAbbrev)) {
          if (TimeHelper.isClassActive(
              classItem.startTime, classItem.endTime)) {
            currentClass = classItem;
            break;
          }
        }
      }

      step = 11;
      if (currentClass != null) {
        await HomeWidget.saveWidgetData(
            _keyCurrentSubject, currentClass.subject);
        await HomeWidget.saveWidgetData(_keyCurrentTime,
            '${currentClass.displayStartTime} - ${currentClass.displayEndTime}');
        await HomeWidget.saveWidgetData(_keyCurrentVisible, true);
        debugPrint('[WidgetUpdateService] Current class: ${currentClass.subject}');
      } else {
        await HomeWidget.saveWidgetData(_keyCurrentVisible, false);
        debugPrint('[WidgetUpdateService] No active class now');
      }

      step = 12;
      ClassModel? nextClass;
      int closestDiff = 999999;

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final checkDayIndex = ((todayIndex - 1 + dayOffset) % 7) + 1;
        final dayAbbrev = dayMap[checkDayIndex]!;

        for (final classItem in allClasses) {
          if (!_dayMatches(classItem.days.toUpperCase(), dayAbbrev)) continue;

          final startMinutes = TimeHelper.convertToMinutes(classItem.startTime);
          if (dayOffset == 0 && startMinutes <= TimeHelper.getCurrentMinutes())
            continue;

          final diff = (dayOffset * 1440) +
              (startMinutes - TimeHelper.getCurrentMinutes());
          if (diff < closestDiff && diff > 0) {
            closestDiff = diff;
            nextClass = classItem;
          }
        }

        if (nextClass != null) break;
      }

      step = 13;
      if (nextClass != null) {
        await HomeWidget.saveWidgetData(_keyNextSubject, nextClass.subject);
        final nextClassTime =
            _getNextClassDateTime(nextClass, todayIndex, dayMap);
        final remaining = nextClassTime.difference(DateTime.now());
        final countdown = _formatCountdown(remaining);
        await HomeWidget.saveWidgetData(_keyNextCountdown, countdown);
        await HomeWidget.saveWidgetData(_keyNextVisible, true);
        debugPrint('[WidgetUpdateService] Next class: ${nextClass.subject} in $countdown');
      } else {
        await HomeWidget.saveWidgetData(_keyNextVisible, false);
        debugPrint('[WidgetUpdateService] No upcoming classes found');
      }

      step = 14;
      int classesToday = 0;
      final currentMinutes = TimeHelper.getCurrentMinutes();

      for (final classItem in allClasses) {
        if (!_dayMatches(classItem.days.toUpperCase(), todayAbbrev)) continue;
        final startMinutes = TimeHelper.convertToMinutes(classItem.startTime);
        if (startMinutes > currentMinutes) {
          classesToday++;
        }
      }

      await HomeWidget.saveWidgetData(_keyScheduleCount, classesToday);
      await HomeWidget.saveWidgetData(_keyScheduleVisible, true);
      debugPrint('[WidgetUpdateService] Classes left today: $classesToday');

      step = 15;
      try {
        debugPrint('[WidgetUpdateService] Step 15 — loading assignments');
        final assignmentsData = await db.getAssignments(userId);
        int pendingAssignments = 0;

        for (final data in assignmentsData) {
          final assignment = Assignment.fromMap(data);
          if (!assignment.isDone) {
            pendingAssignments++;
          }
        }

        await HomeWidget.saveWidgetData(_keyAssignmentsCount, pendingAssignments);
        await HomeWidget.saveWidgetData(_keyAssignmentsVisible, true);
        debugPrint('[WidgetUpdateService] Pending assignments: $pendingAssignments');
      } catch (e, st) {
        debugPrint('[WidgetUpdateService] Step 15 warning — assignment load: $e\n$st');
        await HomeWidget.saveWidgetData(_keyAssignmentsCount, 0);
        await HomeWidget.saveWidgetData(_keyAssignmentsVisible, true);
      }

      step = 16;
      debugPrint('[WidgetUpdateService] Step 16 — triggering native widget update');
      await _triggerNativeUpdate();
      debugPrint('[WidgetUpdateService] === WIDGET UPDATE COMPLETE ===');

    } catch (e, st) {
      debugPrint('[WidgetUpdateService] STEP $step FAILED — UNHANDLED: $e\n$st');
      try {
        await _setErrorState('Update failed at step $step', true);
      } catch (innerE, innerSt) {
        debugPrint('[WidgetUpdateService] CRITICAL — _setErrorState also failed: $innerE\n$innerSt');
      }
    }
  }

  Future<void> _scheduleAlarmChain({int? userId}) async {
    try {
      final now = DateTime.now();
      final alignedMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
      final delayUntilNextMinute = alignedMinute.difference(now);

      if (delayUntilNextMinute.isNegative) {
        debugPrint('[WidgetUpdateService] Scheduling periodic alarm (60s) for userId=$userId');
        await AndroidAlarmManager.periodic(
          const Duration(seconds: 60),
          _alarmId,
          _alarmCallback,
          exact: true,
          allowWhileIdle: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
      } else {
        debugPrint('[WidgetUpdateService] Scheduling oneShot alarm at $alignedMinute for userId=$userId');
        await AndroidAlarmManager.oneShotAt(
          alignedMinute,
          _alarmId,
          _alarmCallback,
          exact: true,
          allowWhileIdle: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
        await AndroidAlarmManager.periodic(
          const Duration(seconds: 60),
          _alarmId + 1,
          _alarmCallback,
          exact: true,
          allowWhileIdle: true,
          wakeup: true,
          rescheduleOnReboot: true,
          startAt: alignedMinute.add(const Duration(seconds: 60)),
        );
      }
      debugPrint('[WidgetUpdateService] Alarm chain scheduled');
    } catch (e, st) {
      debugPrint('[WidgetUpdateService] FAILED to schedule alarm: $e\n$st');
      debugPrint('[WidgetUpdateService] Android 12+ requires SCHEDULE_EXACT_ALARM permission in manifest');
    }
  }

  static bool _dayMatches(String classDays, String targetDay) {
    if (classDays.contains(targetDay)) return true;
    if (targetDay == 'WED' &&
        classDays.contains('W') &&
        !classDays.contains('TUE') &&
        !classDays.contains('FRI')) return true;
    if (targetDay == 'MON' &&
        classDays.contains('M') &&
        !classDays.contains('MON')) return true;
    if (targetDay == 'SAT' &&
        classDays.contains('S') &&
        !classDays.contains('SUN')) return true;
    return false;
  }

  static DateTime _getNextClassDateTime(
      ClassModel classItem, int todayIndex, Map<int, String> dayMap) {
    final now = DateTime.now();
    final startMinutes = TimeHelper.convertToMinutes(classItem.startTime);
    final todayAbbrev = dayMap[todayIndex]!;

    if (_dayMatches(classItem.days.toUpperCase(), todayAbbrev)) {
      final classTime = DateTime(
          now.year, now.month, now.day, startMinutes ~/ 60, startMinutes % 60);
      if (classTime.isAfter(now)) return classTime;
    }

    for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
      final checkDayIndex = ((todayIndex - 1 + dayOffset) % 7) + 1;
      final dayAbbrev = dayMap[checkDayIndex]!;

      if (_dayMatches(classItem.days.toUpperCase(), dayAbbrev)) {
        final futureDate = now.add(Duration(days: dayOffset));
        return DateTime(futureDate.year, futureDate.month, futureDate.day,
            startMinutes ~/ 60, startMinutes % 60);
      }
    }

    return now.add(const Duration(days: 7));
  }

  static String _formatCountdown(Duration duration) {
    if (duration.isNegative) return 'Now';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static Future<void> _setErrorState(String message, bool hasError) async {
    try {
      debugPrint('[WidgetUpdateService] _setErrorState: $message');
      await HomeWidget.saveWidgetData(_keyHasError, hasError);
      await HomeWidget.saveWidgetData(_keyErrorMessage, message);
      await HomeWidget.saveWidgetData(_keyCurrentVisible, false);
      await HomeWidget.saveWidgetData(_keyNextVisible, false);
      await HomeWidget.saveWidgetData(_keyScheduleVisible, false);
      await HomeWidget.saveWidgetData(_keyAssignmentsVisible, false);
      await _triggerNativeUpdate();
    } catch (e, st) {
      debugPrint('[WidgetUpdateService] _setErrorState failed: $e\n$st');
    }
  }

  static Future<void> _setEmptyGrid(String message) async {
    try {
      debugPrint('[WidgetUpdateService] _setEmptyGrid: $message');
      await HomeWidget.saveWidgetData(_keyHasError, true);
      await HomeWidget.saveWidgetData(_keyErrorMessage, message);
      await HomeWidget.saveWidgetData(_keyCurrentVisible, false);
      await HomeWidget.saveWidgetData(_keyNextVisible, false);
      await HomeWidget.saveWidgetData(_keyScheduleCount, 0);
      await HomeWidget.saveWidgetData(_keyScheduleVisible, true);
      await HomeWidget.saveWidgetData(_keyAssignmentsCount, 0);
      await HomeWidget.saveWidgetData(_keyAssignmentsVisible, true);
      await _triggerNativeUpdate();
    } catch (e, st) {
      debugPrint('[WidgetUpdateService] _setEmptyGrid failed: $e\n$st');
    }
  }

  static Future<void> _triggerNativeUpdate() async {
    try {
      await HomeWidget.updateWidget(
        androidName: 'StudentPalWidgetProvider',
        iOSName: 'StudentPalWidget',
        qualifiedAndroidName: 'com.example.mobile_app.StudentPalWidgetProvider',
      );
      debugPrint('[WidgetUpdateService] Native widget update triggered');
    } catch (e, st) {
      debugPrint('[WidgetUpdateService] _triggerNativeUpdate failed: $e\n$st');
    }
  }
}
