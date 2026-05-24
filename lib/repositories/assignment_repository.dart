import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/assignment_model.dart';
import 'package:mobile_app/core/base_repository.dart';


class AssignmentRepository implements BaseRepository<Assignment> {
  final DatabaseHelper _dbHelper;

  AssignmentRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<List<Assignment>> getAll(int userId) async {
    final maps = await _dbHelper.getAssignments(userId);
    return maps.map(Assignment.fromMap).toList();
  }

  @override
  Future<Assignment?> getById(int id) async {
    final maps = await _dbHelper.getAssignments(0);
    final found = maps.where((m) => m['id'] == id);
    return found.isNotEmpty ? Assignment.fromMap(found.first) : null;
  }

  @override
  Future<int> create(int userId, Assignment assignment) async {
    return await _dbHelper.insertAssignment(
      userId,
      assignment.subject ?? '',
      assignment.title,
      assignment.description ?? '',
      assignment.deadline,
    );
  }

  @override
  Future<void> update(Assignment assignment) async {
    if (assignment.id == null) return;
    await _dbHelper.updateAssignment(
      assignment.id!,
      assignment.subject ?? '',
      assignment.title,
      assignment.description ?? '',
      assignment.deadline,
    );
  }

  @override
  Future<void> delete(int id) async {
    await _dbHelper.deleteAssignment(id);
  }

  @override
  Future<List<Assignment>> search(int userId, String query) async {
    final all = await getAll(userId);
    return all
        .where((a) =>
            a.title.toLowerCase().contains(query.toLowerCase()) ||
            (a.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
  }
}