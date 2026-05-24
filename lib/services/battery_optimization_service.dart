import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';



class BatteryOptimizationService {
  static final BatteryOptimizationService _instance =
      BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  static const _channel = MethodChannel(
      'com.studentpal.app/battery');

  
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>(
          'isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  
  
  Future<bool> requestIgnoreBatteryOptimization(
      String packageName) async {
    if (!Platform.isAndroid) return false;
    try {
      final intent = AndroidIntent(
        action:
            'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:$packageName',
      );
      await intent.launch();
      return true;
    } catch (e) {
      debugPrint('[BatteryOptimization] Error: $e');
      return false;
    }
  }

  
  Future<void> checkAndPrompt(String packageName) async {
    if (!Platform.isAndroid) return;
    final already = await isIgnoringBatteryOptimizations();
    if (!already) {
      debugPrint(
          '[BatteryOptimization] Requesting exemption...');
      await requestIgnoreBatteryOptimization(packageName);
    } else {
      debugPrint(
          '[BatteryOptimization] Already exempted â€” skipping.');
    }
  }
}