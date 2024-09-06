package com.viscouspot.gitsync

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.PorterDuff
import android.graphics.Rect
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Bundle
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
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.SearchView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.constraintlayout.widget.ConstraintSet
import androidx.core.app.NotificationManagerCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.ui.RecyclerViewEmptySupport
import com.viscouspot.gitsync.ui.adapter.ApplicationGridAdapter
import com.viscouspot.gitsync.ui.adapter.ApplicationListAdapter
import com.viscouspot.gitsync.ui.adapter.Commit
import com.viscouspot.gitsync.ui.adapter.RecentCommitsAdapter
import com.viscouspot.gitsync.ui.fragment.CloneRepoFragment
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.Helper
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.SettingsManager
import com.viscouspot.gitsync.util.rightDrawable
import java.io.File
import java.util.Locale

class MainActivity : AppCompatActivity() {
    private lateinit var applicationObserverMax: ConstraintSet
    private lateinit var applicationObserverMin: ConstraintSet

    private lateinit var gitManager: GitManager
    private lateinit var settingsManager: SettingsManager

    private val recentCommits: MutableList<Commit> = mutableListOf()
    private lateinit var recentCommitsRecycler: RecyclerViewEmptySupport
    private lateinit var recentCommitsAdapter: RecentCommitsAdapter

    private lateinit var forceSyncButton: MaterialButton
    private lateinit var syncMessageButton: MaterialButton

    private lateinit var gitRepoName: EditText
    private lateinit var cloneRepoButton: MaterialButton
    private lateinit var gitAuthButton: MaterialButton

    private lateinit var gitDirPath: EditText
    private lateinit var selectFileButton: MaterialButton

    private lateinit var viewDocs: MaterialButton

    private lateinit var applicationObserverPanel: ConstraintLayout
    private lateinit var applicationObserverSwitch: Switch

    private lateinit var selectApplication: MaterialButton

    private val applicationList: MutableList<Drawable> = mutableListOf()
    private lateinit var applicationRecycler: RecyclerView
    private lateinit var applicationListAdapter: ApplicationListAdapter

    private lateinit var syncAppOpened: Switch
    private lateinit var syncAppClosed: Switch

    companion object {
        const val REFRESH = "REFRESH"
    }

