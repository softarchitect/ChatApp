package com.widers.widerchat.data.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.widers.widerchat.MainActivity
import com.widers.widerchat.R
import kotlin.random.Random

object NotificationTestSender {
    fun sendLocalTestNotification(
        context: Context,
        contactId: String?
    ) {
        ensureChannel(context)
        val normalizedContactId = contactId?.trim()?.takeIf { it.isNotEmpty() }
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (!normalizedContactId.isNullOrBlank()) {
                putExtra(WiderFirebaseMessagingService.EXTRA_CONTACT_ID, normalizedContactId)
            }
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            normalizedContactId?.hashCode() ?: 0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val message = if (normalizedContactId.isNullOrBlank()) {
            "Local test notification (no deep link)"
        } else {
            "Local test notification for contact_id=$normalizedContactId"
        }
        val notification = NotificationCompat.Builder(context, WiderFirebaseMessagingService.CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Test Push")
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        NotificationManagerCompat.from(context).notify(Random.nextInt(1000, 999999), notification)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(WiderFirebaseMessagingService.CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            WiderFirebaseMessagingService.CHANNEL_ID,
            "Chat Updates",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Notifications for new chat messages and conversation updates"
        }
        manager.createNotificationChannel(channel)
    }
}
