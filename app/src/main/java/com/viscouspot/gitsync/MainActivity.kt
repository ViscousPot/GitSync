package com.viscouspot.gitsync

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.PorterDuff
import android.graphics.Rect
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.Settings
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.view.accessibility.AccessibilityManager
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.Switch
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.constraintlayout.widget.ConstraintSet
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.ui.adapter.ApplicationGridAdapter
import com.viscouspot.gitsync.ui.fragment.CloneRepoFragment
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.Helper
import com.viscouspot.gitsync.util.Helper.log
import com.viscouspot.gitsync.util.SettingsManager
import com.viscouspot.gitsync.util.rightDrawable
import java.io.File


class MainActivity : AppCompatActivity() {
    private lateinit var applicationObserverMax: ConstraintSet
    private lateinit var applicationObserverMin: ConstraintSet

    private lateinit var gitManager: GitManager
    private lateinit var settingsManager: SettingsManager
    private var onStoragePermissionGranted: (() -> Unit)? = null

    private lateinit var forceSyncButton: MaterialButton
    private lateinit var syncMessageButton: MaterialButton

    private lateinit var gitRepoName: EditText
    private lateinit var cloneRepoButton: MaterialButton
    private lateinit var gitAuthButton: MaterialButton

    private lateinit var gitDirPath: EditText
    private lateinit var selectFileButton: MaterialButton
    private lateinit var syncOnFileChange: Switch

    private lateinit var viewLogs: MaterialButton

    private var refreshingAuthButton = false

    private lateinit var applicationObserverPanel: ConstraintLayout
    private lateinit var applicationObserverSwitch: Switch

    private lateinit var selectApplication: MaterialButton
    private lateinit var syncAppOpened: Switch
    private lateinit var syncAppClosed: Switch

