import 'package:flutter/foundation.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/study_resource_model.dart';


class StudyResourceService {
  final DatabaseHelper _dbHelper;

  StudyResourceService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<List<StudyResource>> getResources(int userId, String category) async {
    final resources = await _dbHelper.getLocalResources(userId, category);
    return resources.map(StudyResource.fromMap).toList();
  }

  Future<void> addResource(int userId, StudyResource resource) async {
    try {
      await _dbHelper.insertResource(
        userId,
        resource.fileName,
        resource.localPath ?? '',
        resource.category,
        content: resource.content ?? '',
      );
    } catch (e) {
      debugPrint("Service Error: Save failed! Error: $e");
    }
  }

  Future<void> deleteResource(int id) async {
    await _dbHelper.deleteResource(id);
  }

  Future<StudyResource?> getResourceById(int id) async {
    final resource = await _dbHelper.getResourceById(id);
    return resource == null ? null : StudyResource.fromMap(resource);
  }

  Future<void> updateResource(StudyResource resource) async {
    if (resource.id == null) return;

    final db = await _dbHelper.database;
    await db.update(
      'study_resources',
      {
        'fileName': resource.fileName,
        'content': resource.content,
        'category': resource.category,
      },
      where: 'id = ?',
      whereArgs: [resource.id],
    );
  }
}
