package com.viscouspot.gitsync.ui.dialog

import android.content.Context
import android.text.Spannable
import android.text.style.ForegroundColorSpan
import android.widget.EditText
import android.widget.HorizontalScrollView
import androidx.core.content.ContextCompat
import androidx.core.widget.doOnTextChanged
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.SettingsManager


class SettingsDialog(private val context: Context, private val settingsManager: SettingsManager, private val gitManager: GitManager, private val gitDirPath: String) : BaseDialog(context) {

    override fun onStart() {
        super.onStart()
        setContentView(R.layout.dialog_settings)

        setupSyncMessageSettings()
        setupGitignoreSettings()
        setupGitInfoExcludeSettings()
    }

    private fun highlightStringInFormat(syncMessageInput: EditText) {
        val start = syncMessageInput.text.indexOf("%s")
        if (start == -1) return

        syncMessageInput.getText().setSpan(ForegroundColorSpan(ContextCompat.getColor(context, R.color.additions)), start, start + 2, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
    }

    private fun highlightCommentsInInput(syncMessageInput: EditText) {
        val text = syncMessageInput.text.toString()
        val lines = text.split("\n")
        var start = 0

        for (line in lines) {
            if (line.trim().startsWith("#")) {
                val lineStart = text.indexOf(line, start)
                val lineEnd = lineStart + line.length
                syncMessageInput.getText().setSpan(ForegroundColorSpan(ContextCompat.getColor(context, R.color.text_secondary)), lineStart, lineEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
            start += line.length + 1
        }
    }

    private fun setupSyncMessageSettings() {
        val syncMessageInput = findViewById<EditText>(R.id.syncMessageInput) ?: return
        syncMessageInput.setText(settingsManager.getSyncMessage())
        highlightStringInFormat(syncMessageInput)
        syncMessageInput.doOnTextChanged { text, _, _, _ ->
            settingsManager.setSyncMessage(text.toString())
            highlightStringInFormat(syncMessageInput)
        }
    }

    private fun setupGitignoreSettings() {
        val gitignoreInputWrapper = findViewById<HorizontalScrollView>(R.id.gitignoreInputWrapper) ?: return
        val gitignoreInput = findViewById<EditText>(R.id.gitignoreInput) ?: return
        gitignoreInput.setText(gitManager.readGitignore(gitDirPath))
        highlightCommentsInInput(gitignoreInput)
        gitignoreInput.setOnFocusChangeListener { _, hasFocus ->
            if (hasFocus) {
                gitignoreInputWrapper.post { gitignoreInputWrapper.scrollTo(0, 0) }
            }
        }
        gitignoreInput.doOnTextChanged { text, _, _, _ ->
            gitManager.writeGitignore(gitDirPath, text.toString())
            highlightCommentsInInput(gitignoreInput)
        }
    }

    private fun setupGitInfoExcludeSettings() {
        val gitInfoExcludeInputWrapper = findViewById<HorizontalScrollView>(R.id.gitInfoExcludeInputWrapper) ?: return
        val gitInfoExcludeInput = findViewById<EditText>(R.id.gitInfoExcludeInput) ?: return
        gitInfoExcludeInput.setText(gitManager.readGitInfoExclude(gitDirPath))
        highlightCommentsInInput(gitInfoExcludeInput)
        gitInfoExcludeInput.setOnFocusChangeListener { _, hasFocus ->
            if (hasFocus) {
                gitInfoExcludeInputWrapper.post { gitInfoExcludeInputWrapper.scrollTo(0, 0) }
            }
        }
        gitInfoExcludeInput.doOnTextChanged { text, _, _, _ ->
            gitManager.writeGitInfoExclude(gitDirPath, text.toString())
            highlightCommentsInInput(gitInfoExcludeInput)
        }
    }
}