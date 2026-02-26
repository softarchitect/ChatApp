import Foundation
import Combine

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

struct Conversation: Identifiable {
    let id: String
    let customerName: String
    let customerPhone: String
    var lastMessage: String
    var lastMessageTime: String
    var unreadCount: Int
    var status: ConversationStatus
    let isOnline: Bool
}

struct ChatMessage: Identifiable {
    let id: String
    let conversationId: String
    let content: String
    let timestamp: String
    let type: MessageType
    let sender: MessageSender
    let status: MessageDeliveryStatus
    let noteAuthor: String?
}

enum TextKey {
    case appName, appTagline
    case loginTitle, loginSubtitle, emailLabel, emailPlaceholder, passwordLabel, passwordPlaceholder
    case loginButton, forgotPassword, loginError
    case chats, settings, conversationsTitle, searchPlaceholder, all, open, closed, unread
    case noConversations, noConversationsDesc
    case typeMessage, send, internalNote, internalNotePlaceholder, addNote
    case closeConversation, reopenConversation, conversationClosed
    case online, lastSeen
    case privacyPolicy, termsOfService, version
    case logout, logoutConfirm, cancel, confirm
    case pushNotifications, soundAlerts, darkMode, language, english, arabic
    case account, appearance, notificationSettings, about
    case today
}

func tr(_ locale: AppLocale, _ key: TextKey) -> String {
    let ar = locale == .ar
    switch key {
    case .appName: return ar ? "وايدرز" : "Widers"
    case .appTagline: return ar ? "واجهة واتساب للأعمال السحابية" : "WhatsApp Business Cloud API"
    case .loginTitle: return ar ? "مرحباً بعودتك" : "Welcome Back"
    case .loginSubtitle: return ar ? "سجّل الدخول لإدارة محادثاتك" : "Sign in to manage your conversations"
    case .emailLabel: return ar ? "البريد الإلكتروني" : "Email Address"
    case .emailPlaceholder: return ar ? "أدخل بريدك الإلكتروني" : "Enter your email"
    case .passwordLabel: return ar ? "كلمة المرور" : "Password"
    case .passwordPlaceholder: return ar ? "أدخل كلمة المرور" : "Enter your password"
    case .loginButton: return ar ? "تسجيل الدخول" : "Sign In"
    case .forgotPassword: return ar ? "نسيت كلمة المرور؟" : "Forgot password?"
    case .loginError: return ar ? "البريد الإلكتروني أو كلمة المرور غير صحيحة" : "Invalid email or password"
    case .chats: return ar ? "الدردشات" : "Chats"
    case .settings: return ar ? "الإعدادات" : "Settings"
    case .conversationsTitle: return ar ? "المحادثات" : "Conversations"
    case .searchPlaceholder: return ar ? "البحث في المحادثات..." : "Search conversations..."
    case .all: return ar ? "الكل" : "All"
    case .open: return ar ? "مفتوحة" : "Open"
    case .closed: return ar ? "مغلقة" : "Closed"
    case .unread: return ar ? "غير مقروءة" : "unread"
    case .noConversations: return ar ? "لا توجد محادثات بعد" : "No conversations yet"
    case .noConversationsDesc: return ar ? "عندما يراسلك العملاء، ستظهر المحادثات هنا." : "When customers message you, conversations will appear here."
    case .typeMessage: return ar ? "اكتب رسالة..." : "Type a message..."
    case .send: return ar ? "إرسال" : "Send"
    case .internalNote: return ar ? "ملاحظة داخلية" : "Internal Note"
    case .internalNotePlaceholder: return ar ? "اكتب ملاحظة (غير مرئية للعميل)..." : "Write a note (not visible to customer)..."
    case .addNote: return ar ? "إضافة ملاحظة" : "Add Note"
    case .closeConversation: return ar ? "إغلاق المحادثة" : "Close Conversation"
    case .reopenConversation: return ar ? "إعادة فتح المحادثة" : "Reopen Conversation"
    case .conversationClosed: return ar ? "تم إغلاق المحادثة" : "Conversation closed"
    case .online: return ar ? "متصل" : "Online"
    case .lastSeen: return ar ? "آخر ظهور" : "Last seen"
    case .privacyPolicy: return ar ? "سياسة الخصوصية" : "Privacy Policy"
    case .termsOfService: return ar ? "شروط الخدمة" : "Terms of Service"
    case .version: return ar ? "الإصدار" : "Version"
    case .logout: return ar ? "تسجيل الخروج" : "Sign Out"
    case .logoutConfirm: return ar ? "هل أنت متأكد أنك تريد تسجيل الخروج؟" : "Are you sure you want to sign out?"
    case .cancel: return ar ? "إلغاء" : "Cancel"
    case .confirm: return ar ? "تأكيد" : "Confirm"
    case .pushNotifications: return ar ? "إشعارات الدفع" : "Push Notifications"
    case .soundAlerts: return ar ? "التنبيهات الصوتية" : "Sound Alerts"
    case .darkMode: return ar ? "الوضع الداكن" : "Dark Mode"
    case .language: return ar ? "اللغة" : "Language"
    case .english: return ar ? "الإنجليزية" : "English"
    case .arabic: return ar ? "العربية" : "Arabic"
    case .account: return ar ? "الحساب" : "Account"
    case .appearance: return ar ? "المظهر" : "Appearance"
    case .notificationSettings: return ar ? "إعدادات الإشعارات" : "Notification Settings"
    case .about: return ar ? "حول" : "About"
    case .today: return ar ? "اليوم" : "Today"
    }
}

