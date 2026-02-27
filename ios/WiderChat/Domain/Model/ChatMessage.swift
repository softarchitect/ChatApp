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
    let mediaUrl: String? = nil
    let mediaKind: String? = nil
}
