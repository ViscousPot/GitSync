package com.viscouspot.gitsync

import android.app.PendingIntent
import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.os.Build
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class GitTileManualSyncService: TileService() {
    override fun onClick() {
        super.onClick()
        // send intent to service
        // run app to start from service with arg that default opens manual sync dialog
        // val intent = Intent(this, MainActivity::class.java)
        // intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        // startActivity(intent)
        

        // val tileSyncIntent = Intent(this, id.flutter.flutter_background_service.BackgroundService::class.java)
        // tileSyncIntent.action = "TILE_MANUAL_SYNC"
        // startService(tileSyncIntent)
        
        val manualSyncIntent = Intent(this, MainActivity::class.java)
        manualSyncIntent.setAction("MANUAL_SYNC")
        manualSyncIntent.setFlags(FLAG_ACTIVITY_NEW_TASK)
        val pendingIntent = PendingIntent.getActivity(this, 0, manualSyncIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(manualSyncIntent)
        }
    }
}