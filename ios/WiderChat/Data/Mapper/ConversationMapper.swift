import Foundation

enum ConversationMapper {
    static func fromPayload(_ item: [String: Any]) -> Conversation {
        let id = item.firstString(keys: ["id", "contact_id", "chat_id"]) ?? UUID().uuidString
        let name = item.firstString(keys: ["name", "contact_name", "chat_name", "phone"]) ?? "Unknown"
        let phone = item.firstString(keys: ["phone", "wa_id", "contact_phone"]) ?? ""
        let lastMessage = item.extractDisplayContent()
        let unreadCount = item.firstInt(keys: ["unread_count", "unread"]) ?? 0
        let status = (item.firstString(keys: ["status"])?.lowercased() == "closed") ? ConversationStatus.closed : .open
        let isOnline = item.firstBool(keys: ["online", "is_online"]) ?? false

        return Conversation(
            id: id,
            customerName: name,
            customerPhone: phone,
            lastMessage: lastMessage,
            lastMessageTime: item.firstString(keys: ["last_message_time", "updated_at", "time"]) ?? "",
            unreadCount: unreadCount,
            status: status,
            isOnline: isOnline
        )
    }
}
