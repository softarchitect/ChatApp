package com.widers.widerchat.domain.model

enum class AppScreen {
    LOGIN,
    CONVERSATIONS,
    CHAT,
    SETTINGS,
    PRIVACY,
    TERMS,
    VERSION
}

enum class AppLocale {
    EN,
    AR
}

enum class ConversationStatus {
    OPEN,
    CLOSED
}

enum class MessageType {
    TEXT,
    IMAGE,
    NOTE
}

enum class MessageSender {
    CUSTOMER,
    AGENT
}

enum class MessageDeliveryStatus {
    SENDING,
    SENT,
    DELIVERED,
    READ,
    FAILED
}

data class Conversation(
    val id: String,
    val customerName: String,
    val customerPhone: String,
    val lastMessage: String,
    val lastMessageTime: String,
    val unreadCount: Int,
    val status: ConversationStatus,
    val isOnline: Boolean
)

data class ChatMessage(
    val id: String,
    val conversationId: String,
    val content: String,
    val timestamp: String,
    val type: MessageType,
    val sender: MessageSender,
    val status: MessageDeliveryStatus,
    val noteAuthor: String? = null,
    val mediaUrl: String? = null,
    val mediaKind: String? = null
)
