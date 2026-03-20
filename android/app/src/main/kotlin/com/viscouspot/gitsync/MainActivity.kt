package com.viscouspot.gitsync

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.view.Window
import android.content.Intent

class MainActivity: FlutterActivity() {
    companion object {
        var channel: MethodChannel? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)        

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "accessibility_service_helper")
        channel!!.setMethodCallHandler(AccessibilityServiceHelper(context))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);


        if (actionBar!=null) {
            this.actionBar!!.hide();
        }

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.action?.let { action ->
            val index = intent.getIntExtra("index", -1)
            channel?.invokeMethod("onIntentAction", mapOf(
                "action" to action,
                "index" to index
            ))
        }
    }
}
