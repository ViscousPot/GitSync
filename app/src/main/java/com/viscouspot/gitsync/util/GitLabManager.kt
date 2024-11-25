package com.viscouspot.gitsync.util

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.appcompat.app.AppCompatActivity
import com.viscouspot.gitsync.Secrets
import com.viscouspot.gitsync.util.Logger.log
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.util.UUID

class GitLabManager(private val context: Context, private val activity: AppCompatActivity? = null) : GitManager(context, activity) {
    private val client = OkHttpClient()

    companion object {
        private const val GITHUB_AUTH_URL = "https://github.com/login/oauth"
        private const val GIT_SCOPE = "repo"
    }

    override fun launchOAuthFlow() {
        val fullAuthUrl = "${GITHUB_AUTH_URL}/authorize?client_id=${Secrets.GITHUB_CLIENT_ID}&scope=${GIT_SCOPE}&state=${UUID.randomUUID()}"

        if (activity == null) {
            log(LogType.GithubOAuthFlow, "Activity Not Found")
            return
        }

        log(LogType.GithubOAuthFlow, "Launching Flow")
        activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(fullAuthUrl)).apply {
            addCategory(Intent.CATEGORY_BROWSABLE)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
    }

    override fun getOAuthCredentials(code: String, state: String, setCallback: (username: String, accessToken: String) -> Unit) {
        if (!Helper.isNetworkAvailable(context)) {
            return
        }
        val accessTokenRequest: Request = Request.Builder()
            .url("${GITHUB_AUTH_URL}/access_token?client_id=${Secrets.GITHUB_CLIENT_ID}&client_secret=${Secrets.GITHUB_CLIENT_SECRET}&code=$code&state=$state")
            .post("".toRequestBody())
            .addHeader("Accept", "application/json")
            .build()

        client.newCall(accessTokenRequest).enqueue(object: Callback {
            override fun onFailure(call: Call, e: IOException) {
                log(context, LogType.GithubAuthCredentials, e)
            }

            override fun onResponse(call: Call, response: Response) {
                log(LogType.GithubAuthCredentials, "Auth Token Obtained")
                val accessToken = JSONObject(response.body?.string() ?: "").getString("access_token")

                getUsername(accessToken) {
                    setCallback.invoke(it, accessToken)
                }
            }
        })
    }

    private fun getUsername(accessToken: String, successCallback: (username: String) -> Unit) {
        if (!Helper.isNetworkAvailable(context)) {
            return
        }
        val profileRequest: Request = Request.Builder()
            .url("https://api.github.com/user")
            .addHeader("Accept", "application/json")
            .addHeader("Authorization", "token $accessToken")
            .build()

        log(LogType.GithubAuthCredentials, "Getting User Profile")
        client.newCall(profileRequest).enqueue(object: Callback {
            override fun onFailure(call: Call, e: IOException) {
                log(context, LogType.GithubAuthCredentials, e)
            }

            override fun onResponse(call: Call, response: Response) {
                val json = JSONObject(response.body?.string())
                val username = json.getString("login")

                log(LogType.GithubAuthCredentials, "Username Retrieved")
                successCallback.invoke(username)
            }

        })
    }

    override fun getRepos(accessToken: String, updateCallback: (repos: List<Pair<String, String>>) -> Unit, nextPageCallback: (nextPage: (() -> Unit)?) -> Unit){
        log(LogType.GetRepos, "Getting User Repos")
        getReposRequest(accessToken, "https://api.github.com/user/repos", updateCallback, nextPageCallback)
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
        ).enqueue(object: Callback {
            override fun onFailure(call: Call, e: IOException) {
                log(context, LogType.GetRepos, e)
            }

            override fun onResponse(call: Call, response: Response) {
                log(LogType.GetRepos, "Repos Received")

                val jsonArray = JSONArray(response.body?.string())
                val repoMap: MutableList<Pair<String, String>> = mutableListOf()

                val link = response.headers["link"] ?: ""

                if (link != "") {
                    val regex = "<(.*?)>; rel=\"next\"".toRegex()

                    val match = regex.find(link)
                    val result = match?.groups?.get(1)?.value

                    val nextLink = result ?: ""
                    if (nextLink != "") {
                        nextPageCallback {
                            getReposRequest(accessToken, nextLink, updateCallback, nextPageCallback)
                        }
                    } else {
                        nextPageCallback(null)
                    }
                }

                for (i in 0..<jsonArray.length()) {
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