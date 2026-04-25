class AppUser {
  final int id;
  final String username;
  final String? profilePath;
  final String? secretQuestion;
  final String? recoveryToken;

  const AppUser({
    required this.id,
    required this.username,
    this.profilePath,
    this.secretQuestion,
    this.recoveryToken,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int,
      username: (map['username'] ?? 'Student').toString(),
      profilePath: map['profilePath']?.toString(),
      secretQuestion: map['secretQuestion']?.toString(),
      recoveryToken: map['recoveryToken']?.toString(),
    );
  }

  AppUser copyWith({
    int? id,
    String? username,
    String? profilePath,
    String? secretQuestion,
    String? recoveryToken,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePath: profilePath ?? this.profilePath,
      secretQuestion: secretQuestion ?? this.secretQuestion,
      recoveryToken: recoveryToken ?? this.recoveryToken,
    );
  }
}
