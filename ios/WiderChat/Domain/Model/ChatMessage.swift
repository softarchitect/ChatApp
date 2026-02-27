import Foundation

struct ChatMessage: Identifiable {
    let id: String
    let conversationId: String
    let content: String
    let timestamp: String
    let type: MessageType
    let sender: MessageSender
    let status: MessageDeliveryStatus
    let noteAuthor: String?
    let mediaUrl: String?
    let mediaKind: String?

    init(
        id: String,
        conversationId: String,
        content: String,
        timestamp: String,
        type: MessageType,
        sender: MessageSender,
        status: MessageDeliveryStatus,
        noteAuthor: String?,
        mediaUrl: String? = nil,
        mediaKind: String? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.content = content
        self.timestamp = timestamp
        self.type = type
        self.sender = sender
        self.status = status
        self.noteAuthor = noteAuthor
        self.mediaUrl = mediaUrl
        self.mediaKind = mediaKind
    }
}
