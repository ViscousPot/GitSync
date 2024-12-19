package com.viscouspot.gitsync

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Dialog
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.PorterDuff
import android.graphics.Rect
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.accessibility.AccessibilityManager
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.Switch
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.constraintlayout.widget.ConstraintSet
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.widget.TextViewCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.ui.RecyclerViewEmptySupport
import com.viscouspot.gitsync.ui.adapter.ApplicationListAdapter
import com.viscouspot.gitsync.ui.adapter.Commit
import com.viscouspot.gitsync.ui.adapter.RecentCommitsAdapter
import com.viscouspot.gitsync.ui.dialog.ApplicationSelectDialog
import com.viscouspot.gitsync.ui.dialog.AuthDialog
import com.viscouspot.gitsync.ui.dialog.BaseDialog
import com.viscouspot.gitsync.ui.dialog.BasicDialog
import com.viscouspot.gitsync.ui.dialog.MergeConflictDialog
import com.viscouspot.gitsync.ui.dialog.SettingsDialog
import com.viscouspot.gitsync.ui.fragment.CloneRepoFragment
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.provider.GitProviderManager
import com.viscouspot.gitsync.util.Helper
import com.viscouspot.gitsync.util.LogType
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.OnboardingController
import com.viscouspot.gitsync.util.SettingsManager
import com.viscouspot.gitsync.util.rightDrawable
import java.io.File

class MainActivity : AppCompatActivity() {
    private lateinit var applicationObserverMax: ConstraintSet
    private lateinit var applicationObserverMin: ConstraintSet

    private lateinit var gitManager: GitManager
    private lateinit var settingsManager: SettingsManager
    private lateinit var onboardingController: OnboardingController
    private lateinit var cloneRepoFragment: CloneRepoFragment

    private val recentCommits: MutableList<Commit> = mutableListOf()
    private lateinit var recentCommitsRecycler: RecyclerViewEmptySupport
    private lateinit var recentCommitsAdapter: RecentCommitsAdapter

    private var mergeConflictDialog: Dialog? = null

    private lateinit var forceSyncButton: MaterialButton
    private lateinit var settingsButton: MaterialButton
    private lateinit var syncMessageButton: MaterialButton

    private lateinit var gitRepoName: EditText
    private lateinit var cloneRepoButton: MaterialButton
    private lateinit var gitAuthButton: MaterialButton

    private lateinit var gitDirPath: TextView
    private lateinit var deselectDirButton: MaterialButton
    private lateinit var selectDirButton: MaterialButton

    private lateinit var viewDocs: MaterialButton

    private lateinit var applicationObserverPanel: ConstraintLayout
    private lateinit var applicationObserverSwitch: Switch

    private lateinit var selectApplication: MaterialButton

    private val applicationList: MutableList<Drawable> = mutableListOf()
    private lateinit var applicationRecycler: RecyclerView
    private lateinit var applicationListAdapter: ApplicationListAdapter

    private lateinit var syncAppOpened: Switch
    private lateinit var syncAppClosed: Switch

    private var onStoragePermissionGranted: (() -> Unit)? = null
    private var requestLegacyStoragePermission: ActivityResultLauncher<Array<String>>? = null
    private var requestStoragePermission: ActivityResultLauncher<Intent>? = null

    private lateinit var authDialog: Dialog
    private var prominentDisclosure: AlertDialog? = null
    private var applicationSelectDialog: Dialog? = null

    private var requestedPermission = false

    companion object {
        const val REFRESH = "REFRESH"
        const val MERGE_COMPLETE = "MERGE_COMPLETE"
    }

