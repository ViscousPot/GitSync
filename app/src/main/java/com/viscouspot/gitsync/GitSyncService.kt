package com.viscouspot.gitsync

import android.app.ActivityManager
import android.app.Service
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.FileObserver
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.SettingsManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import kotlin.random.Random

class GitSyncService : Service() {
    private val channelId = "git_sync_service_channel"
    private lateinit var fileObserver: FileObserver
    private lateinit var gitManager: GitManager
    private lateinit var settingsManager: SettingsManager

    private var isScheduled: Boolean = false
    private var isSyncing: Boolean = false
    private val debouncePeriod: Long = 10 * 1000

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action == null) {
            return START_STICKY
        }

        when (intent.action) {
            "FORCE_SYNC" -> {
                log("ToServiceCommand", "Force Sync")
                debouncedSync(forced = true)
            }
            "APPLICATION_SYNC" -> {
                log("ToServiceCommand", "AccessibilityService Sync")
                debouncedSync()
            }
            "INTENT_SYNC" -> {
                log("ToServiceCommand", "Intent Sync")
                debouncedSync()
            }
        }

        return START_STICKY
    }


    override fun onCreate() {
        super.onCreate()
        gitManager = GitManager(this)
        settingsManager = SettingsManager(this)

        startForegroundService()
    }

    private fun startForegroundService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Git Sync Service",
                NotificationManager.IMPORTANCE_MIN
            )
            val manager = this.getSystemService(
                NotificationManager::class.java
            )
            manager?.createNotificationChannel(channel)
        }

        val buttonIntent = Intent(this, GitSyncService::class.java).apply {
            action = "FORCE_SYNC"
        }
        val buttonPendingIntent = PendingIntent.getService(this, Random.nextInt(0, 100), buttonIntent, PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.gitsync_notif)
            .addAction(NotificationCompat.Action(null, "Force Sync", buttonPendingIntent))
            .build()

        startForeground(1, notification)
    }

    private fun debouncedSync(forced: Boolean = false) {
        if (isScheduled) {
            return
        } else {
            if (isSyncing) {
                isScheduled = true
                log("Sync", "Sync Scheduled")
                return
            } else {
                sync(forced)
            }
        }
    }

    private fun sync(forced: Boolean = false) {
        log("Sync", "Start Sync")
        isSyncing = true

        val job = CoroutineScope(Dispatchers.Default).launch {
            val authCredentials = settingsManager.getGitAuthCredentials()
            val gitDirPath = settingsManager.getGitDirPath()

            val file = File("${gitDirPath}/.git/config")

            if (!file.exists()) {
                withContext(Dispatchers.Main) {
                    log("Sync", "Repository Not Found")
                    Toast.makeText(
                        applicationContext,
                        "Repository not found!",
                        Toast.LENGTH_SHORT
                    ).show()
                }
                return@launch
            }

            val fileContents = file.readText()

            val gitConfigUrlRegex = "url = (.*?)\\n".toRegex()
            var gitConfigUrlResult = gitConfigUrlRegex.find(fileContents)
            val repoUrl = gitConfigUrlResult?.groups?.get(1)?.value ?: run {
                withContext(Dispatchers.Main) {
                    log("Sync", "Invalid Repository URL")
                    Toast.makeText(
                        applicationContext,
                        "Invalid repository URL!",
                        Toast.LENGTH_SHORT
                    ).show()
                }
                return@launch
            }

            var synced = false

            log("Sync", "Start Pull Repo")
            val pullResult = gitManager.pullRepository(
                gitDirPath,
                authCredentials.first,
                authCredentials.second
            ) {
                synced = true
                displaySyncMessage("Syncing changes...")
            }

            when (pullResult) {
                null -> {
                    log("Sync", "Pull Repo Failed")
                    return@launch
                }

                true -> log("Sync", "Pull Complete")
                false -> log("Sync", "Pull Not Required")
            }

            while (File(gitDirPath, ".git/index.lock").exists()) {
                delay(1000)
            }

            log("Sync", "Start Push Repo")
            val pushResult = gitManager.pushAllToRepository(
                repoUrl,
                gitDirPath,
                authCredentials.first,
                authCredentials.second
            ) {
                if (!synced) {
                    displaySyncMessage("Syncing local changes...")
                }
            }

            when (pushResult) {
                null -> {
                    log("Sync", "Push Repo Failed")
                    return@launch
                }

                true -> log("Sync", "Push Complete")
                false -> log("Sync", "Push Not Required")
            }

            while (File(gitDirPath, ".git/index.lock").exists()) {
                delay(1000)
            }

            if (!(pushResult || pullResult)) {
                if (forced) {
                    displaySyncMessage("Sync not required!")
                }
                return@launch
            } else {
                displaySyncMessage("Sync complete!")
            }

            if (isForeground()) {
                withContext(Dispatchers.Main) {
                    val intent = Intent("REFRESH")
                    LocalBroadcastManager.getInstance(this@GitSyncService).sendBroadcast(intent)
                }
            }
        }

        job.invokeOnCompletion {
            log("Sync", "Sync Complete")
            isSyncing = false
            if (isScheduled) {
                CoroutineScope(Dispatchers.Default).launch {
                    delay(debouncePeriod)
                    log("Sync", "Scheduled Sync Starting")
                    isScheduled = false
                    sync()
                }
            }
        }
    }

    private fun displaySyncMessage(msg: String) {
        if (settingsManager.getSyncMessageEnabled()) {
            Handler(Looper.getMainLooper()).post {
                Toast.makeText(applicationContext, msg, Toast.LENGTH_SHORT)
                    .show()
            }
        }
    }

    private fun isForeground(): Boolean {
        val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val runningTaskInfo = manager.getRunningTasks(1)
        if (runningTaskInfo.isEmpty()) {
            return false
        }
        val componentInfo = runningTaskInfo[0].topActivity
        return componentInfo!!.packageName == packageName
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            fileObserver.stopWatching()
        } catch (e: Exception) { e.printStackTrace() }
    }
}