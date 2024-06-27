package com.viscouspot.gitsync

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import com.viscouspot.gitsync.util.Helper.log
import com.viscouspot.gitsync.util.SettingsManager

class GitSyncAccessibilityService: AccessibilityService() {
    private lateinit var settingsManager: SettingsManager
    private var open = false

    override fun onCreate() {
        super.onCreate()
        settingsManager = SettingsManager(this)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val appPackageName = settingsManager.getApplicationPackage()

        if (!(settingsManager.getApplicationObserverEnabled() && appPackageName.isNotEmpty() && (settingsManager.getSyncOnAppClosed() || settingsManager.getSyncOnAppOpened()))) return

        event?.takeIf { it.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED }?.let {
            val packageName = it.packageName?.toString().orEmpty()

            if (packageName == appPackageName) {
                if (!open && settingsManager.getSyncOnAppOpened()) {
                    log(this, "AccessibilityService", "Application Opened")
                    sync()
                }
                open = true
            } else {
                if (open && settingsManager.getSyncOnAppClosed()) {
                    log(this, "AccessibilityService", "Application Closed")
                    sync()
                }
                open = false
            }
        }
    }

    override fun onInterrupt() { }

    private fun sync() {
        val syncIntent = Intent(this, GitSyncService::class.java)
        syncIntent.setAction("APPLICATION_SYNC")
        startService(syncIntent)
    }
}