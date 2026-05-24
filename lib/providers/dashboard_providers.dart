import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:intl/intl.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/models/app_user.dart';
import 'package:mobile_app/models/schedule_model.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/utils/schedule_utils.dart';


final databaseHelperProvider = rp.Provider<DatabaseHelper>((ref) => DatabaseHelper());
final userServiceProvider = rp.Provider<UserService>((ref) => UserService());

final userDataProvider = rp.FutureProvider.family<AppUser?, int>((ref, userId) async {
  final userService = ref.read(userServiceProvider);
  return userService.getUser(userId);
});

final schedulesProvider = rp.FutureProvider.family<List<Schedule>, int>((ref, userId) async {
  final dbHelper = ref.read(databaseHelperProvider);
  return dbHelper.getAllSchedules(userId);
});

final todaySchedulesProvider = rp.FutureProvider.family<List<Schedule>, int>((ref, userId) async {
  final schedules = await ref.watch(schedulesProvider(userId).future);
  final now = DateTime.now();
  final currentDayName = DateFormat('EEEE').format(now);
  final dayAbbrev = dayToAbbrev(currentDayName);
  final dayShort = currentDayName.substring(0, 1).toUpperCase();
  final dayFull = currentDayName.substring(0, 3).toUpperCase();
  
  return schedules.where((s) {
    final scheduleDays = s.days.toUpperCase();
    return scheduleDays.contains(dayAbbrev.toUpperCase()) ||
        scheduleDays.contains(dayFull) ||
        scheduleDays.contains(dayShort) ||
        matchesDayFull(scheduleDays, currentDayName.toUpperCase());
  }).toList()..sort((a, b) => timeTo24Hour(a.startTime).compareTo(timeTo24Hour(b.startTime)));
});