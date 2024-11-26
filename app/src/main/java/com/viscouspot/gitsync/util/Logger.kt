package com.viscouspot.gitsync.util

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import com.viscouspot.gitsync.R
import java.io.PrintWriter
import android.Manifest
import android.net.Uri
import java.io.StringWriter
import java.time.Instant
import java.time.format.DateTimeFormatter
import kotlin.random.Random
import androidx.core.app.NotificationCompat
import android.app.NotificationChannel
import android.app.NotificationManager
import com.viscouspot.gitsync.BuildConfig

enum class LogType(val type: String) {
    TEST("TEST"),
    Global("Global"),
    ToServiceCommand("ToServiceCommand"),
    AccessibilityService("AccessibilityService"),

    Sync("Sync"),
    AbortMerge("AbortMerge"),
    GetRepos("GetRepos"),
    CloneRepo("CloneRepo"),
    PullFromRepo("PullFromRepo"),
    PushToRepo("PushToRepo"),
    GitStatus("GitStatus"),
    RecentCommits("RecentCommits"),

    TransportException("TransportException"),

    GithubOAuthFlow("GithubOAuthFlow"),
    GithubAuthCredentials("GithubAuthCredentials"),
    GiteaOAuthFlow("GiteaOAuthFlow"),
    GiteaAuthCredentials("GiteaAuthCredentials"),

}

object Logger {
    private val last5Logs = mutableListOf<Pair<LogType, String>>()
    private const val ERROR_NOTIFICATION_ID = 1757

    fun log(context: Context, type: LogType, e: Throwable) {
        val sw = StringWriter()
        val pw = PrintWriter(sw)
        e.printStackTrace(pw)
        log(type, "Error: $sw")
        addToLast5Logs(type, "Error: $sw")

        sendBugReportNotification(context)
    }

    fun log(type: LogType, message: String) {
        Log.d("///Git Sync//${type.type}", message)
        addToLast5Logs(type, message)
    }

    fun log(message: Any?) {
        Log.d("///Git Sync//${LogType.TEST.type}", message?.toString() ?: "null")
        addToLast5Logs(LogType.TEST, message?.toString() ?: "null")
    }

    private fun addToLast5Logs(type: LogType, message: String) {
        last5Logs.add(Pair(type, message))
        if (last5Logs.size > 5) {
            last5Logs.removeAt(0)
        }
    }

    private fun sendBugReportNotification(context: Context) {
        val channelId = "git_sync_bug_channel"
        val channel = NotificationChannel(
            channelId,
            "Git Sync Bug",
            NotificationManager.IMPORTANCE_HIGH
        )
        val manager = context.getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(channel)

        val emailIntent = createBugReportEmailIntent(context)
        val buttonPendingIntent = PendingIntent.getActivity(context, Random.nextInt(0, 100), emailIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.bug)
            .setContentTitle(context.getString(R.string.report_bug))
            .setContentText(last5Logs.last().second.substringBefore("\n"))
            .setContentIntent(buttonPendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)

        with(NotificationManagerCompat.from(context)) {
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(context, "${context.getString(R.string.report_bug)} ${context.getString(
                    R.string.enable_notifications)}", Toast.LENGTH_LONG).show()
                return
            }

            notify(ERROR_NOTIFICATION_ID, builder.build())
        }
    }

    private fun createBugReportEmailIntent(context: Context): Intent {
        val recipient = "bugs.viscouspotential@gmail.com"
        val last5LogsString = last5Logs.joinToString(separator = "\n") { (first, second) -> "$first: $second" }
        val androidVersion = Build.VERSION.RELEASE  // e.g., "11"
        val sdkVersion = Build.VERSION.SDK_INT      // e.g., 30
        val deviceModel = Build.MODEL               // e.g., "Pixel 4"
        val manufacturer = Build.MANUFACTURER       // e.g., "Google"

        val appVersionName = BuildConfig.VERSION_NAME  // e.g., "1.205"
        val appVersionCode = BuildConfig.VERSION_CODE  // e.g., 1205

        val version = "Android Version: $androidVersion (SDK: $sdkVersion)"
        val model = "Device Model: $manufacturer $deviceModel"
        val appVersion = "App Version: $appVersionName (Code: $appVersionCode)"

        val emailIntent = Intent(Intent.ACTION_SEND).apply {
            data = Uri.parse("mailto:$recipient")
            type = "message/rfc822"
            putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
            putExtra(Intent.EXTRA_SUBJECT, "Bug Report: Git Sync - [${DateTimeFormatter.ISO_INSTANT.format(Instant.now())}]")
            putExtra(Intent.EXTRA_TEXT, "App logs are attached! \n $last5LogsString \n $version \n $model \n $appVersion \n\n\n")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        return Intent.createChooser(emailIntent, context.getString(R.string.select_email_client))
    }
}