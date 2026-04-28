class AppUser {
  final int id;
  final String username;
  final String? profilePath;
  final String? secretQuestion;
  final String? recoveryToken;
  final String? fullName;
  final String? nickname;
  final String? school;
  final String? course;
  final String? yearLevel;

  const AppUser({
    required this.id,
    required this.username,
    this.profilePath,
    this.secretQuestion,
    this.recoveryToken,
    this.fullName,
    this.nickname,
    this.school,
    this.course,
    this.yearLevel,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int,
      username: (map['username'] ?? 'Student').toString(),
      profilePath: map['profilePath']?.toString(),
      secretQuestion: map['secretQuestion']?.toString(),
      recoveryToken: map['recoveryToken']?.toString(),
      fullName: map['fullName']?.toString(),
      nickname: map['nickname']?.toString(),
      school: map['school']?.toString(),
      course: map['course']?.toString(),
      yearLevel: map['yearLevel']?.toString(),
    );
  }

  AppUser copyWith({
    int? id,
    String? username,
    String? profilePath,
    String? secretQuestion,
    String? recoveryToken,
    String? fullName,
    String? nickname,
    String? school,
    String? course,
    String? yearLevel,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePath: profilePath ?? this.profilePath,
      secretQuestion: secretQuestion ?? this.secretQuestion,
      recoveryToken: recoveryToken ?? this.recoveryToken,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      school: school ?? this.school,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
    );
  }
}
