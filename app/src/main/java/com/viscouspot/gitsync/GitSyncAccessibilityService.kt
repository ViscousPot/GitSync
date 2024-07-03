package com.viscouspot.gitsync

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.SettingsManager


class GitSyncAccessibilityService: AccessibilityService() {
    private lateinit var settingsManager: SettingsManager
    private lateinit var enabledInputMethods: List<String>
    private var lastPackageName = ""

    override fun onCreate() {
        super.onCreate()

        settingsManager = SettingsManager(this)

        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        enabledInputMethods = imm.enabledInputMethodList.map { it.packageName }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val appPackageName = settingsManager.getApplicationPackage()

        if (!(settingsManager.getApplicationObserverEnabled() && appPackageName.isNotEmpty() && (settingsManager.getSyncOnAppClosed() || settingsManager.getSyncOnAppOpened()))) return

        event?.takeIf { it.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
                it.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED  }?.let {
            val packageName = it.packageName

            if (packageName != null && !enabledInputMethods.contains(packageName)) {
                val currentApp = packageName.toString()
                if (currentApp != lastPackageName) {
                    if (packageName == appPackageName) {
                        log(this, "AccessibilityService", "Application Opened")
                        sync()
                        lastPackageName = currentApp
                    } else {
                        if (lastPackageName.isNotEmpty()) {
                            log(this, "AccessibilityService", "Application Closed")
                            sync()
                            lastPackageName = ""
                        }
                    }
                }
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