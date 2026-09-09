package com.viscouspot.gitsync

import android.net.Uri
import android.os.Build
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

@RequiresApi(Build.VERSION_CODES.N)
class GitTileSyncService: TileService() {
    override fun onClick() {
        super.onClick()
        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(this, Uri.parse("gitsync://tile-sync?homeWidget"))
        backgroundIntent.send()
    }
}