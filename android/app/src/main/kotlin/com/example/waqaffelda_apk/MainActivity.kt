package com.example.waqaffelda_apk

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.app.AlarmManager
import android.provider.Settings
import android.content.Context

class MainActivity : FlutterActivity() {
	private val CHANNEL = "waqaffelda/exact_alarm"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			CHANNEL
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"canScheduleExactAlarms" -> {
					val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
					val can = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
						alarmManager.canScheduleExactAlarms()
					} else {
						true
					}
					result.success(can)
				}
				"requestExactAlarmPermission" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
						try {
							val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
							intent.data = Uri.parse("package:" + packageName)
							intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
							startActivity(intent)
							result.success(true)
						} catch (e: Exception) {
							result.error("error", "Failed to open exact alarm settings: ${e.message}", null)
						}
					} else {
						result.success(true)
					}
					"openBatteryOptimizationSettings" -> {
						try {
							val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
							intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
							startActivity(intent)
							result.success(true)
						} catch (e: Exception) {
							result.error("error", "Failed to open battery optimization settings: ${e.message}", null)
						}
					}
					"requestIgnoreBatteryOptimizations" -> {
						try {
							val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
							intent.data = Uri.parse("package:" + packageName)
							intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
							startActivity(intent)
							result.success(true)
						} catch (e: Exception) {
							result.error("error", "Failed to request ignore battery optimizations: ${e.message}", null)
						}
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
