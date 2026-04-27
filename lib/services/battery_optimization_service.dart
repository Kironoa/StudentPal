import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';

/// Checks and requests battery optimization exemption on Android
/// so scheduled notifications fire reliably in the background.
class BatteryOptimizationService {
  static final BatteryOptimizationService _instance =
      BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  static const _channel = MethodChannel(
      'com.studentpal.app/battery');

  /// Returns true if the app is already ignoring battery optimizations.
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

  /// Opens the DIRECT per-app battery optimization dialog.
  /// This is the correct intent — not the general list.
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

  /// Call this on app start. Only prompts if not already exempted.
  Future<void> checkAndPrompt(String packageName) async {
    if (!Platform.isAndroid) return;
    final already = await isIgnoringBatteryOptimizations();
    if (!already) {
      debugPrint(
          '[BatteryOptimization] Requesting exemption...');
      await requestIgnoreBatteryOptimization(packageName);
    } else {
      debugPrint(
          '[BatteryOptimization] Already exempted — skipping.');
    }
  }
}