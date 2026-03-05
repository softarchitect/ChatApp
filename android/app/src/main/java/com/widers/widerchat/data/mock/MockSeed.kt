package com.widers.widerchat.data.mock

import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.domain.model.MessageDeliveryStatus
import com.widers.widerchat.domain.model.MessageSender
import com.widers.widerchat.domain.model.MessageType

object MockSeed {
    val conversations = listOf(
        Conversation("1", "Ahmed Al-Hassan", "+966 50 123 4567", "I need help with my order #4521", "2m", 3, ConversationStatus.OPEN, false, true, null, emptyList()),
        Conversation("2", "Sarah Johnson", "+1 555 234 5678", "Thank you for the quick response!", "15m", 0, ConversationStatus.OPEN, false, true, null, emptyList()),
        Conversation("3", "Mohammed Ali", "+971 55 987 6543", "When will my package arrive?", "1h", 1, ConversationStatus.OPEN, false, false, null, emptyList()),
        Conversation("4", "Fatima Zahra", "+212 6 12 34 56 78", "I would like to return this item", "2h", 0, ConversationStatus.OPEN, false, false, null, emptyList()),
        Conversation("5", "Omar Khalid", "+966 55 432 1098", "Do you have this in size L?", "3h", 2, ConversationStatus.OPEN, false, true, null, emptyList()),
        Conversation("6", "Layla Nasser", "+974 33 456 789", "Perfect, I will place the order now", "5h", 0, ConversationStatus.CLOSED, false, false, null, emptyList()),
        Conversation("7", "James Wilson", "+44 7911 123456", "Is the promotion still available?", "1d", 0, ConversationStatus.CLOSED, false, false, null, emptyList()),
        Conversation("8", "Nour El-Din", "+20 10 1234 5678", "Thanks for your help!", "1d", 0, ConversationStatus.CLOSED, false, false, null, emptyList())
    )

    val messages: Map<String, List<ChatMessage>> = mapOf(
        "1" to listOf(
            ChatMessage("m1", "1", "Hello, I placed an order yesterday but I haven't received a confirmation email.", "10:30 AM", MessageType.TEXT, MessageSender.CUSTOMER, MessageDeliveryStatus.READ),
            ChatMessage("m2", "1", "Hi Ahmed! Let me look into that for you. Could you please share your order number?", "10:32 AM", MessageType.TEXT, MessageSender.AGENT, MessageDeliveryStatus.READ),
            ChatMessage("m3", "1", "Customer has ordered before - VIP account. Check order history first.", "10:33 AM", MessageType.NOTE, MessageSender.AGENT, MessageDeliveryStatus.READ, "You"),
            ChatMessage("m4", "1", "Sure, it's order #4521", "10:35 AM", MessageType.TEXT, MessageSender.CUSTOMER, MessageDeliveryStatus.READ),
            ChatMessage("m5", "1", "I found your order. It looks like the confirmation email was sent to your old email address.", "10:38 AM", MessageType.TEXT, MessageSender.AGENT, MessageDeliveryStatus.DELIVERED),
            ChatMessage("m6", "1", "I need help with my order #4521", "10:42 AM", MessageType.TEXT, MessageSender.CUSTOMER, MessageDeliveryStatus.READ)
        ),
        "2" to listOf(
            ChatMessage("m7", "2", "Hi, I have a question about your return policy.", "9:00 AM", MessageType.TEXT, MessageSender.CUSTOMER, MessageDeliveryStatus.READ),
            ChatMessage("m8", "2", "Hello Sarah! We offer a 30-day return policy for all items.", "9:05 AM", MessageType.TEXT, MessageSender.AGENT, MessageDeliveryStatus.READ),
            ChatMessage("m9", "2", "Thank you for the quick response!", "9:10 AM", MessageType.TEXT, MessageSender.CUSTOMER, MessageDeliveryStatus.READ)
        ),
        "3" to listOf(
            ChatMessage("m10", "3", "Hello, I ordered 3 days ago and my tracking still shows processing.", "Yesterday", MessageType.TEXT, MessageSender.CUSTOMER, MessageDeliveryStatus.READ),
            ChatMessage("m11", "3", "Let me check your order status, Mohammed.", "Yesterday", MessageType.TEXT, MessageSender.AGENT, MessageDeliveryStatus.READ),
            ChatMessage("m12", "3", "When will my package arrive?", "11:00 AM", MessageType.TEXT, MessageSender.CUSTOMER, MessageDeliveryStatus.READ)
        ),
        "5" to listOf(
            ChatMessage("m13", "5", "Hi there! I saw the blue jacket on your website.", "8:00 AM", MessageType.TEXT, MessageSender.CUSTOMER, MessageDeliveryStatus.READ),
            ChatMessage("m14", "5", "Do you have this in size L?", "8:01 AM", MessageType.TEXT, MessageSender.CUSTOMER, MessageDeliveryStatus.READ)
        )
    )
}
