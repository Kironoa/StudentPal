class Reminder {
  final int? id;
  final int userId;
  final String title;
  final DateTime reminderTime;
  final String? note;
  final DateTime createdAt;

  Reminder({
    this.id,
    required this.userId,
    required this.title,
    required this.reminderTime,
    this.note,
    required this.createdAt,
  });

  factory Reminder.fromMap(Map<String, dynamic> map) {
    DateTime parseReminderTime() {
      if (map.containsKey('reminderTime') && map['reminderTime'] != null) {
        return DateTime.parse(map['reminderTime'] as String);
      }
      if (map.containsKey('date') && map.containsKey('time')) {
        final dateStr = map['date'] as String;
        final timeStr = map['time'] as String;
        final date = DateTime.parse(dateStr);
        final parts = timeStr.split(':');
        return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
      }
      return DateTime.now();
    }

    return Reminder(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      title: map['title'] as String,
      reminderTime: parseReminderTime(),
      note: (map['note'] ?? map['description']) as String?,
      createdAt: map.containsKey('createdAt') && map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      'reminderTime': reminderTime.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Reminder copyWith({
    int? id,
    int? userId,
    String? title,
    DateTime? reminderTime,
    String? note,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      reminderTime: reminderTime ?? this.reminderTime,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
