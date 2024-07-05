package com.viscouspot.gitsync.util

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Looper
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.viscouspot.gitsync.Secrets
import com.viscouspot.gitsync.ui.adapter.Commit
import com.viscouspot.gitsync.util.Logger.log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.internal.storage.file.FileRepository
import org.eclipse.jgit.lib.Repository
import org.eclipse.jgit.revwalk.RevSort
import org.eclipse.jgit.revwalk.RevWalk
import org.eclipse.jgit.revwalk.filter.RevFilter
import org.eclipse.jgit.transport.UsernamePasswordCredentialsProvider
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID


class GitManager(private val context: Context, private val activity: AppCompatActivity? = null) {
    private val GITHUB_AUTH_URL = "https://github.com/login/oauth/authorize"
    private val GIT_SCOPE = "repo"
    private val client = OkHttpClient()

    fun launchGithubOAuthFlow() {
        val fullAuthUrl = "$GITHUB_AUTH_URL?client_id=${Secrets.GIT_CLIENT_ID}&scope=$GIT_SCOPE&state=${UUID.randomUUID()}"

        if (activity == null) {
            log(context, "GithubFlow", "Activity Not Found")
            return
        }

        log(context, "GithubFlow", "Launching Flow")
        activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(fullAuthUrl)).apply {
            addCategory(Intent.CATEGORY_BROWSABLE)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
    }

    fun getGithubAuthCredentials(code: String, state: String, setCallback: (username: String, authToken: String) -> Unit) {
        val authTokenRequest: Request = Request.Builder()
            .url("https://github.com/login/oauth/access_token?client_id=${Secrets.GIT_CLIENT_ID}&client_secret=${Secrets.GIT_CLIENT_SECRET}&code=$code&state=$state")
            .post("".toRequestBody())
            .addHeader("Accept", "application/json")
            .build()

        client.newCall(authTokenRequest).enqueue(object: Callback {
            override fun onFailure(call: Call, e: IOException) {
                log(context, "GithubAuthCredentials", e)
            }

            override fun onResponse(call: Call, response: Response) {
                log(context, "GithubAuthCredentials", "Auth Token Obtained")
                val authToken = JSONObject(response.body?.string()).getString("access_token")

                getGithubProfile(authToken, {
                    setCallback.invoke(it, authToken)
                }, { })
            }
        })
    }

    fun getGithubProfile(authToken: String, successCallback: (username: String) -> Unit, failureCallback: () -> Unit) {
        val profileRequest: Request = Request.Builder()
            .url("https://api.github.com/user")
            .addHeader("Accept", "application/json")
            .addHeader("Authorization", "token $authToken")
            .build()

        log(context, "GithubAuthCredentials", "Getting User Profile")
        client.newCall(profileRequest).enqueue(object: Callback {
            override fun onFailure(call: Call, e: IOException) {
                log(context, "GithubAuthCredentials", e)
                failureCallback.invoke()
            }

            override fun onResponse(call: Call, response: Response) {
                val json = JSONObject(response.body?.string())
                val username = json.getString("login")

                log(context, "GithubAuthCredentials", "Username Retrieved")
                successCallback.invoke(username)
            }

        })
    }

    fun getRepos(authToken: String, callback: (repos: List<Pair<String, String>>) -> Unit) {
        val reposRequest: Request = Request.Builder()
            .url("https://api.github.com/user/repos")
            .addHeader("Accept", "application/json")
            .addHeader("Authorization", "token $authToken")
            .build()

        log(context, "GetRepos", "Getting User Repos")
        client.newCall(reposRequest).enqueue(object: Callback {
            override fun onFailure(call: Call, e: IOException) {
                log(context, "GetRepos", e)
            }

            override fun onResponse(call: Call, response: Response) {
                log(context, "GetRepos", "Repos Received")

                val jsonArray = JSONArray(response.body?.string())
                val repoMap: MutableList<Pair<String, String>> = mutableListOf()

                for (i in 0..<jsonArray.length()) {
                    val obj = jsonArray.getJSONObject(i)
                    val name = obj.getString("name")
                    val cloneUrl = obj.getString("clone_url")
                    repoMap.add(Pair(name, cloneUrl))
                }

                callback.invoke(repoMap)
            }
        })
    }

    fun cloneRepository(repoUrl: String, storageDir: String, username: String, token: String, callback: () -> Unit) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                log(context, "CloneRepo", "Cloning Repo")
                Git.cloneRepository()
                    .setURI(repoUrl)
                    .setDirectory(File(storageDir))
                    .setCredentialsProvider(UsernamePasswordCredentialsProvider(username, token))
                    .call()

                log(context, "CloneRepo", "Repository cloned successfully")
                withContext(Dispatchers.Main) {
                    Toast.makeText(context, "Repository cloned successfully", Toast.LENGTH_SHORT).show()
                }

