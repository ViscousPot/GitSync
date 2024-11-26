package com.viscouspot.gitsync.util.provider

import android.content.Context
import android.net.Uri
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.util.SettingsManager

interface GitProviderManager {
    val oAuthSupport: Boolean;

    companion object {
        enum class Provider {
            GITHUB,
            GITEA,
            HTTPS,
            SSH,
        }

        val detailsMap: Map<Provider, Pair<String, Int>> = mapOf(
            Provider.GITHUB to Pair("GitHub", R.drawable.provider_github),
            Provider.GITEA to Pair("Gitea", R.drawable.provider_gitea),
            Provider.HTTPS to Pair("HTTP/S", R.drawable.provider_https),
            Provider.SSH to Pair("SSH", R.drawable.provider_ssh),
        )

        val defaultDomainMap: Map<Provider, String> = mapOf(
            Provider.GITHUB to "github.com",
            Provider.GITEA to "gitea.com",
            Provider.HTTPS to "",
            Provider.SSH to "",
        )

        private val managerMap: Map<Provider, (Context, String) -> GitProviderManager> = mapOf(
            Provider.GITHUB to { context, domain -> GithubManager(context, domain) },
            Provider.GITEA to { context, domain -> GiteaManager(context, domain) },
            Provider.HTTPS to { _, _ -> HttpsManager() },
            Provider.SSH to { _, _ -> SshManager() },
        )

        fun getManager(context: Context, settingsManager: SettingsManager): GitProviderManager {
            return managerMap[settingsManager.getGitProvider()]?.invoke(context, settingsManager.getGitDomain())
                ?: throw IllegalArgumentException("No manager found")
        }
    }

    fun launchOAuthFlow() {}

    fun getOAuthCredentials(
        uri: Uri?,
        setCallback: (username: String?, accessToken: String?) -> Unit
    ) {}

    fun getRepos(
        accessToken: String,
        updateCallback: (repos: List<Pair<String, String>>) -> Unit,
        nextPageCallback: (nextPage: (() -> Unit)?) -> Unit
    ): Boolean { return false }
}