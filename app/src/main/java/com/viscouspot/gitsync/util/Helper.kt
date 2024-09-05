package com.viscouspot.gitsync.util

import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.widget.EditText
import androidx.activity.result.ActivityResultCaller
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.DrawableRes
import androidx.core.content.ContextCompat
import com.viscouspot.gitsync.R
import java.io.File
import java.io.IOException
import java.util.regex.Matcher
import java.util.regex.Pattern

object Helper {
    fun getDirSelectionLauncher(activityResultLauncher: ActivityResultCaller, context: Context, callback: ((dirUri: Uri?) -> Unit)): ActivityResultLauncher<Uri?> {
        return activityResultLauncher.registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri ->
            uri?.let {
                try {
                    val testFile = File(getPathFromUri(context, it), "test${System.currentTimeMillis()}.txt")
                    testFile.createNewFile()
                    testFile.delete()
                } catch (e: IOException) {
                    e.printStackTrace()
                    callback.invoke(null)
                    return@let
                }

                context.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)

                callback.invoke(uri)
            }
        }
    }
    fun getPathFromUri(context: Context, uri: Uri): String {
        val docUriTree = DocumentsContract.buildDocumentUriUsingTree(
            uri,
            DocumentsContract.getTreeDocumentId(uri)
        )

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT && DocumentsContract.isDocumentUri(context, docUriTree) -> {
                when {
                    isExternalStorageDocument(docUriTree) -> {
                        val docId = DocumentsContract.getDocumentId(docUriTree)
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
                    isDownloadsDocument(docUriTree) -> {
                        val id = DocumentsContract.getDocumentId(docUriTree)
                        val contentUri = ContentUris.withAppendedId(
                            Uri.parse("content://downloads/public_downloads"), id.toLong()
                        )

                        return getDataColumn(context, contentUri, null, null)
                    }
                    isMediaDocument(docUriTree) -> {
                        val docId = DocumentsContract.getDocumentId(docUriTree)
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
            "content".equals(docUriTree.scheme, ignoreCase = true) -> {
                when {
                    isGooglePhotosUri(docUriTree) -> return uri.lastPathSegment ?: ""
                    else -> return getDataColumn(context, docUriTree, null, null)
                }
            }
            "file".equals(docUriTree.scheme, ignoreCase = true) -> {
                return docUriTree.path ?: ""
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

