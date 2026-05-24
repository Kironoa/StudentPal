import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/study_note_model.dart';
import 'package:mobile_app/core/base_repository.dart';


class NotesRepository implements BaseRepository<StudyNote> {
  final DatabaseHelper _dbHelper;

  NotesRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<List<StudyNote>> getAll(int userId) async {
    final maps = await _dbHelper.getNotes(userId);
    return maps.map(StudyNote.fromMap).toList();
  }

  @override
  Future<StudyNote?> getById(int id) async {
    final map = await _dbHelper.getNoteById(id);
    return map != null ? StudyNote.fromMap(map) : null;
  }

  @override
  Future<int> create(int userId, StudyNote note) async {
    return await _dbHelper.insertNote(
      userId,
      note.title,
      note.description ?? '',
      content: note.content ?? '',
    );
  }

  @override
  Future<void> update(StudyNote note) async {
    if (note.id == null) return;
    await _dbHelper.updateNote(
      note.id!,
      note.title,
      note.description ?? '',
      content: note.content ?? '',
    );
  }

  @override
  Future<void> delete(int id) async {
    await _dbHelper.deleteNote(id);
  }

  @override
  Future<List<StudyNote>> search(int userId, String query) async {
    final maps = await _dbHelper.searchNotesOffline(userId, query);
    return maps.map(StudyNote.fromMap).toList();
  }
}