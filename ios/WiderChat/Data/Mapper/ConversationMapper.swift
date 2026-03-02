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
        let assignedAgentName = (item["agent"] as? [String: Any])?.firstString(keys: ["name", "full_name", "username"])
        let rawLastTime = item.firstString(keys: ["last_message_time", "updated_at", "time"]) ?? ""

        return Conversation(
            id: id,
            customerName: name,
            customerPhone: phone,
            lastMessage: lastMessage,
            lastMessageTime: rawLastTime,
            lastMessageEpochMs: parseEpoch(rawLastTime),
            satisfaction: parseSatisfaction(item),
            unreadCount: unreadCount,
            status: status,
            isOnline: isOnline,
            assignedAgentName: assignedAgentName,
            tags: []
        )
    }
}

private func parseSatisfaction(_ item: [String: Any]) -> ConversationSatisfaction {
    let raw = (
        (item["rating"] as? [String: Any])?.firstString(keys: ["status", "label", "name"])
        ?? (item["satisfaction"] as? [String: Any])?.firstString(keys: ["status", "label", "name"])
        ?? item.firstString(keys: ["satisfaction", "satisfaction_status", "customer_satisfaction", "rating_label", "csat", "sentiment"])
        ?? ""
    ).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if raw.isEmpty || raw == "none" || raw == "null" { return .noRating }
    if raw.contains("satisfied") || raw == "happy" || raw == "positive" || raw == "1" { return .satisfied }
    if raw.contains("neutral") || raw == "0" || raw == "normal" { return .neutral }
    if raw.contains("unsatisfied") || raw.contains("angry") || raw == "-1" || raw == "negative" { return .unsatisfied }
    return .noRating
}

private func parseEpoch(_ value: String) -> Int64 {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return 0 }
    let patterns = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss'Z'"
    ]
    for pattern in patterns {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = pattern
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = formatter.date(from: trimmed) {
            return Int64(date.timeIntervalSince1970 * 1000)
        }
    }
    return 0
}
