import Foundation
import Combine

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

struct AvailableReply: Identifiable {
    let id: Int
    let name: String
    let text: String
}

struct WorkspaceOption: Identifiable, Equatable {
    let companyId: Int
    let name: String
    var id: Int { companyId }
}

struct ConversationsServerFilters {
    let status: String
    let tag: String
    let agent: String
    let rating: String
    let tap: String
    let orderBy: String

    static let `default` = ConversationsServerFilters(
        status: "all",
        tag: "all",
        agent: "all",
        rating: "all",
        tap: "all",
        orderBy: "default"
    )
}

final class AppViewModel: ObservableObject {
    private enum SessionKeys {
        static let token = "widers.session.token"
        static let companyId = "widers.session.companyId"
        static let profileName = "widers.session.profile.name"
        static let profileEmail = "widers.session.profile.email"
    }

    @Published var locale: AppLocale = .en
    @Published var darkMode = false
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var screen: AppScreen = .login
    @Published var activeChatId: String?
    @Published var conversations: [Conversation] = MockSeed.conversations
    @Published var activeMessages: [ChatMessage] = []
    @Published var loginError: String?
    @Published var isActionLoading = false
    @Published var actionStatus: String?
    @Published var contactsLoading = false
    @Published var isChatLoading = false
    @Published var hasMoreActiveMessages = false
    @Published var isLoadingMoreActiveMessages = false
    @Published var newConversationContacts: [NewConversationContact] = []
    @Published var availableTags: [AvailableTag] = []
    @Published var availableAgents: [AvailableAgent] = []
    @Published var availableCustomFields: [AvailableCustomField] = []
    @Published var availableTemplates: [AvailableTemplate] = []
    @Published var availableFlows: [AvailableFlow] = []
    @Published var availableReplies: [AvailableReply] = []
    @Published var profileName = ""
    @Published var profileEmail = ""
    @Published var currentCompanyId: Int?
    @Published var availableWorkspaces: [WorkspaceOption] = []
    @Published var hasMoreConversations = false
    @Published var isLoadingMoreConversations = false
    @Published var hasMoreNewConversationContacts = false
    @Published var isLoadingMoreNewConversationContacts = false
    @Published var pushDebugInfo: String?
    @Published var pushDebugRawToken: String?
    private var localOutgoingByConversation: [String: [ChatMessage]] = [:]
    private var chatPollingTask: Task<Void, Never>?
    private var realtimeConversationsRefreshTask: Task<Void, Never>?
    private var realtimeActiveChatRefreshTask: Task<Void, Never>?
    private var pendingNotificationChatId: String?
    private var latestPushToken: String?
    private var activeConversationFilters: ConversationsServerFilters = .default
    private var contactsNextPage: Int = 1
    private var contactsHasMore: Bool = true
    private let contactsPageSize = 25
    private var contactsSearchMode = false
    private lazy var realtimeClient = PusherRealtimeClient(
        key: "2a6e447d8a701a4d7fe7",
        cluster: "eu",
        onGeneralEvent: { [weak self] channel in
            self?.handleRealtimeGeneralEvent(channel: channel)
        }
    )

    private let repository: ChatRepository
    private let secureStore: SecureSessionStore

    var unreadCount: Int { conversations.reduce(0) { $0 + $1.unreadCount } }

    init(
        repository: ChatRepository = WidersRepository(),
        secureStore: SecureSessionStore = SecureSessionStore()
    ) {
        self.repository = repository
        self.secureStore = secureStore
        restoreStoredLoginIfNeeded()
    }

