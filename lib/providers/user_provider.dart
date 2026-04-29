import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/helper/db_helper.dart';

final userProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, userId) async {
  return await DatabaseHelper().getUser(userId);
});
