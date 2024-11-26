package com.viscouspot.gitsync.ui.adapter

import android.content.Context
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.TextView
import com.viscouspot.gitsync.R

class GitProviderAdapter(private val context: Context, private val items: List<Pair<String, Int>>) : ArrayAdapter<Pair<String, Int>>(context, R.layout.item_git_provider, items) {

    override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
        return createCustomView(position, convertView, parent)
    }

    override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
        return createCustomView(position, convertView, parent)
    }

    private fun createCustomView(position: Int, convertView: View?, parent: ViewGroup): View {
        val inflater = LayoutInflater.from(context)
        val view = convertView ?: inflater.inflate(R.layout.item_git_provider, parent, false)
        val textView = view.findViewById<TextView>(R.id.gitProviderName)
        val item = items[position]
        textView.text = item.first
        val drawable = context.getDrawable(item.second)?.mutate()
        drawable?.setBounds(0, 0, context.resources.getDimensionPixelSize(R.dimen.text_size_lg), context.resources.getDimensionPixelSize(R.dimen.text_size_lg))
        textView.setCompoundDrawables(drawable, null, null, null)
        textView.compoundDrawablePadding = context.resources.getDimensionPixelOffset(R.dimen.space_sm)
        textView.gravity = Gravity.CENTER_VERTICAL
        return view
    }
}
