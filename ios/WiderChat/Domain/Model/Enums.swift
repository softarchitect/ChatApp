import Foundation

enum AppScreen {
    case login
    case conversations
    case chat
    case settings
    case privacy
    case terms
    case version
}

enum AppLocale {
    case en
    case ar
}

enum ConversationStatus {
    case open
    case closed
}

enum MessageType {
    case text
    case media
    case note
}

enum MessageSender {
    case customer
    case agent
}

enum MessageDeliveryStatus {
    case sending
    case sent
    case delivered
    case read
    case failed
}
