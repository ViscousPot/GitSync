package com.viscouspot.gitsync.util

import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.widget.EditText
import androidx.annotation.DrawableRes
import androidx.core.content.ContextCompat
import com.viscouspot.gitsync.R
import java.io.File
import java.io.IOException
import java.util.regex.Matcher
import java.util.regex.Pattern

object Helper {
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
}

fun EditText.rightDrawable(@DrawableRes id: Int? = 0) {
    val drawable = if (id !=null) ContextCompat.getDrawable(context, id) else null
    val size = resources.getDimensionPixelSize(R.dimen.text_size_lg)
    drawable?.setBounds(0, 0, size, size)
    this.compoundDrawableTintList
    this.setCompoundDrawables(null, null, drawable, null)
}

