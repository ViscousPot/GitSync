package com.viscouspot.gitsync.ui.adapter

import android.graphics.drawable.Drawable
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import com.viscouspot.gitsync.R

class ApplicationListAdapter(private val applicationList: MutableList<Drawable>) : RecyclerView.Adapter<ApplicationListAdapter.ViewHolder>() {
    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val icon: ImageView

        init {
            icon = view.findViewById(R.id.icon)
        }
    }

    override fun onCreateViewHolder(viewGroup: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(viewGroup.context).inflate(R.layout.application_recycler_item, viewGroup, false)
        return ViewHolder(view)
    }

    override fun getItemCount(): Int {
        return applicationList.size
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.icon.setImageDrawable(applicationList.elementAt(position))
    }
}