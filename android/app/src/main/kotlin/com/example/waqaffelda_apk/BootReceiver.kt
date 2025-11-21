package app.waqaffelda.waqafer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            Log.i("BootReceiver", "Device boot or package replaced - scheduling reschedule worker")

            // Enqueue a lightweight native OneTimeWorkRequest to touch WorkManager and allow
            // any WorkManager-based scheduling to re-evaluate. This worker is native-only
            // and simply logs; the Dart WorkManager plugin should also re-run persisted tasks.
            val workRequest = OneTimeWorkRequestBuilder<RescheduleWorker>()
                .setInitialDelay(10, TimeUnit.SECONDS)
                .build()

            WorkManager.getInstance(context).enqueue(workRequest)
        }
    }
}
