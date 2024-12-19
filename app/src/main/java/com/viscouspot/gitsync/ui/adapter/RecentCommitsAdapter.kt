package com.viscouspot.gitsync.ui.adapter

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Typeface
import android.text.format.DateUtils
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Chronometer
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R

data class Commit(val commitMessage: String, val author: String, val timestamp: Long, val reference: String, val additions: Int, val deletions: Int)

class RecentCommitsAdapter(private val context: Context, private val recentCommits: MutableList<Commit>, private val openMergeConflictDialog: () -> Unit) : RecyclerView.Adapter<RecentCommitsAdapter.ViewHolder>() {
    companion object {
        const val MERGE_CONFLICT = "MERGE_CONFLICT"
    }

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val container: ConstraintLayout = view.findViewById(R.id.container)
        val commitMessage: TextView = view.findViewById(R.id.commitMessage)
        val author: TextView = view.findViewById(R.id.author)
        val committed: TextView = view.findViewById(R.id.committed)
        val commitDate: Chronometer = view.findViewById(R.id.commitDate)
        val commitRef: MaterialButton = view.findViewById(R.id.commitRef)
        val additions: TextView = view.findViewById(R.id.additions)
        val deletions: TextView = view.findViewById(R.id.deletions)
    }

    override fun onCreateViewHolder(viewGroup: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(viewGroup.context).inflate(R.layout.item_recent_commit, viewGroup, false)
        return ViewHolder(view)
    }

    override fun getItemCount(): Int {
        return recentCommits.size
    }

    override fun onViewRecycled(holder: ViewHolder) {
        super.onViewRecycled(holder)
        holder.commitDate.stop()
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val commit = recentCommits[position]

        if (commit.reference == MERGE_CONFLICT) {
            bindMergeConflictViewHolder(holder)
            return
        }

        holder.container.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.card_secondary_bg))
        holder.commitMessage.text = commit.commitMessage
        holder.commitMessage.setTypeface(null, Typeface.NORMAL)
        holder.commitMessage.setTextColor(ContextCompat.getColor(context, R.color.text_primary))
        holder.author.text = commit.author
        holder.author.setTextColor(ContextCompat.getColor(context, R.color.text_secondary))
        holder.committed.visibility = View.VISIBLE
        holder.commitRef.visibility = View.VISIBLE
        holder.commitRef.text = commit.reference
        holder.commitDate.visibility = View.VISIBLE
        holder.commitDate.base = commit.timestamp
        holder.commitDate.setOnChronometerTickListener { chronometer ->
            chronometer.text = DateUtils.getRelativeTimeSpanString(chronometer.base, System.currentTimeMillis(), DateUtils.MINUTE_IN_MILLIS).toString().replaceFirstChar { it.lowercase() }
        }
        holder.commitDate.start()
        holder.additions.text = context.getString(R.string.additions).format(commit.additions)
        holder.deletions.text = context.getString(R.string.deletions).format(commit.deletions)
    }

    private fun bindMergeConflictViewHolder(holder: ViewHolder) {
        holder.container.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.deletions))
        holder.commitMessage.text = context.getString(R.string.merge_conflict_item_title)
        holder.commitMessage.setTypeface(null, Typeface.BOLD)
        holder.commitMessage.setTextColor(ContextCompat.getColor(context, R.color.card_bg))
        holder.author.text = context.getString(R.string.merge_conflict_item_message)
        holder.author.setTextColor(ContextCompat.getColor(context, R.color.card_secondary_bg))
        holder.committed.visibility = View.GONE
        holder.commitRef.visibility = View.INVISIBLE
        holder.commitDate.visibility = View.GONE
        holder.additions.text = ""
        holder.deletions.text = ""

        holder.container.setOnClickListener {
            openMergeConflictDialog()
        }
    }
}