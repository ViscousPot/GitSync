package com.viscouspot.gitsync.ui.dialog

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.res.ColorStateList
import android.view.LayoutInflater
import android.view.View
import android.widget.AdapterView
import android.widget.EditText
import android.widget.Spinner
import androidx.appcompat.content.res.AppCompatResources
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.content.ContextCompat
import androidx.core.widget.doOnTextChanged
import com.google.android.material.button.MaterialButton
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.ui.adapter.SpinnerIconPrefixAdapter
import com.viscouspot.gitsync.util.Helper
import com.viscouspot.gitsync.util.Logger.log
import com.viscouspot.gitsync.util.SettingsManager
import com.viscouspot.gitsync.util.provider.GitProviderManager

class AuthDialog(private val context: Context, private val settingsManager: SettingsManager, private val setGitCredentials: (username: String?, token: String?) -> Unit) : BaseDialog(context)  {
    private val providers = GitProviderManager.detailsMap
    private lateinit var oAuthContainer: ConstraintLayout
    private lateinit var oAuthButton: MaterialButton

    private lateinit var httpContainer: ConstraintLayout
    private lateinit var usernameInput: EditText
    private lateinit var tokenInput: EditText
    private lateinit var loginButton: MaterialButton

    private lateinit var sshContainer: ConstraintLayout
    private lateinit var pubKeyButton: MaterialButton
    private lateinit var privKeyButton: MaterialButton
    private lateinit var generateKeyButton: MaterialButton
    private lateinit var restoreKeyButton: MaterialButton

    private val keyInput = LayoutInflater.from(context).inflate(R.layout.edittext_key, null) as ConstraintLayout

    private fun showConfirmPrivKeyCopyDialog() {
        BaseDialog(context)
            .setTitle(context.getString(R.string.confirm_priv_key_copy))
            .setMessage(context.getString(R.string.confirm_priv_key_copy_msg))
            .setCancelable(1)
            .setPositiveButton(R.string.understood) { _, _ ->
                privKeyButton.icon = AppCompatResources.getDrawable(context, R.drawable.confirm_clipboard)
                privKeyButton.setIconTintResource(R.color.auth_green)

                val clipboard: ClipboardManager? = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager?
                val clip = ClipData.newPlainText(context.getString(R.string.copied_text), privKeyButton.text)
                clipboard?.setPrimaryClip(clip)
            }
            .setNegativeButton(android.R.string.cancel) { _, _ -> }
            .show()
    }

    private fun showRestoreKeyDialog(provider: GitProviderManager.Companion.Provider){
        val input = keyInput.findViewById<EditText>(R.id.input)
        input.hint = context.getString(R.string.ssh_priv_key_example)
        BaseDialog(context)
            .setTitle(context.getString(R.string.import_private_key))
            .setMessage(context.getString(R.string.import_private_key_msg))
            .setCancelable(1)
            .setView(keyInput)
            .setPositiveButton(R.string.import_key) { _, _ ->
                val key = input.text
                if (key == null || key.isEmpty()) return@setPositiveButton
                setAuth(provider,null, key.toString())
                dismiss()
                this.dismiss()
            }
            .setNegativeButton(android.R.string.cancel) { _, _ -> }
            .show()
    }

    override fun onStart() {
        super.onStart()
        setContentView(R.layout.dialog_auth)

        val spinner = findViewById<Spinner>(R.id.gitProviderSpinner) ?: return
        val adapter = SpinnerIconPrefixAdapter(context, providers.values.toList())

        spinner.adapter = adapter
        spinner.post{
            spinner.dropDownWidth = spinner.width
        }

        oAuthContainer = findViewById(R.id.oAuthContainer) ?: return
        oAuthButton = findViewById(R.id.oAuthButton) ?: return

        httpContainer = findViewById(R.id.httpContainer) ?: return
        usernameInput = findViewById(R.id.usernameInput) ?: return
        tokenInput = findViewById(R.id.tokenInput) ?: return
        loginButton = findViewById(R.id.loginButton) ?: return

        sshContainer = findViewById(R.id.sshContainer) ?: return
        pubKeyButton = findViewById(R.id.pubKeyButton) ?: return
        privKeyButton = findViewById(R.id.privKeyButton) ?: return
        generateKeyButton = findViewById(R.id.generateKeyButton) ?: return
        restoreKeyButton = findViewById(R.id.restoreKeyButton) ?: return

        log(settingsManager.getGitProvider())

        spinner.setSelection(providers.keys.toList().indexOf(settingsManager.getGitProvider()))

        spinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>, view: View?, position: Int, id: Long) {
                val provider = providers.keys.toList()[position]
                updateInputs(provider)
            }

