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
import com.viscouspot.gitsync.BuildConfig
import com.viscouspot.gitsync.R
import java.io.PrintWriter
import java.io.StringWriter
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import kotlin.random.Random

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
    private val lastLogs = mutableListOf<Pair<LogType, String>>()
    private const val ERROR_NOTIFICATION_ID = 1757

    fun log(context: Context, type: LogType, e: Throwable) {
        val sw = StringWriter()
        val pw = PrintWriter(sw)
        e.printStackTrace(pw)
        log(type, "Error: $sw")
        addToLastLogs(type, "Error: $sw")

        sendBugReportNotification(context)
    }

    fun log(type: LogType, message: String) {
        Log.d("///Git Sync//${type.type}", message)
        addToLastLogs(type, message)
    }

    fun log(message: Any?) {
        Log.d("///Git Sync//${LogType.TEST.type}", message?.toString() ?: "null")
        addToLastLogs(LogType.TEST, message?.toString() ?: "null")
    }

    private fun addToLastLogs(type: LogType, message: String) {
        lastLogs.add(Pair(type, message))
        if (lastLogs.size > 10) {
            lastLogs.removeAt(0)
        }
    }

    fun sendBugReportNotification(context: Context) {
        val channelId = "git_sync_bug_channel"
        val channel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel(
                channelId,
                "Git Sync Bug",
                NotificationManager.IMPORTANCE_HIGH
            )
        } else {
            TODO("VERSION.SDK_INT < O")
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(channel)

//        val emailIntent = createBugReportEmailIntent(context)
        val githubIssueIntent = createGitHubIssueIntent()
        val buttonPendingIntent = PendingIntent.getActivity(context, Random.nextInt(0, 100), githubIssueIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.bug)
            .setContentTitle(context.getString(R.string.report_bug))
            .setContentText(lastLogs.last().second.substringBefore("\n"))
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

    private fun urlEncode(str: String): String{
        return URLEncoder.encode(str, StandardCharsets.UTF_8.toString())
    }

    private fun createGitHubIssueIntent(): Intent {
        val lastLogsString = lastLogs.joinToString(separator = "\n") { (first, second) -> "$first: $second" }
        var url = "https://github.com/ViscousPot/GitSync/issues/new?"
        url += "body="
        url += urlEncode("""


<!-- PROVIDE ERROR REPRO STEPS -->

---

**Android Version:** ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})
**Device Model:** ${Build.MANUFACTURER} ${Build.MODEL}
**App Version:** ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})

$lastLogsString
        """.trimIndent())
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        return intent
    }
}