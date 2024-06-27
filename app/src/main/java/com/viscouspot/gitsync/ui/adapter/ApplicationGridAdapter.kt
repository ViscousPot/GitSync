package com.viscouspot.gitsync.ui.adapter

import android.content.pm.PackageManager
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R

class ApplicationGridAdapter(private val packageManager: PackageManager, private val packageNames: List<String>, private val onSelect: (selection: String) -> Unit) : RecyclerView.Adapter<ApplicationGridAdapter.ViewHolder>() {
    class ViewHolder(view: View) : RecyclerView.ViewHolder(view)

    override fun onCreateViewHolder(viewGroup: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(viewGroup.context).inflate(R.layout.application_item, viewGroup, false)
        return ViewHolder(view)
    }

    override fun getItemCount(): Int {
        return packageNames.size
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val selectApplication = (holder.itemView as MaterialButton)
        val appPackageName = packageNames[position]

        selectApplication.text = packageManager.getApplicationLabel(packageManager.getApplicationInfo(appPackageName, 0)).toString()
        selectApplication.icon = packageManager.getApplicationIcon(appPackageName)
        selectApplication.setOnClickListener {
            onSelect(appPackageName)
        }
    }
}