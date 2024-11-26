package com.viscouspot.gitsync.util

import android.content.Context
import android.net.Uri
import android.os.Looper
import android.widget.Toast
import com.github.syari.kgit.KGit
import com.github.syari.kgit.KTransportCommand
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.ui.adapter.Commit
import com.viscouspot.gitsync.util.Helper.sendCheckoutConflictNotification
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.provider.GitProviderManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.apache.sshd.client.SshClient
import org.apache.sshd.client.config.keys.ClientIdentity
import org.apache.sshd.common.keyprovider.KeyPairProvider
import org.apache.sshd.common.util.security.SecurityUtils
import org.eclipse.jgit.api.RebaseCommand
import org.eclipse.jgit.api.ResetCommand
import org.eclipse.jgit.api.errors.CheckoutConflictException
import org.eclipse.jgit.api.errors.GitAPIException
import org.eclipse.jgit.api.errors.InvalidRemoteException
import org.eclipse.jgit.api.errors.JGitInternalException
import org.eclipse.jgit.api.errors.TransportException
import org.eclipse.jgit.api.errors.WrongRepositoryStateException
import org.eclipse.jgit.diff.DiffFormatter
import org.eclipse.jgit.errors.NotSupportedException
import org.eclipse.jgit.internal.JGitText
import org.eclipse.jgit.internal.storage.file.FileRepository
import org.eclipse.jgit.lib.BatchingProgressMonitor
import org.eclipse.jgit.lib.BranchTrackingStatus
import org.eclipse.jgit.lib.Constants
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.lib.RepositoryState
import org.eclipse.jgit.lib.StoredConfig
import org.eclipse.jgit.merge.ResolveMerger
import org.eclipse.jgit.revwalk.RevSort
import org.eclipse.jgit.revwalk.RevWalk
import org.eclipse.jgit.transport.CredentialsProvider
import org.eclipse.jgit.transport.RemoteRefUpdate
import org.eclipse.jgit.transport.SshSessionFactory
import org.eclipse.jgit.transport.SshTransport
import org.eclipse.jgit.transport.URIish
import org.eclipse.jgit.transport.UsernamePasswordCredentialsProvider
import org.eclipse.jgit.transport.sshd.JGitKeyCache
import org.eclipse.jgit.transport.sshd.ServerKeyDatabase
import org.eclipse.jgit.transport.sshd.SshdSessionFactory
import org.eclipse.jgit.transport.sshd.SshdSessionFactoryBuilder
import org.eclipse.jgit.util.io.DisabledOutputStream
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.FileWriter
import java.io.IOException
import java.net.InetSocketAddress
import java.nio.file.Files
import java.nio.file.Path
import java.security.PublicKey
import java.time.Duration
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID


class GitManager(private val context: Context, private val settingsManager: SettingsManager) {
    private fun applyCredentials(command: KTransportCommand<*, *>) {
        if (settingsManager.getGitProvider() == GitProviderManager.Companion.Provider.SSH) {
//            log(settingsManager.getGitSshPrivateKey())
//            log(System.getProperty("user.home"));
//            log(settingsManager.getGitSshPrivateKey())

            val privateKeyContent = settingsManager.getGitSshPrivateKey()
            val passphrase: String? = null
//
            val keyPairs = SecurityUtils.loadKeyPairIdentities(null, null, ByteArrayInputStream(privateKeyContent.toByteArray()),
            ) { _, _, _ -> passphrase }
//
//            val temporaryDirectory: Path
//            try {
//                temporaryDirectory = Files.createTempDirectory("ssh-temp-dir")
//            } catch (e: IOException) {
//                throw RuntimeException("Failed to create temporary directory", e)
//            }


            val sshDir = File(context.filesDir, ".ssh")
            if (!sshDir.exists()) {
                log("created dir")
                sshDir.mkdir()
            }
            val fileName = UUID.randomUUID().toString() + "_private_key"
            val file = File(sshDir, fileName)
            FileOutputStream(file).use { it.write(privateKeyContent.toByteArray()) }

//            val test = SshSessionFactory

            val sshSessionFactory = SshdSessionFactoryBuilder()
                .setPreferredAuthentications("publickey")
                .setDefaultKeysProvider { _ -> keyPairs }
                .setHomeDirectory(context.filesDir)
                .setSshDirectory(context.filesDir)
//                .setServerKeyDatabase { ignoredHomeDir: File?, ignoredSshDir: File? ->
//                    object : ServerKeyDatabase {
//                        override fun lookup(
//                            connectAddress: String,
//                            remoteAddress: InetSocketAddress,
//                            config: ServerKeyDatabase.Configuration
//                        ): List<PublicKey> {
//                            return emptyList()
//                        }
//
//                        override fun accept(
//                            connectAddress: String,
//                            remoteAddress: InetSocketAddress,
//                            serverKey: PublicKey,
//                            config: ServerKeyDatabase.Configuration,
//                            provider: CredentialsProvider
//                        ): Boolean {
//                            return true
//                        }
//                    }
//                }
                .build(JGitKeyCache())

//            command.setTransportConfigCallback {
//                val sshTransport = it as SshTransport
//                sshTransport.sshSessionFactory = sshSessionFactory
//            }

            SshSessionFactory.setInstance(sshSessionFactory)
            command.setTransportConfigCallback {
                val sshTransport = it as SshTransport
                sshTransport.sshSessionFactory = sshSessionFactory
            }
        } else {
            val authCredentials = settingsManager.getGitAuthCredentials()
            command.setCredentialsProvider(UsernamePasswordCredentialsProvider(authCredentials.first, authCredentials.second))
        }
    }

