import 'package:intl/intl.dart';
import 'package:mobile_app/helper/time_helper.dart';

class ClassModel {
  final int? id;
  final int? userId;
  final String subject;
  final String days;
  final String startTime;
  final String endTime;
  final String room;
  final String professor;

  ClassModel({
    this.id,
    this.userId,
    required this.subject,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.professor,
  });

  String get displayStartTime => TimeHelper.formatTimeForDisplay(startTime);
  String get displayEndTime => TimeHelper.formatTimeForDisplay(endTime);

  int get startMinutes => TimeHelper.convertToMinutes(startTime);
  int get endMinutes => TimeHelper.convertToMinutes(endTime);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'startTime': _to24Hour(startTime),
      'endTime': _to24Hour(endTime),
      'room': room,
      'professor': professor,
      'days': days,
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'],
      userId: map['userId'],
      subject: map['subject'] ?? '',
      days: map['days'] ?? '',
      startTime: _formatFromDb(map['startTime'] ?? '00:00'),
      endTime: _formatFromDb(map['endTime'] ?? '00:00'),
      room: map['room'] ?? '',
      professor: map['professor'] ?? '',
    );
  }

  static String _to24Hour(String timeStr) {
    try {
      final trimmed = timeStr.trim();
      if (!trimmed.contains(' ') && trimmed.contains(':')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
          if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
            return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          }
        }
      }
      try {
        final parsed = DateFormat.jm().parse(trimmed);
        return DateFormat('HH:mm').format(parsed);
      } catch (_) {
        try {
          final parsed = DateFormat('h:mm a').parse(trimmed);
          return DateFormat('HH:mm').format(parsed);
        } catch (_) {
          return '00:00';
        }
      }
    } catch (e) {
      return '00:00';
    }
  }

  static String _formatFromDb(String dbTime) {
    return TimeHelper.formatTimeForDisplay(dbTime);
  }

  static int timeToMinutes(String timeStr) {
    return TimeHelper.convertToMinutes(timeStr);
  }

  static bool isCurrentClassActive(String startTime, String endTime, DateTime now) {
    return TimeHelper.isClassActive(startTime, endTime);
  }

  ClassModel copyWith({
    int? id,
    int? userId,
    String? subject,
    String? days,
    String? startTime,
    String? endTime,
    String? room,
    String? professor,
  }) {
    return ClassModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      days: days ?? this.days,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      professor: professor ?? this.professor,
    );
  }

  static DateTime? nextOccurrence(String days, String startTime) {
    const dayAbbrevToWeekday = {
      'M': DateTime.monday,
      'T': DateTime.tuesday,
      'W': DateTime.wednesday,
      'Th': DateTime.thursday,
      'F': DateTime.friday,
      'S': DateTime.saturday,
      'Sun': DateTime.sunday,
    };

    final dayAbbrevs = days.split(',').map((d) => d.trim()).toList();
    final minutes = timeToMinutes(startTime);
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int offset = 0; offset < 7; offset++) {
      final candidate = today.add(Duration(days: offset));
      final weekday = candidate.weekday;

      String? abbrev;
      for (final entry in dayAbbrevToWeekday.entries) {
        if (entry.value == weekday) {
          abbrev = entry.key;
          break;
        }
      }

      if (abbrev != null && dayAbbrevs.contains(abbrev)) {
        final classTime = DateTime(candidate.year, candidate.month, candidate.day, hour, minute);
        if (classTime.isAfter(now)) {
          return classTime;
        }
      }
    }

    return null;
  }

  @override
  String toString() {
    return 'ClassModel(id: $id, subject: $subject, days: $days, startTime: $startTime, endTime: $endTime, room: $room, professor: $professor)';
  }
}