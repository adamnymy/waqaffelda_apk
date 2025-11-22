package app.waqaffelda.waqafer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * AlarmReceiver handles exact alarm broadcasts from AlarmManager.
 * This ensures notifications are shown EXACTLY at prayer times,
 * even when device is in Doze mode or background restrictions are active.
 */
class AlarmReceiver : BroadcastReceiver() {
	companion object {
		private const val TAG = "AlarmReceiver"
		const val ACTION_ALARM = "app.waqaffelda.waqafer.ACTION_PRAYER_ALARM"
		const val EXTRA_PRAYER_NAME = "prayer_name"
		const val EXTRA_NOTIFICATION_ID = "notification_id"
		const val EXTRA_TITLE = "title"
		const val EXTRA_BODY = "body"
		const val EXTRA_CHANNEL_ID = "channel_id"
		const val EXTRA_SCHEDULED_TIME = "scheduled_time"
	}

	override fun onReceive(context: Context, intent: Intent) {
		if (intent.action != ACTION_ALARM) {
			Log.w(TAG, "Received unexpected action: ${intent.action}")
			return
		}

		val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "Prayer"
		val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, 1000)
		val title = intent.getStringExtra(EXTRA_TITLE) ?: "Prayer Time"
		val body = intent.getStringExtra(EXTRA_BODY) ?: "It's time for prayer"
		val channelId = intent.getStringExtra(EXTRA_CHANNEL_ID) ?: "prayer_default"
		val scheduledTime = intent.getStringExtra(EXTRA_SCHEDULED_TIME)

		Log.d(TAG, "🔔 Exact alarm triggered for $prayerName (id: $notificationId)")

		try {
			// Log execution timestamp to SharedPreferences for Execution Log
			val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
			val keyBase = title.lowercase().replace(" ", "_").replace("solat_", "")
			val executedAt = java.time.Instant.now().toString()
			
			with(prefs.edit()) {
				// Save executed timestamp
				putString("flutter.executed_$keyBase", executedAt)
				
				// Save scheduled timestamp if provided
				if (scheduledTime != null) {
					putString("flutter.scheduled_$keyBase", scheduledTime)
					
					// Calculate elapsed time
					try {
						val scheduled = java.time.Instant.parse(scheduledTime)
						val executed = java.time.Instant.parse(executedAt)
						val elapsed = java.time.Duration.between(scheduled, executed).seconds
						Log.d(TAG, "⏱️ Elapsed time for $prayerName: ${elapsed}s (Scheduled: $scheduledTime, Executed: $executedAt)")
					} catch (e: Exception) {
						Log.w(TAG, "Failed to calculate elapsed time: ${e.message}")
					}
				}
				
				apply()
			}

			// Create notification
			val notification = NotificationCompat.Builder(context, channelId)
				.setSmallIcon(R.mipmap.ic_launcher)
				.setContentTitle(title)
				.setContentText(body)
				.setPriority(NotificationCompat.PRIORITY_HIGH)
				.setCategory(NotificationCompat.CATEGORY_ALARM)
				.setAutoCancel(true)
				.setVibrate(longArrayOf(0, 500, 250, 500))
				.build()

			// Show notification
			val notificationManager = NotificationManagerCompat.from(context)
			notificationManager.notify(notificationId, notification)

			Log.d(TAG, "✅ Notification shown for $prayerName")
		} catch (e: Exception) {
			Log.e(TAG, "❌ Failed to show notification for $prayerName: ${e.message}", e)
		}
	}
}
