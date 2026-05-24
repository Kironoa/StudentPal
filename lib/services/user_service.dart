import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/app_user.dart';


class UserService {
  final DatabaseHelper _dbHelper;

  UserService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<AppUser?> getUser(int userId) async {
    final user = await _dbHelper.getUser(userId);
    return user == null ? null : AppUser.fromMap(user);
  }

  Future<void> updateProfilePhoto(int userId, String? imagePath) async {
    await _dbHelper.updateUserProfilePhoto(userId, imagePath);
  }
}
