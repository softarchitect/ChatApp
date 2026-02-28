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
    let assignedAgentName: String?
    let tags: [ConversationTag]

    init(
        id: String,
        customerName: String,
        customerPhone: String,
        lastMessage: String,
        lastMessageTime: String,
        unreadCount: Int,
        status: ConversationStatus,
        isOnline: Bool,
        assignedAgentName: String? = nil,
        tags: [ConversationTag] = []
    ) {
        self.id = id
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
        self.status = status
        self.isOnline = isOnline
        self.assignedAgentName = assignedAgentName
        self.tags = tags
    }
}
