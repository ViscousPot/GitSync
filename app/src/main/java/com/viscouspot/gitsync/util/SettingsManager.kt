package com.viscouspot.gitsync.util

import android.content.Context
import android.net.Uri
import androidx.compose.ui.text.intl.Locale
import androidx.compose.ui.text.toLowerCase
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.util.provider.GitProviderManager

class SettingsManager internal constructor(private val context: Context, private val repoIndex: Int? = null) {
    private val masterKey = MasterKey.Builder(context, MasterKey.DEFAULT_MASTER_KEY_ALIAS)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()
    private val repoManager = RepoManager(context)
    private var settingsSharedPref = EncryptedSharedPreferences.create(
        context,
        "${PREFIX}${repoManager.getRepoNames().elementAt(repoIndex ?: repoManager.getRepoIndex())}",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )
    private var currentRepoIndex: Int? = repoIndex
    private var currentRepoNames: List<String> = listOf()

    companion object {
        const val PREFIX = "git_sync_settings__"

        fun renameSettingsPref(context: Context, oldPrefName: String, newPrefName: String) {
            val masterKey = MasterKey.Builder(context, MasterKey.DEFAULT_MASTER_KEY_ALIAS)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            val oldPref = EncryptedSharedPreferences.create(
                context,
                oldPrefName.toLowerCase(Locale.current),
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
            val newPref = EncryptedSharedPreferences.create(
                context,
                newPrefName.toLowerCase(Locale.current),
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )

            if (oldPref.all.keys.isNotEmpty()) {
                with(newPref.edit()) {
                    for ((key, value) in oldPref.all) {
                        when (value) {
                            is String -> putString(key, value)
                            is Int -> putInt(key, value)
                            is Boolean -> putBoolean(key, value)
                            is Float -> putFloat(key, value)
                            is Long -> putLong(key, value)
                            is Set<*> -> @Suppress("UNCHECKED_CAST") putStringSet(key, value as Set<String>)
                        }
                    }
                    apply()
                }
                with(oldPref.edit()) {
                    clear()
                    apply()
                }
            }
        }
    }

    private fun reloadSharedPref() {
        val newIndex = repoIndex ?: repoManager.getRepoIndex()
        val repoNames = repoManager.getRepoNames()

        if (currentRepoIndex == newIndex && newIndex < currentRepoNames.size && currentRepoNames[newIndex] == repoNames[newIndex]) {
            return
        }

        currentRepoIndex = newIndex
        currentRepoNames = repoNames

        settingsSharedPref = EncryptedSharedPreferences.create(
            context,
            "${PREFIX}${repoManager.getRepoNames().elementAt(newIndex)}",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    fun clearAll() {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            clear()
            apply()
        }
    }

    private fun isFirstTime(): Boolean {
        reloadSharedPref()

        return settingsSharedPref.getBoolean("isFirstTime", true)
    }

    fun getOnboardingStep(): Int {
        reloadSharedPref()

        return settingsSharedPref.getInt("onboardingStep", 0)
    }

    fun setOnboardingStep(step: Int) {
        reloadSharedPref()

        if (getOnboardingStep() == -1) return
        with(settingsSharedPref.edit()) {
            putInt("onboardingStep", step)
            apply()
        }
    }

    fun getAuthorName(): String {
        reloadSharedPref()

        return settingsSharedPref.getString("authorName", "").toString()
    }

    fun setAuthorName(authorName: String) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putString("authorName", authorName)
            apply()
        }
    }

    fun getAuthorEmail(): String {
        reloadSharedPref()

        return settingsSharedPref.getString("authorEmail", "").toString()
    }

