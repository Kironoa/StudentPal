import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/helper/time_helper.dart';
import 'package:mobile_app/models/class_model.dart';
import 'package:mobile_app/models/assignment_model.dart';

class WidgetDataService {
  static final WidgetDataService _instance = WidgetDataService._internal();
  factory WidgetDataService() => _instance;
  WidgetDataService._internal();

  static const String _keyTitle = 'widget_title';
  static const String _keySubtitle = 'widget_subtitle';
  static const String _keyCountdown = 'widget_countdown';
  static const String _keyType = 'widget_type';
  static const String _keyEmptyMessage = 'widget_empty_message';

  Future<void> refreshWidget({int? userId}) async {
    try {
      final db = DatabaseHelper();

      if (userId == null) {
        final user = await db.getUser(1);
        if (user == null) {
          await _setEmptyState('Stay Productive!');
          return;
        }
        userId = user['id'] as int;
      }

      final currentClass = await _findCurrentClass(userId);
      if (currentClass != null) {
        await _setCurrentClass(currentClass);
        return;
      }

      final nextClass = await _findNextClass(userId);
      final nextAssignment = await _findNextAssignment(userId);

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
      debugPrint('[WidgetDataService] refreshWidget error: $e');
      await _setEmptyState('Stay Productive!');
    }
  }

  Future<ClassModel?> _findCurrentClass(int userId) async {
    final allClasses = await DatabaseHelper().getAllClassModels(userId);
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

  Future<ClassModel?> _findNextClass(int userId) async {
    final allClasses = await DatabaseHelper().getAllClassModels(userId);
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

        if (dayOffset == 0 && startMinutes <= currentMinutes) {
          continue;
        }

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

  Future<Assignment?> _findNextAssignment(int userId) async {
    final assignmentsData = await DatabaseHelper().getAssignments(userId);
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

  DateTime _getNextClassDateTime(ClassModel classItem) {
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

  bool _dayMatches(String classDays, String targetDay) {
    if (classDays.contains(targetDay)) return true;
    if (targetDay == 'WED' && classDays.contains('W') && !classDays.contains('TUE') && !classDays.contains('FRI')) return true;
    if (targetDay == 'MON' && classDays.contains('M') && !classDays.contains('MON')) return true;
    if (targetDay == 'SAT' && classDays.contains('S') && !classDays.contains('SUN')) return true;
    return false;
  }

  Future<void> _setCurrentClass(ClassModel classItem) async {
    final now = DateTime.now();
    final endMinutes = TimeHelper.convertToMinutes(classItem.endTime);
    final endTime = DateTime(now.year, now.month, now.day, endMinutes ~/ 60, endMinutes % 60);
    final remaining = endTime.difference(now);

    final countdown = _formatCountdown(remaining);

    await HomeWidget.saveWidgetData(_keyTitle, classItem.subject);
    await HomeWidget.saveWidgetData(_keySubtitle, 'Current Class');
    await HomeWidget.saveWidgetData(_keyCountdown, countdown);
    await HomeWidget.saveWidgetData(_keyType, 'current_class');
    await HomeWidget.saveWidgetData(_keyEmptyMessage, '');

    await HomeWidget.updateWidget(
      name: 'StudentPalWidgetProvider',
      iOSName: 'StudentPalWidget',
    );
  }

  Future<void> _setNextClass(ClassModel classItem) async {
    final nextTime = _getNextClassDateTime(classItem);
    final remaining = nextTime.difference(DateTime.now());

    final countdown = _formatCountdown(remaining);

    await HomeWidget.saveWidgetData(_keyTitle, classItem.subject);
    await HomeWidget.saveWidgetData(_keySubtitle, 'Next Class');
    await HomeWidget.saveWidgetData(_keyCountdown, countdown);
    await HomeWidget.saveWidgetData(_keyType, 'next_class');
    await HomeWidget.saveWidgetData(_keyEmptyMessage, '');

    await HomeWidget.updateWidget(
      name: 'StudentPalWidgetProvider',
      iOSName: 'StudentPalWidget',
    );
  }

  Future<void> _setNextAssignment(Assignment assignment) async {
    final deadline = assignment.deadlineDate!;
    final remaining = deadline.difference(DateTime.now());

    final countdown = _formatCountdown(remaining);

    await HomeWidget.saveWidgetData(_keyTitle, assignment.title);
    await HomeWidget.saveWidgetData(_keySubtitle, 'Assignment');
    await HomeWidget.saveWidgetData(_keyCountdown, countdown);
    await HomeWidget.saveWidgetData(_keyType, 'assignment');
    await HomeWidget.saveWidgetData(_keyEmptyMessage, '');

    await HomeWidget.updateWidget(
      name: 'StudentPalWidgetProvider',
      iOSName: 'StudentPalWidget',
    );
  }

  Future<void> _setEmptyState(String message) async {
    await HomeWidget.saveWidgetData(_keyTitle, '');
    await HomeWidget.saveWidgetData(_keySubtitle, '');
    await HomeWidget.saveWidgetData(_keyCountdown, '');
    await HomeWidget.saveWidgetData(_keyType, 'empty');
    await HomeWidget.saveWidgetData(_keyEmptyMessage, message);

    await HomeWidget.updateWidget(
      name: 'StudentPalWidgetProvider',
      iOSName: 'StudentPalWidget',
    );
  }

  String _formatCountdown(Duration duration) {
    if (duration.isNegative) {
      return '00:00';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Future<String?> getWidgetTitle() async {
    return HomeWidget.getWidgetData<String>(_keyTitle);
  }

  Future<String?> getWidgetSubtitle() async {
    return HomeWidget.getWidgetData<String>(_keySubtitle);
  }

  Future<String?> getWidgetCountdown() async {
    return HomeWidget.getWidgetData<String>(_keyCountdown);
  }
}
