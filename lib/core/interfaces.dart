import 'package:mobile_app/models/study_note_model.dart';
import 'package:mobile_app/models/assignment_model.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/models/app_user.dart';

/// Abstract contracts (interfaces) for repositories and services.
abstract class INotesRepository {
  Future<List<StudyNote>> getAll(int userId);
  Future<StudyNote?> getById(int id);
  Future<int> create(StudyNote note);
  Future<void> update(StudyNote note);
  Future<void> delete(int id);
  Future<List<StudyNote>> search(int userId, String query);
}

abstract class IAssignmentRepository {
  Future<List<Assignment>> getAll(int userId);
  Future<void> create(int userId, Assignment assignment);
  Future<void> update(Assignment assignment);
  Future<void> delete(int id);
}

abstract class IScheduleRepository {
  Future<List<Schedule>> getAll(int userId);
  Future<void> create(int userId, Schedule schedule);
  Future<void> update(Schedule schedule);
  Future<void> delete(int id);
}

abstract class IAuthService {
  Future<AppUser?> login(String username, String password);
  Future<AppUser?> register(String username, String password);
  Future<void> logout();
  Future<bool> usernameExists(String username);
}

abstract class IUserService {
  Future<AppUser?> getCurrentUser();
  Future<void> updateProfilePhoto(int userId, String? imagePath);
}

abstract class ISettingsService {
  Future<Map<String, dynamic>> getSettings();
  Future<void> saveSettings(Map<String, dynamic> settings);
}