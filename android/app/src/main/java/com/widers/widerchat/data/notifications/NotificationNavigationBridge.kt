package com.widers.widerchat.data.notifications

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

object NotificationNavigationBridge {
    private val _targetChatId = MutableStateFlow<String?>(null)
    val targetChatId: StateFlow<String?> = _targetChatId

    fun pushTarget(chatId: String?) {
        _targetChatId.value = chatId?.trim()?.takeIf { it.isNotEmpty() }
    }

    fun clearTarget() {
        _targetChatId.value = null
    }
}