enum MockSeed {
    static let conversations: [Conversation] = [
        Conversation(id: "1", customerName: "Ahmed Al-Hassan", customerPhone: "+966 50 123 4567", lastMessage: "I need help with my order #4521", lastMessageTime: "2m", unreadCount: 3, status: .open, isOnline: true),
        Conversation(id: "2", customerName: "Sarah Johnson", customerPhone: "+1 555 234 5678", lastMessage: "Thank you for the quick response!", lastMessageTime: "15m", unreadCount: 0, status: .open, isOnline: true),
        Conversation(id: "3", customerName: "Mohammed Ali", customerPhone: "+971 55 987 6543", lastMessage: "When will my package arrive?", lastMessageTime: "1h", unreadCount: 1, status: .open, isOnline: false),
        Conversation(id: "4", customerName: "Fatima Zahra", customerPhone: "+212 6 12 34 56 78", lastMessage: "I would like to return this item", lastMessageTime: "2h", unreadCount: 0, status: .open, isOnline: false),
        Conversation(id: "5", customerName: "Omar Khalid", customerPhone: "+966 55 432 1098", lastMessage: "Do you have this in size L?", lastMessageTime: "3h", unreadCount: 2, status: .open, isOnline: true),
        Conversation(id: "6", customerName: "Layla Nasser", customerPhone: "+974 33 456 789", lastMessage: "Perfect, I will place the order now", lastMessageTime: "5h", unreadCount: 0, status: .closed, isOnline: false),
        Conversation(id: "7", customerName: "James Wilson", customerPhone: "+44 7911 123456", lastMessage: "Is the promotion still available?", lastMessageTime: "1d", unreadCount: 0, status: .closed, isOnline: false),
        Conversation(id: "8", customerName: "Nour El-Din", customerPhone: "+20 10 1234 5678", lastMessage: "Thanks for your help!", lastMessageTime: "1d", unreadCount: 0, status: .closed, isOnline: false)
    ]

