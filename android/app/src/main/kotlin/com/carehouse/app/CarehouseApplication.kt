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
        // Firebase's own copy is posted here. A shared tag would replace the
        // first alert, so this channel stays silent and the app posts each
        // message itself on [ALERT_CHANNEL_ID].
        val delivery = NotificationChannel(
            DELIVERY_CHANNEL_ID,
            "Message delivery",
            NotificationManager.IMPORTANCE_NONE,
        ).apply {
            description = "Internal delivery channel"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        manager.createNotificationChannel(alerts)
        manager.createNotificationChannel(delivery)
    }

    companion object {
        const val ALERT_CHANNEL_ID = "messages_high"
        const val DELIVERY_CHANNEL_ID = "messages_fcm"
    }
}
