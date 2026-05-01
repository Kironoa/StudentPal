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
    final normalizedUsername = username.trim().toLowerCase();
    final userMap = await _dbHelper.checkLogin(normalizedUsername, password);
    if (userMap == null) {
      return null;
    }

    final user = AppUser.fromMap(userMap);
    await _sessionService.saveLoggedInUser(user);
    return user;
  }

  Future<bool> usernameExists(String username) async {
    final normalizedUsername = username.trim().toLowerCase();
    return await _dbHelper.usernameExists(normalizedUsername);
  }

  Future<AppUser?> register(String username, String password, String secretQuestion, String secretAnswer) async {
    final normalizedUsername = username.trim().toLowerCase();
    final result = await _dbHelper.registerUserWithRecovery(normalizedUsername, password, secretQuestion, secretAnswer);
    final userId = result['id'] as int;
    final userMap = await _dbHelper.getUser(userId);
    if (userMap == null) {
      return AppUser(id: userId, username: normalizedUsername);
    }
    return AppUser.fromMap(userMap);
  }

  Future<Map<String, dynamic>> registerWithRecoveryToken(
    String username,
    String password,
    String secretQuestion,
    String secretAnswer,
  ) async {
    final normalizedUsername = username.trim().toLowerCase();
    final result = await _dbHelper.registerUserWithRecovery(normalizedUsername, password, secretQuestion, secretAnswer);
    final userId = result['id'] as int;
    final recoveryToken = result['token'] as String;
    final userMap = await _dbHelper.getUser(userId);
    final user = userMap != null ? AppUser.fromMap(userMap) : AppUser(id: userId, username: normalizedUsername);
    return {'user': user, 'recoveryToken': recoveryToken};
  }

  Future<void> logout() {
    return _sessionService.clearSession();
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final session = await loadSession();
    if (!session.hasActiveUser) return null;
    return await _dbHelper.getUserById(session.userId!);
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
    final normalizedUsername = username.trim().toLowerCase();
    final userMap = await _dbHelper.getUserByUsername(normalizedUsername);
    if (userMap == null) return null;
    return AppUser.fromMap(userMap);
  }
}
