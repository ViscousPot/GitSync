package com.viscouspot.gitsync

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager
import com.viscouspot.gitsync.util.LogType
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.RepoManager
import com.viscouspot.gitsync.util.SettingsManager

class GitSyncAccessibilityService: AccessibilityService() {
    private lateinit var enabledInputMethods: List<String>
    private var appOpen = mutableListOf<Boolean>()

    override fun onCreate() {
        super.onCreate()

        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        enabledInputMethods = imm.enabledInputMethodList.map { it.packageName }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        var syncOnAppClosed = false
        var syncOnAppOpened = false

        val repoManager = RepoManager(this);
        val packageNamesIndexed = (0..<repoManager.getRepoNames().size).map { i ->
            val settingsManager = SettingsManager(this, i)

            syncOnAppClosed = syncOnAppClosed || settingsManager.getSyncOnAppClosed()
            syncOnAppOpened = syncOnAppOpened || settingsManager.getSyncOnAppOpened()

            settingsManager.getApplicationPackages()
        }

        if (!(packageNamesIndexed.flatten().isNotEmpty() && (syncOnAppClosed || syncOnAppOpened))) return

        event?.let {
            when (it.eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                    packageNamesIndexed.forEachIndexed { index, packageNames ->
                        log(index)
                        log(appOpen)
                        if ((appOpen.getOrNull(index) == true) && !packageNames.contains(event.packageName) && !enabledInputMethods.contains(event.packageName)) {
                            log(LogType.AccessibilityService, "Application Closed")
                            if (syncOnAppClosed) {
                                sync(index)
                            }
                            while (appOpen.size <= index) {
                                appOpen.add(false)
                            }
                            appOpen[index] = false
                        }

                        log(packageNames.contains(event.packageName))
                        if ((appOpen.getOrNull(index) != true) && packageNames.contains(event.packageName)) {
                            log(LogType.AccessibilityService, "Application Opened")
                            if (syncOnAppOpened) {
                                sync(index)
                            }
                            while (appOpen.size <= index) {
                                appOpen.add(false)
                            }
                            appOpen[index] = true
                        }
                    }
                }
                else -> {}
            }
        }
    }

    override fun onInterrupt() { }

    private fun sync(index: Int) {
        log(index)
        val syncIntent = Intent(this, GitSyncService::class.java)
        syncIntent.setAction(GitSyncService.APPLICATION_SYNC)
        syncIntent.putExtra("repoIndex", index)
        startService(syncIntent)
    }
}