            override fun onNothingSelected(parent: AdapterView<*>) {}
        }
    }

    private fun setAuth(provider: GitProviderManager.Companion.Provider, username: String?, token: String) {
        settingsManager.setGitProvider(provider)
        setGitCredentials(username, token)
    }

    private fun updateInputs(provider: GitProviderManager.Companion.Provider) {
        when (provider) {
            GitProviderManager.Companion.Provider.GITHUB,
            GitProviderManager.Companion.Provider.GITEA -> {
                oAuthContainer.visibility = View.VISIBLE
                httpContainer.visibility = View.GONE
                sshContainer.visibility = View.GONE

                oAuthButton.setOnClickListener {
                    settingsManager.setGitProvider(provider)
                    val gitManager = GitProviderManager.getManager(context, settingsManager)
                    gitManager.launchOAuthFlow()
                    dismiss()
                }
            }
            GitProviderManager.Companion.Provider.HTTPS -> {
                httpContainer.visibility = View.VISIBLE
                oAuthContainer.visibility = View.GONE
                sshContainer.visibility = View.GONE

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
                    setAuth(provider, usernameInput.text.toString(), tokenInput.text.toString())
                    dismiss()
                }
            }
            GitProviderManager.Companion.Provider.SSH -> {
                sshContainer.visibility = View.VISIBLE
                httpContainer.visibility = View.GONE
                oAuthContainer.visibility = View.GONE

                var key: String? = null

                pubKeyButton.text = context.getString(R.string.ssh_pub_key_example)
                pubKeyButton.isEnabled = false
                pubKeyButton.icon = AppCompatResources.getDrawable(context, R.drawable.copy_to_clipboard)
                pubKeyButton.setIconTintResource(R.color.primary_light)

                privKeyButton.text = context.getString(R.string.ssh_priv_key_example)
                privKeyButton.isEnabled = false
                privKeyButton.icon = AppCompatResources.getDrawable(context, R.drawable.copy_to_clipboard)
                privKeyButton.setIconTintResource(R.color.primary_light)

                generateKeyButton.setOnClickListener {
                    restoreKeyButton.visibility = View.GONE
                    if (key == null) {
                        val keyPair = Helper.generateSSHKeyPair()

                        key = keyPair.first
                        privKeyButton.text = keyPair.first
                        pubKeyButton.text = keyPair.second

                        pubKeyButton.isEnabled = true
                        privKeyButton.isEnabled = true

                        generateKeyButton.text = context.getString(R.string.confirm_key_saved)
                        generateKeyButton.isEnabled = false
                        generateKeyButton.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.auth_green_secondary))
                    } else {
                        setAuth(provider, null, key!!)
                        dismiss()
                    }
                }

                restoreKeyButton.setOnClickListener {
                    showRestoreKeyDialog(provider)
                }

                pubKeyButton.setOnClickListener {
                    pubKeyButton.icon = AppCompatResources.getDrawable(context, R.drawable.confirm_clipboard)
                    pubKeyButton.setIconTintResource(R.color.auth_green)

                    val clipboard: ClipboardManager? = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager?
                    val clip = ClipData.newPlainText(context.getString(R.string.copied_text), pubKeyButton.text)
                    clipboard?.setPrimaryClip(clip)

                    generateKeyButton.isEnabled = true
                    generateKeyButton.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(context, R.color.auth_green))
                }

                privKeyButton.setOnClickListener { showConfirmPrivKeyCopyDialog() }
            }
        }
    }
}