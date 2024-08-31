package com.viscouspot.gitsync.ui.adapter

import android.graphics.drawable.Drawable
import android.text.format.DateUtils
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Chronometer
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R

class ApplicationListAdapter(private val applicationList: MutableList<Drawable>) : RecyclerView.Adapter<ApplicationListAdapter.ViewHolder>() {
    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val icon: ImageView
//        val commitMessage: TextView
//        val author: TextView
//        val commitDate: Chronometer
//        val commitRef: MaterialButton
//        val additions: TextView
//        val deletions: TextView

        init {
            icon = view.findViewById(R.id.icon)
//            commitMessage = view.findViewById(R.id.commitMessage)
//            author = view.findViewById(R.id.author)
//            commitDate = view.findViewById(R.id.commitDate)
//            commitRef = view.findViewById(R.id.commitRef)
//            additions = view.findViewById(R.id.additions)
//            deletions = view.findViewById(R.id.deletions)
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
//        val commit = recentCommits[position]
//        holder.commitMessage.text = commit.commitMessage
//        holder.author.text = commit.author
//        holder.commitRef.text = commit.reference
//        holder.commitDate.base = commit.timestamp
//        holder.commitDate.setOnChronometerTickListener { chronometer ->
//            chronometer.text = DateUtils.getRelativeTimeSpanString(chronometer.base, System.currentTimeMillis(), DateUtils.MINUTE_IN_MILLIS).toString().replaceFirstChar { it.lowercase() }
//        }
//        holder.commitDate.start()
//        holder.additions.text = "${commit.additions} ++"
//        holder.deletions.text = "${commit.deletions} --"
    }
}