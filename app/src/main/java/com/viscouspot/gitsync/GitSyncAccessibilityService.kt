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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class GitSyncAccessibilityService: AccessibilityService() {
    private lateinit var enabledInputMethods: List<String>
    private var appOpen = mutableListOf<Boolean>()

    override fun onCreate() {
        super.onCreate()

        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        enabledInputMethods = imm.enabledInputMethodList.map { it.packageName }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        CoroutineScope(Dispatchers.Default).launch {
            val repoManager = RepoManager(applicationContext)
            var syncOnAppClosed = false
            var syncOnAppOpened = false

            val packageNamesIndexed = (0..<repoManager.getRepoNames().size).map { i ->
                val settingsManager = SettingsManager(applicationContext, i)

                syncOnAppClosed = syncOnAppClosed || settingsManager.getSyncOnAppClosed()
                syncOnAppOpened = syncOnAppOpened || settingsManager.getSyncOnAppOpened()

                settingsManager.getApplicationPackages()
            }

            if (!(packageNamesIndexed.flatten().isNotEmpty() && (syncOnAppClosed || syncOnAppOpened))) return@launch

            event?.let {
                when (it.eventType) {
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                        packageNamesIndexed.forEachIndexed { index, packageNames ->
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
    }

    override fun onInterrupt() { }

    private fun sync(index: Int) {
        val syncIntent = Intent(this, GitSyncService::class.java)
        syncIntent.setAction(GitSyncService.APPLICATION_SYNC)
        syncIntent.putExtra("repoIndex", index)
        startService(syncIntent)
    }
}