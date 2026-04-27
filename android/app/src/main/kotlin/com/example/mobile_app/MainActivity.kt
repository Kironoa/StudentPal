package com.example.mobile_app

import android.content.Context
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val CHANNEL = "com.studentpal.app/battery"

  override fun configureFlutterEngine(
      flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        CHANNEL
    ).setMethodCallHandler { call, result ->
      if (call.method == "isIgnoringBatteryOptimizations") {
        val pm = getSystemService(
            Context.POWER_SERVICE) as PowerManager
        result.success(
            pm.isIgnoringBatteryOptimizations(packageName))
      } else {
        result.notImplemented()
      }
    }
  }
}