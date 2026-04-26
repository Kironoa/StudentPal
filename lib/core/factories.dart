import 'package:mobile_app/models/study_note_model.dart';
import 'package:mobile_app/models/assignment_model.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/models/study_resource_model.dart';

/// Factory implementations for model serialization.
abstract class ModelFactory<T> {
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T model);
}

class StudyNoteFactory implements ModelFactory<StudyNote> {
  @override
  StudyNote fromMap(Map<String, dynamic> map) => StudyNote.fromMap(map);

  @override
  Map<String, dynamic> toMap(StudyNote note) => {
        'id': note.id,
        'userId': note.userId,
        'title': note.title,
        'description': note.description,
        'content': note.content,
        'dateCreated': note.dateCreated,
      };
}

class AssignmentFactory implements ModelFactory<Assignment> {
  @override
  Assignment fromMap(Map<String, dynamic> map) => Assignment.fromMap(map);

  @override
  Map<String, dynamic> toMap(Assignment assignment) => assignment.toMap();
}

class ScheduleFactory implements ModelFactory<Schedule> {
  @override
  Schedule fromMap(Map<String, dynamic> map) => Schedule.fromMap(map);

  @override
  Map<String, dynamic> toMap(Schedule schedule) => schedule.toMap();
}

class ResourceFactory implements ModelFactory<StudyResource> {
  @override
  StudyResource fromMap(Map<String, dynamic> map) =>
      StudyResource.fromMap(map);

  @override
  Map<String, dynamic> toMap(StudyResource resource) => resource.toMap();
}