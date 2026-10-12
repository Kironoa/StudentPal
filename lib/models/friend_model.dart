class PeerUser {
  final int id;
  final String username;
  final String? fullName;
  final String? nickname;
  final String? school;
  final String? course;
  final String? yearLevel;
  final String? profilePath;
  final String friendshipStatus;
  final int? friendshipId;

  const PeerUser({
    required this.id,
    required this.username,
    this.fullName,
    this.nickname,
    this.school,
    this.course,
    this.yearLevel,
    this.profilePath,
    this.friendshipStatus = 'none',
    this.friendshipId,
  });

  factory PeerUser.fromMap(Map<String, dynamic> map) {
    return PeerUser(
      id: (map['id'] as num).toInt(),
      username: (map['username'] ?? 'Student').toString(),
      fullName: map['fullName']?.toString(),
      nickname: map['nickname']?.toString(),
      school: map['school']?.toString(),
      course: map['course']?.toString(),
      yearLevel: map['yearLevel']?.toString(),
      profilePath: map['profilePath']?.toString(),
      friendshipStatus:
          (map['friendshipStatus'] as String?) ?? 'none',
      friendshipId: (map['friendshipId'] as num?)?.toInt(),
    );
  }

  String get displayName {
    if (nickname != null && nickname!.trim().isNotEmpty) {
      return nickname!.trim();
    }
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    return username;
  }

  String get subtitle {
    final parts = <String>[];
    if (course != null && course!.trim().isNotEmpty) {
      parts.add(course!.trim());
    }
    if (school != null && school!.trim().isNotEmpty) {
      parts.add(school!.trim());
    }
    if (parts.isEmpty) return '@$username';
    return parts.join(' • ');
  }

  bool get isFriend => friendshipStatus == 'accepted';
  bool get isPendingSent => friendshipStatus == 'pending_sent';
  bool get isPendingReceived => friendshipStatus == 'pending_received';
}
