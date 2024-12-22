package com.viscouspot.gitsync.ui.dialog

import android.content.Context
import android.view.LayoutInflater
import androidx.recyclerview.widget.RecyclerView
import androidx.appcompat.widget.SearchView
import com.viscouspot.gitsync.R
import com.viscouspot.gitsync.ui.adapter.ApplicationGridAdapter
import com.viscouspot.gitsync.util.SettingsManager
import java.util.Locale

class ApplicationSelectDialog(
    context: Context,
    private val settingsManager: SettingsManager,
    private val devicePackageNames: List<String>,
    private val refreshSelectedApplications: () -> Unit
) : BaseDialog(context) {

    private val selectedPackageNames = mutableListOf<String>()
    private val filteredDevicePackageNames = devicePackageNames.toMutableList()

    init {
        val dialogView = LayoutInflater.from(context).inflate(R.layout.dialog_application_select, null)
        setView(dialogView)
        setTitle(context.getString(R.string.select_application))
        setButton(BUTTON_POSITIVE, context.getString(R.string.save_application)) { _, _ ->
            settingsManager.setApplicationPackages(selectedPackageNames)
            refreshSelectedApplications()
        }
        setButton(BUTTON_NEGATIVE, context.getString(android.R.string.cancel)) { _, _ -> dismiss() }

        val recyclerView = dialogView.findViewById<RecyclerView>(R.id.recyclerView)
        val adapter = ApplicationGridAdapter(context.packageManager, filteredDevicePackageNames, selectedPackageNames)
        recyclerView.adapter = adapter

        val searchView = dialogView.findViewById<SearchView>(R.id.searchView)
        searchView.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String?): Boolean {
                return false
            }

            override fun onQueryTextChange(newText: String?): Boolean {
                val prevSize = filteredDevicePackageNames.size
                filteredDevicePackageNames.clear()
                adapter.notifyItemRangeRemoved(0, prevSize)

                if (newText.isNullOrEmpty()) {
                    filteredDevicePackageNames.addAll(devicePackageNames)
                } else {
                    val filteredPackageNames = devicePackageNames.filter {
                        context.packageManager.getApplicationLabel(
                            context.packageManager.getApplicationInfo(it, 0)
                        ).toString().lowercase(Locale.getDefault())
                            .contains(newText.lowercase(Locale.getDefault()))
                    }
                    filteredDevicePackageNames.addAll(filteredPackageNames)
                }

                adapter.notifyItemRangeInserted(0, filteredDevicePackageNames.size)
                return true
            }
        })

        searchView.requestFocus()
    }

}
