package com.viscouspot.gitsync.ui.dialog

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.InsetDrawable
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.MarginLayoutParams
import android.view.WindowManager
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.content.res.AppCompatResources
import androidx.core.content.ContextCompat
import com.viscouspot.gitsync.R


open class BaseDialog(private val context: Context) : AlertDialog(context, R.style.AlertDialogMinTheme) {
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

        window?.clearFlags(WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_ALT_FOCUSABLE_IM)
        val inset = InsetDrawable(
            ColorDrawable(Color.TRANSPARENT),
            0
        )
        window?.setBackgroundDrawable(inset)
    }
}