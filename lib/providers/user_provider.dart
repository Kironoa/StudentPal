import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/services/auth_service.dart';

final userProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, userId) async {
  if (userId <= 0) return null;
  return await DatabaseHelper().getUser(userId);
});

final currentUserProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final authService = AuthService();
  final session = await authService.loadSession();
  if (!session.hasActiveUser) return null;
  final user = await DatabaseHelper().getUser(session.userId!);
  return user;
});
