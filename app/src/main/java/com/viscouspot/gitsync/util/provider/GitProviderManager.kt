package com.viscouspot.gitsync.util.provider

import android.content.Context
import android.net.Uri
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.util.SettingsManager

interface GitProviderManager {
    companion object {
        enum class Provider {
            GITHUB,
            GITEA
        }

        val detailsMap: Map<Provider, Pair<String, Int>> = mapOf(
            Provider.GITHUB to Pair("GitHub", R.drawable.provider_github),
            Provider.GITEA to Pair("Gitea", R.drawable.provider_gitea)
        )

        val defaultDomainMap: Map<Provider, String> = mapOf(
            Provider.GITHUB to "github.com",
            Provider.GITEA to "gitea.com"
        )

        private val managerMap: Map<Provider, (Context, String) -> GitProviderManager> = mapOf(
            Provider.GITHUB to { context: Context, domain: String -> GithubManager(context, domain) },
            Provider.GITEA to { context: Context, domain: String -> GiteaManager(context, domain) }
        )

        fun getManager(context: Context, settingsManager: SettingsManager): GitProviderManager {
            return managerMap[settingsManager.getGitProvider()]?.invoke(context, settingsManager.getGitDomain())
                ?: throw IllegalArgumentException("No manager found")
        }
    }

    fun launchOAuthFlow() {}

    fun getOAuthCredentials(
        uri: Uri,
        setCallback: (username: String?, accessToken: String?) -> Unit
    ) {}

    fun getRepos(
        accessToken: String,
        updateCallback: (repos: List<Pair<String, String>>) -> Unit,
        nextPageCallback: (nextPage: (() -> Unit)?) -> Unit
    ): Boolean { return false }
}