    fun cloneRepository(repoUrl: String, userStorageUri: Uri, username: String, token: String, taskCallback: (action: String) -> Unit, progressCallback: (progress: Int) -> Unit, failureCallback: (error: String) -> Unit, successCallback: () -> Unit) {
        if (!Helper.isNetworkAvailable(context)) {
            return
        }
        CoroutineScope(Dispatchers.IO).launch {
            try {
                log(LogType.CloneRepo, "Cloning Repo")

                val monitor = object : BatchingProgressMonitor() {
                    override fun onUpdate(taskName: String?, workCurr: Int, duration: Duration?) {}

                    override fun onUpdate(
                        taskName: String?,
                        workCurr: Int,
                        workTotal: Int,
                        percentDone: Int,
                        duration: Duration?
                    ) {
                        taskCallback(taskName ?: "")
                        progressCallback(percentDone)
                    }

                    override fun onEndTask(taskName: String?, workCurr: Int, duration: Duration?) {
                    }

                    override fun onEndTask(
                        taskName: String?,
                        workCurr: Int,
                        workTotal: Int,
                        percentDone: Int,
                        duration: Duration?
                    ) {}
                }

                KGit.cloneRepository {
                    setURI(repoUrl)
                    setProgressMonitor(monitor)
                    setDirectory(File(Helper.getPathFromUri(context, userStorageUri)))
                    applyCredentials(this)
//                    setCredentialsProvider(UsernamePasswordCredentialsProvider(username, token))
                }

                log(LogType.CloneRepo, "Repository cloned successfully")
                withContext(Dispatchers.Main) {
                    Toast.makeText(context, "Repository cloned successfully", Toast.LENGTH_SHORT).show()
                }

                successCallback.invoke()
            } catch (e: InvalidRemoteException) {
                failureCallback(context.getString(R.string.invalid_remote))
                return@launch
            } catch (e: TransportException) {
                e.printStackTrace()
                log(e)
                log(e.localizedMessage)
                log(e.cause)
                failureCallback(e.localizedMessage ?: context.getString(R.string.clone_failed))
                return@launch
            } catch (e: GitAPIException) {
                failureCallback(context.getString(R.string.clone_failed))
                return@launch
            }
            catch (e: JGitInternalException) {
                if (e.cause is NotSupportedException) {
                    failureCallback(context.getString(R.string.invalid_remote))
                } else {
                    failureCallback(e.localizedMessage ?: context.getString(R.string.clone_failed))
                }
                return@launch
            } catch (e: NullPointerException) {
                if (e.message?.contains("Inflater has been closed") == true) {
                    failureCallback(context.getString(R.string.large_file))
                    return@launch
                }

                log(context, LogType.CloneRepo, e)
            } catch (e: OutOfMemoryError) {
                failureCallback(context.getString(R.string.out_of_memory))
                return@launch
            } catch (e: Throwable) {
                failureCallback(context.getString(R.string.clone_failed))

                log(context, LogType.CloneRepo, e)
            }
        }
    }

