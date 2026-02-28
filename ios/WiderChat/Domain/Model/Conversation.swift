import Foundation

struct Conversation: Identifiable {
    let id: String
    let customerName: String
    let customerPhone: String
    var lastMessage: String
    var lastMessageTime: String
    var unreadCount: Int
    var status: ConversationStatus
    let isOnline: Bool
    let assignedAgentName: String? = nil
    let tags: [ConversationTag] = []
}
