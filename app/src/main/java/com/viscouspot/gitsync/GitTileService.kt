package com.viscouspot.gitsync

import android.content.Intent
import android.service.quicksettings.TileService

class GitTileService: TileService() {

    // Called when the user adds your tile.
    override fun onTileAdded() {
        super.onTileAdded()
    }
    // Called when your app can update your tile.
    override fun onStartListening() {
        super.onStartListening()
    }

    // Called when your app can no longer update your tile.
    override fun onStopListening() {
        super.onStopListening()
    }

    // Called when the user taps on your tile in an active or inactive state.
    override fun onClick() {
        super.onClick()
        val forceSyncIntent = Intent(this, GitSyncService::class.java)
        forceSyncIntent.setAction("FORCE_SYNC")
        startService(forceSyncIntent)
    }
    // Called when the user removes your tile.
    override fun onTileRemoved() {
        super.onTileRemoved()
    }
}