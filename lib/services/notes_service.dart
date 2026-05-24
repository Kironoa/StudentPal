import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/study_note_model.dart';


class NotesService {
  final DatabaseHelper _dbHelper;

  NotesService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  
  Future<List<StudyNote>> getNotes(int userId) async {
    final notes = await _dbHelper.getNotes(userId);
    return notes.map(StudyNote.fromMap).toList();
  }

  
  Future<int> saveNote(int userId, StudyNote note) async {
    if (note.id == null) {
      
      return await _dbHelper.insertNote(
        userId,
        note.title,
        note.description ?? '',
        content: note.content ?? '',
      );
    } else {
      
      await _dbHelper.updateNote(
        note.id!,
        note.title,
        note.description ?? '',
        content: note.content ?? '',
      );
      return note.id!;
    }
  }

  
  
  

  Future<void> deleteNote(int id) async {
    await _dbHelper.deleteNote(id);
  }

  Future<List<StudyNote>> searchNotesOffline(int userId, String query) async {
    final notes = await _dbHelper.searchNotesOffline(userId, query);
    return notes.map(StudyNote.fromMap).toList();
  }

  Future<StudyNote?> getNoteById(int id) async {
    final noteMap = await _dbHelper.getNoteById(id);
    if (noteMap == null) return null;
    return StudyNote.fromMap(noteMap);
  }
}
