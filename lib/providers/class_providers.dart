import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/class_model.dart';
import 'package:mobile_app/models/assignment_model.dart';
import 'package:mobile_app/repositories/class_repository.dart';
import 'package:mobile_app/services/assignment_service.dart';
import 'package:mobile_app/providers/class_update_notifier.dart';
import 'package:mobile_app/utils/schedule_utils.dart';


final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository();
});

final assignmentServiceProvider = Provider<AssignmentService>((ref) {
  return AssignmentService();
});

final assignmentsProvider =
    FutureProvider.family<List<Assignment>, int>((ref, userId) async {
  final assignmentService = ref.read(assignmentServiceProvider);
  return assignmentService.getRecentAssignments(userId);
});

final classListProvider =
    FutureProvider.family<List<ClassModel>, int>((ref, userId) async {
  final repository = ref.read(classRepositoryProvider);

  void listener() => ref.invalidateSelf();
  ClassUpdateProvider.instance.addListener(listener);
  ref.onDispose(() => ClassUpdateProvider.instance.removeListener(listener));

  return repository.getAllClasses(userId);
});

final todayClassesProvider =
    FutureProvider.family<List<ClassModel>, ({int userId, String day})>(
        (ref, params) async {
  final repository = ref.read(classRepositoryProvider);
  return repository.getClassesForDay(params.userId, params.day);
});

final clockTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

final minuteTickProvider = StreamProvider<DateTime>((ref) async* {
  final now = DateTime.now();
  final msUntilNextMinute = ((60 - now.second) * 1000) - now.millisecond;
  await Future.delayed(Duration(milliseconds: msUntilNextMinute));
  yield DateTime.now();
  yield* Stream.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

final formattedTimeProvider = Provider<String>((ref) {
  ref.watch(clockTickProvider);
  return DateFormat('HH:mm:ss').format(DateTime.now());
});

final formattedDateProvider = Provider<String>((ref) {
  ref.watch(minuteTickProvider);
  return DateFormat('EEE, MMM dd, yyyy').format(DateTime.now());
});

final currentClassProvider = Provider.family<ClassModel?, int>((ref, userId) {
  final classesAsync = ref.watch(classListProvider(userId));
  final timeAsync = ref.watch(minuteTickProvider);

  return classesAsync.when(
    data: (classes) => timeAsync.when(
      data: (now) {
        final nowDayName = DateFormat('EEEE').format(now);
        final dayAbbrev = dayToAbbrev(nowDayName);
        final dayShort = nowDayName.substring(0, 1).toUpperCase();
        final dayFull = nowDayName.substring(0, 3).toUpperCase();

        final todayClassesList = classes.where((c) {
          final classDays = c.days.toUpperCase();
          return classDays.contains(dayAbbrev.toUpperCase()) ||
              classDays.contains(dayFull) ||
              classDays.contains(dayShort) ||
              matchesDayFull(classDays, nowDayName.toUpperCase());
        }).toList();

        todayClassesList.sort((a, b) => ClassModel.timeToMinutes(a.startTime)
            .compareTo(ClassModel.timeToMinutes(b.startTime)));

        for (final schedule in todayClassesList) {
          if (ClassModel.isCurrentClassActive(
              schedule.startTime, schedule.endTime, now)) {
            return schedule;
          }
        }
        return null;
      },
      loading: () => null,
      error: (_, __) => null,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

final nextClassProvider = Provider.family<ClassModel?, int>((ref, userId) {
  final classesAsync = ref.watch(classListProvider(userId));
  final timeAsync = ref.watch(minuteTickProvider);

  return classesAsync.when(
    data: (classes) => timeAsync.when(
      data: (now) {
        final nowDayName = DateFormat('EEEE').format(now);
        final dayAbbrev = dayToAbbrev(nowDayName);
        final dayShort = nowDayName.substring(0, 1).toUpperCase();
        final dayFull = nowDayName.substring(0, 3).toUpperCase();

        final todayClassesList = classes.where((c) {
          final classDays = c.days.toUpperCase();
          return classDays.contains(dayAbbrev.toUpperCase()) ||
              classDays.contains(dayFull) ||
              classDays.contains(dayShort) ||
              matchesDayFull(classDays, nowDayName.toUpperCase());
        }).toList();

        todayClassesList.sort((a, b) => ClassModel.timeToMinutes(a.startTime)
            .compareTo(ClassModel.timeToMinutes(b.startTime)));

        Duration minGap = const Duration(days: 1);
        ClassModel? foundNext;

        for (final schedule in todayClassesList) {
          final startMinutes = ClassModel.timeToMinutes(schedule.startTime);
          final scheduledTime = DateTime(now.year, now.month, now.day,
              startMinutes ~/ 60, startMinutes % 60);
          if (scheduledTime.isAfter(now)) {
            final gap = scheduledTime.difference(now);
            if (gap < minGap) {
              minGap = gap;
              foundNext = schedule;
            }
          }
        }
        return foundNext;
      },
      loading: () => null,
      error: (_, __) => null,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});