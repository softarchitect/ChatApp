import Foundation

extension Dictionary where Key == String, Value == Any {
    func extractMediaPayload() -> (String, String)? {
        if let audio = firstString(keys: ["header_audio"]), audio.isMeaningfulMediaValue { return ("audio", audio) }
        if let image = firstString(keys: ["header_image"]), image.isMeaningfulMediaValue { return ("image", image) }
        if let video = firstString(keys: ["header_video"]), video.isMeaningfulMediaValue { return ("video", video) }
        if let document = firstString(keys: ["header_document"]), document.isMeaningfulMediaValue { return ("document", document) }
        if let location = firstString(keys: ["header_location"]), location.isMeaningfulMediaValue { return ("location", location) }
        return nil
    }

    func extractDisplayContent() -> String {
        if let text = firstString(keys: ["value", "text", "body", "message", "caption", "original_message", "last_message", "note"]), !text.isEmpty {
            return text
        }
        if let action = firstString(keys: ["action", "event", "activity", "title", "description"]), !action.isEmpty {
            return action
        }
        if let audio = firstString(keys: ["header_audio"]), audio.isMeaningfulMediaValue { return "[Audio message]" }
        if let image = firstString(keys: ["header_image"]), image.isMeaningfulMediaValue { return "[Image]" }
        if let video = firstString(keys: ["header_video"]), video.isMeaningfulMediaValue { return "[Video]" }
        if let document = firstString(keys: ["header_document"]), document.isMeaningfulMediaValue { return "[Document]" }
        if let location = firstString(keys: ["header_location"]), location.isMeaningfulMediaValue { return "[Location]" }
        if let buttons = firstString(keys: ["buttons"]), !buttons.isEmpty, buttons != "[]" { return "[Interactive message]" }
        if let components = firstString(keys: ["components"]), !components.isEmpty { return "[Interactive message]" }
        return "[Unsupported message]"
    }

    func isSkippableEmptyOutgoing(content: String, media: (String, String)?, messageTypeCode: Int) -> Bool {
        guard content == "[Unsupported message]", media == nil, messageTypeCode == 1 else { return false }
        let outgoing = firstBool(keys: ["from_me", "is_agent", "agent"])
            ?? ((firstInt(keys: ["is_message_by_contact"]) ?? 1) == 0)
        return outgoing == true
    }

    func firstString(keys: [String]) -> String? {
        for key in keys {
            if let value = self[key] as? String, !value.isEmpty { return value }
            if let value = self[key] as? NSNumber { return value.stringValue }
        }
        return nil
    }

    func firstInt(keys: [String]) -> Int? {
        for key in keys {
            if let value = self[key] as? Int { return value }
            if let value = self[key] as? NSNumber { return value.intValue }
            if let value = self[key] as? String, let parsed = Int(value) { return parsed }
        }
        return nil
    }

    func firstBool(keys: [String]) -> Bool? {
        for key in keys {
            if let value = self[key] as? Bool { return value }
            if let value = self[key] as? NSNumber { return value.intValue == 1 }
            if let value = self[key] as? String {
                if value == "1" || value.lowercased() == "true" { return true }
                if value == "0" || value.lowercased() == "false" { return false }
            }
        }
        return nil
    }

    func firstArray(keys: [String]) -> [[String: Any]] {
        for key in keys {
            if let array = self[key] as? [[String: Any]] { return array }
            if let object = self[key] as? [String: Any], let items = object["items"] as? [[String: Any]] {
                return items
            }
        }
        return []
    }
}

private extension String {
    var isMeaningfulMediaValue: Bool {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty { return false }
        return normalized != "null" && normalized != "[]" && normalized != "{}"
    }
}
