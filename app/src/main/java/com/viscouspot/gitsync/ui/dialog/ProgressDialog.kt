package com.viscouspot.gitsync.ui.dialog

import android.content.Context
import android.widget.ProgressBar
import android.widget.TextView

class ProgressDialog(private val context: Context) : BaseDialog(context) {
    fun setView(view: ProgressBar): ProgressDialog {
        super.setView(view)
        return this
    }

    override fun setTitle(title: String): ProgressDialog {
        super.setTitle(title)
        return this
    }

    override fun setMessage(msg: String): ProgressDialog {
        super.setMessage(msg)
        return this
    }

    override fun setCancelable(int: Int): ProgressDialog {
        super.setCancelable(int != 0)
        return this
    }
}