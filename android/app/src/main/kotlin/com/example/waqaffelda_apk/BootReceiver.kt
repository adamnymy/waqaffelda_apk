package app.waqaffelda.waqafer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.AlarmManager
import android.app.PendingIntent
import android.util.Log
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.*
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received boot intent: $action")

        if (action == Intent.ACTION_BOOT_COMPLETED || action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            // Run reschedule on a background thread
            Thread {
                try {
                    rescheduleAlarms(context)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to reschedule alarms on boot: ${e.message}", e)
                }
            }.start()

            // Also enqueue a tiny WorkManager job to "touch" WorkManager state after boot
            try {
                val workRequest = OneTimeWorkRequestBuilder<RescheduleWorker>()
                    .setInitialDelay(10, TimeUnit.SECONDS)
                    .build()
                WorkManager.getInstance(context).enqueue(workRequest)
                Log.i(TAG, "Enqueued RescheduleWorker to touch WorkManager")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to enqueue RescheduleWorker: ${e.message}")
            }
        }
    }

    private fun rescheduleAlarms(context: Context) {
        Log.d(TAG, "Rescheduling alarms from cached prayer times...")

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val cached = prefs.getString("flutter.cached_prayer_times", null)
        if (cached == null) {
            Log.w(TAG, "No cached prayer times found; nothing to reschedule")
            return
        }

        try {
            val prayerArray = JSONArray(cached)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            for (dayOffset in 0..6) {
                val cal = Calendar.getInstance()
                cal.add(Calendar.DAY_OF_YEAR, dayOffset)

                for (i in 0 until prayerArray.length()) {
                    val obj = prayerArray.getJSONObject(i)
                    val prayerName = obj.optString("name", "")
                    var timeStr = obj.optString("time", "")
                    if (prayerName.isEmpty() || timeStr.isEmpty()) continue

                    // Parse time string robustly (try 24h then 12h)
                    var hour = 0
                    var minute = 0
                    var parsed = false
                    try {
                        if (timeStr.contains("AM", true) || timeStr.contains("PM", true)) {
                            val fmt = SimpleDateFormat("h:mm a", Locale.getDefault())
                            val d = fmt.parse(timeStr)
                            val tmp = Calendar.getInstance()
                            tmp.time = d
                            hour = tmp.get(Calendar.HOUR_OF_DAY)
                            minute = tmp.get(Calendar.MINUTE)
                            parsed = true
                        } else if (timeStr.contains(":")) {
                            val parts = timeStr.split(":")
                            hour = parts[0].toIntOrNull() ?: 0
                            minute = parts[1].toIntOrNull() ?: 0
                            parsed = true
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to parse time '$timeStr' for $prayerName: ${e.message}")
                        parsed = false
                    }

                    if (!parsed) continue

                    val targetCal = Calendar.getInstance()
                    targetCal.timeInMillis = cal.timeInMillis
                    targetCal.set(Calendar.HOUR_OF_DAY, hour)
                    targetCal.set(Calendar.MINUTE, minute)
                    targetCal.set(Calendar.SECOND, 0)
                    targetCal.set(Calendar.MILLISECOND, 0)

                    val triggerAtMillis = targetCal.timeInMillis

                    // Build notification ID mapping (same as Dart)
                    val baseId = when (prayerName) {
                        "Subuh" -> 1001
                        "Zohor" -> 1002
                        "Asar" -> 1003
                        "Maghrib" -> 1004
                        "Isyak" -> 1005
                        else -> 1000
                    }
                    val notificationId = baseId + (dayOffset * 100)

                    try {
                        // Schedule prayer alarm
                        val intentAlarm = Intent(context, AlarmReceiver::class.java).apply {
                            action = AlarmReceiver.ACTION_ALARM
                            putExtra(AlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
                            putExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, notificationId)
                            putExtra(AlarmReceiver.EXTRA_TITLE, "Waktu Solat $prayerName")
                            putExtra(AlarmReceiver.EXTRA_BODY, "Telah masuk waktu solat fardhu $prayerName pada $timeStr")
                            putExtra(AlarmReceiver.EXTRA_CHANNEL_ID, "prayer_$prayerName")
                            putExtra(AlarmReceiver.EXTRA_SCHEDULED_TIME, java.time.Instant.ofEpochMilli(triggerAtMillis).toString())
                        }

                        val pi = PendingIntent.getBroadcast(
                            context,
                            notificationId,
                            intentAlarm,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pi
                        )

                        Log.d(TAG, "Scheduled alarm for $prayerName (id:$notificationId) at ${Date(triggerAtMillis)}")

                        // Schedule widget update alarm
                        val widgetId = notificationId + 10000
                        val intentWidget = Intent(context, AlarmReceiver::class.java).apply {
                            action = AlarmReceiver.ACTION_WIDGET_UPDATE
                            putExtra(AlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
                            putExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, widgetId)
                        }

                        val piWidget = PendingIntent.getBroadcast(
                            context,
                            widgetId,
                            intentWidget,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            piWidget
                        )

                        Log.d(TAG, "Scheduled widget update for $prayerName (id:$widgetId) at ${Date(triggerAtMillis)}")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to schedule alarm for $prayerName: ${e.message}", e)
                    }
                }
            }

            Log.d(TAG, "Reschedule complete")
        } catch (e: Exception) {
            Log.e(TAG, "Error while rescheduling alarms: ${e.message}", e)
        }
    }
}

