package com.viscouspot.gitsync.widget

import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import android.graphics.Color as AndroidColor
import androidx.glance.LocalSize
import androidx.glance.ColorFilter
import androidx.glance.unit.ColorProvider
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.appwidget.SizeMode
import androidx.glance.layout.ContentScale
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.layout.Row
import androidx.glance.Image
import androidx.glance.ImageProvider
import android.util.Log
import androidx.compose.ui.unit.DpSize
import com.viscouspot.gitsync.R

class SyncAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val repoIndex = prefs.getInt("flutter.repoman_widgetSyncIndex", -1)

        val uri = if (repoIndex >= 0) {
            "forcesyncwidget://click?homeWidget&index=$repoIndex"
        } else {
            "forcesyncwidget://click?homeWidget"
        }

        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse(uri))
        backgroundIntent.send()
    }
}

class ForceSyncWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>?
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceContent()
        }
    }

    override val sizeMode: SizeMode = SizeMode.Exact

    @Composable
    private fun GlanceContent() {
        val size = LocalSize.current
        val width = size.width

        val showChangesText = width >= 310.dp
        val showSyncText = width >= 140.dp

        val state = currentState<HomeWidgetGlanceState>()
        val prefs = state.preferences
        val status = prefs.getString("forceSyncWidget_status", "idle") ?: "idle"

        val iconRes: Int
        val tintColor: Color
        val primaryLabel: String
        when (status) {
            "syncing" -> {
                iconRes = R.drawable.sync_now
                tintColor = Color.White
                primaryLabel = "SYNCING"
            }
            "success" -> {
                iconRes = R.drawable.widget_check
                tintColor = Color(0xFF85F48E)
                primaryLabel = "SYNCED"
            }
            "error" -> {
                iconRes = R.drawable.widget_error
                tintColor = Color(0xFFFDA4AF)
                primaryLabel = "ERROR"
            }
            else -> {
                iconRes = R.drawable.sync_now
                tintColor = Color.White
                primaryLabel = "SYNC"
            }
        }

        Row(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(Color(0xFF141414))
                .clickable(onClick = actionRunCallback<SyncAction>()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = GlanceModifier
                    .size(48.dp)
                    .padding(end = if (showSyncText) 16.dp else 0.dp),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    provider = ImageProvider(iconRes),
                    contentDescription = primaryLabel,
                    colorFilter = ColorFilter.tint(ColorProvider(tintColor)),
                    contentScale = ContentScale.Fit
                )
            }

            if (showSyncText) {
                Text(
                    text = primaryLabel,
                    modifier = GlanceModifier.padding(end = 8.dp),
                    style = TextStyle(
                        color = ColorProvider(tintColor),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }

            if (showChangesText && status == "idle") {
                Text(
                    text = "CHANGES",
                    style = TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }
        }
    }
}
