import Foundation

struct ConversationTag: Identifiable {
    let id: Int
    let name: String
    let colorHex: String
    let attachedAt: String?
    let repeatedAt: [String]
}
