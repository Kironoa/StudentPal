import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/assignment_model.dart';


class AssignmentService {
  final DatabaseHelper _dbHelper;

  AssignmentService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<Assignment>> getAssignments(int userId) async {
    final assignments = await _dbHelper.getAssignments(userId);
    return assignments.map(Assignment.fromMap).toList();
  }

  Future<List<Assignment>> getRecentAssignments(
    int userId, {
    int limit = 3,
  }) async {
    final assignments = await getAssignments(userId);
    return assignments.take(limit).toList();
  }

  Future<void> saveAssignment(int userId, Assignment assignment) async {
    if (assignment.id == null) {
      await _dbHelper.insertAssignment(
        userId,
        assignment.subject ?? '',
        assignment.title,
        assignment.description ?? '',
        assignment.deadline,
      );
      return;
    }

    await _dbHelper.updateAssignment(
      assignment.id!,
      assignment.subject ?? '',
      assignment.title,
      assignment.description ?? '',
      assignment.deadline,
    );
  }

  Future<void> deleteAssignment(int id) async {
    await _dbHelper.deleteAssignment(id);
  }
}
