import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:android_intent_plus/android_intent.dart';

class BatteryOptimizationService {
  static final BatteryOptimizationService _instance = BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  Future<bool> requestIgnoreBatteryOptimization() async {
    if (!Platform.isAndroid) {
      debugPrint('[BatteryOptimization] Not Android - skipping');
      return false;
    }

    try {
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );
      
      await intent.launch();
      debugPrint('[BatteryOptimization] Opened system dialog');
      return true;
    } catch (e) {
      debugPrint('[BatteryOptimization] Error: $e');
      return false;
    }
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return false;
    return false;
  }

  Future<void> checkAndPrompt() async {
    debugPrint('[BatteryOptimization] Opening settings for user');
    await requestIgnoreBatteryOptimization();
  }
}