package com.viscouspot.gitsync.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class ManualSyncWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ManualSyncWidget>() {
    override val glanceAppWidget = ManualSyncWidget()
}
