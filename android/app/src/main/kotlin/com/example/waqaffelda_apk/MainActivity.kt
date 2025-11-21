package app.waqaffelda.waqafer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.app.AlarmManager
import android.app.PendingIntent
import android.provider.Settings
import android.content.Context
import android.util.Log

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
				"scheduleExactAlarm" -> {
					try {
						val notificationId = call.argument<Int>("notificationId")!!
						val triggerAtMillis = call.argument<Long>("triggerAtMillis")!!
						val prayerName = call.argument<String>("prayerName")!!
						val title = call.argument<String>("title")!!
						val body = call.argument<String>("body")!!
						val channelId = call.argument<String>("channelId")!!

						scheduleExactAlarm(notificationId, triggerAtMillis, prayerName, title, body, channelId)
						result.success(true)
					} catch (e: Exception) {
						Log.e("MainActivity", "Failed to schedule exact alarm: ${e.message}", e)
						result.error("error", "Failed to schedule exact alarm: ${e.message}", null)
					}
				}
				"cancelExactAlarm" -> {
					try {
						val notificationId = call.argument<Int>("notificationId")!!
						cancelExactAlarm(notificationId)
						result.success(true)
					} catch (e: Exception) {
						Log.e("MainActivity", "Failed to cancel exact alarm: ${e.message}", e)
						result.error("error", "Failed to cancel exact alarm: ${e.message}", null)
					}
				}
				"cancelAllExactAlarms" -> {
					try {
						// Cancel all prayer notification IDs (1001-1005)
						for (id in 1001..1005) {
							cancelExactAlarm(id)
						}
						result.success(true)
					} catch (e: Exception) {
						Log.e("MainActivity", "Failed to cancel all exact alarms: ${e.message}", e)
						result.error("error", "Failed to cancel all exact alarms: ${e.message}", null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun scheduleExactAlarm(
		notificationId: Int,
		triggerAtMillis: Long,
		prayerName: String,
		title: String,
		body: String,
		channelId: String
	) {
		val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

		// Create scheduled time in ISO 8601 format for execution log
		val scheduledTime = java.time.Instant.ofEpochMilli(triggerAtMillis).toString()

		// Create intent for AlarmReceiver
		val intent = Intent(this, AlarmReceiver::class.java).apply {
			action = AlarmReceiver.ACTION_ALARM
			putExtra(AlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
			putExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, notificationId)
			putExtra(AlarmReceiver.EXTRA_TITLE, title)
			putExtra(AlarmReceiver.EXTRA_BODY, body)
			putExtra(AlarmReceiver.EXTRA_CHANNEL_ID, channelId)
			putExtra(AlarmReceiver.EXTRA_SCHEDULED_TIME, scheduledTime)
		}

		val pendingIntent = PendingIntent.getBroadcast(
			this,
			notificationId,
			intent,
			PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
		)

		// Use setExactAndAllowWhileIdle for guaranteed exact timing even in Doze mode
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			// Android 12+ requires exact alarm permission
			if (alarmManager.canScheduleExactAlarms()) {
				alarmManager.setExactAndAllowWhileIdle(
					AlarmManager.RTC_WAKEUP,
					triggerAtMillis,
					pendingIntent
				)
				Log.d("MainActivity", "✅ Scheduled exact alarm for $prayerName at ${java.util.Date(triggerAtMillis)}")
			} else {
				Log.w("MainActivity", "⚠️ Cannot schedule exact alarm - permission not granted")
				// Fallback to setAndAllowWhileIdle (less precise but better than nothing)
				alarmManager.setAndAllowWhileIdle(
					AlarmManager.RTC_WAKEUP,
					triggerAtMillis,
					pendingIntent
				)
				Log.d("MainActivity", "⚠️ Scheduled inexact alarm for $prayerName (fallback)")
			}
		} else {
			// Pre-Android 12: setExactAndAllowWhileIdle always available
			alarmManager.setExactAndAllowWhileIdle(
				AlarmManager.RTC_WAKEUP,
				triggerAtMillis,
				pendingIntent
			)
			Log.d("MainActivity", "✅ Scheduled exact alarm for $prayerName at ${java.util.Date(triggerAtMillis)}")
		}
	}

	private fun cancelExactAlarm(notificationId: Int) {
		val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

		val intent = Intent(this, AlarmReceiver::class.java).apply {
			action = AlarmReceiver.ACTION_ALARM
		}

		val pendingIntent = PendingIntent.getBroadcast(
			this,
			notificationId,
			intent,
			PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
		)

		alarmManager.cancel(pendingIntent)
		pendingIntent.cancel()
		Log.d("MainActivity", "🗑️ Cancelled exact alarm (id: $notificationId)")
	}
}
