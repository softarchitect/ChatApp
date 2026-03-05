package com.widers.widerchat.data.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.widers.widerchat.MainActivity
import com.widers.widerchat.R
import kotlin.random.Random

class WiderFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        val contactId = extractContactId(message.data)
        if (!contactId.isNullOrBlank()) {
            NotificationNavigationBridge.pushTarget(contactId)
        }
        showNotification(message, contactId)
    }

    override fun onNewToken(token: String) {
        NotificationTokenBridge.setToken(token)
    }

    private fun showNotification(message: RemoteMessage, contactId: String?) {
        ensureChannel()
        val title = message.notification?.title
            ?: message.data["title"]
            ?: "New message"
        val body = message.notification?.body
            ?: message.data["body"]
            ?: "You received a new chat update."
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (!contactId.isNullOrBlank()) {
                putExtra(EXTRA_CONTACT_ID, contactId)
            }
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            contactId?.hashCode() ?: 0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        NotificationManagerCompat.from(this).notify(Random.nextInt(1000, 999999), notification)
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Chat Updates",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Notifications for new chat messages and conversation updates"
        }
        manager.createNotificationChannel(channel)
    }

    private fun extractContactId(data: Map<String, String>): String? {
        val keys = listOf("contact_id", "chat_id", "conversation_id", "chatId", "conversationId")
        return keys.firstNotNullOfOrNull { data[it]?.trim()?.takeIf(String::isNotEmpty) }
    }

    companion object {
        const val CHANNEL_ID = "wider_chat_updates"
        const val EXTRA_CONTACT_ID = "contact_id"
    }
}
