package com.viscouspot.gitsync.ui.fragment

import android.app.Dialog
import android.app.ProgressDialog
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.widget.EditText
import androidx.activity.result.ActivityResultLauncher
import androidx.appcompat.app.AlertDialog
import androidx.core.widget.doOnTextChanged
import androidx.fragment.app.DialogFragment
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.ui.adapter.RepoListAdapter
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.Helper
import com.viscouspot.gitsync.util.SettingsManager
import com.viscouspot.gitsync.util.rightDrawable

class CloneRepoFragment(
    private val settingsManager: SettingsManager,
    private val gitManager: GitManager,
    private val dirSelectionCallback: ((dirUri: Uri?) -> Unit)
): DialogFragment(R.layout.clone_repo_fragment) {
    private val repoList = mutableListOf<Pair<String, String>>()
    private var repoUrl = ""
    private var callback: ((dirUri: Uri?) -> Unit) = {dirUri: Uri? -> dirSelectionCallback(dirUri)}

    private lateinit var dirSelectionLauncher: ActivityResultLauncher<Uri?>

    override fun onAttach(context: Context) {
        super.onAttach(context)

        dirSelectionLauncher = Helper.getDirSelectionLauncher(this, requireContext()) {
            callback.invoke(it)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val view = inflater.inflate(R.layout.clone_repo_fragment, container, false)

        val repoListRecycler = view.findViewById<RecyclerView>(R.id.repoList)
        val repoUrlEditText = view.findViewById<EditText>(R.id.repoUrlEditText)
        val pullButton = view.findViewById<MaterialButton>(R.id.pullButton)
        val localRepo = view.findViewById<MaterialButton>(R.id.localRepo)
        repoListRecycler.setLayoutManager(GridLayoutManager(context, 1))

        val adapter = RepoListAdapter(repoList) {
            repoUrl = it.second
            selectLocalDir()
        }

        gitManager.getRepos(settingsManager.getGitAuthCredentials().second) {
            repoList.addAll(it)
            requireActivity().runOnUiThread {
                adapter.notifyDataSetChanged()
            }
        }

        repoUrlEditText.doOnTextChanged { _, _, _, _ ->
            repoUrlEditText.rightDrawable(null)
        }

        pullButton.setOnClickListener {
            if (Helper.isValidGitRepo(repoUrlEditText.text.toString())) {
                repoUrl = repoUrlEditText.text.toString()
                selectLocalDir()
            } else {
                repoUrlEditText.rightDrawable(R.drawable.circle_xmark)
                repoUrlEditText.compoundDrawableTintList = requireContext().getColorStateList(R.color.auth_red)
            }
        }

        repoListRecycler.setAdapter(adapter)

        localRepo.setOnClickListener {
            selectLocalRepo()
        }

        return view
    }

    private fun localRepoCallback(dirUri: Uri?){
        dirSelectionCallback.invoke(dirUri)
        dismiss()
    }

    private fun selectLocalRepo() {
        callback = ::localRepoCallback
        dirSelectionLauncher.launch(null)
    }

    private fun localDirCallback(dirUri: Uri?) {
        if (dirUri == null) {
            dirSelectionCallback.invoke(null)
            dismiss()
            return
        }
        val authCredentials = settingsManager.getGitAuthCredentials()

        val pullDialog = ProgressDialog.show(requireContext(), "Cloning repository...", "This may take a while depending on the size of your repo", true);

        gitManager.cloneRepository(repoUrl, dirUri, authCredentials.first, authCredentials.second) {
            pullDialog.dismiss()

            dirSelectionCallback.invoke(dirUri)
            dismiss()
        }
    }

    private fun selectLocalDir() {
        AlertDialog.Builder(requireContext(), R.style.AlertDialogTheme)
            .setTitle("Select a folder to clone into")
            .setPositiveButton("select") { _, _ ->
                callback = ::localDirCallback
                dirSelectionLauncher.launch(null)
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        val dialog = super.onCreateDialog(savedInstanceState)
        dialog.window!!.requestFeature(Window.FEATURE_NO_TITLE)
        return dialog
    }

    override fun onStart() {
        super.onStart()
        val dialog = dialog
        if (dialog != null) {
            dialog.window!!.setLayout(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            dialog.window!!.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        }
    }
}