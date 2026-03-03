package com.widers.widerchat

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessaging
import com.widers.widerchat.data.notifications.NotificationNavigationBridge
import com.widers.widerchat.data.notifications.NotificationTokenBridge
import com.widers.widerchat.data.notifications.WiderFirebaseMessagingService
import com.widers.widerchat.ui.WidersApp

class MainActivity : ComponentActivity() {
    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { /* no-op */ }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermissionIfNeeded()
        fetchFcmTokenBestEffort()
        consumeLaunchIntent(intent)
        enableEdgeToEdge()
        setContent {
            WidersApp()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        consumeLaunchIntent(intent)
    }

    private fun consumeLaunchIntent(intent: Intent?) {
        val chatId = intent?.getStringExtra(WiderFirebaseMessagingService.EXTRA_CHAT_ID)
        NotificationNavigationBridge.pushTarget(chatId)
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun fetchFcmTokenBestEffort() {
        runCatching {
            FirebaseMessaging.getInstance().token
                .addOnSuccessListener { token -> NotificationTokenBridge.setToken(token) }
        }
    }
}