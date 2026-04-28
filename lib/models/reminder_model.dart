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
    return Reminder(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      title: map['title'] as String,
      reminderTime: DateTime.parse(map['reminderTime'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
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