    static let messages: [String: [ChatMessage]] = [
        "1": [
            ChatMessage(id: "m1", conversationId: "1", content: "Hello, I placed an order yesterday but I haven't received a confirmation email.", timestamp: "10:30 AM", type: .text, sender: .customer, status: .read, noteAuthor: nil),
            ChatMessage(id: "m2", conversationId: "1", content: "Hi Ahmed! Let me look into that for you. Could you please share your order number?", timestamp: "10:32 AM", type: .text, sender: .agent, status: .read, noteAuthor: nil),
            ChatMessage(id: "m3", conversationId: "1", content: "Customer has ordered before - VIP account. Check order history first.", timestamp: "10:33 AM", type: .note, sender: .agent, status: .read, noteAuthor: "You"),
            ChatMessage(id: "m4", conversationId: "1", content: "Sure, it's order #4521", timestamp: "10:35 AM", type: .text, sender: .customer, status: .read, noteAuthor: nil),
            ChatMessage(id: "m5", conversationId: "1", content: "I found your order. It looks like the confirmation email was sent to your old email address.", timestamp: "10:38 AM", type: .text, sender: .agent, status: .delivered, noteAuthor: nil),
            ChatMessage(id: "m6", conversationId: "1", content: "I need help with my order #4521", timestamp: "10:42 AM", type: .text, sender: .customer, status: .read, noteAuthor: nil)
        ],
        "2": [
            ChatMessage(id: "m7", conversationId: "2", content: "Hi, I have a question about your return policy.", timestamp: "9:00 AM", type: .text, sender: .customer, status: .read, noteAuthor: nil),
            ChatMessage(id: "m8", conversationId: "2", content: "Hello Sarah! We offer a 30-day return policy for all items.", timestamp: "9:05 AM", type: .text, sender: .agent, status: .read, noteAuthor: nil),
            ChatMessage(id: "m9", conversationId: "2", content: "Thank you for the quick response!", timestamp: "9:10 AM", type: .text, sender: .customer, status: .read, noteAuthor: nil)
        ],
        "3": [
            ChatMessage(id: "m10", conversationId: "3", content: "Hello, I ordered 3 days ago and my tracking still shows processing.", timestamp: "Yesterday", type: .text, sender: .customer, status: .read, noteAuthor: nil),
            ChatMessage(id: "m11", conversationId: "3", content: "Let me check your order status, Mohammed.", timestamp: "Yesterday", type: .text, sender: .agent, status: .read, noteAuthor: nil),
            ChatMessage(id: "m12", conversationId: "3", content: "When will my package arrive?", timestamp: "11:00 AM", type: .text, sender: .customer, status: .read, noteAuthor: nil)
        ],
        "5": [
            ChatMessage(id: "m13", conversationId: "5", content: "Hi there! I saw the blue jacket on your website.", timestamp: "8:00 AM", type: .text, sender: .customer, status: .read, noteAuthor: nil),
            ChatMessage(id: "m14", conversationId: "5", content: "Do you have this in size L?", timestamp: "8:01 AM", type: .text, sender: .customer, status: .read, noteAuthor: nil)
        ]
    ]
}

final class AppViewModel: ObservableObject {
    @Published var locale: AppLocale = .en
    @Published var darkMode = false
    @Published var isLoggedIn = false
    @Published var screen: AppScreen = .login
    @Published var activeChatId: String?
    @Published var conversations: [Conversation] = MockSeed.conversations
    @Published var activeMessages: [ChatMessage] = []
    @Published var loginError: String?

    private var messagesByConversation: [String: [ChatMessage]] = MockSeed.messages

    var unreadCount: Int { conversations.reduce(0) { $0 + $1.unreadCount } }

    func login(email: String, password: String) {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            loginError = tr(locale, .loginError)
            return
        }
        loginError = nil
        isLoggedIn = true
        screen = .conversations
    }

    func logout() {
        isLoggedIn = false
        screen = .login
        activeChatId = nil
        activeMessages = []
    }

    func openChat(id: String) {
        activeChatId = id
        activeMessages = messagesByConversation[id] ?? []
        screen = .chat
    }

    func backToConversations() {
        screen = .conversations
    }

    func setScreen(_ next: AppScreen) {
        screen = next
    }

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let convoId = activeChatId else { return }
        let msg = ChatMessage(
            id: "new-\(Date().timeIntervalSince1970)",
            conversationId: convoId,
            content: trimmed,
            timestamp: nowLabel(),
            type: .text,
            sender: .agent,
            status: .sent,
            noteAuthor: nil
        )
        appendMessage(msg)
    }

    func addNote(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let convoId = activeChatId else { return }
        let note = ChatMessage(
            id: "note-\(Date().timeIntervalSince1970)",
            conversationId: convoId,
            content: trimmed,
            timestamp: nowLabel(),
            type: .note,
            sender: .agent,
            status: .read,
            noteAuthor: "You"
        )
        appendMessage(note)
    }

    func toggleConversationStatus() {
        guard let convoId = activeChatId, let index = conversations.firstIndex(where: { $0.id == convoId }) else { return }
        conversations[index].status = conversations[index].status == .open ? .closed : .open
    }

    private func appendMessage(_ message: ChatMessage) {
        let convoId = message.conversationId
        var existing = messagesByConversation[convoId] ?? []
        existing.append(message)
        messagesByConversation[convoId] = existing
        activeMessages = existing

        if let i = conversations.firstIndex(where: { $0.id == convoId }) {
            conversations[i].lastMessage = message.content
            conversations[i].lastMessageTime = message.timestamp
            if message.sender == .customer {
                conversations[i].unreadCount += 1
            } else {
                conversations[i].unreadCount = 0
            }
        }
    }

    private func nowLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = locale == .ar ? Locale(identifier: "ar-SA") : Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }
}
