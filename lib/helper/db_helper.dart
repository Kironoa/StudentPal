import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/models/class_model.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/core/crypto_utils.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationSupportDirectory();
    final path = join(directory.path, 'student_pal.db');

    return await openDatabase(
      path,
      version: 19,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            username TEXT, 
            password TEXT, 
            passwordSalt TEXT,
            profilePath TEXT,
            secretQuestion TEXT,
            secretAnswerHash TEXT,
            recoveryToken TEXT
          )
        ''');

        await _createSettingsTable(db);
        await _createSchedulesTable(db);
        await _createAssignmentsTable(db);
        await _createNotesTable(db);
        await _createResourcesTable(db);
        await _createAiCacheTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createSchedulesTable(db);
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE schedules ADD COLUMN userId INTEGER');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE users ADD COLUMN profilePath TEXT');
        }
        if (oldVersion < 5) {
          await _createAssignmentsTable(db);
          await _createNotesTable(db);
        }
        if (oldVersion < 7) await _createSettingsTable(db);
        if (oldVersion < 8) {
          var columns = await db.rawQuery('PRAGMA table_info(assignments)');
          if (!columns.any((column) => column['name'] == 'deadline')) {
            await db
                .execute('ALTER TABLE assignments ADD COLUMN deadline TEXT');
          }
        }
        if (oldVersion < 11) {
          await db.execute('DROP TABLE IF EXISTS study_resources');
          await _createResourcesTable(db);
        }
        if (oldVersion < 12) {
          await db.execute('ALTER TABLE notes ADD COLUMN content TEXT');
        }
        if (oldVersion < 13) {
          var columns = await db.rawQuery('PRAGMA table_info(study_resources)');
          if (!columns.any((column) => column['name'] == 'content')) {
            await db
                .execute('ALTER TABLE study_resources ADD COLUMN content TEXT');
          }
        }
        if (oldVersion < 15) {
          await db.execute('DROP TABLE IF EXISTS ai_cache');
          await _createAiCacheTable(db);
        }
        if (oldVersion < 16) {
          assert(() {
            debugPrint("Upgraded to Version 16: Ready for Manual Notes AI");
            return true;
          }());
        }
        if (oldVersion < 17) {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_schedules_userId ON schedules(userId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_userId ON assignments(userId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_userId ON notes(userId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_study_resources_userId ON study_resources(userId)');
          final columns = await db.rawQuery('PRAGMA table_info(settings)');
          final colNames = columns.map((c) => c['name'] as String).toList();
          if (!colNames.contains('accentColor')) {
            await db.execute('ALTER TABLE settings ADD COLUMN accentColor INTEGER DEFAULT 4278238035');
          }
          if (!colNames.contains('uiScale')) {
            await db.execute('ALTER TABLE settings ADD COLUMN uiScale REAL DEFAULT 1.0');
          }
        }
        if (oldVersion < 18) {
          await db.execute('ALTER TABLE users ADD COLUMN secretQuestion TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN secretAnswerHash TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN recoveryToken TEXT');
        }
        if (oldVersion < 19) {
          await db.execute('ALTER TABLE users ADD COLUMN passwordSalt TEXT');
        }
      },
    );
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY,
        username TEXT,
        isDarkMode INTEGER DEFAULT 0,
        isLoggedIn INTEGER DEFAULT 0,
        accentColor INTEGER DEFAULT 4278238035,
        uiScale REAL DEFAULT 1.0
      )
    ''');
    await db.insert('settings',
        {'id': 1, 'username': 'Student', 'isDarkMode': 0, 'isLoggedIn': 0, 'accentColor': 4278238035, 'uiScale': 1.0});
  }

  Future<void> _createSchedulesTable(Database db) async {
    await db.execute('''
      CREATE TABLE schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER, subject TEXT, days TEXT, startTime TEXT, endTime TEXT, room TEXT, professor TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_schedules_userId ON schedules(userId)');
  }

  Future<void> _createAssignmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE assignments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER, subject TEXT, title TEXT, description TEXT, 
        isCompleted INTEGER DEFAULT 0,
        deadline TEXT 
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_userId ON assignments(userId)');
  }

  Future<void> _createNotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER, title TEXT, description TEXT, content TEXT, dateCreated TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_userId ON notes(userId)');
  }

  Future<void> _createResourcesTable(Database db) async {
    await db.execute('''
      CREATE TABLE study_resources(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        fileName TEXT,
        localPath TEXT,
        category TEXT,
        content TEXT,
        dateAdded TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_study_resources_userId ON study_resources(userId)');
  }

  Future<void> _createAiCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE ai_cache(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        resourceId INTEGER, 
        type TEXT,
        content TEXT,
        createdAt TEXT,
        UNIQUE(resourceId, type)
      )
    ''');
  }

  Future<String?> getCachedAIContent(int resourceId, String type) async {
    final db = await database;
    var res = await db.query("ai_cache",
        where: "resourceId = ? AND type = ?", whereArgs: [resourceId, type]);
    return res.isNotEmpty ? res.first['content'] as String : null;
  }

  Future<void> saveAIContentToCache(
      int resourceId, String type, String content) async {
    final db = await database;
    await db.insert(
        "ai_cache",
        {
          "resourceId": resourceId,
          "type": type,
          "content": content,
          "createdAt": DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearAllAiCache() async {
    final db = await database;
    await db.delete('ai_cache');
  }

  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    List<Map<String, dynamic>> results =
        await db.query('settings', where: 'id = 1');
    if (results.isEmpty) return {};
    
    final settings = results.first;
    if (!settings.containsKey('accentColor') || !settings.containsKey('uiScale')) {
      final columns = await db.rawQuery('PRAGMA table_info(settings)');
      final colNames = columns.map((c) => c['name'] as String).toList();
      if (!colNames.contains('accentColor')) {
        await db.execute('ALTER TABLE settings ADD COLUMN accentColor INTEGER DEFAULT 4278238035');
      }
      if (!colNames.contains('uiScale')) {
        await db.execute('ALTER TABLE settings ADD COLUMN uiScale REAL DEFAULT 1.0');
      }
      results = await db.query('settings', where: 'id = 1');
      return results.isNotEmpty ? results.first : {};
    }
    return settings;
  }

  Future<void> saveSettings({String? name, bool? dark, bool? loggedIn, int? accentColor, double? uiScale}) async {
    final db = await database;
    Map<String, dynamic> data = {};
    if (name != null) data['username'] = name;
    if (dark != null) data['isDarkMode'] = dark ? 1 : 0;
    if (loggedIn != null) data['isLoggedIn'] = loggedIn ? 1 : 0;
    if (accentColor != null) data['accentColor'] = accentColor;
    if (uiScale != null) data['uiScale'] = uiScale;
    if (data.isEmpty) return;
    try {
      await db.update('settings', data, where: 'id = 1');
    } catch (e) {
      if (e.toString().contains('no such column')) {
        final columns = await db.rawQuery('PRAGMA table_info(settings)');
        final colNames = columns.map((c) => c['name'] as String).toList();
        if (!colNames.contains('accentColor')) {
          await db.execute('ALTER TABLE settings ADD COLUMN accentColor INTEGER DEFAULT 4278238035');
        }
        if (!colNames.contains('uiScale')) {
          await db.execute('ALTER TABLE settings ADD COLUMN uiScale REAL DEFAULT 1.0');
        }
        await db.update('settings', data, where: 'id = 1');
      } else {
        rethrow;
      }
    }
  }

  Future<int> registerUser(String username, String password) async {
    final db = await database;
    final salt = CryptoUtils.generateSalt();
    return await db.insert('users', {
      'username': username,
      'password': CryptoUtils.hashPassword(password, salt),
      'passwordSalt': salt,
      'profilePath': null
    });
  }

  Future<Map<String, dynamic>> registerUserWithRecovery(
    String username,
    String password,
    String secretQuestion,
    String secretAnswer,
  ) async {
    final db = await database;
    final salt = CryptoUtils.generateSalt();
    final secretAnswerHash = CryptoUtils.hashPassword(secretAnswer, salt);
    final token = '${username}_${DateTime.now().millisecondsSinceEpoch}';
    final recoveryToken = CryptoUtils.hashPassword(token, salt);
    
    final userId = await db.insert('users', {
      'username': username,
      'password': CryptoUtils.hashPassword(password, salt),
      'passwordSalt': salt,
      'profilePath': null,
      'secretQuestion': secretQuestion,
      'secretAnswerHash': secretAnswerHash,
      'recoveryToken': recoveryToken,
    });
    
    return {'id': userId, 'token': recoveryToken};
  }

  Future<Map<String, dynamic>?> checkLogin(
      String username, String password) async {
    final db = await database;
    final results = await db.query('users',
        where: 'username = ?',
        whereArgs: [username]);
    if (results.isEmpty) return null;
    
    final user = results.first;
    final storedHash = user['password'] as String?;
    final storedSalt = user['passwordSalt'] as String?;
    
    String computedHash;
    if (storedSalt == null || storedSalt.isEmpty) {
      computedHash = CryptoUtils.hashLegacy(password);
    } else {
      computedHash = CryptoUtils.hashPassword(password, storedSalt);
    }
    
    if (computedHash == storedHash) {
      return user;
    }
    return null;
  }

  Future<bool> verifySecretAnswer(String username, String answer) async {
    final db = await database;
    final results = await db.query('users',
        where: 'username = ?',
        whereArgs: [username]);
    if (results.isEmpty) return false;
    
    final user = results.first;
    final storedSalt = user['passwordSalt'] as String?;
    
    String computedHash;
    if (storedSalt == null || storedSalt.isEmpty) {
      computedHash = CryptoUtils.hashLegacy(answer);
    } else {
      computedHash = CryptoUtils.hashPassword(answer, storedSalt);
    }
    
    return computedHash == user['secretAnswerHash'];
  }

  Future<Map<String, dynamic>?> verifyRecoveryToken(String token) async {
    final db = await database;
    final results = await db.query('users',
        where: 'recoveryToken = ?',
        whereArgs: [token]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updatePassword(int userId, String newPassword) async {
    final db = await database;
    final existingUser = await db.query('users',
        where: 'id = ?',
        whereArgs: [userId]);
    if (existingUser.isEmpty) return;
    
    final salt = CryptoUtils.generateSalt();
    await db.update('users',
        {
          'password': CryptoUtils.hashPassword(newPassword, salt),
          'passwordSalt': salt
        },
        where: 'id = ?',
        whereArgs: [userId]);
  }

  Future<String?> getSecretQuestion(String username) async {
    final db = await database;
    final results = await db.query('users',
        columns: ['secretQuestion'],
        where: 'username = ?',
        whereArgs: [username]);
    if (results.isEmpty) return null;
    return results.first['secretQuestion'] as String?;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final results = await db.query('users',
        where: 'username = ?',
        whereArgs: [username]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUser(int userId) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> results =
          await db.query('users', where: 'id = ?', whereArgs: [userId]);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<int> updateUserProfilePhoto(int userId, String? imagePath) async {
    final db = await database;
    return await db.update('users', {'profilePath': imagePath},
        where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> insertAssignment(int userId, String subject, String title,
      String desc, String? deadline) async {
    final db = await database;
    final id = await db.insert('assignments', {
      'userId': userId,
      'subject': subject,
      'title': title,
      'description': desc,
      'isCompleted': 0,
      'deadline': deadline
    });

    final deadlineDate = DateTime.tryParse(deadline ?? '');
    if (deadlineDate != null && id > 0) {
      try {
        await NotificationService().scheduleAssignmentAlerts(
          id: id,
          title: title,
          deadline: deadlineDate,
        );
      } catch (e) {
        debugPrint("Failed to schedule assignment notifications: $e");
      }
    }

    return id;
  }

  Future<int> updateAssignment(int id, String subject, String title,
      String desc, String? deadline) async {
    try {
      await NotificationService().cancelAssignmentNotifications(id);
    } catch (e) {
      debugPrint("Failed to cancel assignment notifications: $e");
    }

    final db = await database;
    final result = await db.update(
        'assignments',
        {
          'subject': subject,
          'title': title,
          'description': desc,
          'deadline': deadline
        },
        where: 'id = ?',
        whereArgs: [id]);

    if (result > 0) {
      final deadlineDate = DateTime.tryParse(deadline ?? '');
      if (deadlineDate != null) {
        try {
          await NotificationService().scheduleAssignmentAlerts(
            id: id,
            title: title,
            deadline: deadlineDate,
          );
        } catch (e) {
          debugPrint("Failed to reschedule assignment notifications: $e");
        }
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getAssignments(int userId) async {
    final db = await database;
    return await db.query('assignments',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'deadline ASC');
  }

  Future<int> deleteAssignment(int id) async {
    try {
      await NotificationService().cancelAssignmentNotifications(id);
    } catch (e) {
      debugPrint("Failed to cancel assignment notifications: $e");
    }
    final db = await database;
    return await db.delete('assignments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertNote(int userId, String title, String desc,
      {String content = ''}) async {
    final db = await database;
    return await db.insert('notes', {
      'userId': userId,
      'title': title,
      'description': desc,
      'content': content,
      'dateCreated': DateTime.now().toIso8601String()
    });
  }

  Future<int> updateNote(int id, String? title, String? desc,
      {String? content}) async {
    final db = await database;
    Map<String, dynamic> data = {
      'dateCreated': DateTime.now().toIso8601String()
    };

    if (title != null) data['title'] = title;
    if (desc != null) data['description'] = desc;
    if (content != null) data['content'] = content;

    return await db.update('notes', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getNotes(int userId) async {
    final db = await database;
    return await db.query('notes',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'dateCreated DESC');
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> searchNotesOffline(
      int userId, String query) async {
    final db = await database;
    return await db.query('notes',
        where:
            'userId = ? AND (title LIKE ? OR description LIKE ? OR content LIKE ?)',
        whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
        orderBy: 'dateCreated DESC');
  }

  Future<Map<String, dynamic>?> getNoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('notes', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<int> insertResource(
      int userId, String name, String localPath, String category,
      {String content = ''}) async {
    final db = await database;
    return await db.insert('study_resources', {
      'userId': userId,
      'fileName': name,
      'localPath': localPath,
      'category': category,
      'content': content,
      'dateAdded': DateTime.now().toIso8601String()
    });
  }

  Future<List<Map<String, dynamic>>> getLocalResources(
      int userId, String category) async {
    final db = await database;
    return await db.query('study_resources',
        where: 'userId = ? AND category = ?',
        whereArgs: [userId, category],
        orderBy: 'dateAdded DESC');
  }

  Future<int> updateResourceName(int id, String newName) async {
    final db = await database;
    return await db.update('study_resources', {'fileName': newName},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteResource(int id) async {
    final db = await database;
    return await db.delete('study_resources', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getResourceById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('study_resources', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<int> insertSchedule(Schedule schedule, int currentUserId) async {
    final db = await database;
    Map<String, dynamic> row = schedule.toMap();
    row['userId'] = currentUserId;
    int id = await db.insert('schedules', row);
    await _syncScheduleNotification(id, schedule.subject, schedule.startTime);
    return id;
  }

  Future<int> updateSchedule(Schedule schedule) async {
    final db = await database;
    int result = await db.update('schedules', schedule.toMap(),
        where: 'id = ?', whereArgs: [schedule.id]);
    if (schedule.id != null) {
      await _syncScheduleNotification(
          schedule.id!, schedule.subject, schedule.startTime);
    }
    return result;
  }

  Future<List<Schedule>> getAllSchedules(int currentUserId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('schedules', where: 'userId = ?', whereArgs: [currentUserId]);
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  Future<int> deleteSchedule(int id) async {
    final db = await database;
    try {
      await NotificationService().cancelNotification(id);
    } catch (_) {}
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ClassModel>> getAllClassModels(int currentUserId) async {
    assert(() {
      debugPrint('[DatabaseHelper] getAllClassModels: Fetching all classes for userId=$currentUserId');
      return true;
    }());
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('schedules', where: 'userId = ?', whereArgs: [currentUserId]);
    final classes = maps.map((m) => ClassModel.fromMap(m)).toList();
    assert(() {
      debugPrint('[DatabaseHelper] getAllClassModels: Found ${classes.length} classes');
      return true;
    }());
    return classes;
  }

  Future<int> insertClassModel(ClassModel classModel, int currentUserId) async {
    assert(() {
      debugPrint('[DatabaseHelper] insertClassModel: Creating class "${classModel.subject}" for userId=$currentUserId');
      debugPrint('[DatabaseHelper] insertClassModel: startTime=${classModel.startTime}, endTime=${classModel.endTime}');
      return true;
    }());
    final db = await database;
    final row = classModel.toMap();
    row['userId'] = currentUserId;
    row.remove('id');
    final id = await db.insert('schedules', row);
    await _syncScheduleNotification(id, classModel.subject, classModel.startTime);
    assert(() {
      debugPrint('[DatabaseHelper] insertClassModel: SUCCESS id=$id');
      return true;
    }());
    return id;
  }

  Future<void> updateClassModel(ClassModel classModel) async {
    assert(() {
      debugPrint('[DatabaseHelper] updateClassModel: Updating class id=${classModel.id}');
      debugPrint('[DatabaseHelper] updateClassModel: startTime=${classModel.startTime}, endTime=${classModel.endTime}');
      return true;
    }());
    final db = await database;
    final row = classModel.toMap();
    row.remove('id');
    row.remove('userId');
    await db.update('schedules', row, where: 'id = ?', whereArgs: [classModel.id]);
    assert(() {
      debugPrint('[DatabaseHelper] updateClassModel: SUCCESS');
      return true;
    }());
    if (classModel.id != null) {
      await _syncScheduleNotification(classModel.id!, classModel.subject, classModel.startTime);
    }
  }

  Future<void> _syncScheduleNotification(
      int id, String subject, String startTimeStr) async {
    try {
      DateTime now = DateTime.now();
      DateTime time;
      try {
        time = DateFormat.jm().parse(startTimeStr);
      } catch (_) {
        time = DateFormat("HH:mm").parse(startTimeStr);
      }
      DateTime scheduledDate =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      await NotificationService().scheduleClassAlerts(
          id: id, subject: subject, startTime: scheduledDate);
    } catch (e) {
      assert(() {
        debugPrint("Sync failed: $e");
        return true;
      }());
    }
  }
}