package com.carehouse.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

/// Creates the message channel before Firebase displays a push.
///
/// If this channel is missing, Android drops the notification.
class CarehouseApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val alerts = NotificationChannel(
            ALERT_CHANNEL_ID,
            "Messages",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "New messages in Communication"
            enableVibration(true)
            setShowBadge(true)
        }
        manager.createNotificationChannel(alerts)
        // An older build posted Firebase alerts here with no sound or popup.
        // Android will not raise that channel's importance, so drop it.
        manager.deleteNotificationChannel(SILENT_CHANNEL_ID)
    }

    companion object {
        const val ALERT_CHANNEL_ID = "messages_high"
        const val SILENT_CHANNEL_ID = "messages_fcm"
    }
}
