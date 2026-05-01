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

  static const String _keyTitle = 'widget_title';
  static const String _keySubtitle = 'widget_subtitle';
  static const String _keyCountdown = 'widget_countdown';
  static const String _keyType = 'widget_type';
  static const String _keyEmptyMessage = 'widget_empty_message';
  static const String _keyLastUpdate = 'widget_last_update';
  static const String _keyDeadlineTimestamp = 'widget_deadline_timestamp';
  static const String _keyNickname = 'widget_nickname';

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
        autoStart: true,
        isForegroundMode: true,
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

    service.invoke('setUserId', {'userId': userId});
  }

  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    int? userId;
    Timer? timer;

    if (service is AndroidServiceInstance) {
      service.on('setUserId').listen((event) {
        if (event != null && event['userId'] != null) {
          userId = event['userId'] as int;
        }
      });
    }

    service.on('stop').listen((event) async {
      timer?.cancel();
      await service.stopSelf();
    });

    if (userId != null) {
      await _performWidgetUpdate(userId);
    }

    timer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (userId != null) {
        await _performWidgetUpdate(userId);
      }
    });
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
          await HomeWidget.saveWidgetData(_keyNickname, '');
          await _setEmptyState('Stay Productive!');
          return;
        }
        userId = storedUserId;
      }

      final db = DatabaseHelper();
      final userData = await db.getUser(userId);
      if (userData == null) {
        await HomeWidget.saveWidgetData(_keyNickname, '');
        await _setEmptyState('Stay Productive!');
        return;
      }
      final nickname = userData['nickname'] as String? ?? '';
      await HomeWidget.saveWidgetData(_keyNickname, nickname);

      final currentClass = await _findCurrentClass(db, userId);
      if (currentClass != null) {
        await _setCurrentClass(currentClass);
        return;
      }

      final nextClass = await _findNextClass(db, userId);
      final nextAssignment = await _findNextAssignment(db, userId);

      if (nextClass == null && nextAssignment == null) {
        await _setEmptyState('No upcoming tasks');
        return;
      }

      if (nextClass == null) {
        await _setNextAssignment(nextAssignment!);
        return;
      }

      if (nextAssignment == null) {
        await _setNextClass(nextClass);
        return;
      }

      final nextClassTime = _getNextClassDateTime(nextClass);
      final assignmentTime = nextAssignment.deadlineDate ?? DateTime(2099);

      if (nextClassTime.isBefore(assignmentTime)) {
        await _setNextClass(nextClass);
      } else {
        await _setNextAssignment(nextAssignment);
      }
    } catch (e) {
      debugPrint('[WidgetUpdateService] _performWidgetUpdate error: $e');
      await HomeWidget.saveWidgetData(_keyNickname, '');
      await _setEmptyState('Stay Productive!');
    }
  }

  Future<void> _scheduleAlarmChain({int? userId}) async {
    await AndroidAlarmManager.periodic(
      const Duration(seconds: 60),
      _alarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _alarmCallback() async {
    await _performWidgetUpdate(null);
  }

  static Future<ClassModel?> _findCurrentClass(DatabaseHelper db, int userId) async {
    final allClasses = await db.getAllClassModels(userId);
    final now = DateTime.now();
    final todayIndex = now.weekday;
    final dayMap = {1: 'MON', 2: 'TUE', 3: 'WED', 4: 'THU', 5: 'FRI', 6: 'SAT', 7: 'SUN'};
    final todayAbbrev = dayMap[todayIndex]!;

    for (final classItem in allClasses) {
      final classDays = classItem.days.toUpperCase();
      if (_dayMatches(classDays, todayAbbrev)) {
        if (TimeHelper.isClassActive(classItem.startTime, classItem.endTime)) {
          return classItem;
        }
      }
    }
    return null;
  }

  static Future<ClassModel?> _findNextClass(DatabaseHelper db, int userId) async {
    final allClasses = await db.getAllClassModels(userId);
    final now = DateTime.now();
    final currentMinutes = TimeHelper.getCurrentMinutes();
    final todayIndex = now.weekday;
    final dayMap = {1: 'MON', 2: 'TUE', 3: 'WED', 4: 'THU', 5: 'FRI', 6: 'SAT', 7: 'SUN'};

    ClassModel? closestClass;
    int closestDiff = 999999;

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final checkDayIndex = ((todayIndex - 1 + dayOffset) % 7) + 1;
      final dayAbbrev = dayMap[checkDayIndex]!;

      final dayClasses = allClasses.where((c) {
        return _dayMatches(c.days.toUpperCase(), dayAbbrev);
      }).toList();

      for (final classItem in dayClasses) {
        final startMinutes = TimeHelper.convertToMinutes(classItem.startTime);
        if (dayOffset == 0 && startMinutes <= currentMinutes) continue;

        final diff = (dayOffset * 1440) + (startMinutes - currentMinutes);
        if (diff < closestDiff && diff > 0) {
          closestDiff = diff;
          closestClass = classItem;
        }
      }

      if (closestClass != null) break;
    }

    return closestClass;
  }

  static Future<Assignment?> _findNextAssignment(DatabaseHelper db, int userId) async {
    final assignmentsData = await db.getAssignments(userId);
    final now = DateTime.now();

    Assignment? closest;
    DateTime? closestDate;

    for (final data in assignmentsData) {
      final assignment = Assignment.fromMap(data);
      if (assignment.isDone) continue;

      final deadline = assignment.deadlineDate;
      if (deadline == null || deadline.isBefore(now)) continue;

      if (closestDate == null || deadline.isBefore(closestDate)) {
        closestDate = deadline;
        closest = assignment;
      }
    }

    return closest;
  }

  static DateTime _getNextClassDateTime(ClassModel classItem) {
    final now = DateTime.now();
    final startMinutes = TimeHelper.convertToMinutes(classItem.startTime);
    final todayIndex = now.weekday;
    final dayMap = {1: 'MON', 2: 'TUE', 3: 'WED', 4: 'THU', 5: 'FRI', 6: 'SAT', 7: 'SUN'};
    final todayAbbrev = dayMap[todayIndex]!;

    if (_dayMatches(classItem.days.toUpperCase(), todayAbbrev)) {
      final classTime = DateTime(now.year, now.month, now.day, startMinutes ~/ 60, startMinutes % 60);
      if (classTime.isAfter(now)) return classTime;
    }

    for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
      final checkDayIndex = ((todayIndex - 1 + dayOffset) % 7) + 1;
      final dayAbbrev = dayMap[checkDayIndex]!;

      if (_dayMatches(classItem.days.toUpperCase(), dayAbbrev)) {
        final futureDate = now.add(Duration(days: dayOffset));
        return DateTime(futureDate.year, futureDate.month, futureDate.day, startMinutes ~/ 60, startMinutes % 60);
      }
    }

    return now.add(const Duration(days: 7));
  }

  static bool _dayMatches(String classDays, String targetDay) {
    if (classDays.contains(targetDay)) return true;
    if (targetDay == 'WED' && classDays.contains('W') && !classDays.contains('TUE') && !classDays.contains('FRI')) return true;
    if (targetDay == 'MON' && classDays.contains('M') && !classDays.contains('MON')) return true;
    if (targetDay == 'SAT' && classDays.contains('S') && !classDays.contains('SUN')) return true;
    return false;
  }

  static Future<void> _setCurrentClass(ClassModel classItem) async {
    final now = DateTime.now();
    final endMinutes = TimeHelper.convertToMinutes(classItem.endTime);
    final endTime = DateTime(now.year, now.month, now.day, endMinutes ~/ 60, endMinutes % 60);
    final remaining = endTime.difference(now);

    await HomeWidget.saveWidgetData(_keyTitle, classItem.subject);
    await HomeWidget.saveWidgetData(_keySubtitle, 'Current Class');
    await HomeWidget.saveWidgetData(_keyCountdown, _formatCountdown(remaining));
    await HomeWidget.saveWidgetData(_keyType, 'current_class');
    await HomeWidget.saveWidgetData(_keyEmptyMessage, '');
    await HomeWidget.saveWidgetData(_keyLastUpdate, now.millisecondsSinceEpoch);
    await HomeWidget.saveWidgetData(_keyDeadlineTimestamp, endTime.millisecondsSinceEpoch);

    await _triggerNativeUpdate();
  }

  static Future<void> _setNextClass(ClassModel classItem) async {
    final nextTime = _getNextClassDateTime(classItem);
    final remaining = nextTime.difference(DateTime.now());

    await HomeWidget.saveWidgetData(_keyTitle, classItem.subject);
    await HomeWidget.saveWidgetData(_keySubtitle, 'Next Class');
    await HomeWidget.saveWidgetData(_keyCountdown, _formatCountdown(remaining));
    await HomeWidget.saveWidgetData(_keyType, 'next_class');
    await HomeWidget.saveWidgetData(_keyEmptyMessage, '');
    await HomeWidget.saveWidgetData(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);
    await HomeWidget.saveWidgetData(_keyDeadlineTimestamp, nextTime.millisecondsSinceEpoch);

    await _triggerNativeUpdate();
  }

  static Future<void> _setNextAssignment(Assignment assignment) async {
    final deadline = assignment.deadlineDate!;
    final remaining = deadline.difference(DateTime.now());

    await HomeWidget.saveWidgetData(_keyTitle, assignment.title);
    await HomeWidget.saveWidgetData(_keySubtitle, 'Assignment');
    await HomeWidget.saveWidgetData(_keyCountdown, _formatCountdown(remaining));
    await HomeWidget.saveWidgetData(_keyType, 'assignment');
    await HomeWidget.saveWidgetData(_keyEmptyMessage, '');
    await HomeWidget.saveWidgetData(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);
    await HomeWidget.saveWidgetData(_keyDeadlineTimestamp, deadline.millisecondsSinceEpoch);

    await _triggerNativeUpdate();
  }

  static Future<void> _setEmptyState(String message) async {
    await HomeWidget.saveWidgetData(_keyTitle, '');
    await HomeWidget.saveWidgetData(_keySubtitle, '');
    await HomeWidget.saveWidgetData(_keyCountdown, '');
    await HomeWidget.saveWidgetData(_keyType, 'empty');
    await HomeWidget.saveWidgetData(_keyEmptyMessage, message);
    await HomeWidget.saveWidgetData(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);

    await _triggerNativeUpdate();
  }

  static String _formatCountdown(Duration duration) {
    if (duration.isNegative) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  static Future<void> _triggerNativeUpdate() async {
    await HomeWidget.updateWidget(
      name: 'StudentPalWidgetProvider',
      iOSName: 'StudentPalWidget',
      qualifiedAndroidName: 'com.example.mobile_app.StudentPalWidgetProvider',
    );
  }
}
