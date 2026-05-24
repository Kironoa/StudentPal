import 'dart:async';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/helper/time_helper.dart';
import 'package:mobile_app/models/class_model.dart';
import 'package:mobile_app/models/assignment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await _initBackgroundService(userId: userId);
    await _scheduleAlarmChain(userId: userId);
  }

  Future<void> stopPeriodicUpdates() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
    AndroidAlarmManager.cancel(_alarmId);
  }

  Future<void> refreshWidget({int? userId}) async {
    await _performWidgetUpdate(userId);
  }

  Future<void> performOneTimeUpdate({int? userId}) async {
    await _performWidgetUpdate(userId);
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
    if (!isRunning) {
      await service.startService();
    }

    await Future.delayed(const Duration(milliseconds: 800));
    service.invoke('setUserId', {'userId': userId});
  }

  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    int? userId;
    Timer? timer;

    service.on('stop').listen((_) async {
      timer?.cancel();
      await service.stopSelf();
    });

    service.on('setUserId').listen((event) async {
      if (event != null && event['userId'] != null) {
        userId = event['userId'] as int;
      }
      await _performWidgetUpdate(userId);
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 60), (_) async {
        await _performWidgetUpdate(userId);
      });
    });

    await Future.delayed(const Duration(seconds: 5));
    if (userId == null) {
      await _performWidgetUpdate(null);
      timer ??= Timer.periodic(const Duration(seconds: 60), (_) async {
        await _performWidgetUpdate(userId);
      });
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    await _performWidgetUpdate(null);
    return true;
  }

  @pragma('vm:entry-point')
  static Future<void> _performWidgetUpdate(int? userId) async {
    try {
      
      if (userId == null) {
        final prefs = await SharedPreferences.getInstance();
        final storedUserId = prefs.getInt('userId');
        final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        if (!isLoggedIn || storedUserId == null) {
          debugPrint(
              '[WidgetUpdateService] Not logged in â€” showing empty state');
          await _setErrorState('Welcome to StudentPal!', true);
          return;
        }
        userId = storedUserId;
      }

      debugPrint(
          '[WidgetUpdateService] Updating 2x2 widget for userId=$userId');

      final db = DatabaseHelper();

      
      final userData = await db.getUser(userId);
      if (userData == null) {
        debugPrint('[WidgetUpdateService] User not found in DB');
        await _setErrorState('Unable to load your data', true);
        return;
      }

      
      await HomeWidget.saveWidgetData(_keyHasError, false);
      await HomeWidget.saveWidgetData(_keyErrorMessage, '');

      
      final allClasses = await db.getAllClassModels(userId);
      if (allClasses.isEmpty) {
        debugPrint('[WidgetUpdateService] No classes found');
        await _setEmptyGrid('No classes scheduled');
        return;
      }

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

      if (currentClass != null) {
        await HomeWidget.saveWidgetData(
            _keyCurrentSubject, currentClass.subject);
        await HomeWidget.saveWidgetData(_keyCurrentTime,
            '${currentClass.displayStartTime} - ${currentClass.displayEndTime}');
        await HomeWidget.saveWidgetData(_keyCurrentVisible, true);
        debugPrint(
            '[WidgetUpdateService] Current class: ${currentClass.subject}');
      } else {
        await HomeWidget.saveWidgetData(_keyCurrentVisible, false);
      }

      
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

      if (nextClass != null) {
        await HomeWidget.saveWidgetData(_keyNextSubject, nextClass.subject);
        final nextClassTime =
            _getNextClassDateTime(nextClass, todayIndex, dayMap);
        final remaining = nextClassTime.difference(DateTime.now());
        await HomeWidget.saveWidgetData(
            _keyNextCountdown, _formatCountdown(remaining));
        await HomeWidget.saveWidgetData(_keyNextVisible, true);
        debugPrint(
            '[WidgetUpdateService] Next class: ${nextClass.subject} in ${_formatCountdown(remaining)}');
      } else {
        await HomeWidget.saveWidgetData(_keyNextVisible, false);
      }

      
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
      debugPrint(
          '[WidgetUpdateService] Pending assignments: $pendingAssignments');

      await _triggerNativeUpdate();
    } catch (e, st) {
      debugPrint('[WidgetUpdateService] Error updating widget: $e\n$st');
      await _setErrorState('Having trouble loading data', true);
    }
  }

  Future<void> _scheduleAlarmChain({int? userId}) async {
    await AndroidAlarmManager.periodic(
      const Duration(seconds: 60),
      _alarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _alarmCallback() async {
    await _performWidgetUpdate(null);
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
    await HomeWidget.saveWidgetData(_keyHasError, hasError);
    await HomeWidget.saveWidgetData(_keyErrorMessage, message);
    await HomeWidget.saveWidgetData(_keyCurrentVisible, false);
    await HomeWidget.saveWidgetData(_keyNextVisible, false);
    await HomeWidget.saveWidgetData(_keyScheduleVisible, false);
    await HomeWidget.saveWidgetData(_keyAssignmentsVisible, false);
    await _triggerNativeUpdate();
  }

  static Future<void> _setEmptyGrid(String message) async {
    await HomeWidget.saveWidgetData(_keyHasError, true);
    await HomeWidget.saveWidgetData(_keyErrorMessage, message);
    await HomeWidget.saveWidgetData(_keyCurrentVisible, false);
    await HomeWidget.saveWidgetData(_keyNextVisible, false);
    await HomeWidget.saveWidgetData(_keyScheduleCount, 0);
    await HomeWidget.saveWidgetData(_keyScheduleVisible, true);
    await HomeWidget.saveWidgetData(_keyAssignmentsCount, 0);
    await HomeWidget.saveWidgetData(_keyAssignmentsVisible, true);
    await _triggerNativeUpdate();
  }

  static Future<void> _triggerNativeUpdate() async {
    await HomeWidget.updateWidget(
      androidName: 'StudentPalWidgetProvider',
      iOSName: 'StudentPalWidget',
      qualifiedAndroidName: 'com.example.mobile_app.StudentPalWidgetProvider',
    );
  }
}
