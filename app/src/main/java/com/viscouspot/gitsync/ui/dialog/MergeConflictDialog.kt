package com.viscouspot.gitsync.ui.dialog

import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.net.Uri
import android.view.View
import android.webkit.MimeTypeMap
import android.widget.HorizontalScrollView
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.GitSyncService
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.ui.adapter.ConflictEditorAdapter
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.Helper
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.SettingsManager
import java.io.File
import kotlin.math.max
import kotlin.math.min


class MergeConflictDialog(private val context: Context, private val repoIndex: Int, private val settingsManager: SettingsManager, private val gitManager: GitManager, private val refreshRecentCommits: () -> Unit) : BaseDialog(context) {

    override fun onStart() {
        super.onStart()
        setContentView(R.layout.dialog_merge_conflict)

        val conflicts = gitManager.getConflicting(settingsManager.getGitDirUri())
        if (conflicts.isEmpty()) return
        
        val conflictEditor = findViewById<HorizontalScrollView>(R.id.conflictEditor) ?: return
        val conflictEditorInput = findViewById<RecyclerView>(R.id.conflictEditorInput) ?: return
        val fileName = findViewById<MaterialButton>(R.id.fileName) ?: return
        val filePrev = findViewById<MaterialButton>(R.id.filePrev) ?: return
        val fileNext = findViewById<MaterialButton>(R.id.fileNext) ?: return
        val merge = findViewById<MaterialButton>(R.id.merge) ?: return
        val abortMerge = findViewById<MaterialButton>(R.id.abortMerge) ?: return

        val conflictSections = mutableListOf<String>()

        conflictEditorInput.adapter = ConflictEditorAdapter(context, conflictSections, conflictEditor) {
            if (conflictSections.isEmpty() || conflictSections.firstOrNull { it.contains(context.getString(R.string.conflict_start)) } == null) {
                merge.isEnabled = true
                merge.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.auth_green))
                merge.setTextColor(ContextCompat.getColor(context, R.color.card_secondary_bg))
            } else {
                merge.isEnabled = false
                merge.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.card_secondary_bg))
                merge.setTextColor(ContextCompat.getColor(context, R.color.text_secondary))
            }
        }

        var conflictIndex = 0

        fileName.setOnClickListener {
            val file = File("${Helper.getPathFromUri(context, settingsManager.getGitDirUri()!!)}/${conflicts.elementAt(conflictIndex)}")

            if (file.exists()) {
                val intent = Intent(Intent.ACTION_VIEW)
                val fileUri: Uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
                val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension) ?: "text/plain"

                intent.setDataAndType(fileUri, mimeType)
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

                context.startActivity(Intent.createChooser(intent, "Open file with"))
            }

        }

        filePrev.setOnClickListener {
            conflictIndex = max(conflictIndex - 1, 0)
            refreshMergeConflictDialog(conflicts, conflictSections, conflictIndex, merge, fileName, filePrev, fileNext, conflictEditorInput)
        }

        fileNext.setOnClickListener {
            conflictIndex = min(conflictIndex + 1, conflicts.size - 1)
            refreshMergeConflictDialog(conflicts, conflictSections, conflictIndex, merge, fileName, filePrev, fileNext, conflictEditorInput)
        }

        merge.post {
            refreshMergeConflictDialog(conflicts, conflictSections, conflictIndex, merge, fileName, filePrev, fileNext, conflictEditorInput)
        }

        merge.setOnClickListener{
            File("${Helper.getPathFromUri(context, settingsManager.getGitDirUri()!!)}/${conflicts.elementAt(conflictIndex)}").bufferedWriter().use { writer ->
                conflictSections.forEach { line ->
                    writer.write(line)
                    writer.newLine()
                }
            }

            if (conflicts.size > 1) {
                conflicts.removeAt(conflictIndex)
                conflictIndex = min(conflictIndex, conflicts.size - 1)
                refreshMergeConflictDialog(conflicts, conflictSections, conflictIndex, merge, fileName, filePrev, fileNext, conflictEditorInput)
                return@setOnClickListener
            }

            merge.text = context.getString(R.string.merging)
            merge.isEnabled = false
            merge.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.card_secondary_bg))
            merge.setTextColor(ContextCompat.getColor(context, R.color.text_secondary))
            abortMerge.visibility = View.GONE

            val forceSyncIntent = Intent(context, GitSyncService::class.java)
            forceSyncIntent.setAction(GitSyncService.MERGE)
            forceSyncIntent.putExtra("repoIndex", repoIndex)
            context.startService(forceSyncIntent)
        }

        abortMerge.setOnClickListener {
            gitManager.abortMerge(settingsManager.getGitDirUri())
            dismiss()
            refreshRecentCommits()
        }
    }

    private fun refreshMergeConflictDialog(conflicts: MutableList<String>, conflictSections: MutableList<String>, conflictIndex: Int, merge: MaterialButton, fileName: MaterialButton, filePrev: MaterialButton, fileNext: MaterialButton, conflictEditorInput: RecyclerView) {
        filePrev.isEnabled = conflictIndex > 0
        fileNext.isEnabled = conflictIndex < conflicts.size - 1

        fileName.text = conflicts.elementAt(conflictIndex).substringAfterLast("/")

        val file = File("${Helper.getPathFromUri(context, settingsManager.getGitDirUri()!!)}/${conflicts.elementAt(conflictIndex)}")

        if (conflictSections.isNotEmpty()) {
            val conflictSectionsSize = conflictSections.size
            conflictSections.clear()
            conflictEditorInput.adapter?.notifyItemRangeRemoved(0, conflictSectionsSize)
        }

        if (file.exists()) {
            Helper.extractConflictSections(context, file) {
                conflictSections.add(it)
                conflictEditorInput.adapter?.notifyItemInserted(conflictSections.size)
            }

            log(conflictSections.toString())
        } else {
            conflictSections.add("File not found.")
            conflictEditorInput.adapter?.notifyItemInserted(conflictSections.size)
        }

        if (conflictSections.firstOrNull { it.contains("\n") || it.contains("File not found.") } == null) {
            merge.isEnabled = true
            merge.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.auth_green))
            merge.setTextColor(ContextCompat.getColor(context, R.color.card_secondary_bg))
        } else {
            merge.isEnabled = false
            merge.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.card_secondary_bg))
            merge.setTextColor(ContextCompat.getColor(context, R.color.text_secondary))
        }
    }
}