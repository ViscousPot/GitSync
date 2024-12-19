package com.viscouspot.gitsync.ui.dialog

import android.content.Context
import android.content.DialogInterface
import android.widget.TextView

class BasicDialog(private val context: Context) : BaseDialog(context) {
    fun setCancelable(int: Int): BasicDialog {
        super.setCancelable(int != 0)
        return this
    }
    fun setTitle(title: String): BasicDialog {
        super.setTitle(title)
        return this
    }
    fun setMessage(msg: String): BasicDialog {
        super.setMessage(msg)
        return this
    }
    fun setView(view: TextView): BasicDialog {
        super.setView(view)
        return this
    }
    fun setPositiveButton(textResource: Int, onClick: (dialog: DialogInterface, index: Int) -> Unit): BasicDialog {
        setButton(BUTTON_POSITIVE, context.getString(textResource), onClick)
        return this
    }
    fun setNeutralButton(textResource: Int, onClick: (dialog: DialogInterface, index: Int) -> Unit): BasicDialog {
        setButton(BUTTON_NEUTRAL, context.getString(textResource), onClick)
        return this
    }
    fun setNegativeButton(textResource: Int, onClick: (dialog: DialogInterface, index: Int) -> Unit): BasicDialog {
        setButton(BUTTON_NEGATIVE, context.getString(textResource), onClick)
        return this
    }
}