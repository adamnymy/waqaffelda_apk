package app.waqaffelda.waqafer

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.ListenableWorker.Result as WorkResult

class RescheduleWorker(appContext: Context, workerParams: WorkerParameters) : Worker(appContext, workerParams) {
    override fun doWork(): WorkResult {
        Log.i("RescheduleWorker", "RescheduleWorker running - native WorkManager touch on boot")
        // This native worker doesn't run Dart code by itself. It's mainly a "touch"
        // to ensure WorkManager is active after boot. The Dart-side WorkManager
        // periodic task (registered earlier) should survive reboot; if not, users
        // can still Force Reschedule in-app.
        return WorkResult.success()
    }
}
