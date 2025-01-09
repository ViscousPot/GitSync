package com.viscouspot.gitsync

import android.app.PendingIntent
import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.os.Build
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi
import androidx.localbroadcastmanager.content.LocalBroadcastManager

@RequiresApi(Build.VERSION_CODES.N)
class GitTileManualSyncService: TileService() {
    override fun onClick() {
        super.onClick()
        val manualSyncIntent = Intent(this, MainActivity::class.java)
        manualSyncIntent.setAction(MainActivity.MANUAL_SYNC)
        manualSyncIntent.setFlags(FLAG_ACTIVITY_NEW_TASK)
        val pendingIntent = PendingIntent.getActivity(this, 0, manualSyncIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(pendingIntent)
        } else {
            startActivity(manualSyncIntent)
        }
    }
}