    fun setAuthorEmail(authorEmail: String) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putString("authorEmail", authorEmail)
            apply()
        }
    }

    fun getSyncMessage(): String {
        reloadSharedPref()

        return settingsSharedPref.getString("syncMessage", null) ?: context.getString(R.string.sync_message)
    }

    fun setSyncMessage(syncMessage: String) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putString("syncMessage", syncMessage)
            apply()
        }
    }

    fun getRemote(): String {
        reloadSharedPref()

        return settingsSharedPref.getString("remote", null) ?: context.getString(R.string.default_remote)
    }

    fun setRemote(remote: String) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putString("remote", remote)
            apply()
        }
    }

    fun getSyncMessageEnabled(): Boolean {
        reloadSharedPref()

        return settingsSharedPref.getBoolean("syncMessageEnabled", true)
    }

    fun setSyncMessageEnabled(enabled: Boolean) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putBoolean("syncMessageEnabled", enabled)
            apply()
        }
    }

    fun getGitDirUri(): Uri? {
        reloadSharedPref()

        val dirUri = settingsSharedPref.getString("gitDirUri", "")

        if (dirUri == "") return null
        return Uri.parse(dirUri)
    }

    fun setGitDirUri(dirUri: String) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putString("gitDirUri", dirUri)
            apply()
        }
    }

    fun getGitProvider(): GitProviderManager.Companion.Provider {
        reloadSharedPref()

        val gitProviderString = settingsSharedPref.getString("gitProvider", "").toString()
        if (gitProviderString.isEmpty()) return GitProviderManager.Companion.Provider.GITHUB
        val providerEntry = GitProviderManager.detailsMap.firstNotNullOf {
            it.takeIf { it.value.first == gitProviderString }
        }

        return providerEntry.key
    }

    fun setGitProvider(provider: GitProviderManager.Companion.Provider) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putString("gitProvider", GitProviderManager.detailsMap[provider]?.first)
            apply()
        }
    }

    fun getGitAuthCredentials(): Pair<String, String> {
        reloadSharedPref()

        return Pair(
            settingsSharedPref.getString("gitAuthUsername", "")!!,
            settingsSharedPref.getString("gitAuthToken", "")!!
        )
    }

    fun setGitAuthCredentials(username: String, accessToken: String) {
        reloadSharedPref()

        setAuthorName(username)
        with(settingsSharedPref.edit()) {
            putString("gitAuthUsername", username)
            putString("gitAuthToken", accessToken)
            apply()
        }
    }

    fun getGitSshPrivateKey(): String {
        reloadSharedPref()

        return settingsSharedPref.getString("gitSshKey", "").toString()
    }

    fun setGitSshPrivateKey(gitSshKey: String) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putString("gitSshKey", gitSshKey)
            apply()
        }
    }

    fun getApplicationObserverEnabled(): Boolean {
        reloadSharedPref()

        return settingsSharedPref.getBoolean("applicationObserverEnabled", false)
    }

    fun setApplicationObserverEnabled(enabled: Boolean) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putBoolean("applicationObserverEnabled", enabled)
            apply()
        }
    }

    private fun getApplicationPackage(): String {
        reloadSharedPref()

        return settingsSharedPref.getString("packageName", "")!!
    }

    fun getApplicationPackages(): Set<String> {
        reloadSharedPref()

        return settingsSharedPref.getStringSet("packageNames", setOf())!!
    }

    fun setApplicationPackages(packageNames: List<String>) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putStringSet("packageNames", packageNames.toSet())
            apply()
        }
    }

    fun getSyncOnAppOpened(): Boolean {
        reloadSharedPref()

        return settingsSharedPref.getBoolean("syncOnAppOpened", false)
    }

    fun setSyncOnAppOpened(enabled: Boolean) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putBoolean("syncOnAppOpened", enabled)
            apply()
        }
    }

    fun getSyncOnAppClosed(): Boolean {
        reloadSharedPref()

        return settingsSharedPref.getBoolean("syncOnAppClosed", false)
    }

    fun setSyncOnAppClosed(enabled: Boolean) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putBoolean("syncOnAppClosed", enabled)
            apply()
        }
    }

    fun hasContributed(): Boolean {
        reloadSharedPref()

        return settingsSharedPref.getBoolean("hasContributed", false)
    }

    fun setHasContributed() {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putBoolean("hasContributed", true)
            apply()
        }
    }

    fun getLastSyncMethod(): String {
        reloadSharedPref()

        return settingsSharedPref.getString("lastSyncMethod", context.getString(R.string.sync_now)).toString()
    }

    fun setLastSyncMethod(lastSyncMethod: String) {
        reloadSharedPref()

        with(settingsSharedPref.edit()) {
            putString("lastSyncMethod", lastSyncMethod)
            apply()
        }
    }

    fun runMigrations() {
        renameSettingsPref(context, "git_sync_settings", "${PREFIX}main")

        val oldApplicationPackage = getApplicationPackage()
        if (oldApplicationPackage != "" && getApplicationPackages().isEmpty()) {
            setApplicationPackages(listOf(oldApplicationPackage))
        }

        val oldHadFirstTime = isFirstTime()
        if (!oldHadFirstTime) {
            setOnboardingStep(-1)
        }
    }
}
