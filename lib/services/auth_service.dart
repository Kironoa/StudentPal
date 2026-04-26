import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/app_user.dart';
import 'package:mobile_app/models/user_session.dart';
import 'package:mobile_app/services/user_session_service.dart';

/// Handles user login, registration, and password recovery.
class AuthService {
  final DatabaseHelper _dbHelper;
  final UserSessionService _sessionService;

  AuthService({
    DatabaseHelper? dbHelper,
    UserSessionService? sessionService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _sessionService = sessionService ?? UserSessionService();

  Future<UserSession> loadSession() {
    return _sessionService.loadSession();
  }

  Future<AppUser?> login(String username, String password) async {
    final userMap = await _dbHelper.checkLogin(username, password);
    if (userMap == null) {
      return null;
    }

    final user = AppUser.fromMap(userMap);
    await _sessionService.saveLoggedInUser(user);
    return user;
  }

  Future<bool> usernameExists(String username) async {
    final db = await _dbHelper.database;
    final existingUsers = await db.query(
      'users',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return existingUsers.isNotEmpty;
  }

  Future<AppUser?> register(String username, String password, String secretQuestion, String secretAnswer) async {
    final result = await _dbHelper.registerUserWithRecovery(username, password, secretQuestion, secretAnswer);
    final userId = result['id'] as int;
    final userMap = await _dbHelper.getUser(userId);
    if (userMap == null) {
      return AppUser(id: userId, username: username);
    }
    return AppUser.fromMap(userMap);
  }

  Future<Map<String, dynamic>> registerWithRecoveryToken(
    String username,
    String password,
    String secretQuestion,
    String secretAnswer,
  ) async {
    final result = await _dbHelper.registerUserWithRecovery(username, password, secretQuestion, secretAnswer);
    final userId = result['id'] as int;
    final recoveryToken = result['token'] as String;
    final userMap = await _dbHelper.getUser(userId);
    final user = userMap != null ? AppUser.fromMap(userMap) : AppUser(id: userId, username: username);
    return {'user': user, 'recoveryToken': recoveryToken};
  }

  Future<void> logout() {
    return _sessionService.clearSession();
  }

  Future<String?> getSecretQuestion(String username) {
    return _dbHelper.getSecretQuestion(username);
  }

  Future<bool> verifySecretAnswer(String username, String answer) {
    return _dbHelper.verifySecretAnswer(username, answer);
  }

  Future<Map<String, dynamic>?> verifyRecoveryToken(String token) {
    return _dbHelper.verifyRecoveryToken(token);
  }

  Future<void> updatePassword(int userId, String newPassword) {
    return _dbHelper.updatePassword(userId, newPassword);
  }

  Future<AppUser?> getUserByUsername(String username) async {
    final userMap = await _dbHelper.getUserByUsername(username);
    if (userMap == null) return null;
    return AppUser.fromMap(userMap);
  }
}
