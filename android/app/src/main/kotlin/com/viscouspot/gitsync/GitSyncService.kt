package com.viscouspot.gitsync

import android.app.Service
import android.content.Intent
import android.os.IBinder
import io.flutter.Log

class GitSyncService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action == null) {
            return START_STICKY
        }

        when (intent.action) {
            "INTENT_SYNC" -> {
                Log.d("ToServiceCommand", "Intent Sync")

                val intentSyncIntent = Intent(this, id.flutter.flutter_background_service.BackgroundService::class.java)
                intentSyncIntent.action = "INTENT_SYNC"
                if (intent.hasExtra("index")) {
                    intentSyncIntent.putExtra("repoman_repoIndex", intent.getIntExtra("index", 0).toString())
                }
                if (intent.hasExtra("message")) {
                    intentSyncIntent.putExtra("commitMessage", intent.getStringExtra("message"))
                }
                startService(intentSyncIntent)
            }
        }

        return START_STICKY
    }

    override fun onBind(p0: Intent?): IBinder? {
        return null
    }
}
