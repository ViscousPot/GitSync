package com.viscouspot.gitsync

import android.content.Intent
import android.service.quicksettings.TileService

class GitTileService: TileService() {
    override fun onClick() {
        super.onClick()
        val forceSyncIntent = Intent(this, GitSyncService::class.java)
        forceSyncIntent.setAction("FORCE_SYNC")
        startService(forceSyncIntent)
    }
}