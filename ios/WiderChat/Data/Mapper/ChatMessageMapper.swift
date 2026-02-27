import Foundation

enum ChatMessageMapper {
    static func fromPayload(_ item: [String: Any], conversationId: String) -> ChatMessage {
        let messageTypeCode = item.firstInt(keys: ["message_type", "type", "msg_type"]) ?? 1
        let content = item.extractDisplayContent()
        let media = item.extractMediaPayload()
        let outgoing = item.firstBool(keys: ["from_me", "is_agent", "agent"])
            ?? ((item.firstInt(keys: ["is_message_by_contact"]) ?? 1) == 0)
        let sender: MessageSender = outgoing ? .agent : .customer
        let type: MessageType = (messageTypeCode == 3 || media != nil) ? .media : .text

        return ChatMessage(
            id: item.firstString(keys: ["id", "message_id"]) ?? UUID().uuidString,
            conversationId: conversationId,
            content: content,
            timestamp: item.firstString(keys: ["time", "created_at", "date"]) ?? "",
            type: type,
            sender: sender,
            status: .delivered,
            noteAuthor: nil
        )
    }
}
