package com.viscouspot.gitsync.util

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.util.Log
import android.widget.EditText
import android.widget.Toast
import androidx.annotation.DrawableRes
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.viscouspot.gitsync.R
import java.io.File
import java.io.FileWriter
import java.io.IOException
import java.io.PrintWriter
import java.io.StringWriter
import java.time.Instant
import java.time.format.DateTimeFormatter
import java.util.regex.Matcher
import java.util.regex.Pattern
import kotlin.random.Random


object Helper {
    fun log(context: Context, type: String, e: Exception) {
        val sw = StringWriter()
        val pw = PrintWriter(sw)
        e.printStackTrace(pw)
        log(context, type, "Error: $sw")

        sendBugReportNotification(context)
    }

    fun log(context: Context, type: String, message: String) {
        Log.d("///Git Sync//$type", message)

        val file = File(context.filesDir, "logs.txt")
        if (!file.exists()) {
            file.createNewFile()
        }

        FileWriter(file, true).use { writer ->
            writer.appendLine("${DateTimeFormatter.ISO_INSTANT.format(Instant.now())}  $type\n        - $message")
        }
    }

    fun deleteLogs(context: Context) {
        val file = File(context.filesDir, "logs.txt")
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
                Toast.makeText(context, "${context.getString(R.string.report_bug)} ${context.getString(R.string.enable_notifications)}", Toast.LENGTH_SHORT).show()
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

    fun getPathFromUri(context: Context, uri: Uri): String {
        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT && DocumentsContract.isDocumentUri(context, uri) -> {
                when {
                    isExternalStorageDocument(uri) -> {
                        val docId = DocumentsContract.getDocumentId(uri)
                        val split = docId.split(":")
                        val type = split[0]

                        if ("primary".equals(type, ignoreCase = true)) {
                            return "${Environment.getExternalStorageDirectory()}/${split[1]}"
                        } else {
                            val externalStorageVolumes = context.getExternalFilesDirs(null)
                            for (externalFile in externalStorageVolumes) {
                                val path = externalFile.absolutePath
                                if (path.contains(type)) {
                                    val subPath = path.substringBefore("/Android")
                                    return "$subPath/${split[1]}"
                                }
                            }
                        }
                    }
                    isDownloadsDocument(uri) -> {
                        val id = DocumentsContract.getDocumentId(uri)
                        val contentUri = ContentUris.withAppendedId(
                            Uri.parse("content://downloads/public_downloads"), id.toLong()
                        )

                        return getDataColumn(context, contentUri, null, null)
                    }
                    isMediaDocument(uri) -> {
                        val docId = DocumentsContract.getDocumentId(uri)
                        val split = docId.split(":")
                        val type = split[0]

                        var contentUri: Uri? = null
                        when (type) {
                            "image" -> contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                            "video" -> contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                            "audio" -> contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                        }

                        val selection = "_id=?"
                        val selectionArgs = arrayOf(split[1])

                        return getDataColumn(context, contentUri, selection, selectionArgs)
                    }
                }
            }
            "content".equals(uri.scheme, ignoreCase = true) -> {
                when {
                    isGooglePhotosUri(uri) -> return uri.lastPathSegment ?: ""
                    else -> return getDataColumn(context, uri, null, null)
                }
            }
            "file".equals(uri.scheme, ignoreCase = true) -> {
                return uri.path ?: ""
            }
        }

        return ""
    }

    private fun isExternalStorageDocument(uri: Uri): Boolean {
        return "com.android.externalstorage.documents" == uri.authority
    }

    private fun isDownloadsDocument(uri: Uri): Boolean {
        return "com.android.providers.downloads.documents" == uri.authority
    }

    private fun isMediaDocument(uri: Uri): Boolean {
        return "com.android.providers.media.documents" == uri.authority
    }

    private fun isGooglePhotosUri(uri: Uri): Boolean {
        return "com.google.android.apps.photos.content" == uri.authority
    }

    private fun getDataColumn(
        context: Context,
        uri: Uri?,
        selection: String?,
        selectionArgs: Array<String>?
    ): String {
        var cursor: Cursor? = null
        val column = "_data"
        val projection = arrayOf(column)

        try {
            cursor = context.contentResolver.query(uri!!, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val index = cursor.getColumnIndexOrThrow(column)
                return cursor.getString(index)
            }
        } finally {
            cursor?.close()
        }

        return ""
    }

    fun isValidGitRepo(url: String): Boolean {
        val regex = ("((http|git|ssh|http(s)|file|\\/?)|"
                + "(git@[\\w\\.]+))(:(\\/\\/)?)"
                + "([\\w\\.@\\:/\\-~]+)(\\.git)(\\/)?")

        val p: Pattern = Pattern.compile(regex)
        val m: Matcher = p.matcher(url)

        return m.matches()
    }

    fun copyDirectory(source: File, destination: File) {
        if (!destination.exists()) {
            destination.mkdirs()
        }

        val files = source.listFiles() ?: throw IOException("Source directory is empty or cannot be read")

        for (file in files) {
            val destFile = File(destination, file.name)
            if (file.isDirectory) {
                copyDirectory(file, destFile)
            } else {
                file.copyTo(destFile, overwrite = true)
            }
        }
    }
}

fun EditText.rightDrawable(@DrawableRes id: Int? = 0) {
    val drawable = if (id !=null) ContextCompat.getDrawable(context, id) else null
    val size = resources.getDimensionPixelSize(R.dimen.text_size_lg)
    drawable?.setBounds(0, 0, size, size)
    this.compoundDrawableTintList
    this.setCompoundDrawables(null, null, drawable, null)
}

