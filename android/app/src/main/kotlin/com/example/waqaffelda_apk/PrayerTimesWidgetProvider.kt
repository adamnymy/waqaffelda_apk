package com.example.waqaffelda_apk

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.Intent
import android.app.PendingIntent
import android.app.AlarmManager
import android.os.SystemClock
import es.antonborri.home_widget.HomeWidgetPlugin
import app.waqaffelda.waqafer.MainActivity
import java.text.SimpleDateFormat
import java.util.*

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        
        // Schedule next update at the next prayer time
        scheduleNextUpdate(context)
    }
    
    private fun scheduleNextUpdate(context: Context) {
        try {
            val widgetData = HomeWidgetPlugin.getData(context)
            val nextPrayerTime = widgetData.getString("next_prayer_time", null)
            
            if (nextPrayerTime != null && nextPrayerTime != "--:--") {
                val prayerDateTime = parseTimeToDateTime(nextPrayerTime)
                
                if (prayerDateTime != null && prayerDateTime.after(Date())) {
                    // Schedule update 1 minute after prayer time
                    val updateTime = prayerDateTime.time + 60000 // +1 minute
                    
                    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val intent = Intent(context, PrayerTimesWidgetProvider::class.java)
                    intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    
                    val pendingIntent = PendingIntent.getBroadcast(
                        context,
                        0,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        updateTime,
                        pendingIntent
                    )
                }
            }
        } catch (e: Exception) {
            // Silently fail if scheduling doesn't work
        }
    }
    
    private fun parseTimeToDateTime(timeStr: String): Date? {
        try {
            val calendar = Calendar.getInstance()
            val timeParts = timeStr.split(":")
            
            if (timeParts.size == 2) {
                val hour = timeParts[0].toInt()
                val minute = timeParts[1].toInt()
                
                calendar.set(Calendar.HOUR_OF_DAY, hour)
                calendar.set(Calendar.MINUTE, minute)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
                
                return calendar.time
            }
        } catch (e: Exception) {
            // Return null if parsing fails
        }
        return null
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, app.waqaffelda.waqafer.R.layout.prayer_times_widget)
        
        // Get data from SharedPreferences (saved by Flutter)
        val widgetData = HomeWidgetPlugin.getData(context)
        
        // Update location
        val location = widgetData.getString("location", "Loading...")
        views.setTextViewText(app.waqaffelda.waqafer.R.id.location_text, location)
        
        // Update next prayer info
        val nextPrayerName = widgetData.getString("next_prayer_name", "Subuh")
        val nextPrayerTime = widgetData.getString("next_prayer_time", "--:--")
        val countdown = widgetData.getString("countdown", "")
        
        views.setTextViewText(app.waqaffelda.waqafer.R.id.next_prayer_name, nextPrayerName)
        views.setTextViewText(app.waqaffelda.waqafer.R.id.next_prayer_time, nextPrayerTime)
        views.setTextViewText(app.waqaffelda.waqafer.R.id.countdown_text, countdown)
        
        // Update all prayer times
        val subuhTime = widgetData.getString("subuh_time", "--:--")
        val syurukTime = widgetData.getString("syuruk_time", "--:--")
        val zohorTime = widgetData.getString("zohor_time", "--:--")
        val asarTime = widgetData.getString("asar_time", "--:--")
        val maghribTime = widgetData.getString("maghrib_time", "--:--")
        val isyakTime = widgetData.getString("isyak_time", "--:--")
        
        views.setTextViewText(app.waqaffelda.waqafer.R.id.subuh_time, subuhTime)
        views.setTextViewText(app.waqaffelda.waqafer.R.id.syuruk_time, syurukTime)
        views.setTextViewText(app.waqaffelda.waqafer.R.id.zohor_time, zohorTime)
        views.setTextViewText(app.waqaffelda.waqafer.R.id.asar_time, asarTime)
        views.setTextViewText(app.waqaffelda.waqafer.R.id.maghrib_time, maghribTime)
        views.setTextViewText(app.waqaffelda.waqafer.R.id.isyak_time, isyakTime)
        
        // Set up click intent to open app
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(app.waqaffelda.waqafer.R.id.widget_root, pendingIntent)
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
}
