package com.viscouspot.gitsync.util.provider

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Base64
import com.viscouspot.gitsync.Secrets
import com.viscouspot.gitsync.util.Helper
import com.viscouspot.gitsync.util.LogType
import com.viscouspot.gitsync.util.Logger.log
import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.UUID

class GiteaManager(private val context: Context, private val domain: String) : GitProviderManager {
    private val client = OkHttpClient()
    private var codeVerifier: String? = null

    companion object {
        private const val REDIRECT_URI = "gitsync://auth"
        private const val CODE_VERIFIER_LENGTH = 128
    }

    override fun launchOAuthFlow() {
        codeVerifier = generateCodeVerifier()
        val codeChallenge = generateCodeChallenge(codeVerifier!!)

        val fullAuthUrl = "https://${domain}/login/oauth/authorize" +
                "?client_id=${Secrets.GITEA_CLIENT_ID}" +
                "&client_secret=${Secrets.GITEA_CLIENT_SECRET}" +
                "&redirect_uri=$REDIRECT_URI" +
                "&response_type=code" +
                "&state=${UUID.randomUUID()}" +
                "&code_challenge=$codeChallenge" +
                "&code_challenge_method=S256"

        log(LogType.GiteaOAuthFlow, "Launching Flow")
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(fullAuthUrl)).apply {
            addCategory(Intent.CATEGORY_BROWSABLE)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
    }

    override fun getOAuthCredentials(uri: Uri, setCallback: (username: String?, accessToken: String?) -> Unit) {
        val code = uri.getQueryParameter("code")
        val state = uri.getQueryParameter("state")

        if (code == null || state == null) return

        if (!Helper.isNetworkAvailable(context)) {
            return
        }

        val jsonObject = JSONObject().apply {
            put("client_id", Secrets.GITEA_CLIENT_ID)
            put("client_secret", Secrets.GITEA_CLIENT_SECRET)
            put("code", code)
            put("state", state)
            put("grant_type", "authorization_code")
            put("redirect_uri", REDIRECT_URI)
            put("code_verifier", codeVerifier)
        }

        val accessTokenRequest: Request = Request.Builder()
            .url("https://${domain}/login/oauth/access_token")
            .post(jsonObject.toString().toRequestBody("application/json".toMediaType()))
            .addHeader("Accept", "application/json")
            .build()

        client.newCall(accessTokenRequest).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                log(context, LogType.GiteaAuthCredentials, e)

                setCallback.invoke(null, null)
            }

            override fun onResponse(call: Call, response: Response) {
                log(LogType.GiteaAuthCredentials, "Auth Token Obtained")
                val accessToken = JSONObject(response.body?.string() ?: "").getString("access_token")

                getUsername(accessToken) {
                    setCallback.invoke(it, accessToken)
                }
            }
        })
    }

    private fun generateCodeVerifier(): String {
        val secureRandom = SecureRandom()
        val code = ByteArray(CODE_VERIFIER_LENGTH)
        secureRandom.nextBytes(code)
        return Base64.encodeToString(code, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
    }

    private fun generateCodeChallenge(codeVerifier: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(codeVerifier.toByteArray())
        return Base64.encodeToString(bytes, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
    }

    private fun getUsername(accessToken: String, successCallback: (username: String) -> Unit) {
        if (!Helper.isNetworkAvailable(context)) {
            return
        }
        val profileRequest: Request = Request.Builder()
            .url("https://${domain}/api/v1/user")
            .addHeader("Accept", "application/json")
            .addHeader("Authorization", "token $accessToken")
            .build()

        log(LogType.GiteaAuthCredentials, "Getting User Profile")
        client.newCall(profileRequest).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                log(context, LogType.GiteaAuthCredentials, e)
            }

            override fun onResponse(call: Call, response: Response) {
                val json = JSONObject(response.body?.string())
                val username = json.getString("login")

                log(LogType.GiteaAuthCredentials, "Username Retrieved")
                successCallback.invoke(username)
            }
        })
    }

    override fun getRepos(accessToken: String, updateCallback: (repos: List<Pair<String, String>>) -> Unit, nextPageCallback: (nextPage: (() -> Unit)?) -> Unit): Boolean {
        log(LogType.GetRepos, "Getting User Repos")
        getReposRequest(accessToken, "https://${domain}/api/v1/user/repos", updateCallback, nextPageCallback)

        return true
    }

    private fun getReposRequest(accessToken: String, url: String, updateCallback: (repos: List<Pair<String, String>>) -> Unit, nextPageCallback: (nextPage: (() -> Unit)?) -> Unit) {
        if (!Helper.isNetworkAvailable(context)) {
            return
        }
        client.newCall(
            Request.Builder()
                .url(url)
                .addHeader("Accept", "application/json")
                .addHeader("Authorization", "token $accessToken")
                .build()
        ).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                log(context, LogType.GetRepos, e)
            }

            override fun onResponse(call: Call, response: Response) {
                log(LogType.GetRepos, "Repos Received")

                val jsonArray = JSONArray(response.body?.string())
                val repoMap: MutableList<Pair<String, String>> = mutableListOf()
                val link = response.headers["link"] ?: ""

                if (link.isNotEmpty()) {
                    val regex = "<(.*?)>; rel=\"next\"".toRegex()
                    val match = regex.find(link)
                    val nextLink = match?.groups?.get(1)?.value.orEmpty()

                    if (nextLink.isNotEmpty()) {
                        nextPageCallback {
                            getReposRequest(accessToken, nextLink, updateCallback, nextPageCallback)
                        }
                    } else {
                        nextPageCallback(null)
                    }
                }

                for (i in 0 until jsonArray.length()) {
                    val obj = jsonArray.getJSONObject(i)
                    val name = obj.getString("name")
                    val cloneUrl = obj.getString("clone_url")
                    repoMap.add(Pair(name, cloneUrl))
                }

                updateCallback.invoke(repoMap)
            }
        })
    }
}