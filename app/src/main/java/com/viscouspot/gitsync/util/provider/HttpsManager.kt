package com.viscouspot.gitsync.util.provider

class HttpsManager : GitProviderManager {
    override val oAuthSupport = false

    override fun getRepos(accessToken: String, updateCallback: (repos: List<Pair<String, String>>) -> Unit, nextPageCallback: (nextPage: (() -> Unit)?) -> Unit): Boolean {
        return false
    }
}