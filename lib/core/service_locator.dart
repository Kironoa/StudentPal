import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/repositories/notes_repository.dart';
import 'package:mobile_app/repositories/assignment_repository.dart';
import 'package:mobile_app/repositories/schedule_repository.dart';


class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  DatabaseHelper? _dbHelper;

  DatabaseHelper get dbHelper {
    _dbHelper ??= DatabaseHelper();
    return _dbHelper!;
  }

  void register<T>(T service) {
    _services[T] = service;
  }

  void registerLazy<T>(T Function() factory) {
    _services[T] = factory;
  }

  T call<T>() {
    final service = _services[T];
    if (service is T Function()) {
      final instance = service();
      _services[T] = instance;
      return instance;
    }
    if (service is T) {
      return service;
    }
    throw Exception('Service $T not registered');
  }

  bool isRegistered<T>() => _services.containsKey(T);

  void reset() {
    _services.clear();
    _dbHelper = null;
  }

  void registerDefaults() {
    register<NotesRepository>(NotesRepository());
    register<AssignmentRepository>(AssignmentRepository());
    register<ScheduleRepository>(ScheduleRepository());
  }
}

final locator = ServiceLocator();