package com.nazrinapp.petani

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val iconAliases = linkedMapOf(
        "Default" to "MainActivityDefault",
        "IndianMan" to "MainActivityIndianMan",
        "IndianWoman" to "MainActivityIndianWoman",
        "ChineseMan" to "MainActivityChineseMan",
        "ChineseWoman" to "MainActivityChineseWoman",
        "MalayWomanHijab" to "MainActivityMalayWomanHijab",
        "MalayMan" to "MainActivityMalayMan",
        "SabahSarawakMan" to "MainActivitySabahSarawakMan",
        "SabahSarawakWoman" to "MainActivitySabahSarawakWoman",
        "Boy" to "MainActivityBoy",
        "Girl" to "MainActivityGirl",
        "ElderlyWoman" to "MainActivityElderlyWoman",
        "ElderlyMan" to "MainActivityElderlyMan",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.nazrinapp.petani/app_icon",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentIcon" -> result.success(currentIconName())
                "setIcon" -> {
                    val iconName = call.argument<String>("iconName")
                    if (iconName == null || !iconAliases.containsKey(iconName)) {
                        result.error("INVALID_ICON", "Ikon aplikasi tidak dikenali.", null)
                        return@setMethodCallHandler
                    }
                    setAppIcon(iconName)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun componentFor(aliasName: String): ComponentName {
        return ComponentName(packageName, "$packageName.$aliasName")
    }

    private fun currentIconName(): String {
        return iconAliases.entries.firstOrNull { (_, aliasName) ->
            packageManager.getComponentEnabledSetting(componentFor(aliasName)) ==
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        }?.key ?: "Default"
    }

    private fun setAppIcon(iconName: String) {
        val selectedAlias = iconAliases.getValue(iconName)
        packageManager.setComponentEnabledSetting(
            componentFor(selectedAlias),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )

        iconAliases.filterKeys { it != iconName }.forEach { (_, aliasName) ->
            packageManager.setComponentEnabledSetting(
                componentFor(aliasName),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }
}
