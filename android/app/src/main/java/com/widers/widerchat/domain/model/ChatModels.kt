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

enum class ConversationSatisfaction {
    SATISFIED,
    NEUTRAL,
    UNSATISFIED,
    NO_RATING
}

enum class MessageType {
    TEXT,
    IMAGE,
    NOTE,
    SYSTEM
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
    val isWindowExpired: Boolean = false,
    val isOnline: Boolean,
    val assignedAgentName: String? = null,
    val tags: List<ConversationTag> = emptyList(),
    val satisfaction: ConversationSatisfaction = ConversationSatisfaction.NO_RATING,
    val lastMessageEpochMs: Long = 0L
)

data class ConversationTag(
    val id: Long,
    val name: String,
    val colorHex: String,
    val attachedAt: String? = null,
    val repeatedAt: List<String> = emptyList()
)

data class AvailableTag(
    val id: Long,
    val name: String,
    val colorHex: String = "#64748B"
)

data class AvailableAgent(
    val id: Long,
    val name: String
)

data class AvailableCustomField(
    val id: String,
    val label: String,
    val value: String? = null
)

data class AvailableTemplate(
    val id: Long,
    val name: String
)

data class AvailableFlow(
    val id: Long,
    val name: String
)

data class AvailableReply(
    val id: Long,
    val name: String,
    val text: String
)

data class WorkspaceOption(
    val companyId: Long,
    val name: String
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
