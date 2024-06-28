package com.viscouspot.gitsync.ui.adapter

import android.text.format.DateUtils
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

data class Commit(val commitMessage: String, val author: String, val timestamp: Long, val reference: String)

class RecentCommitsAdapter(private val recentCommits: MutableList<Commit>) : RecyclerView.Adapter<RecentCommitsAdapter.ViewHolder>() {
    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val commitMessage: TextView
        val author: TextView
        val commitDate: TextView
        val commitRef: MaterialButton

        init {
            commitMessage = view.findViewById(R.id.commitMessage)
            author = view.findViewById(R.id.author)
            commitDate = view.findViewById(R.id.commitDate)
            commitRef = view.findViewById(R.id.commitRef)
        }
    }

    override fun onCreateViewHolder(viewGroup: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(viewGroup.context).inflate(R.layout.recent_commit, viewGroup, false)
        return ViewHolder(view)
    }

    override fun getItemCount(): Int {
        return recentCommits.size
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val commit = recentCommits[position]
        holder.commitMessage.text = commit.commitMessage
        holder.author.text = commit.author
        holder.commitRef.text = commit.reference

        CoroutineScope(Dispatchers.Main + SupervisorJob()).launch {
            while (true) {
                holder.commitDate.text = DateUtils.getRelativeTimeSpanString(commit.timestamp, System.currentTimeMillis(), DateUtils.MINUTE_IN_MILLIS).toString().replaceFirstChar { it.lowercase() }
                delay(15 * 1000)
            }
        }
    }
}