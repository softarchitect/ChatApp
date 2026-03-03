package com.widers.widerchat.data.notifications

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

object NotificationTokenBridge {
    private val _token = MutableStateFlow<String?>(null)
    val token: StateFlow<String?> = _token

    fun setToken(token: String?) {
        _token.value = token?.trim()?.takeIf { it.isNotEmpty() }
    }
}
