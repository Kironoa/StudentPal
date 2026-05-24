import 'package:mobile_app/models/app_user.dart';
import 'package:mobile_app/models/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';


class UserSessionService {
  Future<UserSession> loadSession() async {
    final preferences = await SharedPreferences.getInstance();
    return UserSession.fromPreferences(preferences);
  }

  Future<void> saveLoggedInUser(AppUser user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('isLoggedIn', true);
    await preferences.setInt('userId', user.id);
    await preferences.setString('username', user.username);
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }
}
