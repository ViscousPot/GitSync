package com.viscouspot.gitsync.ui.dialog

import android.app.ActionBar.LayoutParams
import android.app.AlertDialog
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.InsetDrawable
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.EditText
import android.widget.Spinner
import android.widget.Toast
import androidx.core.widget.doOnTextChanged
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.ui.adapter.GitProviderAdapter
import com.viscouspot.gitsync.util.GitManager
import com.viscouspot.gitsync.util.GitProviderManager
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.SettingsManager
import org.eclipse.jgit.api.Git

class AuthDialog(context: Context, settingsManager: SettingsManager) : AlertDialog(context, R.style.AlertDialogMinTheme) {
    private val providers = GitProviderManager.detailsMap

    init {
        val inflater = LayoutInflater.from(context)
        val view = inflater.inflate(R.layout.dialog_auth, null)
        setView(view)

        val spinner = view.findViewById<Spinner>(R.id.gitProviderSpinner)
        log( providers.values)
        log( providers.keys)

        val adapter = GitProviderAdapter(context, providers.values.toList())

        spinner.adapter = adapter
        spinner.post{
            spinner.dropDownWidth = spinner.width
        }

        val domainInput = view.findViewById<EditText>(R.id.domainInput)
        domainInput.doOnTextChanged { text, start, before, count ->
            settingsManager.setGitDomain(text.toString())
        }

        spinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>, view: View?, position: Int, id: Long) {
                val provider = providers.keys.toList()[position]
                log(provider)
                settingsManager.setGitProvider(provider)
                val defaultDomain = GitProviderManager.defaultDomainMap[provider]!!
                domainInput.setHint(defaultDomain)
                settingsManager.setGitDomain(defaultDomain)
            }

            override fun onNothingSelected(parent: AdapterView<*>) {}
        }


        val oAuthButton = view.findViewById<MaterialButton>(R.id.oAuthButton)
        oAuthButton.setOnClickListener {
            val gitManager = GitProviderManager.getManager(context, settingsManager)
            gitManager.launchOAuthFlow()
            dismiss()
        }


        val inset = InsetDrawable(
            ColorDrawable(Color.TRANSPARENT),
            0
        )
        window?.setBackgroundDrawable(inset)
    }

    private fun handleItemSelected(item: String) {
        Toast.makeText(context, "Selected: $item", Toast.LENGTH_SHORT).show()
    }
}