    private val broadcastReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                REFRESH -> refreshRecentCommits()
                MERGE_COMPLETE -> {
                    mergeConflictDialog?.dismiss()
                    refreshRecentCommits()
                }
            }
        }
    }

    private val dirSelectionLauncher = Helper.getDirSelectionLauncher(this, this, ::dirSelectionCallback)

    private fun dirSelectionCallback(dirUri: Uri?) {
        if (dirUri == null) {
            Toast.makeText(this, getString(R.string.inaccessible_directory_message), Toast.LENGTH_LONG).show()
            return
        }

        settingsManager.setGitDirUri(dirUri.toString())

        gitDirPath.text = Helper.getPathFromUri(this, dirUri)
        refreshGitRepo()

        settingsManager.setOnboardingStep(4)
        onboardingController.dismissAll()
        onboardingController.show()
    }

    private val requestNotificationPermission = this.registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_DOWN) {
            val v = currentFocus
            if (v is EditText) {
                val outRect = Rect()
                v.getGlobalVisibleRect(outRect)
                if (!outRect.contains(event.rawX.toInt(), event.rawY.toInt())) {
                    v.clearFocus()
                    val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.hideSoftInputFromWindow(v.windowToken, 0)
                }
            }
        }

        return super.dispatchTouchEvent(event)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val uri = intent.data ?: return

        log(LogType.GithubOAuthFlow, "Flow Ended")

        val gitManager = GitProviderManager.getManager(this, settingsManager)
        gitManager.getOAuthCredentials(uri, ::setGitCredentials)
    }

    fun setGitCredentials(username: String?, token: String?) {
        if (token == null) {
            return
        }

        if (username == null) {
            log(LogType.GithubAuthCredentials, "SSH Key Received")
            settingsManager.setGitSshPrivateKey(token)
        } else {
            log(LogType.GithubAuthCredentials, "Username and Token Received")
            settingsManager.setGitAuthCredentials(username, token)
        }

        if (!cloneRepoFragment.isAdded) {
            cloneRepoFragment.show(supportFragmentManager, getString(R.string.clone_repo_title))
        }

        settingsManager.setOnboardingStep(3)
        onboardingController.dismissAll()

        refreshAuthButton()
    }

    private fun setRecyclerViewHeight(recyclerView: RecyclerView) {
        val adapter = recyclerView.adapter ?: return

        val viewHolder = adapter.createViewHolder(recyclerView, adapter.getItemViewType(0))
        viewHolder.itemView.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED)

        val itemHeight = (viewHolder.itemView.layoutParams as ViewGroup.MarginLayoutParams).topMargin + viewHolder.itemView.measuredHeight

        recyclerView.layoutParams.height = itemHeight * 3
        recyclerView.requestLayout()
    }

    override fun onPause() {
        super.onPause()

        if (settingsManager.getOnboardingStep() != 0 && !onboardingController.hasSkipped) {
            onboardingController.dismissAll()
        }
    }

    override fun onDestroy() {
        super.onDestroy()

        try {
            unregisterReceiver(broadcastReceiver)
        } catch (_: Exception) { }
    }

    override fun onResume() {
        super.onResume()

        if (requestedPermission) {
            requestedPermission = false
            if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
                settingsManager.setSyncMessageEnabled(true)
            } else {
                if (onboardingController.showNotificationsOrNext()) return
            }

            if (checkAccessibilityPermission()) {
                settingsManager.setApplicationObserverEnabled(true)
            }
        } else {
            if (settingsManager.getOnboardingStep() != -1 && !authDialog.isShowing && prominentDisclosure?.isShowing != true) {
                onboardingController.show()
                return
            }

            val hasAllFilesAccess = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) Environment.isExternalStorageManager() else
                ContextCompat.checkSelfPermission(this, android.Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
            if (!hasAllFilesAccess || !NotificationManagerCompat.from(this).areNotificationsEnabled()) {
                if (onboardingController.showNotificationsOrNext(true)) return
            }
        }

        refreshAll()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        System.setProperty("org.eclipse.jgit.util.Debug", "true")
        System.setProperty("org.apache.sshd.common.util.logging.level", "DEBUG")

        Thread.setDefaultUncaughtExceptionHandler { _, paramThrowable ->
            log(this, LogType.Global, paramThrowable)
        }

        settingsManager = SettingsManager(this)
        settingsManager.runMigrations()

        requestLegacyStoragePermission = this.registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { isGrantedMap ->
            if (isGrantedMap.values.all { it }) {
                onStoragePermissionGranted?.invoke()
            }
        }

        requestStoragePermission = this.registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
            val hasPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Environment.isExternalStorageManager()
            } else ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED

            if (hasPermissions) {
                onStoragePermissionGranted?.invoke()
            }
        }

        if (!settingsManager.isFirstTime()) {
            checkAndRequestStoragePermission()
        }

        val bManager = LocalBroadcastManager.getInstance(this)
        val intentFilter = IntentFilter()
        intentFilter.addAction(REFRESH)
        intentFilter.addAction(MERGE_COMPLETE)
        bManager.registerReceiver(broadcastReceiver, intentFilter)

        window.statusBarColor = ContextCompat.getColor(this, R.color.app_bg)

        gitManager = GitManager(this, settingsManager)

        recentCommitsRecycler = findViewById(R.id.recentCommitsRecycler)

        recentCommitsAdapter = RecentCommitsAdapter(this, recentCommits, ::openMergeConflictDialog)

        forceSyncButton = findViewById(R.id.forceSyncButton)
        settingsButton = findViewById(R.id.settingsButton)
        syncMessageButton = findViewById(R.id.syncMessageButton)

        gitRepoName = findViewById(R.id.gitRepoName)
        cloneRepoButton = findViewById(R.id.cloneRepoButton)
        gitAuthButton = findViewById(R.id.gitAuthButton)

        gitDirPath = findViewById(R.id.gitDirPath)
        deselectDirButton = findViewById(R.id.deselectDirButton)
        selectDirButton = findViewById(R.id.selectDirButton)

        viewDocs = findViewById(R.id.viewDocs)

        applicationObserverPanel = findViewById(R.id.applicationObserverPanel)
        applicationObserverSwitch = applicationObserverPanel.findViewById(R.id.enableApplicationObserver)

        selectApplication = findViewById(R.id.selectApplication)
        applicationRecycler = findViewById(R.id.applicationRecycler)
        applicationListAdapter = ApplicationListAdapter(applicationList)
        syncAppOpened = findViewById(R.id.syncAppOpened)
        syncAppClosed = findViewById(R.id.syncAppClosed)

        applicationObserverMax = ConstraintSet().apply { clone(applicationContext, R.layout.application_observer_max) }
        applicationObserverMin = ConstraintSet().apply { clone(applicationContext, R.layout.application_observer_min) }

        recentCommitsRecycler.adapter = recentCommitsAdapter
        applicationRecycler.adapter = applicationListAdapter

        authDialog = AuthDialog(this, settingsManager, ::setGitCredentials)
        cloneRepoFragment = CloneRepoFragment(settingsManager, gitManager, ::dirSelectionCallback)
        onboardingController = OnboardingController(this, this, settingsManager, authDialog, cloneRepoFragment, ::updateApplicationObserver, ::checkAndRequestNotificationPermission, ::checkAndRequestStoragePermission)

        setRecyclerViewHeight(recentCommitsRecycler)

        val emptyCommitsView = findViewById<TextView>(R.id.emptyCommitsView)
        recentCommitsRecycler.setEmptyView(emptyCommitsView)

        forceSyncButton.setOnClickListener {
            val forceSyncIntent = Intent(this, GitSyncService::class.java)
            forceSyncIntent.setAction(GitSyncService.FORCE_SYNC)
            startService(forceSyncIntent)
        }

        settingsButton.setOnClickListener {
            openSettingsDialog()
        }

        syncMessageButton.setOnClickListener {
            val syncMessageEnabled = settingsManager.getSyncMessageEnabled()

            if (!syncMessageEnabled) {
                checkAndRequestNotificationPermission {
                    settingsManager.setSyncMessageEnabled(true)
                    syncMessageButton.setIconResource(R.drawable.notify)
                    syncMessageButton.setIconTintResource(R.color.auth_green)
                }
            } else {
                settingsManager.setSyncMessageEnabled(false)
                syncMessageButton.setIconResource(R.drawable.notify_off)
                syncMessageButton.setIconTintResource(R.color.primary_light)
            }
        }

        gitAuthButton.setOnClickListener {
            authDialog.show()
        }

        deselectDirButton.setOnClickListener {
            settingsManager.setGitDirUri("")

            gitDirPath.text = getString(R.string.git_dir_path_hint)
            refreshGitRepo()
            val recentCommitsSize = recentCommits.size
            recentCommits.clear()
            recentCommitsAdapter.notifyItemRangeRemoved(0, recentCommitsSize)
        }

        selectDirButton.setOnClickListener {
            dirSelectionLauncher.launch(null)
        }

        (if (settingsManager.getApplicationObserverEnabled()) applicationObserverMax else applicationObserverMin).applyTo(applicationObserverPanel)
        updateApplicationObserverSwitch()

        applicationObserverSwitch.setOnCheckedChangeListener { _, isChecked ->
            updateApplicationObserver(isChecked)
        }

        selectApplication.setOnClickListener {
            showApplicationSelectDialog()
        }

        syncAppOpened.setOnCheckedChangeListener { _, isChecked ->
            settingsManager.setSyncOnAppOpened(isChecked)
        }

        syncAppClosed.setOnCheckedChangeListener { _, isChecked ->
            settingsManager.setSyncOnAppClosed(isChecked)
        }

        viewDocs.setOnClickListener {
            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(getString(R.string.docs_link)))
            startActivity(browserIntent)
        }
    }

    private fun updateApplicationObserver(isChecked: Boolean) {
        (if (isChecked) applicationObserverMax else applicationObserverMin).applyTo(applicationObserverPanel)
        if (isChecked) {
            updateApplicationObserverSwitch(true)
            if (!checkAccessibilityPermission()) {
                applicationObserverSwitch.isChecked = false
                syncAppOpened.isChecked = false
                syncAppClosed.isChecked = false
                updateApplicationObserverSwitch(false)
                applicationObserverMin.applyTo(applicationObserverPanel)
                displayProminentDisclosure()
            } else {
                settingsManager.setApplicationObserverEnabled(true)
                refreshSelectedApplications()
            }
        } else {
            updateApplicationObserverSwitch(false)
            settingsManager.setApplicationObserverEnabled(false)
        }
    }

    private fun openMergeConflictDialog() {
        if (mergeConflictDialog?.isShowing == true) mergeConflictDialog?.dismiss()

        mergeConflictDialog = MergeConflictDialog(this, settingsManager, gitManager, ::refreshRecentCommits)
        mergeConflictDialog?.show()
    }

    private fun updateApplicationObserverSwitch(upDown: Boolean = settingsManager.getApplicationObserverEnabled()) {
        applicationObserverSwitch.setCompoundDrawablesWithIntrinsicBounds(null, null, ContextCompat.getDrawable(this, if (upDown) R.drawable.angle_up else R.drawable.angle_down)
            ?.apply {
                setTint(ContextCompat.getColor(this@MainActivity, if (checkAccessibilityPermission()) R.color.auth_green else R.color.text_secondary))
            }, null)
    }

    private fun openSettingsDialog() {
        val settingsDialog = SettingsDialog(this, settingsManager, gitManager, gitDirPath.text.toString())
        settingsDialog.show()
    }

    private fun getDeviceApps(): List<String> {
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)
        val apps = packageManager.queryIntentActivities(intent, PackageManager.GET_META_DATA)

        return apps.map {
            it.activityInfo.packageName
        }.sortedBy { packageManager.getApplicationLabel(packageManager.getApplicationInfo(it, 0)).toString() }
    }

    private fun showApplicationSelectDialog() {
        if (applicationSelectDialog?.isShowing == true) applicationSelectDialog?.dismiss()

        applicationSelectDialog = ApplicationSelectDialog(this, settingsManager, getDeviceApps(), ::refreshSelectedApplications)
        applicationSelectDialog?.show()
    }

    private fun refreshAll() {
        refreshRecentCommits()

        runOnUiThread {
            if (settingsManager.getSyncMessageEnabled()) {
                settingsManager.setSyncMessageEnabled(false)
                if (settingsManager.getOnboardingStep() != 0) {
                    checkAndRequestNotificationPermission {
                        settingsManager.setSyncMessageEnabled(true)
                        syncMessageButton.setIconResource(R.drawable.notify)
                        syncMessageButton.setIconTintResource(R.color.auth_green)
                    }
                }
            } else {
                syncMessageButton.setIconResource(R.drawable.notify_off)
                syncMessageButton.setIconTintResource(R.color.primary_light)
            }
        }

        refreshAuthButton()
        refreshGitRepo()

        runOnUiThread {
            settingsManager.getGitDirUri()?.let {
                gitDirPath.text = Helper.getPathFromUri(this, it)
            }
        }

        val applicationObserverEnabled = settingsManager.getApplicationObserverEnabled()
        updateApplicationObserver(applicationObserverEnabled)

        runOnUiThread {
            syncAppOpened.isChecked = settingsManager.getSyncOnAppOpened()
            syncAppClosed.isChecked = settingsManager.getSyncOnAppClosed()
        }
    }

    private fun refreshSelectedApplications() {
        runOnUiThread {
            if (settingsManager.getApplicationPackages().isEmpty()) {
                syncAppOpened.isEnabled = false
                syncAppOpened.isChecked = false
                syncAppClosed.isEnabled = false
                syncAppClosed.isChecked = false
            } else {
                syncAppOpened.isEnabled = true
                syncAppClosed.isEnabled = true
            }

            val packageNames = settingsManager.getApplicationPackages()
            if (packageNames.isNotEmpty()) {
                when (packageNames.size) {
                    1 -> {
                        selectApplication.text = packageManager.getApplicationLabel(
                            packageManager.getApplicationInfo(
                                packageNames.elementAt(0),
                                0
                            )
                        ).toString()
                        selectApplication.icon =
                            packageManager.getApplicationIcon(packageNames.elementAt(0))
                        selectApplication.iconTintMode = PorterDuff.Mode.MULTIPLY
                        selectApplication.iconTint = ContextCompat.getColorStateList(this, android.R.color.white)

                        applicationRecycler.visibility = View.GONE
                    }

                    else -> {
                        selectApplication.text = getString(R.string.multiple_application_selected).format(if (packageNames.size < 5) packageNames.size else getString(R.string.lg_3_apps_selected_text))
                        selectApplication.icon = null

                        applicationRecycler.visibility = View.VISIBLE
                        val iconList = packageNames.map { packageManager.getApplicationIcon(it) }
                        val prevSize = applicationList.size
                        applicationList.clear()
                        applicationListAdapter.notifyItemRangeRemoved(0, prevSize)
                        applicationList.addAll(iconList)
                        applicationListAdapter.notifyItemRangeInserted(0, iconList.size)
                    }
                }
            } else {
                selectApplication.text = getString(R.string.application_not_set)
                selectApplication.setIconResource(R.drawable.circle_plus)
                selectApplication.setIconTintResource(R.color.primary_light)
                selectApplication.iconTintMode = PorterDuff.Mode.SRC_IN

                applicationRecycler.visibility = View.GONE
            }
        }
    }

    private fun refreshRecentCommits() {
        runOnUiThread {
            val mergeConflictIndex = recentCommits.indexOfFirst { it.reference == RecentCommitsAdapter.MERGE_CONFLICT}
            if (mergeConflictIndex >= 0) {
                recentCommits.removeAt(mergeConflictIndex)
                recentCommitsAdapter.notifyItemRemoved(mergeConflictIndex)
            }

        }

        val gitDirUri = settingsManager.getGitDirUri()
        gitDirUri?.let {
            val recentCommitsReferences = recentCommits.map { commit -> commit.reference }
            log(settingsManager.getGitDirUri())
            val newRecentCommits = gitManager.getRecentCommits(Helper.getPathFromUri(this, it))
                .filter { commit -> !recentCommitsReferences.contains(commit.reference) }
            if (newRecentCommits.isNotEmpty()) {
                runOnUiThread {
                    recentCommits.addAll(0, newRecentCommits)
                    recentCommitsAdapter.notifyItemRangeInserted(0, newRecentCommits.size)
                    recentCommitsRecycler.smoothScrollToPosition(0)
                }
            }
        }

        if (gitManager.getConflicting(settingsManager.getGitDirUri()).isNotEmpty()) {
            runOnUiThread {
                forceSyncButton.isEnabled = false

                recentCommits.add(0, Commit("", "", 0L, RecentCommitsAdapter.MERGE_CONFLICT, 0, 0))
                recentCommitsAdapter.notifyItemInserted(0)
                recentCommitsRecycler.smoothScrollToPosition(0)
            }
        } else {
            runOnUiThread {
                forceSyncButton.isEnabled = true
            }
        }
    }

    private fun refreshGitRepo() {
        runOnUiThread {
            var repoName = ""
            val gitDirUri = settingsManager.getGitDirUri()

            gitDirUri?.let {
                val gitConfigFile = File("${Helper.getPathFromUri(this, it)}/${getString(R.string.git_config_path)}")
                if (gitConfigFile.exists()) {
                    val fileContents = gitConfigFile.readText()

                    val gitConfigUrlRegex = "url = (.*?)\\n".toRegex()
                    val gitConfigUrlResult = gitConfigUrlRegex.find(fileContents)
                    val url = gitConfigUrlResult?.groups?.get(1)?.value

                    val gitRepoNameRegex = ".*/([^/]+?)(\\.git)?$".toRegex()
                    val gitRepoNameResult = gitRepoNameRegex.find(url.toString())
                    repoName = gitRepoNameResult?.groups?.get(1)?.value ?: ""
                }
            }

            if (repoName == "") {
                gitRepoName.setText(getString(R.string.repo_not_found))
                gitRepoName.isEnabled = false

                cloneRepoButton.visibility = View.VISIBLE
                deselectDirButton.visibility = View.GONE
                cloneRepoButton.setOnClickListener {
                    CloneRepoFragment(settingsManager, gitManager, ::dirSelectionCallback).show(supportFragmentManager, getString(R.string.clone_repo))
                }

                applicationObserverSwitch.isChecked = false
                applicationObserverSwitch.isEnabled = false
                settingsButton.isEnabled = false

                if (gitDirPath.text.isEmpty()) {
                    gitRepoName.rightDrawable(null)
                    gitRepoName.compoundDrawablePadding = 0
                    return@runOnUiThread
                }

                gitRepoName.rightDrawable(R.drawable.circle_xmark)
                TextViewCompat.setCompoundDrawableTintList(gitRepoName, ContextCompat.getColorStateList(this, R.color.auth_red))
                gitRepoName.compoundDrawablePadding =
                    (4 * resources.displayMetrics.density + 0.5f).toInt()

                val recentCommitsSize = recentCommits.size
                recentCommits.clear()
                recentCommitsAdapter.notifyItemRangeRemoved(0, recentCommitsSize)

                return@runOnUiThread
            }

            gitRepoName.setText(repoName)
            gitRepoName.isEnabled = true
            settingsButton.isEnabled = true
            gitRepoName.rightDrawable(R.drawable.circle_check)
            TextViewCompat.setCompoundDrawableTintList(gitRepoName, ContextCompat.getColorStateList(this, R.color.auth_green))
            gitRepoName.compoundDrawablePadding =
                (4 * resources.displayMetrics.density + 0.5f).toInt()

            cloneRepoButton.visibility = View.GONE
            deselectDirButton.visibility = View.VISIBLE

            applicationObserverSwitch.isEnabled = true

        }

        refreshRecentCommits()
    }

    private fun refreshAuthButton() {
        runOnUiThread {
            if (settingsManager.getGitAuthCredentials().second != "" || settingsManager.getGitSshPrivateKey() != "") {
                gitAuthButton.icon = ContextCompat.getDrawable(this, R.drawable.circle_check)
                gitAuthButton.setIconTintResource(R.color.auth_green)

                selectDirButton.isEnabled = true
                cloneRepoButton.isEnabled = true

                return@runOnUiThread
            }

            gitAuthButton.icon = ContextCompat.getDrawable(this, R.drawable.circle_xmark)
            gitAuthButton.setIconTintResource(R.color.auth_red)

            selectDirButton.isEnabled = false
            cloneRepoButton.isEnabled = false
        }
    }

    private fun checkAccessibilityPermission(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)

        return enabledServices.any {
            it.resolveInfo.serviceInfo.packageName == packageName &&
                    it.resolveInfo.serviceInfo.name == GitSyncAccessibilityService::class.java.name
        }
    }

    private fun displayProminentDisclosure() {
        prominentDisclosure?.dismiss()

        prominentDisclosure = BasicDialog(this)
            .setTitle(getString(R.string.accessibility_service_disclosure_title))
            .setMessage(getString(R.string.accessibility_service_disclosure_message))
            .setPositiveButton(android.R.string.ok) { _, _ ->
                requestAccessibilityPermission()
            }
            .setNegativeButton(android.R.string.cancel) { _, _ -> }

        prominentDisclosure?.show()
    }

    private fun requestAccessibilityPermission() {
        val openSettings = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        openSettings.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY)
        requestedPermission = true
        settingsManager.setOnboardingStep(-1)
        startActivity(openSettings)
        Toast.makeText(this, getString(R.string.enable_accessibility_service), Toast.LENGTH_LONG).show()
    }

    private fun checkAndRequestNotificationPermission(onGranted: (() -> Unit)? = null) {
        if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            onGranted?.invoke()
            return
        }

        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
        } else {
            Intent().apply {
                action = "android.settings.APP_NOTIFICATION_SETTINGS"
                putExtra("app_package", packageName)
            }
        }

        requestedPermission = true
        requestNotificationPermission.launch(intent)
    }

    private fun checkAndRequestStoragePermission(onGranted: (() -> Unit)? = null) {
        val hasPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED


        if (hasPermissions) {
            onGranted?.invoke()
            return
        }

        onStoragePermissionGranted = onGranted
        requestedPermission = true

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val uri = Uri.fromParts("package", packageName, null)
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, uri)
            intent.data = Uri.fromParts("package", packageName, null)
            requestStoragePermission?.launch(intent)
        } else {
            requestLegacyStoragePermission?.launch(arrayOf(android.Manifest.permission.WRITE_EXTERNAL_STORAGE, android.Manifest.permission.READ_EXTERNAL_STORAGE))
        }
    }
}
