import Foundation

enum PushNotificationBridge {
    static let didOpenChat = Notification.Name("PushNotificationBridge.didOpenChat")
    static let tokenUpdated = Notification.Name("PushNotificationBridge.tokenUpdated")

    static func postOpenChat(chatId: String) {
        let normalized = chatId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        NotificationCenter.default.post(name: didOpenChat, object: nil, userInfo: ["chat_id": normalized])
    }

    static func postToken(_ token: String) {
        let normalized = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        NotificationCenter.default.post(name: tokenUpdated, object: nil, userInfo: ["token": normalized])
    }

    static func extractChatId(from userInfo: [AnyHashable: Any]) -> String? {
        let keys = ["chat_id", "conversation_id", "contact_id", "chatId", "conversationId"]
        for key in keys {
            if let value = userInfo[key] as? String {
                let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !normalized.isEmpty { return normalized }
            }
            if let number = userInfo[key] as? NSNumber {
                return number.stringValue
            }
        }
        return nil
    }
}
