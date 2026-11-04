package com.vicolo.chrono

import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Reports and opens the system settings that decide whether alarms ring
 * reliably. Every intent is tried in order and wrapped in try/catch, so a
 * missing settings screen (for example a Samsung screen on another brand)
 * falls back to the next option instead of crashing.
 */
class ReliabilityChannel(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        const val CHANNEL = "com.vicolo.chrono/reliability"
    }

    private val context: Context get() = activity.applicationContext
    private val pkg: String get() = activity.packageName

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getStatus" -> result.success(getStatus())
                    "open" -> result.success(open(call.argument<String>("item") ?: ""))
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("reliability", e.message, null)
            }
        }
    }

    private fun getStatus(): Map<String, Any> {
        val sdk = Build.VERSION.SDK_INT
        val status = HashMap<String, Any>()
        status["sdk"] = sdk
        status["manufacturer"] = Build.MANUFACTURER ?: ""
        status["notifications"] = try {
            if (sdk >= Build.VERSION_CODES.N) {
                (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).areNotificationsEnabled()
            } else true
        } catch (e: Exception) { true }
        status["exactAlarms"] = try {
            if (sdk >= Build.VERSION_CODES.S) {
                (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).canScheduleExactAlarms()
            } else true
        } catch (e: Exception) { true }
        status["fullScreenIntent"] = try {
            if (sdk >= 34) {
                (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).canUseFullScreenIntent()
            } else true
        } catch (e: Exception) { true }
        status["batteryOptimization"] = try {
            (context.getSystemService(Context.POWER_SERVICE) as PowerManager).isIgnoringBatteryOptimizations(pkg)
        } catch (e: Exception) { true }
        status["autoRevoke"] = try {
            if (sdk >= Build.VERSION_CODES.R) {
                context.packageManager.isAutoRevokeWhitelisted
            } else true
        } catch (e: Exception) { true }
        return status
    }

    private fun pkgUri(): Uri = Uri.parse("package:$pkg")

    private fun appDetails() = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkgUri())

    private fun component(p: String, c: String) =
        Intent().setComponent(ComponentName(p, c))

    /** Starts the first intent that works. Returns true if one started. */
    private fun startFirst(intents: List<Intent>): Boolean {
        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                activity.startActivity(intent)
                return true
            } catch (e: Exception) {
                // Try the next option.
            }
        }
        return false
    }

    private fun open(item: String): Boolean {
        val sdk = Build.VERSION.SDK_INT
        val intents = ArrayList<Intent>()
        when (item) {
            "notifications" -> {
                if (sdk >= Build.VERSION_CODES.O) {
                    intents.add(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, pkg))
                }
            }
            "exactAlarms" -> {
                if (sdk >= Build.VERSION_CODES.S) {
                    intents.add(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, pkgUri()))
                }
            }
            "fullScreenIntent" -> {
                if (sdk >= 34) {
                    intents.add(Intent("android.settings.MANAGE_APP_USE_FULL_SCREEN_INTENT", pkgUri()))
                }
            }
            "batteryOptimization" -> {
                intents.add(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, pkgUri()))
                intents.add(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            }
            "autoRevoke" -> {
                if (sdk >= Build.VERSION_CODES.R) {
                    intents.add(Intent(Intent.ACTION_AUTO_REVOKE_PERMISSIONS, pkgUri()))
                }
            }
            "samsungSleeping" -> {
                // Device care > Battery > Background usage limits.
                intents.add(component("com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.BatteryActivity"))
                intents.add(component("com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity"))
                intents.add(component("com.samsung.android.sm",
                    "com.samsung.android.sm.ui.battery.BatteryActivity"))
                intents.add(component("com.samsung.android.sm_cn",
                    "com.samsung.android.sm.ui.battery.BatteryActivity"))
                intents.add(Intent(Intent.ACTION_POWER_USAGE_SUMMARY))
            }
            "samsungAppBattery" -> {
                // App info > Battery, where "Unrestricted" can be chosen.
            }
        }
        intents.add(appDetails())
        intents.add(Intent(Settings.ACTION_SETTINGS))
        return startFirst(intents)
    }
}
