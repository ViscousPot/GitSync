package com.viscouspot.gitsync

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import android.util.Log
import android.widget.CompoundButton
import android.widget.Switch
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.constraintlayout.widget.ConstraintSet
import androidx.core.content.ContextCompat
import com.viscouspot.gitsync.util.SettingsManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.internal.storage.file.FileRepository
import org.eclipse.jgit.transport.UsernamePasswordCredentialsProvider
import java.io.File

class MainActivity : ComponentActivity() {
    private lateinit var settingsManager: SettingsManager
    private var onStoragePermissionGranted: (() -> Unit)? = null

    private val requestLegacyStoragePermission = this.registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { isGrantedMap ->
        if (isGrantedMap.values.all { it }) {
            onStoragePermissionGranted?.invoke()
        }
    }

    private val requestStoragePermission = this.registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        if (Environment.isExternalStorageManager()) {
            onStoragePermissionGranted?.invoke()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        settingsManager = SettingsManager(this)

        val enableService = findViewById<Switch>(R.id.enableService)
        val gitRepoUrl = findViewById<Switch>(R.id.gitRepoUrl)
        val gitAuthButton = findViewById<Switch>(R.id.gitAuthButton)

        val applicationObserverPanel = findViewById<ConstraintLayout>(R.id.applicationObserverPanel)
        val applicationObserverSwitch = applicationObserverPanel.findViewById<Switch>(R.id.enableApplicationObserver)

        val applicationObserverMax = ConstraintSet().apply { clone(applicationContext, R.layout.application_observer_max) }
        val applicationObserverMin = ConstraintSet().apply { clone(applicationContext, R.layout.application_observer_min) }

        enableService.isChecked = settingsManager.getEnabled()
        enableService.setOnCheckedChangeListener { _, isChecked ->
            if (isChecked) {
                // Check if can enable
                settingsManager.setEnabled(true)
            } else {
                settingsManager.setEnabled(false)
            }
        }

        gitAuthButton.setOnClickListener {

        }

        applicationObserverMin.applyTo(applicationObserverPanel)

        applicationObserverSwitch.setOnCheckedChangeListener { _, isChecked -> (if (isChecked) applicationObserverMax else applicationObserverMin).applyTo(applicationObserverPanel) }

        checkAndRequestStoragePermission {
            val intent = Intent(this, GitSyncService::class.java)
            ContextCompat.startForegroundService(this, intent)
        }
    }


    fun checkAndRequestStoragePermission(onGranted: (() -> Unit)? = null) {
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
            requestStoragePermission.launch(intent)
        } else {
            requestLegacyStoragePermission.launch(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.READ_EXTERNAL_STORAGE))
        }

    }

    private fun pullRepository() {
        val repoUrl = ""
        val username = ""
        val password = ""
        val storageDir = Environment.getExternalStorageDirectory().absolutePath + "/Obsidian-TestingOnly"

//        val storageDir = File(Environment.getExternalStorageDirectory(), storageDirName)

        Log.d("////", "start")
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val git = Git(FileRepository("$storageDir/.git"))
                git.pull()
                    .setCredentialsProvider(UsernamePasswordCredentialsProvider(username, password))
                    .setRemote("origin")
                    .setRemoteBranchName("master")
                    .call()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        Log.d("////", "end")
    }

    private fun cloneRepository() {
        val repoUrl = ""
        val username = ""
        val password = ""
        val storageDir = Environment.getExternalStorageDirectory().absolutePath + "/Obsidian-TestingOnly"

        CoroutineScope(Dispatchers.IO).launch {
            try {
                Log.d("////", "start")
                Git.cloneRepository()
                    .setURI(repoUrl)
                    .setDirectory(File(storageDir))
                    .setCredentialsProvider(UsernamePasswordCredentialsProvider(username, password))
                    .call()
                Log.d("////", "end")
                withContext(Dispatchers.Main) {
                    Toast.makeText(this@MainActivity, "Repository cloned successfully", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                e.printStackTrace()
                withContext(Dispatchers.Main) {
                    Toast.makeText(this@MainActivity, "Failed to clone repository", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
}