    private val broadcastReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == REFRESH) {
                refreshRecentCommits()
            }
        }
    }

    private val dirSelectionLauncher = Helper.getDirSelectionLauncher(this, this, ::dirSelectionCallback)

    private fun dirSelectionCallback(dirUri: Uri?) {
        if (dirUri == null) {
            Toast.makeText(this, "Inaccessible! Please select a different directory.", Toast.LENGTH_SHORT).show()
            return
        }

        settingsManager.setGitDirUri(dirUri.toString())

        updateGitDirPath(dirUri)
        refreshGitRepo()
    }

    private fun updateGitDirPath(dirUri: Uri) {
        gitDirPath.setText(Helper.getPathFromUri(this, dirUri))
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

        val code = uri.getQueryParameter("code")
        val state = uri.getQueryParameter("state")

        if (code == null || state == null ) return

        log("GithubFlow", "Flow Ended")

        gitManager.getGithubAuthCredentials(code, state) { username, authToken ->
            log("GithubAuthCredentials", "Username and Token Received")

            settingsManager.setGitAuthCredentials(username, authToken)
            refreshAuthButton()

            CloneRepoFragment(settingsManager, gitManager, ::dirSelectionCallback).show(supportFragmentManager, "Select a repository")
        }
    }

    private fun setRecyclerViewHeight(recyclerView: RecyclerView) {
        val adapter = recyclerView.adapter ?: return

        val viewHolder = adapter.createViewHolder(recyclerView, adapter.getItemViewType(0))
        viewHolder.itemView.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);

        val itemHeight = (viewHolder.itemView.layoutParams as ViewGroup.MarginLayoutParams).topMargin + viewHolder.itemView.measuredHeight

        recyclerView.layoutParams.height = itemHeight * 3
        recyclerView.requestLayout()
    }

    override fun onDestroy() {
        super.onDestroy()

        try {
            unregisterReceiver(broadcastReceiver)
        } catch (e: Exception) { }
    }

    override fun onResume() {
        super.onResume()

        refreshAll()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.main_activity)

        Thread.setDefaultUncaughtExceptionHandler { paramThread, paramThrowable ->
            log(this, "Global", Exception(paramThrowable))
        }

        val bManager = LocalBroadcastManager.getInstance(this)
        val intentFilter = IntentFilter()
        intentFilter.addAction(REFRESH)
        bManager.registerReceiver(broadcastReceiver, intentFilter)

        window.statusBarColor = getColor(R.color.app_bg)

        settingsManager = SettingsManager(this)
        settingsManager.runMigrations()

        gitManager = GitManager(this, this)

        recentCommitsRecycler = findViewById(R.id.recentCommitsRecycler)

        recentCommitsAdapter = RecentCommitsAdapter(recentCommits)

        forceSyncButton = findViewById(R.id.forceSyncButton)
        syncMessageButton = findViewById(R.id.syncMessageButton)

        gitRepoName = findViewById(R.id.gitRepoName)
        cloneRepoButton = findViewById(R.id.cloneRepoButton)
        gitAuthButton = findViewById(R.id.gitAuthButton)

        gitDirPath = findViewById(R.id.gitDirPath)
        selectFileButton = findViewById(R.id.selectFileButton)

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

        applicationObserverMin.applyTo(applicationObserverPanel)

        refreshAll()

        recentCommitsRecycler.adapter = recentCommitsAdapter
        applicationRecycler.adapter = applicationListAdapter

        setRecyclerViewHeight(recentCommitsRecycler)

        val emptyCommitsView = findViewById<TextView>(R.id.emptyCommitsView)
        recentCommitsRecycler.setEmptyView(emptyCommitsView)

        forceSyncButton.setOnClickListener {
            val forceSyncIntent = Intent(this, GitSyncService::class.java)
            forceSyncIntent.setAction(GitSyncService.FORCE_SYNC)
            startService(forceSyncIntent)
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
                syncMessageButton.setIconTintResource(R.color.textPrimary)
            }
        }

        gitAuthButton.setOnClickListener {
            gitManager.launchGithubOAuthFlow()

        }

        gitDirPath.isEnabled = false

        selectFileButton.setOnClickListener {
            dirSelectionLauncher.launch(null)
        }

        applicationObserverMin.applyTo(applicationObserverPanel)

        applicationObserverSwitch.setOnCheckedChangeListener { _, isChecked ->
            (if (isChecked) applicationObserverMax else applicationObserverMin).applyTo(applicationObserverPanel)
            if (isChecked) {
                if (!checkAccessibilityPermission()) {
                    applicationObserverSwitch.isChecked = false
                    requestAccessibilityPermission()
                } else {
                    settingsManager.setApplicationObserverEnabled(true)
                    refreshSelectedApplications()
                }
            } else {
                settingsManager.setApplicationObserverEnabled(false)
                syncAppOpened.isChecked = false
                syncAppClosed.isChecked = false
            }
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

    private fun getDeviceApps(): List<String> {
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)
        val apps = packageManager.queryIntentActivities(intent, PackageManager.GET_META_DATA)

        return apps.map {
            it.activityInfo.packageName
        }.sortedBy { packageManager.getApplicationLabel(packageManager.getApplicationInfo(it, 0)).toString() }
    }

    private fun showApplicationSelectDialog() {
        val builderSingle = AlertDialog.Builder(this@MainActivity, R.style.AlertDialogTheme)
        val selectedPackageNames = mutableListOf<String>()

        builderSingle.setTitle(getString(R.string.select_application))
        builderSingle.setPositiveButton(getString(R.string.save_application)) { dialog, _ ->
            dialog.cancel()
            settingsManager.setApplicationPackages(selectedPackageNames)
            refreshSelectedApplications()
        }
        builderSingle.setNegativeButton(getString(android.R.string.cancel)) { dialog, _ -> dialog.dismiss() }

        val applicationSelectDialog = layoutInflater.inflate(R.layout.application_select_dialog, null)
        builderSingle.setView(applicationSelectDialog)
        val dialog = builderSingle.create()

        val devicePackageNames = getDeviceApps()
        val filteredDevicePackageNames = devicePackageNames.toMutableList()

        val recyclerView = applicationSelectDialog.findViewById<RecyclerView>(R.id.recyclerView)
        val adapter = ApplicationGridAdapter(packageManager, filteredDevicePackageNames, selectedPackageNames)

        val searchView = applicationSelectDialog.findViewById<SearchView>(R.id.searchView)
        searchView.setOnQueryTextListener(object: SearchView.OnQueryTextListener{
            override fun onQueryTextSubmit(query: String?): Boolean {
                return false
            }

            override fun onQueryTextChange(newText: String?): Boolean {
                if ((newText == null) or (newText == "")) {
                    filteredDevicePackageNames.clear()
                    filteredDevicePackageNames.addAll(devicePackageNames)
                    adapter.notifyDataSetChanged()
                } else {
                    filteredDevicePackageNames.clear()
                    filteredDevicePackageNames.addAll(
                        devicePackageNames.filter {
                            packageManager.getApplicationLabel(
                                packageManager.getApplicationInfo(it, 0)
                            ).toString()
                                .lowercase(Locale.getDefault())
                                .contains(
                                    newText.toString().lowercase(Locale.getDefault())
                                )
                        }
                    )
                    adapter.notifyDataSetChanged()
                }
                return true
            }

        })

        recyclerView.adapter = adapter
        dialog.show()
    }

    private fun refreshAll() {
        runOnUiThread {
            refreshRecentCommits()

            if (settingsManager.getSyncMessageEnabled()) {
                settingsManager.setSyncMessageEnabled(false)
                checkAndRequestNotificationPermission {
                    settingsManager.setSyncMessageEnabled(true)
                    syncMessageButton.setIconResource(R.drawable.notify)
                    syncMessageButton.setIconTintResource(R.color.auth_green)
                }
            } else {
                syncMessageButton.setIconResource(R.drawable.notify_off)
                syncMessageButton.setIconTintResource(R.color.textPrimary)
            }

            refreshAuthButton()
            refreshGitRepo()

            settingsManager.getGitDirUri()?.let {
                gitDirPath.setText(Helper.getPathFromUri(this, it))
            }

            val applicationObserverEnabled = settingsManager.getApplicationObserverEnabled()
            applicationObserverSwitch.isChecked = applicationObserverEnabled

            if (applicationObserverEnabled) {
                if (!checkAccessibilityPermission()) {
                    applicationObserverSwitch.isChecked = false
                    settingsManager.setApplicationObserverEnabled(false)
                    requestAccessibilityPermission()
                }
            }

            (if (applicationObserverSwitch.isChecked) applicationObserverMax else applicationObserverMin).applyTo(
                applicationObserverPanel
            )

            refreshSelectedApplications()

            syncAppOpened.isChecked = settingsManager.getSyncOnAppOpened()
            syncAppClosed.isChecked = settingsManager.getSyncOnAppClosed()
        }
    }

    private fun refreshSelectedApplications() {
        runOnUiThread {
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
                        selectApplication.iconTint = getColorStateList(android.R.color.white)

                        applicationRecycler.visibility = View.GONE
                    }

                    else -> {
                        selectApplication.text =
                            "${getString(R.string.multiple_application_selected)} (${if (packageNames.size < 5) packageNames.size else "4+"})"
                        selectApplication.icon = null

                        applicationRecycler.visibility = View.VISIBLE
                        val iconList = packageNames.map { packageManager.getApplicationIcon(it) }
                        applicationList.clear()
                        applicationList.addAll(iconList)
                        applicationListAdapter.notifyDataSetChanged()
                    }
                }
            } else {
                selectApplication.text = getString(R.string.application_not_set)
                selectApplication.setIconResource(R.drawable.circle_xmark)
                selectApplication.setIconTintResource(R.color.auth_red)
                selectApplication.iconTintMode = PorterDuff.Mode.SRC_IN

                applicationRecycler.visibility = View.GONE
            }
        }
    }

    private fun refreshRecentCommits() {
        runOnUiThread {
            val recentCommitsReferences = recentCommits.map { commit -> commit.reference }
            val newRecentCommits = gitManager.getRecentCommits(gitDirPath.text.toString())
                .filter { !recentCommitsReferences.contains(it.reference) }
            if (newRecentCommits.isNotEmpty()) {
                recentCommits.addAll(0, newRecentCommits)
                recentCommitsAdapter.notifyItemRangeInserted(0, newRecentCommits.size)
                recentCommitsRecycler.smoothScrollToPosition(0);
            }
        }
    }

    private fun refreshGitRepo() {
        runOnUiThread {
            var repoName = ""
            val gitDirUri = settingsManager.getGitDirUri()

            gitDirUri?.let {
                val gitConfigFile = File("${Helper.getPathFromUri(this, it)}/.git/config")
                if (gitConfigFile.exists()) {
                    val fileContents = gitConfigFile.readText()

                    val gitConfigUrlRegex = "url = (.*?)\\n".toRegex()
                    var gitConfigUrlResult = gitConfigUrlRegex.find(fileContents)
                    val url = gitConfigUrlResult?.groups?.get(1)?.value

                    val gitRepoNameRegex = ".*/([^/]+)\\.git$".toRegex()
                    val gitRepoNameResult = gitRepoNameRegex.find(url.toString())
                    repoName = gitRepoNameResult?.groups?.get(1)?.value ?: ""
                }
            }

            if (repoName == "") {
                gitRepoName.setText(getString(R.string.respository_not_found))
                gitRepoName.isEnabled = false

                cloneRepoButton.visibility = View.VISIBLE
                cloneRepoButton.isEnabled = true
                cloneRepoButton.setOnClickListener {
                    CloneRepoFragment(settingsManager, gitManager, ::dirSelectionCallback).show(supportFragmentManager, getString(R.string.clone_repo))
                }

                applicationObserverSwitch.isChecked = false
                applicationObserverSwitch.isEnabled = false

                if (gitDirPath.text.isEmpty()) {
                    gitRepoName.rightDrawable(null)
                    gitRepoName.compoundDrawablePadding = 0
                    return@runOnUiThread
                }

                gitRepoName.rightDrawable(R.drawable.circle_xmark)
                gitRepoName.compoundDrawableTintList = getColorStateList(R.color.auth_red)
                gitRepoName.compoundDrawablePadding =
                    (4 * resources.displayMetrics.density + 0.5f).toInt()

                val recentCommitsSize = recentCommits.size
                recentCommits.clear()
                recentCommitsAdapter.notifyItemRangeRemoved(0, recentCommitsSize)

                return@runOnUiThread
            }

            gitRepoName.setText(repoName)
            gitRepoName.isEnabled = true
            gitRepoName.rightDrawable(R.drawable.circle_check)
            gitRepoName.compoundDrawableTintList = getColorStateList(R.color.auth_green)
            gitRepoName.compoundDrawablePadding =
                (4 * resources.displayMetrics.density + 0.5f).toInt()

            cloneRepoButton.visibility = View.GONE

            applicationObserverSwitch.isEnabled = true

            refreshRecentCommits()
        }
    }

    private fun refreshAuthButton() {
        runOnUiThread {
            if (settingsManager.getGitAuthCredentials().second != "") {
                gitAuthButton.icon = getDrawable(R.drawable.circle_check)
                gitAuthButton.setIconTintResource(R.color.auth_green)

                cloneRepoButton.isEnabled = true

                return@runOnUiThread
            }

            gitAuthButton.icon = getDrawable(R.drawable.circle_xmark)
            gitAuthButton.setIconTintResource(R.color.auth_red)

            cloneRepoButton.isEnabled = false
        }
    }

    private fun checkAccessibilityPermission(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK);

        return enabledServices.any {
            it.resolveInfo.serviceInfo.packageName == packageName &&
                    it.resolveInfo.serviceInfo.name == GitSyncAccessibilityService::class.java.name
        }
    }

    private fun requestAccessibilityPermission() {
        val openSettings = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        openSettings.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY)
        startActivity(openSettings)
        Toast.makeText(this, getString(R.string.enable_accessibility_service), Toast.LENGTH_SHORT).show()
    }

    private fun checkAndRequestNotificationPermission(onGranted: (() -> Unit)? = null) {
        if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            onGranted?.invoke()
            return
        }

        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
        intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)

        requestNotificationPermission.launch(intent)
    }
}