    private val dirSelectionLauncher = registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri ->
        uri?.let {
            val docUriTree = DocumentsContract.buildDocumentUriUsingTree(
                it,
                DocumentsContract.getTreeDocumentId(it)
            )

            val newDirPath = Helper.getPathFromUri(this, docUriTree)

            gitDirPath.setText(newDirPath)
            settingsManager.setGitDirPath(newDirPath)

            refreshGitRepoName()
        }
    }

    private val requestLegacyStoragePermission = this.registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { isGrantedMap ->
        if (isGrantedMap.values.all { it }) {
            onStoragePermissionGranted?.invoke()
        }
    }

    private val requestStoragePermission = this.registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        val hasPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
        
        if (hasPermissions) {
            onStoragePermissionGranted?.invoke()
        }
    }

    private val requestNotificationPermission = this.registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { }

    private fun startGitSyncService() {
        val intent = Intent(this, GitSyncService::class.java)
        startForegroundService(intent)
    }

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

        log(applicationContext, "GithubFlow", "Flow Ended")

        gitManager.getGithubAuthCredentials(code, state) { username, authToken ->
            log(applicationContext, "GithubAuthCredentials", "Username and Token Received")

            settingsManager.setGitAuthCredentials(username, authToken)
            refreshAuthButton()

            CloneRepoFragment(settingsManager, gitManager) {
                refresh()
            }.show(supportFragmentManager, "Select a repository")
        }

        refreshAuthButton()
    }

    override fun onPause() {
        super.onPause()

        settingsManager.setGitDirPath(gitDirPath.text.toString())
    }

    override fun onResume() {
        super.onResume()

        refresh()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.main_activity)

        window.statusBarColor = getColor(R.color.app_bg)

        checkAndRequestStoragePermission { }

        settingsManager = SettingsManager(this)
        gitManager = GitManager(this, this)

        forceSyncButton = findViewById(R.id.forceSyncButton)
        syncMessageButton = findViewById(R.id.syncMessageButton)

        gitRepoName = findViewById(R.id.gitRepoName)
        cloneRepoButton = findViewById(R.id.cloneRepoButton)
        gitAuthButton = findViewById(R.id.gitAuthButton)

        gitDirPath = findViewById(R.id.gitDirPath)
        selectFileButton = findViewById(R.id.selectFileButton)

        syncOnFileChange = findViewById(R.id.enableFileObserver)

        viewLogs = findViewById(R.id.viewLogs)

        applicationObserverPanel = findViewById(R.id.applicationObserverPanel)
        applicationObserverSwitch = applicationObserverPanel.findViewById(R.id.enableApplicationObserver)

        selectApplication = findViewById(R.id.selectApplication)
        syncAppOpened = findViewById(R.id.syncAppOpened)
        syncAppClosed = findViewById(R.id.syncAppClosed)

        applicationObserverMax = ConstraintSet().apply { clone(applicationContext, R.layout.application_observer_max) }
        applicationObserverMin = ConstraintSet().apply { clone(applicationContext, R.layout.application_observer_min) }

        applicationObserverMin.applyTo(applicationObserverPanel)

        refresh()

        forceSyncButton.setOnClickListener {
            val forceSyncIntent = Intent(this, GitSyncService::class.java)
            forceSyncIntent.setAction("FORCE_SYNC")
            startService(forceSyncIntent)
        }

        syncMessageButton.setOnClickListener {
            settingsManager.toggleSyncMessageEnabled()
            if (settingsManager.getSyncMessageEnabled()) {
                syncMessageButton.setIconResource(R.drawable.notify)
                syncMessageButton.setIconTintResource(R.color.auth_green)
            } else {
                syncMessageButton.setIconResource(R.drawable.notify_off)
                syncMessageButton.setIconTintResource(R.color.textPrimary)
            }
        }

        refreshAuthButton()

        gitAuthButton.setOnClickListener {
            gitManager.launchGithubOAuthFlow()

        }

        gitDirPath.setOnFocusChangeListener { v, hasFocus ->
            if (!hasFocus) {
                settingsManager.setGitDirPath(gitDirPath.text.toString())
                refreshGitRepoName()
            }
        }

        selectFileButton.setOnClickListener {
            dirSelectionLauncher.launch(null)
        }

        syncOnFileChange.setOnCheckedChangeListener { _, isChecked ->
            if (isChecked) {
                settingsManager.setSyncOnFileChanges(true)

                if (checkNotificationPermission()) {
                    startGitSyncService()
                } else {
                    syncOnFileChange.isChecked = false
                    settingsManager.setSyncOnFileChanges(false)
                    requestNotificationPermission()
                }
            } else {
                val intent = Intent(this, GitSyncService::class.java)
                stopService(intent)

                settingsManager.setSyncOnFileChanges(false)
            }
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

        viewLogs.setOnClickListener {
            val file = File(filesDir, "logs.txt")
            if (file.exists()) {
                val clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                val clip = ClipData.newPlainText("Git Sync Logs", file.readText())
                clipboardManager.setPrimaryClip(clip)

                Toast.makeText(applicationContext, "Logs have been copied to clipboard!", Toast.LENGTH_SHORT).show()
                Helper.deleteLogs(this)
            }
        }

        refreshGitRepoName()
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

        builderSingle.setTitle("Select an Application")
        builderSingle.setNegativeButton(getString(android.R.string.cancel)) { dialog, _ -> dialog.dismiss() }

        val applicationSelectDialog = layoutInflater.inflate(R.layout.application_select_dialog, null)
        builderSingle.setView(applicationSelectDialog)
        val dialog = builderSingle.create()
        dialog.show()

        val devicePackageNames = getDeviceApps()

        val recyclerView = applicationSelectDialog.findViewById<RecyclerView>(R.id.recyclerView)
        recyclerView.adapter = ApplicationGridAdapter(packageManager, devicePackageNames) {
            dialog.cancel()
            settingsManager.setApplicationPackage(it)
            refresh()
        }
    }

    private fun refresh() {

        val serviceEnabled = settingsManager.getSyncOnFileChanges()

        if (serviceEnabled) {
            val intent = Intent(this, GitSyncService::class.java)
            startForegroundService(intent)
        }

        gitDirPath.setText(settingsManager.getGitDirPath())
        syncOnFileChange.isChecked = serviceEnabled

        if (settingsManager.getSyncMessageEnabled()) {
            syncMessageButton.setIconResource(R.drawable.notify)
            syncMessageButton.setIconTintResource(R.color.auth_green)
        } else {
            syncMessageButton.setIconResource(R.drawable.notify_off)
            syncMessageButton.setIconTintResource(R.color.textPrimary)
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

        (if (applicationObserverSwitch.isChecked) applicationObserverMax else applicationObserverMin).applyTo(applicationObserverPanel)

        val appPackageName = settingsManager.getApplicationPackage()
        if (appPackageName !== "") {
            selectApplication.text = packageManager.getApplicationLabel(packageManager.getApplicationInfo(appPackageName, 0)).toString()
            selectApplication.icon = packageManager.getApplicationIcon(appPackageName)
            selectApplication.iconTintMode = PorterDuff.Mode.MULTIPLY
            selectApplication.iconTint = getColorStateList(android.R.color.white)
        } else {
            selectApplication.text = getString(R.string.application_not_set)
            selectApplication.setIconResource(R.drawable.circle_xmark)
            selectApplication.setIconTintResource(R.color.auth_red)
            selectApplication.iconTintMode = PorterDuff.Mode.SRC_IN
        }

        syncAppOpened.isChecked = settingsManager.getSyncOnAppOpened()
        syncAppClosed.isChecked = settingsManager.getSyncOnAppClosed()

        refreshAuthButton()
        refreshGitRepoName()
    }

    private fun noGitRepoFound() {
        syncOnFileChange.isChecked = false
        syncOnFileChange.isEnabled = false

        cloneRepoButton.visibility = View.VISIBLE
        cloneRepoButton.setOnClickListener {
            CloneRepoFragment(settingsManager, gitManager) {
                refresh()
            }.show(supportFragmentManager, "Select a repository")
        }

        applicationObserverSwitch.isChecked = false
        applicationObserverSwitch.isEnabled = false
    }

    private fun gitRepoFound() {
        syncOnFileChange.isEnabled = true

        cloneRepoButton.visibility = View.GONE
        cloneRepoButton.setOnClickListener {
            gitDirPath.setText("")
            settingsManager.setGitDirPath(gitDirPath.text.toString())
            refreshGitRepoName()
        }

        applicationObserverSwitch.isEnabled = true
    }

    private fun refreshGitRepoName() {
        if (gitDirPath.text.toString().trim() == "") {
            gitRepoName.setText(getString(R.string.respository_not_found))
            gitRepoName.isEnabled = false
            gitRepoName.rightDrawable(null)
            gitRepoName.compoundDrawablePadding = 0
            noGitRepoFound()
            return
        }

        val file = File("${gitDirPath.text}/.git/config")

        if (!file.exists()) {
            gitRepoName.setText(getString(R.string.respository_not_found))
            gitRepoName.isEnabled = false
            gitRepoName.rightDrawable(R.drawable.circle_xmark)
            gitRepoName.compoundDrawableTintList = getColorStateList(R.color.auth_red)
            gitRepoName.compoundDrawablePadding = (4 * resources.displayMetrics.density + 0.5f).toInt()
            noGitRepoFound()
            return
        }

        gitRepoFound()

        val fileContents = file.readText()

        val gitConfigUrlRegex = "url = (.*?)\\n".toRegex()
        var gitConfigUrlResult = gitConfigUrlRegex.find(fileContents)
        val url = gitConfigUrlResult?.groups?.get(1)?.value

        val gitRepoNameRegex = ".*/([^/]+)\\.git$".toRegex()
        val gitRepoNameResult = gitRepoNameRegex.find(url.toString())
        val newGitRepoName = gitRepoNameResult?.groups?.get(1)?.value

        gitRepoName.setText(newGitRepoName)
        gitRepoName.isEnabled = true
        gitRepoName.rightDrawable(R.drawable.circle_check)
        gitRepoName.compoundDrawableTintList = getColorStateList(R.color.auth_green)
        gitRepoName.compoundDrawablePadding = (4 * resources.displayMetrics.density + 0.5f).toInt()
    }

    private fun refreshAuthButton() {
        if (refreshingAuthButton) return
        refreshingAuthButton = true

        authDisabled()

        if (settingsManager.getGitAuthCredentials().second != "") {
            authEnabled()

            gitManager.getGithubProfile(settingsManager.getGitAuthCredentials().second, {
                authEnabled()
                refreshingAuthButton = false
            }, {
                authDisabled()
                refreshingAuthButton = false
            })
        }
    }

    private fun authEnabled() {
        runOnUiThread {
            gitAuthButton.icon = getDrawable(R.drawable.circle_check)
            gitAuthButton.setIconTintResource(R.color.auth_green)

            cloneRepoButton.isEnabled = true
        }
    }

    private fun authDisabled() {
        runOnUiThread {
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

    private fun checkAndRequestStoragePermission(onGranted: (() -> Unit)? = null) {
        val hasPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED


        if (hasPermissions) {
            onGranted?.invoke()
            return
        }

        onStoragePermissionGranted = onGranted

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val uri = Uri.fromParts("package", packageName, null)
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, uri)
            intent.data = Uri.fromParts("package", packageName, null)
            requestStoragePermission.launch(intent)
        } else {
            requestLegacyStoragePermission.launch(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.READ_EXTERNAL_STORAGE))
        }
    }

    private fun checkNotificationPermission(): Boolean {
        return NotificationManagerCompat.from(this).areNotificationsEnabled()
    }

    private fun requestNotificationPermission() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
        intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)

        requestNotificationPermission.launch(intent)
    }
}
