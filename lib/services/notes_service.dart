import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/study_note_model.dart';

/// Manages study notes CRUD operations.
class NotesService {
  final DatabaseHelper _dbHelper;

  NotesService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Fetches all notes for a user
  Future<List<StudyNote>> getNotes(int userId) async {
    final notes = await _dbHelper.getNotes(userId);
    return notes.map(StudyNote.fromMap).toList();
  }

  /// Handles both Creating and Updating a Note
  Future<int> saveNote(int userId, StudyNote note) async {
    if (note.id == null) {
      // Create new note
      return await _dbHelper.insertNote(
        userId,
        note.title,
        note.description ?? '',
        content: note.content ?? '',
      );
    } else {
      // Update existing note
      await _dbHelper.updateNote(
        note.id!,
        note.title,
        note.description ?? '',
        content: note.content ?? '',
      );
      return note.id!;
    }
  }

  /// Note: saveSummary, saveFlashcards, and saveQuiz were removed from here.
  /// These are now handled by StudyResourceService to ensure they appear
  /// in the dedicated Quizzes, Flashcards, and Summaries tabs.

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
