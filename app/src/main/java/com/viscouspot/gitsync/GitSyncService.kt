package com.viscouspot.gitsync

import android.app.Service
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.os.FileObserver
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class GitSyncService : Service() {

    private lateinit var fileObserver: FileObserver

    override fun onCreate() {
        super.onCreate()
        startForegroundService()
        startFileObserver()
    }

    private fun startForegroundService() {
        val channelId = "git_sync_service_channel"
        val channelName = "Git Sync Service"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationChannel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(notificationChannel)
        }

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Git Sync")
//            .setContentText("Monitoring folder changes...")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .build()

        startForeground(1, notification)
    }

    private fun startFileObserver() {
        Log.d("////", "test")
        val folderPath = Environment.getExternalStorageDirectory().absolutePath + "/Obsidian-TestingOnly" // Change this to your folder path

        fileObserver = object : FileObserver(folderPath, ALL_EVENTS) {
            override fun onEvent(event: Int, path: String?) {
                path?.let {
                    when (event) {
                        CREATE -> onFileCreated(it)
                        DELETE -> onFileDeleted(it)
                        MODIFY -> onFileModified(it)
                        // Handle other events as needed
                    }
                }
            }
        }
        Log.d("////", "test")
        fileObserver.startWatching()
    }

    private fun onFileCreated(path: String) {
        // Your code for handling file creation
        Log.d("////", "File created: $path")
    }

    private fun onFileDeleted(path: String) {
        // Your code for handling file deletion
        Log.d("////", "File deleted: $path")
    }

    private fun onFileModified(path: String) {
        // Your code for handling file modification
        Log.d("////", "File modified: $path")
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        fileObserver.stopWatching()
    }
}