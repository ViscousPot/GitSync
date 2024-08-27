package com.viscouspot.gitsync.util

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys

class SettingsManager internal constructor(context: Context) {
    private val masterKey = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
    private val settingsSharedPref = EncryptedSharedPreferences.create(
        "git_sync_settings",
        masterKey,
        context,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun clearAll() {
        with(settingsSharedPref.edit()) {
            clear()
            apply()
        }
    }

    fun getSyncMessageEnabled(): Boolean {
        return settingsSharedPref.getBoolean("syncMessageEnabled", true)
    }

    fun setSyncMessageEnabled(enabled: Boolean) {
        with(settingsSharedPref.edit()) {
            putBoolean("syncMessageEnabled", enabled)
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

    fun getGitAuthCredentials(): Pair<String, String> {
        return Pair(
            settingsSharedPref.getString("gitAuthUsername", "")!!,
            settingsSharedPref.getString("gitAuthToken", "")!!
        )
    }

    fun setGitAuthCredentials(username: String, token: String) {
        with(settingsSharedPref.edit()) {
            putString("gitAuthUsername", username)
            putString("gitAuthToken", token)
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

    fun getApplicationPackage(): String {
        return settingsSharedPref.getString("packageName", "")!!
    }

    fun setApplicationPackage(packageName: String) {
        with(settingsSharedPref.edit()) {
            putString("packageName", packageName)
            apply()
        }
    }

    fun getSyncOnAppOpened(): Boolean {
        return settingsSharedPref.getBoolean("syncOnAppOpened", false)!!
    }

    fun setSyncOnAppOpened(enabled: Boolean) {
        with(settingsSharedPref.edit()) {
            putBoolean("syncOnAppOpened", enabled)
            apply()
        }
    }

    fun getSyncOnAppClosed(): Boolean {
        return settingsSharedPref.getBoolean("syncOnAppClosed", false)!!
    }

    fun setSyncOnAppClosed(enabled: Boolean) {
        with(settingsSharedPref.edit()) {
            putBoolean("syncOnAppClosed", enabled)
            apply()
        }
    }
}
