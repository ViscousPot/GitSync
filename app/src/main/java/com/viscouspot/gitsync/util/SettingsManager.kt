package com.viscouspot.gitsync.util

import android.content.Context

class SettingsManager internal constructor(context: Context) {
    private val settingsSharedPref = context.getSharedPreferences("git_sync_settings", Context.MODE_PRIVATE)

    fun getEnabled(): Boolean {
        return settingsSharedPref.getBoolean("enabled", false)
    }

    fun setEnabled(enabled: Boolean) {
        with(settingsSharedPref.edit()) {
            putBoolean("enabled", enabled)
            apply()
        }
    }

    fun getGitRepoUrl(): String {
        return settingsSharedPref.getString("gitRepoUrl", "")!!
    }

    fun setGitRepoUrl(repoUrl: String) {
        with(settingsSharedPref.edit()) {
            putString("gitRepoUrl", repoUrl)
            apply()
        }
    }

    fun getGitDirPath(): String {
        return settingsSharedPref.getString("gitDirPath", "")!!
    }

    fun setGitDirPath(dirPath: String) {
        with(settingsSharedPref.edit()) {
            putString("gitDirPath", dirPath)
            apply()
        }
    }

    fun getGitAuthCredentials(): List<String> {
        return listOf(
            settingsSharedPref.getString("gitAuthUsername", "gitAuthToken")!!,
            settingsSharedPref.getString("gitAuthToken", "gitAuthToken")!!
        )
    }

    fun setGitAuthCredentials(username: String, token: String) {
        with(settingsSharedPref.edit()) {
            putString("gitAuthUsername", username)
            putString("gitAuthToken", token)
            apply()
        }
    }

    fun getFileObserverEnabled(): Boolean {
        return settingsSharedPref.getBoolean("fileObserverEnabled", true)!!
    }

    fun setFileObserverEnabled(enabled: Boolean) {
        with(settingsSharedPref.edit()) {
            putBoolean("fileObserverEnabled", enabled)
            apply()
        }
    }

    fun getApplicationObserverEnabled(): Boolean {
        return settingsSharedPref.getBoolean("applicationObserverEnabled", false)!!
    }

    fun setApplicationObserverEnabled(enabled: Boolean) {
        with(settingsSharedPref.edit()) {
            putBoolean("applicationObserverEnabled", enabled)
            apply()
        }
    }
}
