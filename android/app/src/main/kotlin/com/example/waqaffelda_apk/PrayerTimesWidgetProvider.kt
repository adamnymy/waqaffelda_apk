package com.example.waqaffelda_apk

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.Intent
import android.app.PendingIntent
import androidx.work.*
import es.antonborri.home_widget.HomeWidgetPlugin
import app.waqaffelda.waqafer.MainActivity
import java.util.*
import java.util.concurrent.TimeUnit

class PrayerTimesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        
        // Schedule periodic widget updates
        schedulePeriodicUpdates(context)
    }
    
    private fun schedulePeriodicUpdates(context: Context) {
        try {
            // Create a periodic work request that runs every 15 minutes
            val workRequest = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                15, TimeUnit.MINUTES,
                5, TimeUnit.MINUTES // Flex interval for battery optimization
            )
                .setConstraints(
                    Constraints.Builder()
                        .setRequiresBatteryNotLow(false)
                        .build()
                )
                .build()
            
            // Enqueue with unique name to avoid duplicates
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                "widget_periodic_update",
                ExistingPeriodicWorkPolicy.KEEP,
                workRequest
            )
        } catch (e: Exception) {
            // Silently fail if scheduling doesn't work
        }
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
        
        // Update date
        val date = widgetData.getString("date", "Loading...")
        views.setTextViewText(app.waqaffelda.waqafer.R.id.date_text, date)
        
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
        // Start periodic updates when first widget is added
        schedulePeriodicUpdates(context)
    }

    override fun onDisabled(context: Context) {
        // Cancel periodic updates when last widget is removed
        try {
            WorkManager.getInstance(context).cancelUniqueWork("widget_periodic_update")
        } catch (e: Exception) {
            // Ignore
        }
    }
}

// Worker class for periodic widget updates
class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    
    override fun doWork(): Result {
        return try {
            // Trigger widget update
            val intent = Intent(applicationContext, PrayerTimesWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            
            val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
            val widgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(
                    applicationContext,
                    PrayerTimesWidgetProvider::class.java
                )
            )
            
            if (widgetIds.isNotEmpty()) {
                intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
                applicationContext.sendBroadcast(intent)
            }
            
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }
}
