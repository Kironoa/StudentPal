import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/class_model.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:flutter/foundation.dart';

/// Data access layer for class scheduling — wraps DatabaseHelper queries.
class ClassRepository {
  final DatabaseHelper _dbHelper;

  ClassRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<ClassModel>> getAllClasses(int userId) async {
    debugPrint('[ClassRepository] getAllClasses: Fetching all classes for userId=$userId');
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'schedules',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      final classes = maps.map((m) => ClassModel.fromMap(m)).toList();
      debugPrint('[ClassRepository] getAllClasses: Found ${classes.length} classes');
      return classes;
    } catch (e) {
      debugPrint('[ClassRepository] getAllClasses ERROR: $e');
      rethrow;
    }
  }

  Future<ClassModel?> getClassById(int id) async {
    debugPrint('[ClassRepository] getClassById: Fetching class with id=$id');
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'schedules',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return ClassModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('[ClassRepository] getClassById ERROR: $e');
      return null;
    }
  }

  Future<int> createClass(int userId, ClassModel classModel) async {
    debugPrint('[ClassRepository] createClass: Creating class "${classModel.subject}" for userId=$userId');
    debugPrint('[ClassRepository] createClass: startTime=${classModel.startTime}, endTime=${classModel.endTime}');
    try {
      final db = await _dbHelper.database;
      final row = classModel.toMap();
      row['userId'] = userId;
      row.remove('id');
      row.remove('userId');
      row['userId'] = userId;
      final id = await db.insert('schedules', row);
      debugPrint('[ClassRepository] createClass: SUCCESS with id=$id');
      await _scheduleNotification(id, classModel.subject, classModel.startTime);
      return id;
    } catch (e) {
      debugPrint('[ClassRepository] createClass ERROR: $e');
      rethrow;
    }
  }

  Future<void> updateClass(ClassModel classModel) async {
    debugPrint('[ClassRepository] updateClass: Updating class id=${classModel.id}');
    debugPrint('[ClassRepository] updateClass: startTime=${classModel.startTime}, endTime=${classModel.endTime}');
    try {
      final db = await _dbHelper.database;
      final row = classModel.toMap();
      row.remove('id');
      row.remove('userId');
      await db.update(
        'schedules',
        row,
        where: 'id = ?',
        whereArgs: [classModel.id],
      );
      debugPrint('[ClassRepository] updateClass: SUCCESS');
      if (classModel.id != null) {
        await _scheduleNotification(classModel.id!, classModel.subject, classModel.startTime);
      }
    } catch (e) {
      debugPrint('[ClassRepository] updateClass ERROR: $e');
      rethrow;
    }
  }

  Future<void> deleteClass(int id) async {
    debugPrint('[ClassRepository] deleteClass: Deleting class id=$id');
    try {
      try {
        await NotificationService().cancelNotification(id);
      } catch (_) {}
      final db = await _dbHelper.database;
      await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
      debugPrint('[ClassRepository] deleteClass: SUCCESS');
    } catch (e) {
      debugPrint('[ClassRepository] deleteClass ERROR: $e');
      rethrow;
    }
  }

  Future<List<ClassModel>> getClassesForDay(int userId, String dayAbbreviation) async {
    debugPrint('[ClassRepository] getClassesForDay: Fetching classes for userId=$userId, day=$dayAbbreviation');
    try {
      final allClasses = await getAllClasses(userId);
      final dayUpper = dayAbbreviation.toUpperCase();
      final filtered = allClasses.where((c) {
        final classDays = c.days.toUpperCase();
        if (dayUpper == 'WED') return classDays.contains('WED') || (classDays.contains('W') && !classDays.contains('TUE') && !classDays.contains('FRI'));
        if (dayUpper == 'MON') return classDays.contains('MON') || classDays.contains('M');
        if (dayUpper == 'TUE') return classDays.contains('TUE') || classDays.contains('T');
        if (dayUpper == 'THU') return classDays.contains('THU') || (classDays.contains('TH') && !classDays.contains('MON'));
        if (dayUpper == 'FRI') return classDays.contains('FRI');
        if (dayUpper == 'SAT') return classDays.contains('SAT') || classDays.contains('S');
        if (dayUpper == 'SUN') return classDays.contains('SUN');
        return classDays.contains(dayUpper);
      }).toList();
      filtered.sort((a, b) => ClassModel.timeToMinutes(a.startTime).compareTo(ClassModel.timeToMinutes(b.startTime)));
      debugPrint('[ClassRepository] getClassesForDay: Found ${filtered.length} classes');
      return filtered;
    } catch (e) {
      debugPrint('[ClassRepository] getClassesForDay ERROR: $e');
      return [];
    }
  }

  Future<void> _scheduleNotification(int id, String subject, String startTime) async {
    debugPrint('[ClassRepository] _scheduleNotification: Scheduling notification for id=$id, subject=$subject, startTime=$startTime');
    try {
      final startMinutes = ClassModel.timeToMinutes(startTime);
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, startMinutes ~/ 60, startMinutes % 60);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      await NotificationService().scheduleClassAlerts(id: id, subject: subject, startTime: scheduledDate);
      debugPrint('[ClassRepository] _scheduleNotification: SUCCESS');
    } catch (e) {
      debugPrint('[ClassRepository] _scheduleNotification ERROR: $e');
    }
  }

  ClassModel scheduleToClassModel(Schedule schedule) {
    return ClassModel(
      id: schedule.id,
      userId: schedule.userId,
      subject: schedule.subject,
      days: schedule.days,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      room: schedule.room,
      professor: schedule.professor,
    );
  }
}