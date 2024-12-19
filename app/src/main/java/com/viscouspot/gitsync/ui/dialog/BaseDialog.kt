package com.viscouspot.gitsync.ui.dialog

import android.content.Context
import android.content.DialogInterface
import android.content.res.ColorStateList
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.MarginLayoutParams
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.content.res.AppCompatResources
import androidx.core.content.ContextCompat
import com.viscouspot.gitsync.R


open class BaseDialog(private val context: Context) : AlertDialog(context, R.style.AlertDialogMinTheme) {
    fun setCancelable(int: Int): BaseDialog {
        super.setCancelable(int != 0)
        return this
    }
    fun setTitle(title: String): BaseDialog {
        super.setTitle(title)
        return this
    }
    fun setMessage(msg: String): BaseDialog {
        super.setMessage(msg)
        return this
    }
    fun setView(view: TextView): BaseDialog {
        super.setView(view)
        return this
    }
    fun setPositiveButton(textResource: Int, onClick: (dialog: DialogInterface, index: Int) -> Unit): BaseDialog {
        setButton(BUTTON_POSITIVE, context.getString(textResource), onClick)
        return this
    }
    fun setNeutralButton(textResource: Int, onClick: (dialog: DialogInterface, index: Int) -> Unit): BaseDialog {
        setButton(BUTTON_NEUTRAL, context.getString(textResource), onClick)
        return this
    }
    fun setNegativeButton(textResource: Int, onClick: (dialog: DialogInterface, index: Int) -> Unit): BaseDialog {
        setButton(BUTTON_NEGATIVE, context.getString(textResource), onClick)
        return this
    }

    override fun show() {
        super.show()

        getButton(BUTTON_POSITIVE)?.setTextColor(ContextCompat.getColor(context, R.color.auth_green))
        getButton(BUTTON_NEGATIVE)?.setTextColor(ContextCompat.getColor(context, R.color.text_secondary))
        getButton(BUTTON_NEUTRAL)?.setTextColor(ContextCompat.getColor(context, R.color.text_secondary))
    }

    override fun onContentChanged() {
        super.onContentChanged()

        val contentView = (findViewById<View>(android.R.id.content) as ViewGroup).getChildAt(0)
        contentView.background = AppCompatResources.getDrawable(context, R.drawable.input_bg_md)
        contentView.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.card_bg))

        val spaceXl = context.resources.getDimensionPixelSize(R.dimen.space_xl)
        (contentView.layoutParams as MarginLayoutParams).setMargins(0, spaceXl, 0, spaceXl)
    }
}