    fun downloadChanges(userStorageUri: Uri, username: String, token: String, scheduleNetworkSync: () -> Unit, onSync: () -> Unit): Boolean? {
        if (conditionallyScheduleNetworkSync(scheduleNetworkSync)) {
            return null
        }
        try {
            var returnResult: Boolean? = false
            log(LogType.PullFromRepo, "Getting local directory")
            val repo = FileRepository("${Helper.getPathFromUri(context, userStorageUri)}/${context.getString(R.string.git_path)}")
            val git = KGit(repo)
            val cp = UsernamePasswordCredentialsProvider(username, token)

            log(LogType.PullFromRepo, "Fetching changes")
            val fetchResult = git.fetch {
                applyCredentials(this)
//                setCredentialsProvider(cp)
            }

            if (conditionallyScheduleNetworkSync(scheduleNetworkSync)) {
                return null
            }

            val localHead: ObjectId = repo.resolve(Constants.HEAD)
            val remoteHead: ObjectId = repo.resolve(Constants.FETCH_HEAD)

            if (!fetchResult.trackingRefUpdates.isEmpty() || !localHead.equals(remoteHead)) {
                log(LogType.PullFromRepo, "Pulling changes")
                onSync.invoke()
                val result = git.pull {
                    applyCredentials(this)
//                    setCredentialsProvider(cp)
                    remote = "origin"
                }
                if (result.mergeResult.failingPaths != null && result.mergeResult.failingPaths.containsValue(ResolveMerger.MergeFailureReason.DIRTY_WORKTREE)) {
                    log(LogType.PullFromRepo, "Merge conflict")
                    return false
                }

                if (!result.mergeResult.mergeStatus.isSuccessful) {
                    log(LogType.PullFromRepo, "Checkout conflict")
                    sendCheckoutConflictNotification(context)
                    return null
                }

                returnResult = if (result.isSuccessful()) {
                    true
                } else {
                    null
                }
            }

            log(LogType.PullFromRepo, "Closing repository")
            closeRepo(repo)

            return returnResult
        } catch (e: CheckoutConflictException) {
            log(LogType.PullFromRepo, e.stackTraceToString())
            return false
        } catch (e: WrongRepositoryStateException) {
            if (e.message?.contains(context.getString(R.string.merging_exception_message)) == true) {
                log(LogType.PullFromRepo, "Merge conflict")
                return false
            }
            log(context, LogType.PullFromRepo, e)
            return null
        } catch (e: TransportException) {
            handleTransportException(e, scheduleNetworkSync)
        } catch (e: Throwable) {
            log(context, LogType.PullFromRepo, e)
        }
        return null
    }

