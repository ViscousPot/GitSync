package com.viscouspot.gitsync.util

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Log
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.FileProvider
import com.viscouspot.gitsync.R
import java.io.File
import java.io.FileWriter
import java.io.PrintWriter
import java.io.StringWriter
import java.time.Instant
import java.time.format.DateTimeFormatter
import kotlin.random.Random

object Logger {
    private const val LOG_FILE_NAME = "logs.txt"
    private val logBuffer = StringBuilder()

    fun log(context: Context, type: String, e: Exception) {
        val sw = StringWriter()
        val pw = PrintWriter(sw)
        e.printStackTrace(pw)
        log(context, type, "Error: $sw")

        sendBugReportNotification(context)
    }

    fun log(context: Context, type: String, message: String) {
        Log.d("///Git Sync//$type", message)

        val logEntry = "${DateTimeFormatter.ISO_INSTANT.format(Instant.now())}  $type\n        - $message\n"
        synchronized(logBuffer) {
            logBuffer.append(logEntry)
        }
    }

    fun flushLogs(context: Context) {
        val file = File(context.filesDir, LOG_FILE_NAME)
        synchronized(logBuffer) {
            if (logBuffer.isNotEmpty()) {
                FileWriter(file, true).use { writer ->
                    writer.append(logBuffer.toString())
                }
                logBuffer.clear()
            }
        }
    }

    fun deleteLogs(context: Context) {
        val file = File(context.filesDir, LOG_FILE_NAME)
        if (file.exists()) {
            file.delete()
        }
    }

    private fun sendBugReportNotification(context: Context) {
        val channelId = "git_sync_bug_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Git Sync Bug",
                NotificationManager.IMPORTANCE_MIN
            )
            val manager = context.getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }

        val emailIntent = createBugReportEmailIntent(context)
        val buttonPendingIntent = PendingIntent.getActivity(context, Random.nextInt(0, 100), emailIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.bug)
            .setContentTitle(context.getString(R.string.report_bug))
            .setContentText(context.getString(R.string.send_bug_report))
            .setContentIntent(buttonPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)

        with(NotificationManagerCompat.from(context)) {
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(context, "${context.getString(R.string.report_bug)} ${context.getString(
                    R.string.enable_notifications)}", Toast.LENGTH_SHORT).show()
                return
            }

            notify(2, builder.build())
        }
    }

    private fun createBugReportEmailIntent(context: Context): Intent {
        val recipient = "bugs.viscouspotential@gmail.com"

        val file = File(context.filesDir, "logs.txt")
        val fileUri = FileProvider.getUriForFile(context, "${context.packageName}.provider", file)

        val emailIntent = Intent(Intent.ACTION_SEND).apply {
            data = Uri.parse("mailto:$recipient")
            type = "message/rfc822"
            putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
            putExtra(Intent.EXTRA_SUBJECT, "Bug Report: Git Sync - [${DateTimeFormatter.ISO_INSTANT.format(Instant.now())}]")
            putExtra(Intent.EXTRA_TEXT, "App logs are attached! \n\n")
            putExtra(Intent.EXTRA_STREAM, fileUri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        return Intent.createChooser(emailIntent, context.getString(R.string.select_email_client))
    }
}