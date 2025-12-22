package app.waqaffelda.waqafer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * AlarmReceiver handles exact alarm broadcasts from AlarmManager.
 * This ensures notifications are shown EXACTLY at prayer times,
 * even when device is in Doze mode or background restrictions are active.
 */
class AlarmReceiver : BroadcastReceiver() {
	companion object {
		private const val TAG = "AlarmReceiver"
		const val ACTION_ALARM = "app.waqaffelda.waqafer.ACTION_PRAYER_ALARM"
		const val ACTION_WIDGET_UPDATE = "app.waqaffelda.waqafer.ACTION_WIDGET_UPDATE"
		const val EXTRA_PRAYER_NAME = "prayer_name"
		const val EXTRA_NOTIFICATION_ID = "notification_id"
		const val EXTRA_TITLE = "title"
		const val EXTRA_BODY = "body"
		const val EXTRA_CHANNEL_ID = "channel_id"
		const val EXTRA_SCHEDULED_TIME = "scheduled_time"
	}

	override fun onReceive(context: Context, intent: Intent) {
		when (intent.action) {
			ACTION_ALARM -> {
				handlePrayerAlarm(context, intent)
			}
			ACTION_WIDGET_UPDATE -> {
				handleWidgetUpdate(context, intent)
			}
			else -> {
				Log.w(TAG, "Received unexpected action: ${intent.action}")
			}
		}
	}

	private fun handlePrayerAlarm(context: Context, intent: Intent) {
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

			// Update widget data to reflect the new prayer state
			updateWidgetAfterPrayerNotification(context, prayerName)
			
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

	private fun handleWidgetUpdate(context: Context, intent: Intent) {
		val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "Prayer"
		
		Log.d(TAG, "🔄 Widget update alarm triggered for $prayerName")

		try {
			// Update widget data to reflect the new prayer state
			updateWidgetAfterPrayerNotification(context, prayerName)
			
			Log.d(TAG, "✅ Widget updated for $prayerName")
		} catch (e: Exception) {
			Log.e(TAG, "❌ Failed to update widget for $prayerName: ${e.message}", e)
		}
	}
	
	/**
	 * Update the home screen widget to reflect the current prayer state
	 * after a notification has been shown
	 */
	private fun updateWidgetAfterPrayerNotification(context: Context, prayerName: String) {
		try {
			Log.d(TAG, "🔄 Updating widget after $prayerName notification")
			
			// Get current prayer times from SharedPreferences
			val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
			val cachedPrayerTimes = prefs.getString("flutter.cached_prayer_times", null)
			
			if (cachedPrayerTimes != null) {
				// Parse the cached prayer times
				val prayerTimes = org.json.JSONArray(cachedPrayerTimes)
				var nextPrayerName = "Subuh"
				var nextPrayerTime = "--:--"
				var countdown = "sedang berlaku"
				
				// Find the next prayer after the current one
				val prayerOrder = arrayOf("Subuh", "Zohor", "Asar", "Maghrib", "Isyak")
				val currentIndex = prayerOrder.indexOf(prayerName)
				
				if (currentIndex >= 0 && currentIndex < prayerOrder.size - 1) {
					// Set next prayer to the following one
					val nextPrayer = prayerOrder[currentIndex + 1]
					nextPrayerName = nextPrayer
					
					// Find the time for the next prayer
					for (i in 0 until prayerTimes.length()) {
						val prayer = prayerTimes.getJSONObject(i)
						if (prayer.getString("name") == nextPrayer) {
							nextPrayerTime = prayer.getString("time")
							break
						}
					}
					
					// Calculate countdown to next prayer
					try {
						val timeParts = nextPrayerTime.split(":")
						if (timeParts.size >= 2) {
							val hour = timeParts[0].toInt()
							val minute = timeParts[1].toInt()
							
							val now = java.util.Calendar.getInstance()
							val nextPrayerCal = java.util.Calendar.getInstance()
							nextPrayerCal.set(java.util.Calendar.HOUR_OF_DAY, hour)
							nextPrayerCal.set(java.util.Calendar.MINUTE, minute)
							nextPrayerCal.set(java.util.Calendar.SECOND, 0)
							
							// If next prayer time has passed today, it's for tomorrow
							if (nextPrayerCal.before(now)) {
								nextPrayerCal.add(java.util.Calendar.DAY_OF_MONTH, 1)
							}
							
							val diffMillis = nextPrayerCal.timeInMillis - now.timeInMillis
							val diffMinutes = (diffMillis / (1000 * 60)).toLong()
							val hours = diffMinutes / 60
							val minutes = diffMinutes % 60
							
							if (hours > 0) {
								countdown = "dalam ${hours}j ${minutes}m"
							} else {
								countdown = "dalam ${minutes}m"
							}
						}
					} catch (e: Exception) {
						Log.w(TAG, "Failed to calculate countdown: ${e.message}")
						countdown = ""
					}
				} else {
					// Last prayer of the day, next is Subuh tomorrow
					nextPrayerName = "Subuh"
					for (i in 0 until prayerTimes.length()) {
						val prayer = prayerTimes.getJSONObject(i)
						if (prayer.getString("name") == "Subuh") {
							nextPrayerTime = prayer.getString("time")
							break
						}
					}
					countdown = "esok"
				}
				
				// Add today's date in Malay format
				val now = java.util.Calendar.getInstance()
				val malayMonths = arrayOf("Jan", "Feb", "Mac", "Apr", "Mei", "Jun", "Jul", "Ogo", "Sep", "Okt", "Nov", "Dis")
				val dateString = "${now.get(java.util.Calendar.DAY_OF_MONTH)} ${malayMonths[now.get(java.util.Calendar.MONTH)]} ${now.get(java.util.Calendar.YEAR)}"
				
				// Update widget data using SharedPreferences (compatible with home_widget)
				val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
				with(prefs.edit()) {
					putString("date", dateString)
					putString("next_prayer_name", nextPrayerName)
					putString("next_prayer_time", nextPrayerTime)
					putString("countdown", countdown)
					apply()
				}
				
				// Trigger widget update
				val intent = Intent(context, com.example.waqaffelda_apk.PrayerTimesWidgetProvider::class.java)
				intent.action = "android.appwidget.action.APPWIDGET_UPDATE"
				context.sendBroadcast(intent)
				
				Log.d(TAG, "✅ Widget updated: next=$nextPrayerName at $nextPrayerTime ($countdown)")
			} else {
				Log.w(TAG, "No cached prayer times found for widget update")
			}
		} catch (e: Exception) {
			Log.e(TAG, "❌ Failed to update widget after notification: ${e.message}", e)
		}
	}
}
