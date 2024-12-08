package com.viscouspot.gitsync.ui.dialog

import android.app.AlertDialog
import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.InsetDrawable
import android.view.LayoutInflater
import android.view.View
import android.widget.AdapterView
import android.widget.EditText
import android.widget.Spinner
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.content.ContextCompat
import androidx.core.widget.doOnTextChanged
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.ui.adapter.GitProviderAdapter
import com.viscouspot.gitsync.util.SettingsManager
import com.viscouspot.gitsync.util.provider.GitProviderManager


class AuthDialog(private val context: Context, private val settingsManager: SettingsManager, private val setGitCredentials: (username: String?, toke: String?) -> Unit) : AlertDialog(context, R.style.AlertDialogMinTheme) {
    private val providers = GitProviderManager.detailsMap
    private var oAuthContainer: ConstraintLayout
    private var oAuthButton: MaterialButton

    private var httpContainer: ConstraintLayout
    private var usernameInput: EditText
    private var tokenInput: EditText
    private var loginButton: MaterialButton

    init {
        val inflater = LayoutInflater.from(context)
        val view = inflater.inflate(R.layout.dialog_auth, null)
        setView(view)

        val spinner = view.findViewById<Spinner>(R.id.gitProviderSpinner)

        val adapter = GitProviderAdapter(context, providers.values.toList())

        spinner.adapter = adapter
        spinner.post{
            spinner.dropDownWidth = spinner.width
        }

        oAuthContainer = view.findViewById(R.id.oAuthContainer)
        oAuthButton = view.findViewById(R.id.oAuthButton)

        httpContainer = view.findViewById(R.id.httpContainer)
        usernameInput = view.findViewById(R.id.usernameInput)
        tokenInput = view.findViewById(R.id.tokenInput)
        loginButton = view.findViewById(R.id.loginButton)

        spinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>, view: View?, position: Int, id: Long) {
                val provider = providers.keys.toList()[position]
                settingsManager.setGitProvider(provider)
                updateInputs(provider)
            }

            override fun onNothingSelected(parent: AdapterView<*>) {}
        }


        val inset = InsetDrawable(
            ColorDrawable(Color.TRANSPARENT),
            0
        )
        window?.setBackgroundDrawable(inset)
    }

    private fun updateInputs(provider: GitProviderManager.Companion.Provider) {
        when (provider) {
            GitProviderManager.Companion.Provider.GITHUB,
            GitProviderManager.Companion.Provider.GITEA -> {
                oAuthContainer.visibility = View.VISIBLE
                httpContainer.visibility = View.GONE

                oAuthButton.setOnClickListener {
                    val gitManager = GitProviderManager.getManager(context, settingsManager)
                    gitManager.launchOAuthFlow()
                    dismiss()
                }
            }
            GitProviderManager.Companion.Provider.HTTPS -> {
                httpContainer.visibility = View.VISIBLE
                oAuthContainer.visibility = View.GONE

                usernameInput.doOnTextChanged { text, _, _, _ ->
                    if (text.isNullOrEmpty()) {
                        loginButton.isEnabled = false
                        loginButton.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.auth_green_secondary))
                    } else {
                        if (!tokenInput.text.isNullOrEmpty()) {
                            loginButton.isEnabled = true
                            loginButton.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.auth_green))
                        }
                    }
                }

                tokenInput.doOnTextChanged { text, _, _, _ ->
                    if (text.isNullOrEmpty()) {
                        loginButton.isEnabled = false
                        loginButton.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.auth_green_secondary))
                    } else {
                        if (!usernameInput.text.isNullOrEmpty()) {
                            loginButton.isEnabled = true
                            loginButton.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.auth_green))
                        }
                    }
                }

                loginButton.setOnClickListener {
                    setGitCredentials(usernameInput.text.toString(), tokenInput.text.toString())
                    dismiss()
                }
            }
        }
    }
}