    fun uploadChanges(userStorageUri: Uri, syncMessage: String, username: String, token: String, scheduleNetworkSync: () -> Unit, onSync: () -> Unit): Boolean? {
        if (conditionallyScheduleNetworkSync(scheduleNetworkSync)) {
            return null
        }
        try {
            var returnResult = false
            log(LogType.PushToRepo, "Getting local directory")

            val repo = FileRepository("${Helper.getPathFromUri(context, userStorageUri)}/${context.getString(R.string.git_path)}")
            val git = KGit(repo)

            logStatus(git)
            val status = git.status()

            if (status.uncommittedChanges.isNotEmpty() || status.untracked.isNotEmpty()) {
                onSync.invoke()
                log(LogType.PushToRepo, "Adding Files to Stage")
                git.add {
                    addFilepattern(".")
                    isRenormalize = false
                }
                git.add {
                    addFilepattern(".")
                    isRenormalize = false
                    isUpdate = true
                }

                log(LogType.PushToRepo, "Getting current time")
                val currentDateTime = LocalDateTime.now()
                val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")

                log(LogType.PushToRepo, "Committing changes")
                val config: StoredConfig = git.repository.config
                val committerEmail = config.getString("user", null, "email")
                var committerName = config.getString("user", null, "name")
                if (committerName == null || committerName.equals("")) {
                    committerName = username
                }
                git.commit {
                    setCommitter(committerName, committerEmail ?: "")
                    message = syncMessage.format(currentDateTime.format(formatter))
                }

                returnResult = true
            }

            if (conditionallyScheduleNetworkSync(scheduleNetworkSync)) {
                return null
            }

            log(LogType.PushToRepo, "Pushing changes")
            for (pushResult in git.push {
                applyCredentials(this)
//                setCredentialsProvider(UsernamePasswordCredentialsProvider(username, token))
                remote = "origin"
            }) {
                for (remoteUpdate in pushResult.remoteUpdates) {
                    when (remoteUpdate.status) {
                        RemoteRefUpdate.Status.REJECTED_NONFASTFORWARD -> {
                            log(LogType.PushToRepo, "Attempting rebase on REJECTED_NONFASTFORWARD")
                            logStatus(git)
                            val trackingStatus = BranchTrackingStatus.of(git.repository, git.repository.branch)
                                ?: throw Exception(context.getString(R.string.auto_rebase_failed_exception))

                            if (git.repository.repositoryState == RepositoryState.MERGING || git.repository.repositoryState == RepositoryState.MERGING_RESOLVED) {
                                log(LogType.PushToRepo, "Aborting previous merge to ensure clean state for rebase")
                                git.rebase {
                                    setOperation(RebaseCommand.Operation.ABORT)
                                }
                            }

                            val rebaseResult = git.rebase {
                                setUpstream(trackingStatus.remoteTrackingBranch)
                            }

                            logStatus(git)

                            if (!rebaseResult.status.isSuccessful) {
                                git.rebase {
                                    setOperation(RebaseCommand.Operation.ABORT)
                                }

                                downloadChanges(userStorageUri, username, token, scheduleNetworkSync, onSync)
                                return false
                            }
                            break
                        }
                        RemoteRefUpdate.Status.NON_EXISTING -> {
                            throw Exception(context.getString(R.string.non_existing_exception))
                        }
                        RemoteRefUpdate.Status.REJECTED_NODELETE -> {
                            throw Exception(context.getString(R.string.rejected_nodelete_exception))
                        }
                        RemoteRefUpdate.Status.REJECTED_OTHER_REASON -> {
                            val reason = remoteUpdate.message
                            throw Exception(if (reason == null || reason == "") context.getString(R.string.rejected_exception) else context.getString(
                                R.string.rejection_with_reason_exception
                            ).format(reason))
                        }
                        RemoteRefUpdate.Status.REJECTED_REMOTE_CHANGED -> {
                            throw Exception(context.getString(R.string.remote_changed_exception))
                        }
                        else -> {}
                    }
                }
            }

            if (Looper.myLooper() == null) {
                Looper.prepare()
            }

            logStatus(git)

            log(LogType.PushToRepo, "Closing repository")
            closeRepo(repo)

            return returnResult
        } catch (e: TransportException) {
            handleTransportException(e, scheduleNetworkSync)
        } catch (e: Throwable) {
            log(context, LogType.PushToRepo, e)
        }
        return null
    }

    private fun conditionallyScheduleNetworkSync(scheduleNetworkSync: () -> Unit): Boolean {
        if (!Helper.isNetworkAvailable(context)) {
            scheduleNetworkSync()
            return true
        }
        return false
    }

    private fun handleTransportException(e: TransportException, scheduleNetworkSync: () -> Unit) {
        if (listOf(
            JGitText.get().connectionFailed,
            JGitText.get().connectionTimeOut,
            JGitText.get().transactionAborted,
            JGitText.get().cannotOpenService
        ).any{ e.message.toString().contains(it) } ) {
            scheduleNetworkSync.invoke()
            return
        }

        var message = e.message.toString()
        if (listOf(
            JGitText.get().authenticationNotSupported,
            JGitText.get().notAuthorized,
        ).any {
            message = it
            e.message.toString().contains(it)
        }) {
            log(context, LogType.TransportException, Throwable(message))
            return
        }

        log(context, LogType.TransportException, e)
    }

    private fun logStatus(git: KGit) {
        val status = git.status()
        log(LogType.GitStatus, """
            HasUncommittedChanges: ${status.hasUncommittedChanges()}
            Missing: ${status.missing}
            Modified: ${status.modified}
            Removed: ${status.removed}
            IgnoredNotInIndex: ${status.ignoredNotInIndex}
            Changed: ${status.changed}
            Untracked: ${status.untracked}
            Added: ${status.added}
            Conflicting: ${status.conflicting}
            UncommittedChanges: ${status.uncommittedChanges}
        """.trimIndent())
    }

