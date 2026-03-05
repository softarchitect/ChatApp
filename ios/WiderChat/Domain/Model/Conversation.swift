import Foundation

struct Conversation: Identifiable {
    let id: String
    let customerName: String
    let customerPhone: String
    var lastMessage: String
    var lastMessageTime: String
    var lastMessageEpochMs: Int64
    var satisfaction: ConversationSatisfaction
    var unreadCount: Int
    var status: ConversationStatus
    var isWindowExpired: Bool
    let isOnline: Bool
    let assignedAgentName: String?
    let tags: [ConversationTag]

    init(
        id: String,
        customerName: String,
        customerPhone: String,
        lastMessage: String,
        lastMessageTime: String,
        lastMessageEpochMs: Int64 = 0,
        satisfaction: ConversationSatisfaction = .noRating,
        unreadCount: Int,
        status: ConversationStatus,
        isWindowExpired: Bool = false,
        isOnline: Bool,
        assignedAgentName: String? = nil,
        tags: [ConversationTag] = []
    ) {
        self.id = id
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.lastMessageEpochMs = lastMessageEpochMs
        self.satisfaction = satisfaction
        self.unreadCount = unreadCount
        self.status = status
        self.isWindowExpired = isWindowExpired
        self.isOnline = isOnline
        self.assignedAgentName = assignedAgentName
        self.tags = tags
    }
}
