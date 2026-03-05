package com.widers.widerchat.domain.repository

import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus

interface ChatRepository {
    suspend fun login(email: String, password: String): Boolean
    suspend fun getConversations(): List<Conversation>
    suspend fun getMessages(conversationId: String): List<ChatMessage>
    suspend fun appendMessage(message: ChatMessage)
    suspend fun updateConversationStatus(conversationId: String, status: ConversationStatus)
    suspend fun addNote(conversationId: String, note: String)
    suspend fun registerPushToken(token: String, platform: String = "android"): Boolean
}
