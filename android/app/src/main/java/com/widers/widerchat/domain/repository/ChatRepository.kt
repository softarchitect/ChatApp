package com.widers.widerchat.domain.repository

import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus

interface ChatRepository {
    fun getConversations(): List<Conversation>
    fun getMessages(conversationId: String): List<ChatMessage>
    fun appendMessage(message: ChatMessage)
    fun updateConversationStatus(conversationId: String, status: ConversationStatus)
}
