package com.viscouspot.gitsync

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class GitTileSyncService: TileService() {
    override fun onClick() {
        super.onClick()
        val forceSyncIntent = Intent(this, GitSyncService::class.java)
        forceSyncIntent.setAction(GitSyncService.FORCE_SYNC)
        startService(forceSyncIntent)
    }
}