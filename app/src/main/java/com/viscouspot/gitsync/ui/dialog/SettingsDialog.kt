package com.viscouspot.gitsync.ui.dialog

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.text.Spannable
import android.text.style.ForegroundColorSpan
import android.view.View
import android.widget.EditText
import android.widget.HorizontalScrollView
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.core.widget.doOnTextChanged
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.Logger.sendBugReportNotification
import com.viscouspot.gitsync.util.RepoManager
import com.viscouspot.gitsync.util.SettingsManager

class SettingsDialog(private val context: Context, private val repoManager: RepoManager, private val settingsManager: SettingsManager, private val gitManager: GitManager, private val gitDirPath: String) : BaseDialog(context) {

    override fun onStart() {
        super.onStart()
        setContentView(R.layout.dialog_settings)

        setupSyncMessageSettings()
        setupRemoteSetings()
        setupAuthorNameSettings()
        setupAuthorEmailSettings()
        
        val gitDirUri = settingsManager.getGitDirUri()
        setupGitignoreSettings(gitDirUri)
        setupGitInfoExcludeSettings(gitDirUri)

        setupViewDocsButton()
        setupContributeButton()
        setupReportBugButton()
    }

    private fun setupViewDocsButton() {
        val viewDocsButton = findViewById<MaterialButton>(R.id.viewDocsButton) ?: return
        viewDocsButton.setOnClickListener {
            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(context.getString(R.string.docs_link)))
            context.startActivity(browserIntent)
        }
    }

    private fun setupContributeButton() {
        val contributeButton = findViewById<MaterialButton>(R.id.contributeButton) ?: return
        contributeButton.setOnClickListener {
            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(context.getString(R.string.contribute_link)))
            context.startActivity(browserIntent)
            repoManager.setHasContributed()
        }
    }

    private fun setupReportBugButton() {
        val reportBugButton = findViewById<MaterialButton>(R.id.reportBugButton) ?: return
        reportBugButton.setOnClickListener {
            sendBugReportNotification(context)
        }
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

    private fun setupRemoteSetings() {
        val remoteInput = findViewById<EditText>(R.id.remoteInput) ?: return
        remoteInput.setText(settingsManager.getRemote())
        remoteInput.doOnTextChanged { text, _, _, _ ->
            settingsManager.setRemote(text.toString())
        }
    }

    private fun setupAuthorNameSettings() {
        val authorNameInput = findViewById<EditText>(R.id.authorNameInput) ?: return
        authorNameInput.setText(settingsManager.getAuthorName())
        authorNameInput.doOnTextChanged { text, _, _, _ ->
            settingsManager.setAuthorName(text.toString())
        }
    }

    private fun setupAuthorEmailSettings() {
        val authorEmailInput = findViewById<EditText>(R.id.authorEmailInput) ?: return
        authorEmailInput.setText(settingsManager.getAuthorEmail())
        authorEmailInput.doOnTextChanged { text, _, _, _ ->
            settingsManager.setAuthorEmail(text.toString())
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

    private fun setupGitignoreSettings(gitDirUri: Uri?) {
        val gitIgnoreLabel = findViewById<TextView>(R.id.gitIgnoreLabel) ?: return
        val gitIgnoreDescription = findViewById<TextView>(R.id.gitIgnoreDescription) ?: return
        val gitignoreInputWrapper = findViewById<HorizontalScrollView>(R.id.gitignoreInputWrapper) ?: return
        val gitignoreInput = findViewById<EditText>(R.id.gitignoreInput) ?: return

        if (gitDirUri == null) {
            gitIgnoreLabel.visibility = View.GONE
            gitIgnoreDescription.visibility = View.GONE
            gitignoreInputWrapper.visibility = View.GONE
            return
        }

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

    private fun setupGitInfoExcludeSettings(gitDirUri: Uri?) {
        val gitInfoExcludeLabel = findViewById<TextView>(R.id.gitInfoExcludeLabel) ?: return
        val gitInfoExcludeDescription = findViewById<TextView>(R.id.gitInfoExcludeDescription) ?: return
        val gitInfoExcludeInputWrapper = findViewById<HorizontalScrollView>(R.id.gitInfoExcludeInputWrapper) ?: return
        val gitInfoExcludeInput = findViewById<EditText>(R.id.gitInfoExcludeInput) ?: return

        if (gitDirUri == null) {
            gitInfoExcludeLabel.visibility = View.GONE
            gitInfoExcludeDescription.visibility = View.GONE
            gitInfoExcludeInputWrapper.visibility = View.GONE
            return
        }

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