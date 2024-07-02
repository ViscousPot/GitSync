package com.viscouspot.gitsync

import android.app.ActivityManager
import android.app.Service
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.FileObserver
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.Helper.log
import com.viscouspot.gitsync.util.SettingsManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.io.File

class GitSyncService : Service() {
    private val channelId = "git_sync_service_channel"
    private lateinit var fileObserver: FileObserver
    private lateinit var gitManager: GitManager
    private lateinit var settingsManager: SettingsManager

    private var lastRunTime: Long = 0
    private var isScheduled: Boolean = false
    private var currentSyncJob: Job? = null
    private val delay: Long = 10000

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action == null) {
            return START_STICKY
        }

        when (intent.action) {
            "FORCE_SYNC" -> {
                log(this, "ToServiceCommand", "Force Sync")
                sync()
            }
            "APPLICATION_SYNC" -> {
                log(this, "ToServiceCommand", "AccessibilityService Sync")
                sync()
            }
        }

        return START_STICKY
    }


    override fun onCreate() {
        super.onCreate()
        gitManager = GitManager(this)
        settingsManager = SettingsManager(this)

        startForegroundService()

        if (settingsManager.getSyncOnFileChanges()) {
            startFileObserver()
        }
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

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher_foreground)
            .build()

        startForeground(1, notification)
    }

    private fun startFileObserver() {
        log(applicationContext, "FileObserver", "Observer Created")
        fileObserver = object : FileObserver(File(settingsManager.getGitDirPath()), ALL_EVENTS) {
            override fun onEvent(event: Int, path: String?) {
                val eventMap = hashMapOf(
                    1 to "ACCESS",
                    4095 to "ALL_EVENTS",
                    4 to "ATTRIB",
                    16 to "CLOSE_NOWRITE",
                    8 to "CLOSE_WRITE",
                    256 to "CREATE",
                    512 to "DELETE",
                    1024 to "DELETE_SELF",
                    2 to "MODIFY",
                    64 to "MOVED_FROM",
                    128 to "MOVED_TO",
                    2048 to "MOVE_SELF",
                    32 to "OPEN"
                )
                path?.let {
                    when (event) {
                        OPEN, CREATE, DELETE, MODIFY, MOVED_FROM, MOVED_TO -> {
                            log(applicationContext, "FileObserverEvent", eventMap[event].toString())
                            debouncedSync()
                        }
                    }
                }
            }
        }

        log(applicationContext, "FileObserver", "Watching Started")
        fileObserver.startWatching()
    }

    fun debouncedSync() {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastRunTime >= delay) {
            sync()
            lastRunTime = currentTime
            isScheduled = false
        } else if (!isScheduled) {
            isScheduled = true
            log(applicationContext, "Sync", "Sync Scheduled")
            CoroutineScope(Dispatchers.Default).launch {
                delay(delay - (currentTime - lastRunTime))
                sync()
                lastRunTime = System.currentTimeMillis()
                isScheduled = false
            }
        }
    }

    private fun sync() {
        log(applicationContext, "Sync", "Start Sync")

        currentSyncJob?.cancel()

        currentSyncJob = CoroutineScope(Dispatchers.Default).launch {
            if (Looper.myLooper() == null) {
                Looper.prepare()
            }

            val authCredentials = settingsManager.getGitAuthCredentials()
            val gitDirPath = settingsManager.getGitDirPath()

            val file = File("${gitDirPath}/.git/config")

            if (!file.exists()) {
                log(applicationContext, "Sync", "Repository Not Found")
                Toast.makeText(applicationContext, "Repository not found!", Toast.LENGTH_SHORT).show()
                return@launch
            }

            if (!isActive) return@launch

            val fileContents = file.readText()

            val gitConfigUrlRegex = "url = (.*?)\\n".toRegex()
            var gitConfigUrlResult = gitConfigUrlRegex.find(fileContents)
            val repoUrl = gitConfigUrlResult?.groups?.get(1)?.value

            log(applicationContext, "Sync", "Start Pull Repo")
            val pullResult = gitManager.pullRepository(gitDirPath, authCredentials.first, authCredentials.second)

            when (pullResult) {
                null -> {
                    lastRunTime -= delay
                    log(applicationContext, "Sync", "Pull Repo Failed")
                    return@launch
                }
                true -> log(applicationContext, "Sync", "Pull Complete")
                false -> log(applicationContext, "Sync", "Pull Not Required")
            }

            if (!isActive) return@launch

            while (File("$gitDirPath/.git", "index.lock").exists()) {
                delay(1000)
            }

            log(applicationContext, "Sync", "Start Push Repo")
            val pushResult = gitManager.pushAllToRepository(repoUrl.toString(), gitDirPath, authCredentials.first, authCredentials.second)

            when (pushResult) {
                null -> {
                    lastRunTime -= delay
                    log(applicationContext, "Sync", "Push Repo Failed")
                    return@launch
                }
                true -> log(applicationContext, "Sync", "Push Complete")
                false -> log(applicationContext, "Sync", "Push Not Required")
            }

            while (File("$gitDirPath/.git", "index.lock").exists()) {
                delay(1000)
            }

            if (!(pushResult == true || pullResult == true)) {
                lastRunTime -= delay
                return@launch
            }

            if (isForeground()) {
                val intent = Intent("REFRESH")
                LocalBroadcastManager.getInstance(this@GitSyncService).sendBroadcast(intent)
            }

            if (settingsManager.getSyncMessageEnabled()) {
                Toast.makeText(applicationContext, "Files synced!", Toast.LENGTH_SHORT).show()
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