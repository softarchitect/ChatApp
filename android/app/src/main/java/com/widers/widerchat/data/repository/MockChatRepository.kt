package com.widers.widerchat.data.repository

import com.widers.widerchat.data.mock.MockSeed
import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.domain.repository.ChatRepository

class MockChatRepository : ChatRepository {
    private val conversations = MockSeed.conversations.toMutableList()
    private val messages = MockSeed.messages.mapValues { it.value.toMutableList() }.toMutableMap()

    override suspend fun login(email: String, password: String): Boolean {
        return email.isNotBlank() && password.isNotBlank()
    }

    override suspend fun getConversations(): List<Conversation> = conversations.toList()

    override suspend fun getMessages(conversationId: String): List<ChatMessage> {
        return messages[conversationId]?.toList().orEmpty()
    }

    override suspend fun appendMessage(message: ChatMessage) {
        val list = messages.getOrPut(message.conversationId) { mutableListOf() }
        list.add(message)
        val index = conversations.indexOfFirst { it.id == message.conversationId }
        if (index >= 0) {
            conversations[index] = conversations[index].copy(
                lastMessage = message.content,
                lastMessageTime = message.timestamp
            )
        }
    }

    override suspend fun updateConversationStatus(conversationId: String, status: ConversationStatus) {
        val index = conversations.indexOfFirst { it.id == conversationId }
        if (index >= 0) {
            conversations[index] = conversations[index].copy(status = status)
        }
    }

    override suspend fun addNote(conversationId: String, note: String) {
        val message = ChatMessage(
            id = "note-${System.currentTimeMillis()}",
            conversationId = conversationId,
            content = note,
            timestamp = "now",
            type = com.widers.widerchat.domain.model.MessageType.NOTE,
            sender = com.widers.widerchat.domain.model.MessageSender.AGENT,
            status = com.widers.widerchat.domain.model.MessageDeliveryStatus.READ,
            noteAuthor = "You"
        )
        appendMessage(message)
    }
}