                callback.invoke()
            } catch (e: Exception) {
                log(context, "CloneRepo", e)

                log(context, "CloneRepo", "Repository clone failed")
                withContext(Dispatchers.Main) {
                    Toast.makeText(context, "Failed to clone repository", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }


    fun pullRepository(storageDir: String, username: String, token: String, onSync: () -> Unit): Boolean? {
        try {
            var returnResult: Boolean? = false
            log(context, "PullFromRepo", "Getting local directory")
            val repo = FileRepository("$storageDir/.git")
            val git = Git(repo)
            val cp = UsernamePasswordCredentialsProvider(username, token)

            log(context, "PullFromRepo", "Fetching changes")
            val fetchResult = git.fetch().setCredentialsProvider(cp).call()

            if (!fetchResult.trackingRefUpdates.isEmpty()) {
                log(context, "PullFromRepo", "Pulling changes")
                onSync.invoke()
                val result = git.pull()
                    .setCredentialsProvider(cp)
                    .setRemote("origin")
                    .call()
                if (result.isSuccessful()) {
                    returnResult = true
                } else {
                    returnResult = null
                }
            }

            log(context, "PullFromRepo", "Closing repository")
            closeRepo(repo)

            return returnResult
        } catch (e: Exception) {
            log(context, "PullFromRepo", e)
        }
        return null
    }

    fun pushAllToRepository(repoUrl: String, storageDir: String, username: String, token: String, onSync: () -> Unit): Boolean? {
        try {
            var returnResult = false
            log(context, "PushToRepo", "Getting local directory")

            val repo = FileRepository("$storageDir/.git")
            val git = Git(repo)

            logStatus(git)
            val status = git.status().call()
            if (status.uncommittedChanges.isNotEmpty() || status.untracked.isNotEmpty()) {
                onSync.invoke()
                log(context, "PushToRepo", "Adding Files to Stage")
                git.add().addFilepattern(".").call();
                git.add().addFilepattern(".").setUpdate(true).call();

                log(context, "PushToRepo", "Getting current time")
                val currentDateTime = LocalDateTime.now()
                val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")

                log(context, "PushToRepo", "Committing changes")
                git.commit()
                    .setCommitter(username, "")
                    .setMessage("Last Sync: ${currentDateTime.format(formatter)} (Mobile)")
                    .call()

                log(context, "PushToRepo", "Pushing changes")
                git.push()
                    .setCredentialsProvider(UsernamePasswordCredentialsProvider(username, token))
                    .setRemote(repoUrl)
                    .call()

                if (Looper.myLooper() == null) {
                    Looper.prepare()
                }

                returnResult = true
            }
            logStatus(git)

            log(context, "PushToRepo", "Closing repository")
            closeRepo(repo)

            return returnResult
        } catch (e: Exception) {
            log(context, "PushToRepo", e)
        }
        return null
    }

    private fun logStatus(git: Git) {
        val status = git.status().call()
        log(context, "GitStatus.HasUncommittedChanges", status.hasUncommittedChanges().toString())
        log(context, "GitStatus.Missing", status.missing.toString())
        log(context, "GitStatus.Modified", status.modified.toString())
        log(context, "GitStatus.Removed", status.removed.toString())
        log(context, "GitStatus.IgnoredNotInIndex", status.ignoredNotInIndex.toString())
        log(context, "GitStatus.Changed", status.changed.toString())
        log(context, "GitStatus.Untracked", status.untracked.toString())
        log(context, "GitStatus.Added", status.added.toString())
        log(context, "GitStatus.Conflicting", status.conflicting.toString())
        log(context, "GitStatus.UncommittedChanges", status.uncommittedChanges.toString())
    }

    fun getRecentCommits(storageDir: String): List<Commit> {
        try {
            if (!File("$storageDir/.git").exists()) return listOf()

            val repo = FileRepository("$storageDir/.git")
            val revWalk = RevWalk(repo)

            val head = repo.resolve("refs/heads/master")
            revWalk.markStart(revWalk.parseCommit(head))
            revWalk.sort(RevSort.COMMIT_TIME_DESC)
            revWalk.setRevFilter(RevFilter.NO_MERGES)

            val commits = mutableListOf<Commit>()
            var count = 0
            val iterator = revWalk.iterator()

            while (iterator.hasNext() && count < 10) {
                val commit = iterator.next()
                commits.add(
                    Commit(
                        commit.shortMessage,
                        commit.authorIdent.name,
                        commit.authorIdent.`when`.time,
                        commit.name.substring(0, 7)
                    )
                )
                count++
            }

            closeRepo(repo)

            return commits
        } catch (e: java.lang.Exception) {
            log(context, "RecentCommits", e)
        }
        return listOf()
    }

    private fun closeRepo(repo: Repository) {
        repo.close()
        val lockFile = File(repo.directory, "index.lock")
        if (lockFile.exists()) lockFile.delete()
    }
}