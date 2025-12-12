package com.viscouspot.gitsync

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.provider.Settings
import android.text.TextUtils
import android.app.ActivityManager
import java.io.File
import android.widget.Toast
import io.flutter.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream


class AccessibilityServiceHelper(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasLegacySettings" -> {
                val prefsDir = File(context.applicationInfo.dataDir, "shared_prefs")
                val prefsFiles = prefsDir.listFiles()
                result.success(prefsFiles.filter { it.isFile && it.name == "git_sync_repos.xml" }.size == 1)
            }
            "isAccessibilityServiceEnabled" -> {
                val isEnabled = isAccessibilityServiceEnabled(context)
                result.success(isEnabled)
            }
            "openAccessibilitySettings" -> {
                openAccessibilitySettings()
                result.success(null)
            }
            "isExcludedFromRecents" -> {
                val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val tasks = activityManager.appTasks
                var excluded = false;
                tasks.forEach { appTask ->
                    excluded = excluded || (appTask.taskInfo.baseIntent.flags and Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS) != 0;
                }
                result.success(excluded)
            }
            "enableExcludeFromRecents" -> {
                val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val tasks = activityManager.appTasks
                tasks.forEach { appTask ->
                    appTask.setExcludeFromRecents(true)
                }
                result.success(null)
            }
            "disableExcludeFromRecents" -> {
                val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val tasks = activityManager.appTasks
                tasks.forEach { appTask ->
                    appTask.setExcludeFromRecents(false)
                }
                result.success(null)
            }
            "getDeviceApplications" -> {
                val intent = Intent(Intent.ACTION_MAIN, null)
                intent.addCategory(Intent.CATEGORY_LAUNCHER)
                val apps = context.packageManager.queryIntentActivities(intent, PackageManager.GET_META_DATA)

                val packageNames =  apps.map {
                    it.activityInfo.packageName
                }.sortedBy {
                    context.packageManager.getApplicationLabel(
                        context.packageManager.getApplicationInfo(it, 0)
                    ).toString()
                }
                result.success(packageNames)
            }
            "getApplicationLabel" -> {
                val label = context.packageManager.getApplicationLabel(context.packageManager.getApplicationInfo(call.arguments as String, 0)).toString()
                result.success(label)
            }
            "getApplicationIcon" -> {
                val icon = context.packageManager.getApplicationIcon(call.arguments as String)
                val byteArray = bitmapToByteArray(drawableToBitmap(icon))
                result.success(byteArray)
            }
            else -> result.notImplemented()
        }
    }

    private fun bitmapToByteArray(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        var bitmap: Bitmap? = null

        if (drawable is BitmapDrawable) {
            val bitmapDrawable = drawable
            if (bitmapDrawable.bitmap != null) {
                return bitmapDrawable.bitmap
            }
        }

        bitmap = if (drawable.intrinsicWidth <= 0 || drawable.intrinsicHeight <= 0) {
            Bitmap.createBitmap(
                1,
                1,
                Bitmap.Config.ARGB_8888
            ) // Single color bitmap will be created of 1x1 pixel
        } else {
            Bitmap.createBitmap(
                drawable.intrinsicWidth,
                drawable.intrinsicHeight,
                Bitmap.Config.ARGB_8888
            )
        }

        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }


    private fun isAccessibilityServiceEnabled(context: Context): Boolean {

        var accessibilityEnabled = 0
        val service: String =
            context.packageName + "/" + GitSyncAccessibilityService::class.java.canonicalName
        try {
            accessibilityEnabled = Settings.Secure.getInt(
                context.getApplicationContext().getContentResolver(),
                Settings.Secure.ACCESSIBILITY_ENABLED
            )
            Log.v("////", "accessibilityEnabled = $accessibilityEnabled")
        } catch (e: Settings.SettingNotFoundException) {
            Log.e(
                "////", "Error finding setting, default accessibility to not found: "
                        + e.message
            )
        }
        val mStringColonSplitter = TextUtils.SimpleStringSplitter(':')

        if (accessibilityEnabled == 1) {
            Log.v("////", "***ACCESSIBILITY IS ENABLED*** -----------------")
            val settingValue = Settings.Secure.getString(
                context.getApplicationContext().getContentResolver(),
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                mStringColonSplitter.setString(settingValue)
                while (mStringColonSplitter.hasNext()) {
                    val accessibilityService = mStringColonSplitter.next()

                    Log.v(
                        "////",
                        "-------------- > accessibilityService :: $accessibilityService $service"
                    )
                    if (accessibilityService.equals(service, ignoreCase = true)) {
                        Log.v(
                            "////",
                            "We've found the correct setting - accessibility is switched on!"
                        )
                        return true
                    }
                }
            }
        } else {
            Log.v("////", "***ACCESSIBILITY IS DISABLED***")
        }

        return false
        // val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        // val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)

        // Log.d("////", enabledServices.size.toString())

        // enabledServices.forEach { service ->
        //     val serviceName = "${service.resolveInfo.serviceInfo.packageName}/${service.resolveInfo.serviceInfo.name}"
        //     Log.d("AccessibilityService", "Enabled service: $serviceName")
        // }

        // return enabledServices.any {
        //     val serviceName = "${context.packageName}/${GitSyncAccessibilityService::class.java.name}"
        //     it.resolveInfo.serviceInfo.name == GitSyncAccessibilityService::class.java.name ||
        //             it.resolveInfo.serviceInfo.packageName + "/" + it.resolveInfo.serviceInfo.name == serviceName
        // }
        // return enabledServices.any {
        //     it.resolveInfo.serviceInfo.packageName == context.packageName &&
        //             it.resolveInfo.serviceInfo.name == GitSyncAccessibilityService::class.java.name
        // }
    }

    private fun openAccessibilitySettings() {
        val openSettings = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        openSettings.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY)
        context.startActivity(openSettings)
        Toast.makeText(context, "Please enable GitSync under \"Installed apps\"", Toast.LENGTH_LONG).show()
    }
}