    func login(email: String, password: String) {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            loginError = tr(locale, .loginError)
            return
        }
        isLoading = true
        loginError = nil
        Task { @MainActor in
            let ok = await repository.login(email: email, password: password)
            guard ok else {
                isLoading = false
                loginError = tr(locale, .loginError)
                return
            }
            let profile = repository.currentUserSnapshot()
            profileName = profile.name ?? ""
            profileEmail = profile.email ?? ""
            isLoading = false
            isLoggedIn = true
            screen = .conversations
            if let session = repository.currentSessionSnapshot() {
                secureStore.saveString(session.token, for: SessionKeys.token)
                secureStore.saveString(String(session.companyId), for: SessionKeys.companyId)
                secureStore.saveString(profileName, for: SessionKeys.profileName)
                secureStore.saveString(profileEmail, for: SessionKeys.profileEmail)
                realtimeClient.connect(companyId: session.companyId)
            }
            tryRegisterLatestPushToken()
            refreshWorkspaceState()
            launchPostLoginDataWarmup()
            if let pending = pendingNotificationChatId {
                pendingNotificationChatId = nil
                openChat(id: pending)
            }
        }
    }

    func logout() {
        stopChatPolling()
        realtimeClient.disconnect()
        pendingNotificationChatId = nil
        activeConversationFilters = .default
        contactsNextPage = 1
        contactsHasMore = true
        contactsSearchMode = false
        secureStore.removeValue(for: SessionKeys.token)
        secureStore.removeValue(for: SessionKeys.companyId)
        isLoggedIn = false
        screen = .login
        activeChatId = nil
        activeMessages = []
        isChatLoading = false
        hasMoreActiveMessages = false
        isLoadingMoreActiveMessages = false
        actionStatus = nil
        profileName = ""
        profileEmail = ""
        currentCompanyId = nil
        availableWorkspaces = []
        hasMoreConversations = false
        isLoadingMoreConversations = false
        hasMoreNewConversationContacts = false
        isLoadingMoreNewConversationContacts = false
        newConversationContacts = []
        pushDebugInfo = nil
        pushDebugRawToken = nil
        availableAgents = []
        availableCustomFields = []
        availableTemplates = []
        availableFlows = []
        availableReplies = []
        secureStore.removeValue(for: SessionKeys.profileName)
        secureStore.removeValue(for: SessionKeys.profileEmail)
    }

    func openChat(id: String) {
        stopChatPolling()
        realtimeClient.setActiveChat(chatId: id)
        activeChatId = id
        screen = .chat
        activeMessages = []
        isChatLoading = true
        hasMoreActiveMessages = false
        isLoadingMoreActiveMessages = false
        conversations = conversations.map { convo in
            if convo.id == id {
                var updated = convo
                updated.unreadCount = 0
                return updated
            }
            return convo
        }
        Task { @MainActor in
            defer {
                if self.activeChatId == id {
                    self.isChatLoading = false
                }
            }
            if let contactId = Int(id) {
                _ = await repository.updateRead(contactId: contactId, status: true)
            }
            let remote = await fetchLatestMessages(conversationId: id, resetHistory: true)
            guard self.activeChatId == id else { return }
            activeMessages = mergeWithLocalOutgoing(conversationId: id, remote: remote)
            let latestConversations = await repository.getConversations()
            conversations = latestConversations.map { convo in
                var updated = convo
                if updated.id == id { updated.unreadCount = 0 }
                return updated
            }
            startChatPolling(id: id)
        }
    }

    func backToConversations() {
        let lastActive = activeChatId
        stopChatPolling()
        realtimeClient.setActiveChat(chatId: nil)
        screen = .conversations
        activeChatId = nil
        activeMessages = []
        isChatLoading = false
        hasMoreActiveMessages = false
        isLoadingMoreActiveMessages = false
        Task { @MainActor in
            let fetched = await repository.getConversations()
            if let lastActive {
                conversations = fetched.map { convo in
                    var updated = convo
                    if updated.id == lastActive { updated.unreadCount = 0 }
                    return updated
                }
            } else {
                conversations = fetched
            }
        }
    }

    func loadOlderMessagesForActiveChat() async {
        guard let conversationId = activeChatId, let repo = repository as? WidersRepository else { return }
        guard hasMoreActiveMessages, !isLoadingMoreActiveMessages else { return }
        isLoadingMoreActiveMessages = true
        let older = await repo.loadOlderMessagesPage(conversationId: conversationId)
        if activeChatId == conversationId {
            activeMessages = mergeWithLocalOutgoing(conversationId: conversationId, remote: older)
            hasMoreActiveMessages = repo.hasMoreMessagesSnapshot(conversationId: conversationId)
            isLoadingMoreActiveMessages = repo.isLoadingMoreMessagesSnapshot(conversationId: conversationId)
        } else {
            isLoadingMoreActiveMessages = false
        }
    }

    func refreshConversationsList(filters: ConversationsServerFilters? = nil) async {
        if let filters {
            activeConversationFilters = filters
        }
        if let repo = repository as? WidersRepository {
            let requestFilters = WidersRepository.ConversationsRequestFilters(
                status: activeConversationFilters.status,
                tag: activeConversationFilters.tag,
                agent: activeConversationFilters.agent,
                rating: "all",
                tap: activeConversationFilters.tap,
                orderBy: activeConversationFilters.orderBy
            )
            var loaded = await repo.refreshConversationsFirstPage(filters: requestFilters)
            if activeConversationFilters.rating != "all" {
                var pagesLoaded = 1
                while repo.hasMoreConversationsSnapshot() && pagesLoaded < 25 {
                    loaded = await repo.loadMoreConversationsPage(filters: requestFilters)
                    pagesLoaded += 1
                }
            }
            conversations = loaded
            hasMoreConversations = repo.hasMoreConversationsSnapshot()
            isLoadingMoreConversations = repo.isLoadingMoreConversationsSnapshot()
        } else {
            conversations = await repository.getConversations()
            hasMoreConversations = false
            isLoadingMoreConversations = false
        }
    }

    func loadMoreConversations() async {
        guard let repo = repository as? WidersRepository else { return }
        if isLoadingMoreConversations || !hasMoreConversations { return }
        isLoadingMoreConversations = true
        conversations = await repo.loadMoreConversationsPage(
            filters: WidersRepository.ConversationsRequestFilters(
                status: activeConversationFilters.status,
                tag: activeConversationFilters.tag,
                agent: activeConversationFilters.agent,
                rating: "all",
                tap: activeConversationFilters.tap,
                orderBy: activeConversationFilters.orderBy
            )
        )
        hasMoreConversations = repo.hasMoreConversationsSnapshot()
        isLoadingMoreConversations = repo.isLoadingMoreConversationsSnapshot()
    }

    func setScreen(_ next: AppScreen) {
        screen = next
    }

    func onNotificationOpenChat(chatId: String) {
        let normalized = chatId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        if isLoggedIn {
            openChat(id: normalized)
        } else {
            pendingNotificationChatId = normalized
        }
    }

    func onPushTokenReceived(token: String) {
        let normalized = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, normalized != latestPushToken else { return }
        latestPushToken = normalized
        updatePushDebugStatus(status: "Token received", token: normalized)
        tryRegisterLatestPushToken()
    }

    func switchWorkspace(companyId: Int) {
        guard companyId > 0, let repo = repository as? WidersRepository else { return }
        guard repo.currentSessionSnapshot()?.companyId != companyId else { return }
        isLoading = true
        Task { @MainActor in
            let switched = repo.switchWorkspace(companyId: companyId)
            guard switched else {
                isLoading = false
                actionStatus = "Failed: unable to switch workspace"
                return
            }
            stopChatPolling()
            realtimeClient.setActiveChat(chatId: nil)
            activeChatId = nil
            activeMessages = []
            isChatLoading = false
            hasMoreActiveMessages = false
            isLoadingMoreActiveMessages = false
            screen = .conversations
            conversations = await repo.refreshConversationsFirstPage(
                filters: WidersRepository.ConversationsRequestFilters(
                    status: activeConversationFilters.status,
                    tag: activeConversationFilters.tag,
                    agent: activeConversationFilters.agent,
                    rating: "all",
                    tap: activeConversationFilters.tap,
                    orderBy: activeConversationFilters.orderBy
                )
            )
            await refreshAvailableTags()
            await refreshAvailableAgents()
            await refreshAvailableTemplates()
            await refreshAvailableFlows()
            await refreshAvailableReplies()
            if let session = repository.currentSessionSnapshot() {
                secureStore.saveString(String(session.companyId), for: SessionKeys.companyId)
            }
            refreshWorkspaceState()
            if let session = repository.currentSessionSnapshot() {
                realtimeClient.connect(companyId: session.companyId)
            }
            tryRegisterLatestPushToken()
            hasMoreConversations = repo.hasMoreConversationsSnapshot()
            isLoadingMoreConversations = repo.isLoadingMoreConversationsSnapshot()
            isLoading = false
            actionStatus = "Workspace switched"
        }
    }

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let convoId = activeChatId else { return }
        let localMessage = ChatMessage(
            id: "local-\(Int(Date().timeIntervalSince1970 * 1000))",
            conversationId: convoId,
            content: trimmed,
            timestamp: nowLabel(),
            type: .text,
            sender: .agent,
            status: .sent,
            noteAuthor: nil
        )
        addLocalOutgoing(localMessage)
        activeMessages.append(localMessage)
        Task { @MainActor in
            let ok = await repository.sendMessage(conversationId: convoId, text: trimmed)
            guard ok else {
                actionStatus = "Failed: unable to send message"
                return
            }
            activeMessages = mergeWithLocalOutgoing(
                conversationId: convoId,
                remote: await fetchLatestMessages(conversationId: convoId)
            )
            conversations = await repository.getConversations()
            actionStatus = "Message sent"
        }
    }

    func sendAttachment(fileName: String, fileData: Data, kindLabel: String) {
        guard let convoId = activeChatId, !fileData.isEmpty else { return }
        let mediaKind: String = {
            if kindLabel.lowercased().contains("image") { return "image" }
            if kindLabel.lowercased().contains("voice") || kindLabel.lowercased().contains("audio") { return "audio" }
            return "document"
        }()
        let localMessage = ChatMessage(
            id: "local-\(Int(Date().timeIntervalSince1970 * 1000))",
            conversationId: convoId,
            content: "[\(kindLabel)]",
            timestamp: nowLabel(),
            type: .media,
            sender: .agent,
            status: .sent,
            noteAuthor: nil,
            mediaUrl: nil,
            mediaKind: mediaKind
        )
        addLocalOutgoing(localMessage)
        activeMessages.append(localMessage)
        Task { @MainActor in
            let ok = await repository.sendMedia(
                conversationId: convoId,
                fileName: fileName,
                fileData: fileData,
                text: nil
            )
            guard ok else {
                actionStatus = "Failed: unable to upload \(kindLabel.lowercased())"
                return
            }
            activeMessages = mergeWithLocalOutgoing(
                conversationId: convoId,
                remote: await fetchLatestMessages(conversationId: convoId)
            )
            conversations = await repository.getConversations()
            actionStatus = "\(kindLabel) sent"
        }
    }

    func sendVoiceMessage(fileName: String, fileData: Data) {
        sendAttachment(fileName: fileName, fileData: fileData, kindLabel: "Voice message")
    }

    func addNote(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let convoId = activeChatId else { return }
        Task { @MainActor in
            let ok = await repository.addNote(conversationId: convoId, note: trimmed)
            guard ok else {
                actionStatus = "Failed: unable to add note"
                return
            }
            activeMessages = await fetchLatestMessages(conversationId: convoId)
            conversations = await repository.getConversations()
            actionStatus = "Note added"
        }
    }

    func toggleConversationStatus() {
        guard let convoId = activeChatId, let index = conversations.firstIndex(where: { $0.id == convoId }) else { return }
        let open = conversations[index].status != .open
        Task { @MainActor in
            let ok = await repository.updateConversationStatus(conversationId: convoId, open: open)
            guard ok else {
                actionStatus = "Failed: unable to update conversation status"
                return
            }
            activeMessages = await fetchLatestMessages(conversationId: convoId)
            conversations = await repository.getConversations()
            actionStatus = open ? "Conversation reopened" : "Conversation closed"
        }
    }

    func assignCurrentChat(agentId: Int) {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.assignAgent(contactId: contactId, agent: agentId)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to assign agent" : "Agent assigned"
        }
    }

    func unassignCurrentChat() {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.unassignAgent(contactId: contactId)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to unassign agent" : "Agent unassigned"
        }
    }

    func muteCurrentChat(_ muted: Bool) {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.updateMute(contactId: contactId, status: muted)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to update mute status" : (muted ? "Conversation muted" : "Conversation unmuted")
        }
    }

    func markCurrentChatRead(_ read: Bool) {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.updateRead(contactId: contactId, status: read)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to update read status" : (read ? "Marked as read" : "Marked as unread")
        }
    }

    func markConversationRead(conversationId: String, read: Bool) {
        guard let contactId = Int(conversationId) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.updateRead(contactId: contactId, status: read)
            isActionLoading = false
            guard result != nil else {
                actionStatus = "Failed: unable to update read status"
                return
            }
            conversations = await repository.getConversations()
            actionStatus = read ? "Marked as read" : "Marked as unread"
        }
    }

    func toggleConversationStatus(conversationId: String) {
        guard let current = conversations.first(where: { $0.id == conversationId }) else { return }
        let open = current.status != .open
        Task { @MainActor in
            isActionLoading = true
            let ok = await repository.updateConversationStatus(conversationId: conversationId, open: open)
            isActionLoading = false
            guard ok else {
                actionStatus = "Failed: unable to update conversation status"
                return
            }
            conversations = await repository.getConversations()
            if activeChatId == conversationId {
                activeMessages = await fetchLatestMessages(conversationId: conversationId)
            }
            actionStatus = open ? "Conversation reopened" : "Conversation closed"
        }
    }

    func attachTag(conversationId: String, tagId: Int) {
        guard let contactId = Int(conversationId) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.attachTag(contactId: contactId, tagId: tagId)
            isActionLoading = false
            guard result != nil else {
                actionStatus = "Failed: unable to attach tag"
                return
            }
            conversations = await repository.getConversations()
            actionStatus = "Tag attached"
        }
    }

    func detachTag(conversationId: String, tagId: Int) {
        guard let contactId = Int(conversationId) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.detachTag(contactId: contactId, tagId: tagId)
            isActionLoading = false
            guard result != nil else {
                actionStatus = "Failed: unable to detach tag"
                return
            }
            conversations = await repository.getConversations()
            actionStatus = "Tag detached"
        }
    }

    func repeatTag(conversationId: String, tagId: Int) {
        attachTag(conversationId: conversationId, tagId: tagId)
    }

    func attachTagToCurrentChat(tagId: Int) {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.attachTag(contactId: contactId, tagId: tagId)
            isActionLoading = false
            guard result != nil else {
                actionStatus = "Failed: unable to attach tag"
                return
            }
            conversations = await repository.getConversations()
            if activeChatId == id {
                activeMessages = await fetchLatestMessages(conversationId: id)
            }
            actionStatus = "Tag attached"
        }
    }

    func detachTagFromCurrentChat(tagId: Int) {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.detachTag(contactId: contactId, tagId: tagId)
            isActionLoading = false
            guard result != nil else {
                actionStatus = "Failed: unable to detach tag"
                return
            }
            conversations = await repository.getConversations()
            if activeChatId == id {
                activeMessages = await fetchLatestMessages(conversationId: id)
            }
            actionStatus = "Tag detached"
        }
    }

    func sendTemplateToCurrentChat(templateId: Int) {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.sendTemplateMessage(contactId: contactId, templateId: templateId)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to send template" : "Template sent"
        }
    }

    func sendFlowToCurrentChat(flowId: Int) {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.sendFlow(contactId: contactId, flowId: flowId)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to send flow" : "Flow sent"
        }
    }

    func sendQuickReplyToCurrentChat(replyId: Int) {
        guard let reply = availableReplies.first(where: { $0.id == replyId }) else { return }
        let text = reply.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        sendMessage(text)
        actionStatus = "Reply sent"
        Task { @MainActor in
            await refreshAvailableReplies()
        }
    }

    func syncCurrentContactCustomField(fieldId: String, fieldValue: String) {
        guard let id = activeChatId, let contactId = Int(id), !fieldId.isEmpty else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.syncContactCustomFields(contactId: contactId, custom: [fieldId: fieldValue])
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to sync custom field" : "Custom field synced"
        }
    }

    func refreshCurrentContactCustomFields() async {
        guard let id = activeChatId, let contactId = Int(id) else {
            availableCustomFields = []
            return
        }
        guard let payload = await repository.getContactCustomFields(contactId: contactId) else {
            availableCustomFields = []
            return
        }
        availableCustomFields = parseAvailableCustomFields(payload)
    }

    func deleteCurrentChat() {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.deleteChat(contactId: contactId)
            isActionLoading = false
            guard result != nil else {
                actionStatus = "Failed: unable to delete chat"
                return
            }
            conversations = await repository.getConversations()
            activeChatId = nil
            activeMessages = []
            screen = .conversations
            actionStatus = "Conversation deleted"
        }
    }

    func deleteConversations(ids: [String]) {
        let contactIds = Array(Set(ids.compactMap(Int.init)))
        guard !contactIds.isEmpty else { return }
        Task { @MainActor in
            isActionLoading = true
            var deleted = 0
            for contactId in contactIds {
                let result = await repository.deleteChat(contactId: contactId)
                if result != nil { deleted += 1 }
            }
            isActionLoading = false
            conversations = await repository.getConversations()
            if let active = activeChatId, ids.contains(active) {
                activeChatId = nil
                activeMessages = []
                screen = .conversations
            }
            actionStatus = deleted > 0 ? "Conversations removed" : "Failed: unable to remove conversations"
        }
    }

    func updateCurrentContact(name: String, phone: String, email: String?) {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmedPhone = normalizeInternationalPhone(phone) else {
            actionStatus = "Failed: phone must be in international format, e.g. +96654377556"
            return
        }
        let trimmedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedPhone.isEmpty else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.updateContact(
                contactId: contactId,
                name: trimmedName,
                phone: trimmedPhone,
                email: (trimmedEmail?.isEmpty == true) ? nil : trimmedEmail
            )
            isActionLoading = false
            guard result != nil else {
                actionStatus = "Failed: unable to update contact"
                return
            }
            conversations = await repository.getConversations()
            actionStatus = "Contact updated"
        }
    }

    func preloadSupportData() {
        Task { @MainActor in
            isActionLoading = true
            let c1 = await repository.getContactsList()
            let c2 = await repository.getTemplatesList()
            let c3 = await repository.getTagsList()
            let c4 = await repository.getRepliesList()
            let c5 = await repository.getFlowsList()
            let c6 = await repository.getAgentsList()
            availableTags = c3.map(parseAvailableTags) ?? []
            availableAgents = c6.map(parseAvailableAgents) ?? []
            availableTemplates = c2.map(parseAvailableTemplates) ?? []
            availableFlows = c5.map(parseAvailableFlows) ?? []
            availableReplies = c4.map(parseAvailableReplies) ?? []
            isActionLoading = false
            let allOk = [c1, c2, c3, c4, c5, c6].allSatisfy { $0 != nil }
            actionStatus = allOk ? "Support data synced" : "Failed: support data sync incomplete"
        }
    }

    func createOrUpdateTag(name: String, color: String, tagId: Int?) {
        guard !name.isEmpty, !color.isEmpty else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.createOrUpdateTag(name: name, color: color, tagId: tagId)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to save tag" : "Tag saved"
        }
    }

    func createOrUpdateReply(name: String, text: String, replyId: Int?) {
        guard !name.isEmpty, !text.isEmpty else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.createOrUpdateReply(name: name, text: text, replyId: replyId)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to save reply" : "Reply saved"
        }
    }

    func addContact(name: String, phone: String, email: String?) {
        guard !name.isEmpty, !phone.isEmpty else { return }
        guard let normalizedPhone = normalizeInternationalPhone(phone) else {
            actionStatus = "Failed: phone must be in international format, e.g. +96654377556"
            return
        }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.addContact(name: name, phone: normalizedPhone, email: email)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to add contact" : "Contact added"
        }
    }

    func startNewConversation(name: String, phone: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmedPhone = normalizeInternationalPhone(phone) else {
            actionStatus = "Failed: phone must be in international format, e.g. +96654377556"
            return
        }
        guard !trimmedName.isEmpty, !trimmedPhone.isEmpty else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.addContact(name: trimmedName, phone: trimmedPhone, email: nil)
            isActionLoading = false
            guard result != nil else {
                actionStatus = "Failed: unable to create conversation"
                return
            }

            let updated = await repository.getConversations()
            conversations = updated
            actionStatus = "Conversation created"

            let createdId = ((result?["data"] as? [String: Any])?.firstString(keys: ["contact_id", "id"]))
            let normalizedPhone = trimmedPhone.filter(\.isNumber)
            let created: Conversation? = {
                if let createdId, !createdId.isEmpty {
                    return updated.first { $0.id == createdId }
                }
                return updated.first {
                    $0.customerName.caseInsensitiveCompare(trimmedName) == .orderedSame ||
                    $0.customerPhone.filter(\.isNumber).hasSuffix(normalizedPhone)
                }
            }()

            if let created {
                openChat(id: created.id)
            } else {
                actionStatus = "Conversation created. Open it from contacts/search if it has no messages yet."
            }
        }
    }

    func updateProfile(name: String, email: String) {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { return }
        profileName = normalizedName
        profileEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func loadContactsForNewConversation() {
        contactsSearchMode = false
        contactsNextPage = 1
        contactsHasMore = true
        Task { @MainActor in
            contactsLoading = true
            defer { contactsLoading = false }
            let payload: [String: Any]? = {
                if let repo = repository as? WidersRepository {
                    return await repo.getContactsList(page: contactsNextPage, limit: contactsPageSize)
                }
                return await repository.getContactsList()
            }()
            guard let payload else { return }
            let parsed = parseNewConversationContacts(payload)
            contactsHasMore = parsed.count >= contactsPageSize
            contactsNextPage = contactsHasMore ? 2 : 1
            newConversationContacts = parsed
            hasMoreNewConversationContacts = contactsHasMore
            isLoadingMoreNewConversationContacts = false
        }
    }

    func loadMoreContactsForNewConversation() {
        if contactsSearchMode || !contactsHasMore || contactsLoading || isLoadingMoreNewConversationContacts { return }
        Task { @MainActor in
            isLoadingMoreNewConversationContacts = true
            defer { isLoadingMoreNewConversationContacts = false }
            guard let repo = repository as? WidersRepository else { return }
            guard let payload = await repo.getContactsList(page: contactsNextPage, limit: contactsPageSize) else { return }
            let parsed = parseNewConversationContacts(payload)
            if parsed.isEmpty {
                contactsHasMore = false
            } else {
                contactsHasMore = parsed.count >= contactsPageSize
                if contactsHasMore { contactsNextPage += 1 }
            }
            newConversationContacts = dedupeContacts(newConversationContacts + parsed)
            hasMoreNewConversationContacts = contactsHasMore
        }
    }

    func searchContactsForNewConversation(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            loadContactsForNewConversation()
            return
        }
        contactsSearchMode = true
        contactsHasMore = false
        Task { @MainActor in
            contactsLoading = true
            defer { contactsLoading = false }
            guard let payload = await repository.searchContacts(query: trimmed) else { return }
            newConversationContacts = parseNewConversationContacts(payload)
            hasMoreNewConversationContacts = false
            isLoadingMoreNewConversationContacts = false
        }
    }

    func startConversationForContact(_ contact: NewConversationContact) {
        Task { @MainActor in
            let updated = await repository.getConversations()
            conversations = updated
            let normalizedPhone = contact.phone.filter(\.isNumber)
            if let existing = updated.first(where: {
                $0.id == contact.id || $0.customerPhone.filter(\.isNumber).hasSuffix(normalizedPhone)
            }) {
                openChat(id: existing.id)
                return
            }
            let synthetic = Conversation(
                id: contact.id,
                customerName: contact.name,
                customerPhone: contact.phone,
                lastMessage: "",
                lastMessageTime: "",
                unreadCount: 0,
                status: .open,
                isOnline: false
            )
            if !conversations.contains(where: { $0.id == synthetic.id }) {
                conversations.append(synthetic)
            }
            openChat(id: contact.id)
        }
    }

    func searchChats(_ keyword: String) {
        guard !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Task { @MainActor in
                conversations = await repository.getConversations()
            }
            return
        }
        Task { @MainActor in
            isActionLoading = true
            let result = await (repository as? WidersRepository)?.searchConversations(keyword: keyword, page: 1, limit: 50)
            isActionLoading = false
            if let result {
                conversations = result
                actionStatus = "Search completed"
                return
            }
            let source = await repository.getConversations()
            conversations = source.filter {
                $0.customerName.localizedCaseInsensitiveContains(keyword) ||
                $0.lastMessage.localizedCaseInsensitiveContains(keyword)
            }
            actionStatus = "Search completed"
        }
    }

    private func addLocalOutgoing(_ message: ChatMessage) {
        localOutgoingByConversation[message.conversationId, default: []].append(message)
    }

    private func mergeWithLocalOutgoing(conversationId: String, remote: [ChatMessage]) -> [ChatMessage] {
        let local = localOutgoingByConversation[conversationId] ?? []
        guard !local.isEmpty else { return remote }
        let existing = Set(remote.map(\.id))
        let existingSignatures = Set(remote.map { message in
            "\(message.sender == .agent)|\(message.content.trimmingCharacters(in: .whitespacesAndNewlines))"
        })
        return remote + local.filter {
            !existing.contains($0.id) &&
            !existingSignatures.contains("\($0.sender == .agent)|\($0.content.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
    }

    private func nowLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: locale == .ar ? "ar_SA" : "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private func normalizeInternationalPhone(_ raw: String) -> String? {
        let compact = raw.filter { !$0.isWhitespace }
        guard compact.hasPrefix("+") else { return nil }
        let digits = String(compact.dropFirst())
        guard (8...15).contains(digits.count), digits.allSatisfy(\.isNumber) else { return nil }
        return "+\(digits)"
    }

    private func fetchLatestMessages(conversationId: String, resetHistory: Bool = false) async -> [ChatMessage] {
        if let repo = repository as? WidersRepository {
            let messages = await repo.refreshMessagesFirstPage(conversationId: conversationId, resetLoaded: resetHistory)
            hasMoreActiveMessages = repo.hasMoreMessagesSnapshot(conversationId: conversationId)
            isLoadingMoreActiveMessages = repo.isLoadingMoreMessagesSnapshot(conversationId: conversationId)
            return messages
        }
        hasMoreActiveMessages = false
        isLoadingMoreActiveMessages = false
        return await repository.getMessages(conversationId: conversationId)
    }

    private func startChatPolling(id: String) {
        chatPollingTask?.cancel()
        chatPollingTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                guard activeChatId == id, screen == .chat else { break }
                let remote = await fetchLatestMessages(conversationId: id)
                activeMessages = mergeWithLocalOutgoing(conversationId: id, remote: remote)
                conversations = await repository.getConversations()
            }
        }
    }

    private func stopChatPolling() {
        chatPollingTask?.cancel()
        chatPollingTask = nil
    }

    private func handleRealtimeGeneralEvent(channel: String) {
        guard isLoggedIn else { return }
        if channel.hasPrefix("chatupdate.") {
            scheduleRealtimeConversationsRefresh()
            if let active = activeChatId {
                scheduleRealtimeActiveChatRefresh(conversationId: active)
            }
            return
        }
        if channel.hasPrefix("chat.") {
            scheduleRealtimeConversationsRefresh()
            let eventChatId = String(channel.dropFirst("chat.".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !eventChatId.isEmpty, eventChatId == activeChatId {
                scheduleRealtimeActiveChatRefresh(conversationId: eventChatId)
            }
        }
    }

    private func scheduleRealtimeConversationsRefresh() {
        realtimeConversationsRefreshTask?.cancel()
        realtimeConversationsRefreshTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            if let repo = repository as? WidersRepository {
                conversations = await repo.refreshConversationsFirstPage(
                    filters: WidersRepository.ConversationsRequestFilters(
                        status: activeConversationFilters.status,
                        tag: activeConversationFilters.tag,
                        agent: activeConversationFilters.agent,
                        rating: "all",
                        tap: activeConversationFilters.tap,
                        orderBy: activeConversationFilters.orderBy
                    )
                )
                hasMoreConversations = repo.hasMoreConversationsSnapshot()
                isLoadingMoreConversations = repo.isLoadingMoreConversationsSnapshot()
            } else {
                conversations = await repository.getConversations()
            }
        }
    }

    private func scheduleRealtimeActiveChatRefresh(conversationId: String) {
        realtimeActiveChatRefreshTask?.cancel()
        realtimeActiveChatRefreshTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard activeChatId == conversationId, screen == .chat else { return }
            let remote = await fetchLatestMessages(conversationId: conversationId)
            activeMessages = mergeWithLocalOutgoing(conversationId: conversationId, remote: remote)
        }
    }

    private func parseNewConversationContacts(_ payload: [String: Any]) -> [NewConversationContact] {
        let rows = payload.firstArray(keys: ["contacts", "data", "rows", "result"])
        let parsed: [NewConversationContact] = rows.compactMap { item in
            guard let id = item.firstString(keys: ["id", "contact_id"]) else { return nil }
            let name = item.firstString(keys: ["name", "contact_name"]) ?? "Contact"
            let phone = item.firstString(keys: ["phone", "wa_id", "number"]) ?? ""
            guard !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            if isHiddenTestContact(name: name, phone: phone) { return nil }
            return NewConversationContact(id: id, name: name, phone: phone)
        }
        var seen = Set<String>()
        return parsed.filter { seen.insert($0.id).inserted }
    }

    private func dedupeContacts(_ contacts: [NewConversationContact]) -> [NewConversationContact] {
        var seen = Set<String>()
        return contacts.filter { seen.insert($0.id).inserted }
    }

    private func isHiddenTestContact(name: String, phone: String) -> Bool {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let digits = phone.filter(\.isNumber)
        if normalizedName == "cursor qa test" { return true }
        return ["966500000001", "966500000002", "0500000003"].contains(digits)
    }

    func refreshAvailableTags() async {
        guard let payload = await repository.getTagsList() else {
            availableTags = []
            return
        }
        availableTags = parseAvailableTags(payload)
    }

    func refreshAvailableAgents() async {
        guard let payload = await repository.getAgentsList() else {
            availableAgents = []
            return
        }
        availableAgents = parseAvailableAgents(payload)
    }

    func refreshAvailableTemplates() async {
        guard let payload = await repository.getTemplatesList() else {
            availableTemplates = []
            return
        }
        availableTemplates = parseAvailableTemplates(payload)
    }

    func refreshAvailableFlows() async {
        guard let payload = await repository.getFlowsList() else {
            availableFlows = []
            return
        }
        availableFlows = parseAvailableFlows(payload)
    }

    func refreshAvailableReplies() async {
        guard let payload = await repository.getRepliesList() else {
            availableReplies = []
            return
        }
        availableReplies = parseAvailableReplies(payload)
    }

    private func parseAvailableTags(_ payload: [String: Any]) -> [AvailableTag] {
        let rows = payload.firstArray(keys: ["tags", "data", "rows", "result"])
        var seen = Set<Int>()
        let parsed: [AvailableTag] = rows.compactMap { item in
            guard let id = item.firstInt(keys: ["id", "tag_id"]) else { return nil }
            let name = (item.firstString(keys: ["name", "title"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            guard seen.insert(id).inserted else { return nil }
            let color = item.firstString(keys: ["color", "color_hex", "hex"])
            return AvailableTag(id: id, name: name, colorHex: color)
        }
        return parsed.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func parseAvailableAgents(_ payload: [String: Any]) -> [AvailableAgent] {
        let rows = payload.firstArray(keys: ["agents", "data", "rows", "result"])
        var seen = Set<Int>()
        let parsed: [AvailableAgent] = rows.compactMap { item in
            guard let id = item.firstInt(keys: ["id", "agent_id", "user_id"]) else { return nil }
            let name = (item.firstString(keys: ["name", "full_name", "username"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(id).inserted else { return nil }
            return AvailableAgent(id: id, name: name)
        }
        return parsed.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func parseAvailableTemplates(_ payload: [String: Any]) -> [AvailableTemplate] {
        var rows = payload.firstArray(keys: ["templates", "data", "rows", "result"])
        if rows.isEmpty, let dataObj = payload["data"] as? [String: Any] {
            rows = dataObj.firstArray(keys: ["templates", "rows", "result"])
        }
        var seen = Set<Int>()
        let parsed: [AvailableTemplate] = rows.compactMap { item in
            guard let id = item.firstInt(keys: ["id", "template_id"]) else { return nil }
            let name = (item.firstString(keys: ["name", "title"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(id).inserted else { return nil }
            return AvailableTemplate(id: id, name: name)
        }
        return parsed.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func parseAvailableFlows(_ payload: [String: Any]) -> [AvailableFlow] {
        var rows = payload.firstArray(keys: ["flows", "data", "rows", "result"])
        if rows.isEmpty, let dataObj = payload["data"] as? [String: Any] {
            rows = dataObj.firstArray(keys: ["flows", "rows", "result"])
        }
        var seen = Set<Int>()
        let parsed: [AvailableFlow] = rows.compactMap { item in
            guard let id = item.firstInt(keys: ["id", "flow_id"]) else { return nil }
            let name = (item.firstString(keys: ["name", "title"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(id).inserted else { return nil }
            return AvailableFlow(id: id, name: name)
        }
        return parsed.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func parseAvailableReplies(_ payload: [String: Any]) -> [AvailableReply] {
        var rows = payload.firstArray(keys: ["replies", "data", "rows", "result"])
        if rows.isEmpty, let dataObj = payload["data"] as? [String: Any] {
            rows = dataObj.firstArray(keys: ["replies", "rows", "result"])
        }
        var seen = Set<Int>()
        let parsed: [AvailableReply] = rows.compactMap { item in
            guard let id = item.firstInt(keys: ["id", "reply_id"]) else { return nil }
            let name = (item.firstString(keys: ["name", "title"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let text = (item.firstString(keys: ["text", "value", "message"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !text.isEmpty, seen.insert(id).inserted else { return nil }
            return AvailableReply(id: id, name: name, text: text)
        }
        return parsed.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func parseAvailableCustomFields(_ payload: [String: Any]) -> [AvailableCustomField] {
        var rows = payload.firstArray(keys: ["fields", "custom_fields", "data", "rows", "result"])
        if rows.isEmpty, let dataObj = payload["data"] as? [String: Any] {
            rows = dataObj.firstArray(keys: ["fields", "custom_fields", "rows", "result"])
        }

        var seen = Set<String>()
        var parsed: [AvailableCustomField] = rows.compactMap { item in
            let id = (item.firstString(keys: ["id", "field_id", "key", "name"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !id.isEmpty, seen.insert(id).inserted else { return nil }
            let label = (item.firstString(keys: ["label", "name", "title", "key"]) ?? id).trimmingCharacters(in: .whitespacesAndNewlines)
            let value = item.firstString(keys: ["value", "field_value", "current", "default"])
            return AvailableCustomField(id: id, label: label, value: value)
        }

        func appendFromMap(_ map: [String: Any]?) {
            guard let map else { return }
            for (key, rawValue) in map {
                let id = key.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !id.isEmpty, seen.insert(id).inserted else { continue }
                if let obj = rawValue as? [String: Any] {
                    let label = (obj.firstString(keys: ["label", "name", "title", "key"]) ?? id).trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = obj.firstString(keys: ["value", "field_value", "current", "default"])
                    parsed.append(AvailableCustomField(id: id, label: label, value: value))
                } else {
                    parsed.append(AvailableCustomField(id: id, label: id, value: String(describing: rawValue)))
                }
            }
        }

        appendFromMap(payload["custom"] as? [String: Any])
        appendFromMap(payload["fields"] as? [String: Any])
        if let dataObj = payload["data"] as? [String: Any] {
            appendFromMap(dataObj["custom"] as? [String: Any])
            appendFromMap(dataObj["fields"] as? [String: Any])
        }

        return parsed.sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    func restoreSession(token: String, companyId: Int) {
        guard !token.isEmpty, companyId > 0 else { return }
        isLoading = true
        loginError = nil
        Task { @MainActor in
            repository.restoreSession(token: token, companyId: companyId)
            profileName = secureStore.readString(for: SessionKeys.profileName) ?? ""
            profileEmail = secureStore.readString(for: SessionKeys.profileEmail) ?? ""
            let probe = await repository.getContactsList()
            if probe != nil {
                isLoading = false
                isLoggedIn = true
                screen = .conversations
                secureStore.saveString(token, for: SessionKeys.token)
                secureStore.saveString(String(companyId), for: SessionKeys.companyId)
                realtimeClient.connect(companyId: companyId)
                tryRegisterLatestPushToken()
                refreshWorkspaceState()
                launchPostLoginDataWarmup()
                if let pending = pendingNotificationChatId {
                    pendingNotificationChatId = nil
                    openChat(id: pending)
                }
            } else {
                repository.clearSession()
                isLoading = false
                loginError = tr(locale, .loginError)
                secureStore.removeValue(for: SessionKeys.token)
                secureStore.removeValue(for: SessionKeys.companyId)
                secureStore.removeValue(for: SessionKeys.profileName)
                secureStore.removeValue(for: SessionKeys.profileEmail)
                profileName = ""
                profileEmail = ""
                availableTags = []
                availableAgents = []
                availableCustomFields = []
                availableTemplates = []
                availableFlows = []
                availableWorkspaces = []
                currentCompanyId = nil
                hasMoreConversations = false
                isLoadingMoreConversations = false
            }
        }
    }

    private func restoreStoredLoginIfNeeded() {
        let token = (secureStore.readString(for: SessionKeys.token) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let companyId = Int(secureStore.readString(for: SessionKeys.companyId) ?? "") ?? 0
        guard !token.isEmpty, companyId > 0 else { return }
        restoreSession(token: token, companyId: companyId)
    }

    private func tryRegisterLatestPushToken() {
        guard let token = latestPushToken else { return }
        guard isLoggedIn else {
            updatePushDebugStatus(status: "Waiting for login", token: token)
            return
        }
        Task { @MainActor in
            updatePushDebugStatus(status: "Registering...", token: token)
            let ok = await repository.registerPushToken(token: token, platform: "ios")
            updatePushDebugStatus(status: ok ? "Registered" : "Registration failed", token: token)
        }
    }

    private func updatePushDebugStatus(status: String, token: String?) {
#if DEBUG
        let masked = token.map(maskPushToken(_:)) ?? "n/a"
        pushDebugInfo = "Token: \(masked)\nLast attempt: \(nowLabel())\nResult: \(status)"
        pushDebugRawToken = token
#endif
    }

    private func maskPushToken(_ token: String) -> String {
        let normalized = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count > 10 else { return "***" }
        return "\(normalized.prefix(6))...\(normalized.suffix(4))"
    }

    private func launchPostLoginDataWarmup() {
        Task { @MainActor in
            if let repo = repository as? WidersRepository {
                conversations = await repo.refreshConversationsFirstPage(
                    filters: WidersRepository.ConversationsRequestFilters(
                        status: activeConversationFilters.status,
                        tag: activeConversationFilters.tag,
                        agent: activeConversationFilters.agent,
                        rating: "all",
                        tap: activeConversationFilters.tap,
                        orderBy: activeConversationFilters.orderBy
                    )
                )
                hasMoreConversations = repo.hasMoreConversationsSnapshot()
                isLoadingMoreConversations = repo.isLoadingMoreConversationsSnapshot()
            } else {
                conversations = await repository.getConversations()
                hasMoreConversations = false
                isLoadingMoreConversations = false
            }
        }
        Task { @MainActor in await refreshAvailableTags() }
        Task { @MainActor in await refreshAvailableAgents() }
        Task { @MainActor in await refreshAvailableTemplates() }
        Task { @MainActor in await refreshAvailableFlows() }
        Task { @MainActor in await refreshAvailableReplies() }
    }

    private func refreshWorkspaceState() {
        guard let repo = repository as? WidersRepository else {
            currentCompanyId = repository.currentSessionSnapshot()?.companyId
            availableWorkspaces = []
            return
        }
        currentCompanyId = repo.currentCompanyIdSnapshot()
        availableWorkspaces = repo.availableWorkspacesSnapshot()
    }
}
