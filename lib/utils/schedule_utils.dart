import 'package:mobile_app/models/class_model.dart';

String dayToAbbrev(String day) {
  final map = {
    'MONDAY': 'MON',
    'TUESDAY': 'TUE',
    'WEDNESDAY': 'WED',
    'THURSDAY': 'THU',
    'FRIDAY': 'FRI',
    'SATURDAY': 'SAT',
    'SUNDAY': 'SUN',
  };
  return map[day.toUpperCase()] ?? day.substring(0, 3).toUpperCase();
}

bool matchesDayFull(String scheduleDays, String currentDay) {
  final abbrev = dayToAbbrev(currentDay);
  if (scheduleDays.contains(abbrev)) return true;
  if (scheduleDays.contains(currentDay.substring(0, 3).toUpperCase())) {
    return true;
  }
  final scheduleDayList = scheduleDays.split(', ');
  final currentShort = currentDay.substring(0, 1).toUpperCase();
  if (scheduleDayList.contains(currentShort)) return true;
  return false;
}

int timeTo24Hour(String timeStr) {
  try {
    final trimmed = timeStr.trim();
    final parts = trimmed.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) hour += 12;
    if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  } catch (e) {
    return 0;
  }
}

List<List<ClassModel>> findConflicts(List<ClassModel> classes) {
  final conflicts = <List<ClassModel>>[];
  final processedPairs = <String>{};

  for (int i = 0; i < classes.length; i++) {
    for (int j = i + 1; j < classes.length; j++) {
      final a = classes[i];
      final b = classes[j];

      final aDays = a.days.toUpperCase().replaceAll(' ', '');
      final bDays = b.days.toUpperCase().replaceAll(' ', '');
      
      final aDayParts = aDays.split(',');
      final bDayParts = bDays.split(',');
      
      final sharedDays = aDayParts.where((d) => bDayParts.contains(d)).toList();
      if (sharedDays.isEmpty) continue;

      final aStart = ClassModel.timeToMinutes(a.startTime);
      final aEnd = ClassModel.timeToMinutes(a.endTime);
      final bStart = ClassModel.timeToMinutes(b.startTime);
      final bEnd = ClassModel.timeToMinutes(b.endTime);

      if (aStart < bEnd && bStart < aEnd) {
        final pairKey = '${a.id}-${b.id}';
        final reverseKey = '${b.id}-${a.id}';
        
        if (!processedPairs.contains(pairKey) && !processedPairs.contains(reverseKey)) {
          processedPairs.add(pairKey);
          conflicts.add([a, b]);
        }
      }
    }
  }

  return conflicts;
}