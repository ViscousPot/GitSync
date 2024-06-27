package com.viscouspot.gitsync.ui.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.recyclerview.widget.RecyclerView
import com.viscouspot.gitsync.R

class RepoListAdapter(private val repoList: MutableList<Pair<String, String>>, private val onSelect: (selection: Pair<String, String>) -> Unit) : RecyclerView.Adapter<RepoListAdapter.ViewHolder>() {
    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val container: ConstraintLayout
        val repoName: TextView

        init {
            container = view.findViewById(R.id.container)
            repoName = view.findViewById(R.id.repoName)
        }
    }

    override fun onCreateViewHolder(viewGroup: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(viewGroup.context).inflate(R.layout.repo_recycler_item, viewGroup, false)
        return ViewHolder(view)
    }

    override fun getItemCount(): Int {
        return repoList.size
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.container.setOnClickListener {
            onSelect(repoList[position])
        }
        holder.repoName.text = repoList[position].first
    }
}