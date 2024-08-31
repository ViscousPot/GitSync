package com.viscouspot.gitsync.ui.adapter

import android.content.pm.PackageManager
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R

class ApplicationGridAdapter(private val packageManager: PackageManager, private val packageNames: MutableList<String>, private val selectedPackageNames: MutableList<String>) : RecyclerView.Adapter<ApplicationGridAdapter.ViewHolder>() {
    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val applicationItem: MaterialButton
        val check: ImageView

        init {
            applicationItem = view.findViewById(R.id.applicationItem)
            check = view.findViewById(R.id.check)
        }
    }

    override fun onCreateViewHolder(viewGroup: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(viewGroup.context).inflate(R.layout.application_item, viewGroup, false)
        return ViewHolder(view)
    }

    override fun getItemCount(): Int {
        return packageNames.size
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val appPackageName = packageNames[position]

        if (selectedPackageNames.contains(appPackageName)) {
            holder.check.visibility = View.VISIBLE
        } else {
            holder.check.visibility = View.GONE
        }

        holder.applicationItem.text = packageManager.getApplicationLabel(packageManager.getApplicationInfo(appPackageName, 0)).toString()
        holder.applicationItem.icon = packageManager.getApplicationIcon(appPackageName)
        holder.applicationItem.setOnClickListener {
            val index = packageNames.indexOf(appPackageName)
            if (selectedPackageNames.contains(appPackageName)) {
                selectedPackageNames.remove(appPackageName)
            } else {
                selectedPackageNames.add(appPackageName)
            }
            notifyItemChanged(index)
        }
    }
}