package com.viscouspot.gitsync.ui.dialog

import android.content.Context
import android.content.res.ColorStateList
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.ui.RecyclerViewEmptySupport
import com.viscouspot.gitsync.ui.adapter.ManualSyncItemAdapter
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.Helper
import com.viscouspot.gitsync.util.Helper.makeToast
import com.viscouspot.gitsync.util.Helper.networkRequired
import com.viscouspot.gitsync.util.LogType
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.SettingsManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File

class ManualSyncDialog(private val context: Context, private val settingsManager: SettingsManager, private val gitManager: GitManager, private val refreshRecentCommits: () -> Unit) : BaseDialog(context) {
    private val selectedFiles = mutableListOf<String>()
    private lateinit var syncButton: MaterialButton
    private lateinit var syncMessageInput: EditText

    override fun onStart() {
        super.onStart()
        setContentView(R.layout.dialog_manual_sync)

        val manualSyncItems = findViewById<RecyclerViewEmptySupport>(R.id.manualSyncItems) ?: return
        val emptyCommitsView = findViewById<TextView>(R.id.emptyCommitsView) ?: return
        manualSyncItems.setEmptyView(emptyCommitsView)

        syncButton = findViewById(R.id.manualSyncButton) ?: return
        syncMessageInput = findViewById(R.id.syncMessageInput) ?: return

        val gitDirUri = settingsManager.getGitDirUri() ?: return

        val files = gitManager.getUncommittedFilePaths(gitDirUri)
        manualSyncItems.adapter = ManualSyncItemAdapter(context, files, selectedFiles) { filePath ->
            if (selectedFiles.contains(filePath)) {
                selectedFiles.remove(filePath)
            } else {
                selectedFiles.add(filePath)
            }
            updateSyncButton()
        }

        updateSyncButton()

        syncButton.setOnClickListener {
            syncButton.isEnabled = false
            syncButton.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.card_secondary_bg))
            syncButton.setTextColor(ContextCompat.getColor(context, R.color.text_secondary))
            syncButton.text = context.getString(R.string.sync_start_pull)

            val job = CoroutineScope(Dispatchers.Default).launch {
                log(LogType.Sync, "Start Pull Repo")
                val pullResult = gitManager.downloadChanges(
                    gitDirUri,
                    {
                        networkRequired(context)
                        dismiss()
                    },
                ) { }
                when (pullResult) {
                    null -> {
                        log(LogType.Sync, "Pull Repo Failed")
                        makeToast(
                            context,
                            "Pull Repo Failed",
                            Toast.LENGTH_LONG
                        )
                        dismiss()
                        return@launch
                    }

                    true -> log(LogType.Sync, "Pull Complete")
                    false -> log(LogType.Sync, "Pull Not Required")
                }

                while (File(
                        Helper.getPathFromUri(context, gitDirUri),
                        context.getString(R.string.git_lock_path)
                    ).exists()
                ) {
                    delay(1000)
                }

                log(LogType.Sync, "Start Push Repo")
                val pushResult = gitManager.uploadChanges(
                    gitDirUri,
                    {
                        networkRequired(context)
                        dismiss()
                    },
                    {},
                    selectedFiles,
                    syncMessageInput.text.toString()
                )

                when (pushResult) {
                    null -> {
                        log(LogType.Sync, "Push Repo Failed")
                        makeToast(
                            context,
                            "Push Repo Failed",
                            Toast.LENGTH_LONG
                        )
                        dismiss()
                        return@launch
                    }

                    true -> log(LogType.Sync, "Push Complete")
                    false -> log(LogType.Sync, "Push Not Required")
                }

                while (File(
                        Helper.getPathFromUri(context, gitDirUri),
                        context.getString(R.string.git_lock_path)
                    ).exists()
                ) {
                    delay(1000)
                }
            }

            job.invokeOnCompletion {
                dismiss()
            }
        }
    }

    override fun show() {
        if (settingsManager.getGitDirUri() == null) {
            log(LogType.Sync, "Repository Not Found")
            makeToast(
                context,
                context.getString(R.string.repository_not_found),
                Toast.LENGTH_LONG
            )
            return
        }
        super.show()
    }

    override fun dismiss() {
        refreshRecentCommits()
        super.dismiss()
    }

    private fun updateSyncButton() {
        if (selectedFiles.isNotEmpty()) {
            syncButton.isEnabled = true
            syncButton.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.auth_green))
            syncButton.setTextColor(ContextCompat.getColor(context, R.color.card_secondary_bg))
        } else {
            syncButton.isEnabled = false
            syncButton.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.card_secondary_bg))
            syncButton.setTextColor(ContextCompat.getColor(context, R.color.text_secondary))
        }
    }
}