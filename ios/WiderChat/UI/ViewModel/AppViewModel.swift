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
    @Published var newConversationContacts: [NewConversationContact] = []
    @Published var profileName = ""
    @Published var profileEmail = ""
    private var localOutgoingByConversation: [String: [ChatMessage]] = [:]

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
            let loaded = await repository.getConversations()
            conversations = loaded
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
            }
        }
    }

    func logout() {
        secureStore.removeValue(for: SessionKeys.token)
        secureStore.removeValue(for: SessionKeys.companyId)
        isLoggedIn = false
        screen = .login
        activeChatId = nil
        activeMessages = []
        isChatLoading = false
        actionStatus = nil
        profileName = ""
        profileEmail = ""
        secureStore.removeValue(for: SessionKeys.profileName)
        secureStore.removeValue(for: SessionKeys.profileEmail)
    }

    func openChat(id: String) {
        activeChatId = id
        screen = .chat
        activeMessages = []
        isChatLoading = true
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
            let remote = await repository.getMessages(conversationId: id)
            guard self.activeChatId == id else { return }
            activeMessages = mergeWithLocalOutgoing(conversationId: id, remote: remote)
            conversations = await repository.getConversations().map { convo in
                var updated = convo
                if updated.id == id { updated.unreadCount = 0 }
                return updated
            }
        }
    }

    func backToConversations() {
        screen = .conversations
        isChatLoading = false
        Task { @MainActor in
            conversations = await repository.getConversations()
        }
    }

    func setScreen(_ next: AppScreen) {
        screen = next
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
                remote: await repository.getMessages(conversationId: convoId)
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
                remote: await repository.getMessages(conversationId: convoId)
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
            activeMessages = await repository.getMessages(conversationId: convoId)
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
            activeMessages = await repository.getMessages(conversationId: convoId)
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

    func attachTagToCurrentChat(tagId: Int) {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.attachTag(contactId: contactId, tagId: tagId)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to attach tag" : "Tag attached"
        }
    }

    func detachTagFromCurrentChat(tagId: Int) {
        guard let id = activeChatId, let contactId = Int(id) else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.detachTag(contactId: contactId, tagId: tagId)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to detach tag" : "Tag detached"
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

    func syncCurrentContactCustomField(fieldId: String, fieldValue: String) {
        guard let id = activeChatId, let contactId = Int(id), !fieldId.isEmpty else { return }
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.syncContactCustomFields(contactId: contactId, custom: [fieldId: fieldValue])
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to sync custom field" : "Custom field synced"
        }
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

    func preloadSupportData() {
        Task { @MainActor in
            isActionLoading = true
            let c1 = await repository.getContactsList()
            let c2 = await repository.getTemplatesList()
            let c3 = await repository.getTagsList()
            let c4 = await repository.getRepliesList()
            let c5 = await repository.getFlowsList()
            let c6 = await repository.getAgentsList()
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
        Task { @MainActor in
            isActionLoading = true
            let result = await repository.addContact(name: name, phone: phone, email: email)
            isActionLoading = false
            actionStatus = result == nil ? "Failed: unable to add contact" : "Contact added"
        }
    }

    func startNewConversation(name: String, phone: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
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

    func loadContactsForNewConversation() {
        Task { @MainActor in
            contactsLoading = true
            defer { contactsLoading = false }
            guard let payload = await repository.getContactsList() else { return }
            newConversationContacts = parseNewConversationContacts(payload)
        }
    }

    func searchContactsForNewConversation(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            loadContactsForNewConversation()
            return
        }
        Task { @MainActor in
            contactsLoading = true
            defer { contactsLoading = false }
            guard let payload = await repository.searchContacts(query: trimmed) else { return }
            newConversationContacts = parseNewConversationContacts(payload)
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
            let result = await repository.searchChats(keyword: keyword, page: 1, limit: 50)
            isActionLoading = false
            guard result != nil else {
                actionStatus = "Failed: search request"
                return
            }
            conversations = conversations.filter {
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

    private func isHiddenTestContact(name: String, phone: String) -> Bool {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let digits = phone.filter(\.isNumber)
        if normalizedName == "cursor qa test" { return true }
        return ["966500000001", "966500000002", "0500000003"].contains(digits)
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
                let loaded = await repository.getConversations()
                conversations = loaded
                isLoading = false
                isLoggedIn = true
                screen = .conversations
                secureStore.saveString(token, for: SessionKeys.token)
                secureStore.saveString(String(companyId), for: SessionKeys.companyId)
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
            }
        }
    }

    private func restoreStoredLoginIfNeeded() {
        let token = (secureStore.readString(for: SessionKeys.token) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let companyId = Int(secureStore.readString(for: SessionKeys.companyId) ?? "") ?? 0
        guard !token.isEmpty, companyId > 0 else { return }
        restoreSession(token: token, companyId: companyId)
    }
}