    fun getRecentCommits(gitDirPath: String?): List<Commit> {
        try {
            if (gitDirPath == null || !File("$gitDirPath/${context.getString(R.string.git_path)}").exists()) return listOf()

            log(LogType.RecentCommits, ".git folder found")

            val repo = FileRepository("$gitDirPath/${context.getString(R.string.git_path)}")
            val revWalk = RevWalk(repo)

            val localHead = repo.resolve(Constants.HEAD)
            revWalk.markStart(revWalk.parseCommit(localHead))
            log(LogType.RecentCommits, "HEAD parsed")

            revWalk.sort(RevSort.COMMIT_TIME_DESC)

            val commits = mutableListOf<Commit>()
            var count = 0
            val iterator = revWalk.iterator()

            while (iterator.hasNext() && count < 10) {
                val commit = iterator.next()

                val diffFormatter = DiffFormatter(DisabledOutputStream.INSTANCE)
                diffFormatter.setRepository(repo)
                val parent = if (commit.parentCount > 0) commit.getParent(0) else null
                val diffs = if (parent != null) diffFormatter.scan(parent.tree, commit.tree) else listOf()

                var additions = 0
                var deletions = 0
                for (diff in diffs) {
                    val editList = diffFormatter.toFileHeader(diff).toEditList()
                    for (edit in editList) {
                        additions += edit.endB - edit.beginB
                        deletions += edit.endA - edit.beginA
                    }
                }

                commits.add(
                    Commit(
                        commit.shortMessage,
                        commit.authorIdent.name,
                        commit.authorIdent.`when`.time,
                        commit.name.substring(0, 7),
                        additions,
                        deletions
                    )
                )
                count++
            }

            log(LogType.RecentCommits, "Recent commits retrieved")
            revWalk.dispose()
            closeRepo(repo)

            return commits
        } catch (e: java.lang.Exception) {
            log(context, LogType.RecentCommits, e)
        }
        return listOf()
    }

    fun getConflicting(gitDirUri: Uri?): MutableList<String> {
        if (gitDirUri == null) return mutableListOf()

        val repo = FileRepository("${Helper.getPathFromUri(context, gitDirUri)}/${context.getString(R.string.git_path)}")
        val git = KGit(repo)
        val status = git.status()
        return status.conflicting.toMutableList()
    }

    fun abortMerge(gitDirUri: Uri?) {
        if (gitDirUri == null) return
        val gitDirPath = Helper.getPathFromUri(context, gitDirUri)

        try {
            val repo = FileRepository("$gitDirPath/${context.getString(R.string.git_path)}")
            val git = KGit(repo)

            val mergeHeadFile = File("$gitDirPath/${context.getString(R.string.git_merge_head_path)}")
            if (mergeHeadFile.exists()) {
                git.reset {
                    setMode(ResetCommand.ResetType.HARD)
                }

                val mergeMsgFile = File("$gitDirPath/${context.getString(R.string.git_merge_msg_path)}")
                if (mergeMsgFile.exists()) {
                    mergeMsgFile.delete()
                }
                if (mergeHeadFile.exists()) {
                    mergeHeadFile.delete()
                }
            }

            log(LogType.AbortMerge, "Merge successful")
        } catch (e: IOException) {
            log(context, LogType.AbortMerge, e)
        } catch (e: GitAPIException) {
            log(context, LogType.AbortMerge, e)
        }
    }

    fun readGitignore(gitDirPath: String): String {
        if (!File("$gitDirPath/${context.getString(R.string.gitignore_path)}").exists()) return ""

        val gitignoreFile = File(gitDirPath, context.getString(R.string.gitignore_path))
        return gitignoreFile.readText()
    }

    fun writeGitignore(gitDirPath: String, gitignoreString: String) {
        val gitignoreFile = File(gitDirPath, context.getString(R.string.gitignore_path))
        if (!gitignoreFile.exists()) gitignoreFile.createNewFile()
        try {
            FileWriter(gitignoreFile, false).use { writer ->
                writer.write(gitignoreString)
            }
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    fun readGitInfoExclude(gitDirPath: String): String {
        if (!File("$gitDirPath/${context.getString(R.string.git_info_exclude_path)}").exists()) return ""

        val gitignoreFile = File(gitDirPath, context.getString(R.string.git_info_exclude_path))
        return gitignoreFile.readText()
    }

    fun writeGitInfoExclude(gitDirPath: String, gitignoreString: String) {
        val gitignoreFile = File(gitDirPath, context.getString(R.string.git_info_exclude_path))
        val parentDir = gitignoreFile.parentFile
        if (parentDir != null) {
            if (!parentDir.exists()) {
                parentDir.mkdirs()
            }
        }
        if (!gitignoreFile.exists()) gitignoreFile.createNewFile()

        try {
            FileWriter(gitignoreFile, false).use { writer ->
                writer.write(gitignoreString)
            }
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    private fun closeRepo(repo: FileRepository) {
        repo.close()
        val lockFile = File(repo.directory, context.getString(R.string.git_lock_path))
        if (lockFile.exists()) lockFile.delete()
    }
}