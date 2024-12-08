package com.viscouspot.gitsync

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager
import com.viscouspot.gitsync.util.LogType
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.SettingsManager

class GitSyncAccessibilityService: AccessibilityService() {
    private lateinit var settingsManager: SettingsManager
    private lateinit var enabledInputMethods: List<String>
    private var appOpen = false

    override fun onCreate() {
        super.onCreate()
        settingsManager = SettingsManager(this)

        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        enabledInputMethods = imm.enabledInputMethodList.map { it.packageName }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageNames = settingsManager.getApplicationPackages()

        if (!(packageNames.isNotEmpty() && (settingsManager.getSyncOnAppClosed() || settingsManager.getSyncOnAppOpened()))) return

        event?.let {
            when (it.eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                    if (appOpen && !packageNames.contains(event.packageName) && !enabledInputMethods.contains(event.packageName)) {
                        log(LogType.AccessibilityService, "Application Closed")
                        if (settingsManager.getSyncOnAppClosed()) {
                            sync()
                        }
                        appOpen = false
                    }

                    if (!appOpen && packageNames.contains(event.packageName)) {
                        log(LogType.AccessibilityService, "Application Opened")
                        if (settingsManager.getSyncOnAppOpened()) {
                            sync()
                        }
                        appOpen = true
                    }
                }
                else -> {}
            }
        }
    }

    override fun onInterrupt() { }

    private fun sync() {
        val syncIntent = Intent(this, GitSyncService::class.java)
        syncIntent.setAction(GitSyncService.APPLICATION_SYNC)
        startService(syncIntent)
    }
}