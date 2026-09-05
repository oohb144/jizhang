package com.example.jizhang

import android.content.Intent
import android.provider.Settings
import com.example.jizhang.capture.CapturedPaymentStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "jizhang/auto_capture"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationAccessEnabled" -> result.success(isNotificationAccessEnabled())
                    "openNotificationAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "drainCandidates" -> result.success(CapturedPaymentStore.drain(this))
                    else -> result.notImplemented()
                }
            }
    }

    private fun isNotificationAccessEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        return enabled.contains(packageName)
    }
}
