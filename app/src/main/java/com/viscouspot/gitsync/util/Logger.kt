package com.viscouspot.gitsync.util

import android.util.Log
import java.io.PrintWriter
import java.io.StringWriter
import kotlin.system.exitProcess

object Logger {
    fun log(type: String, e: Exception) {
        val sw = StringWriter()
        val pw = PrintWriter(sw)
        e.printStackTrace(pw)
        log(type, "Error: $sw")

        exitProcess(0)
    }

    fun log(type: String, message: String) {
        Log.d("///Git Sync//$type", message)
    }
}