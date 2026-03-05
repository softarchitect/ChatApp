import Foundation

final class WidersRepository: ChatRepository {
    struct ConversationsRequestFilters {
        let status: String
        let tag: String
        let agent: String
        let rating: String
        let tap: String
        let orderBy: String

        static let `default` = ConversationsRequestFilters(
            status: "all",
            tag: "all",
            agent: "all",
            rating: "all",
            tap: "all",
            orderBy: "default"
        )
    }

    private let api = WidersAPIClient()
    private(set) var session: APISession?
    private(set) var conversationsCache: [Conversation] = []
    private var contactPhonesById: [String: String] = [:]
    private var sessionUserName: String?
    private var sessionUserEmail: String?
    private var sessionWorkspaces: [WorkspaceOption] = []
    private var conversationsNextPage: Int = 1
    private var conversationsHasMore: Bool = true
    private let conversationsPageSize: Int = 30
    private var conversationsLoading: Bool = false
    private var conversationsFilters: ConversationsRequestFilters = ConversationsRequestFilters(
        status: "all",
        tag: "all",
        agent: "all",
        rating: "all",
        tap: "all",
        orderBy: "default"
    )
    private var latestRegisteredPushToken: String?
    private struct MessagePagingState {
        var pageSize: Int = 60
        var nextPage: Int = 1
        var hasMore: Bool = true
        var isLoading: Bool = false
        var loaded: [ChatMessage] = []
    }
    private var messagePagingByConversation: [String: MessagePagingState] = [:]

    func login(email: String, password: String) async -> Bool {
        do {
            let response = try await api.login(email: email, password: password)
            let companiesTop = response["companies"] as? [[String: Any]]
            let companiesNested = (response["data"] as? [String: Any])?["companies"] as? [[String: Any]]
            guard
                let token = response.firstString(keys: ["token", "access_token", "api_token"])
                    ?? (response["data"] as? [String: Any])?.firstString(keys: ["token", "access_token", "api_token"]),
                let companyId = response.firstInt(keys: ["company_id"])
                    ?? (response["data"] as? [String: Any])?.firstInt(keys: ["company_id", "id"])
                    ?? companiesTop?.first?.firstInt(keys: ["company_id", "id"])
                    ?? companiesNested?.first?.firstInt(keys: ["company_id", "id"])
            else {
                return false
            }
            session = APISession(token: token, companyId: companyId)
            sessionWorkspaces = parseWorkspaceOptions(response: response, fallbackCompanyId: companyId)
            let data = response["data"] as? [String: Any]
            let user = response["user"] as? [String: Any]
                ?? data?["user"] as? [String: Any]
            let merchant = user?["merchant"] as? [String: Any]
                ?? data?["merchant"] as? [String: Any]
            let fallbackName = email.split(separator: "@").first.map(String.init)?.capitalized ?? "Account"
            sessionUserName = user?.firstString(keys: ["name", "full_name", "username"])
                ?? merchant?.firstString(keys: ["name", "company_name"])
                ?? fallbackName
            sessionUserEmail = user?.firstString(keys: ["email", "user_email"])
                ?? response.firstString(keys: ["email"])
                ?? email.trimmingCharacters(in: .whitespacesAndNewlines)
            return true
        } catch {
            return false
        }
    }

    func getConversations() async -> [Conversation] {
        if !conversationsCache.isEmpty { return conversationsCache }
        return await refreshConversationsFirstPage()
    }

    func refreshConversationsFirstPage(
        filters: ConversationsRequestFilters = ConversationsRequestFilters(
            status: "all",
            tag: "all",
            agent: "all",
            rating: "all",
            tap: "all",
            orderBy: "default"
        )
    ) async -> [Conversation] {
        guard let session else { return [] }
        conversationsFilters = filters
        conversationsNextPage = 1
        conversationsHasMore = true
        conversationsCache = []
        do {
            let response = try await api.getChatsList(
                session: session,
                page: conversationsNextPage,
                limit: conversationsPageSize,
                status: conversationsFilters.status,
                tag: conversationsFilters.tag,
                agent: conversationsFilters.agent,
                rating: conversationsFilters.rating,
                tap: conversationsFilters.tap,
                orderBy: conversationsFilters.orderBy
            )
            let rows = response.firstArray(keys: ["conversations", "chats", "data", "rows", "result"])
            let mapped = mapConversations(rows)
            conversationsCache = mapped
            conversationsHasMore = mapped.count >= conversationsPageSize
            conversationsNextPage = conversationsHasMore ? 2 : 1
            return conversationsCache
        } catch {
            conversationsHasMore = false
            return conversationsCache
        }
    }

    func loadMoreConversationsPage(filters: ConversationsRequestFilters? = nil) async -> [Conversation] {
        guard let session else { return conversationsCache }
        let activeFilters = filters ?? conversationsFilters
        if let filters {
            conversationsFilters = filters
        }
        if !conversationsHasMore || conversationsLoading { return conversationsCache }
        conversationsLoading = true
        defer { conversationsLoading = false }
        do {
            let response = try await api.getChatsList(
                session: session,
                page: conversationsNextPage,
                limit: conversationsPageSize,
                status: activeFilters.status,
                tag: activeFilters.tag,
                agent: activeFilters.agent,
                rating: activeFilters.rating,
                tap: activeFilters.tap,
                orderBy: activeFilters.orderBy
            )
            let rows = response.firstArray(keys: ["conversations", "chats", "data", "rows", "result"])
            let mapped = mapConversations(rows)
            if mapped.isEmpty {
                conversationsHasMore = false
                return conversationsCache
            }
            let previousCount = conversationsCache.count
            var seen = Set<String>()
            let merged = (conversationsCache + mapped).filter { seen.insert($0.id).inserted }
            let addedCount = merged.count - previousCount
            conversationsCache = merged
            conversationsHasMore = addedCount > 0 && mapped.count >= conversationsPageSize
            if conversationsHasMore { conversationsNextPage += 1 }
            return conversationsCache
        } catch {
            return conversationsCache
        }
    }

    func getMessages(conversationId: String) async -> [ChatMessage] {
        if let state = messagePagingByConversation[conversationId], !state.loaded.isEmpty {
            return state.loaded
        }
        return await refreshMessagesFirstPage(conversationId: conversationId, resetLoaded: false)
    }

    func refreshMessagesFirstPage(conversationId: String, resetLoaded: Bool) async -> [ChatMessage] {
        guard let session, let contactId = Int(conversationId) else { return [] }
        let existing = messagePagingByConversation[conversationId]
        let pageSize = existing?.pageSize ?? 60
        do {
            let response = try await api.getChatMessages(
                session: session,
                contactId: contactId,
                page: 1,
                limit: pageSize
            )
            let rows = response.firstArray(keys: ["messages", "data", "rows", "result"])
            let parsed = parseMessageRows(conversationId: conversationId, rows: rows)
            let previous = resetLoaded ? [] : (existing?.loaded ?? [])
            let merged = dedupeMessages(previous + parsed)
            messagePagingByConversation[conversationId] = MessagePagingState(
                pageSize: pageSize,
                nextPage: parsed.count >= pageSize ? 2 : 1,
                hasMore: parsed.count >= pageSize,
                isLoading: false,
                loaded: merged
            )
            return merged
        } catch {
            return existing?.loaded ?? []
        }
    }

    func loadOlderMessagesPage(conversationId: String) async -> [ChatMessage] {
        guard let session, let contactId = Int(conversationId) else { return [] }
        var state = messagePagingByConversation[conversationId] ?? MessagePagingState()
        if !state.hasMore || state.isLoading { return state.loaded }
        state.isLoading = true
        messagePagingByConversation[conversationId] = state
        defer {
            var latest = messagePagingByConversation[conversationId] ?? state
            latest.isLoading = false
            messagePagingByConversation[conversationId] = latest
        }
        do {
            let response = try await api.getChatMessages(
                session: session,
                contactId: contactId,
                page: state.nextPage,
                limit: state.pageSize
            )
            let rows = response.firstArray(keys: ["messages", "data", "rows", "result"])
            let parsed = parseMessageRows(conversationId: conversationId, rows: rows)
            if parsed.isEmpty {
                state.hasMore = false
                messagePagingByConversation[conversationId] = state
                return state.loaded
            }
            state.loaded = dedupeMessages(parsed + state.loaded)
            state.hasMore = parsed.count >= state.pageSize
            if state.hasMore { state.nextPage += 1 }
            messagePagingByConversation[conversationId] = state
            return state.loaded
        } catch {
            return messagePagingByConversation[conversationId]?.loaded ?? []
        }
    }

    func sendMessage(conversationId: String, text: String) async -> Bool {
        guard let session else { return false }
        let phone = conversationsCache.first(where: { $0.id == conversationId })?.customerPhone
            ?? contactPhonesById[conversationId]
        guard let phone, !phone.isEmpty else { return false }
        do {
            _ = try await api.sendMessageMedia(
                session: session,
                phone: phone,
                text: text,
                fileName: nil,
                fileData: nil
            )
            return true
        } catch {
            return false
        }
    }

    func sendMedia(conversationId: String, fileName: String, fileData: Data, text: String? = nil) async -> Bool {
        guard let session else { return false }
        let phone = conversationsCache.first(where: { $0.id == conversationId })?.customerPhone
            ?? contactPhonesById[conversationId]
        guard let phone, !phone.isEmpty else { return false }
        do {
            _ = try await api.sendMessageMedia(
                session: session,
                phone: phone,
                text: text,
                fileName: fileName,
                fileData: fileData
            )
            return true
        } catch {
            return false
        }
    }

    func addNote(conversationId: String, note: String) async -> Bool {
        guard let session, let contactId = Int(conversationId) else { return false }
        do {
            _ = try await api.addNote(session: session, contactId: contactId, note: note)
            return true
        } catch {
            return false
        }
    }

    func updateConversationStatus(conversationId: String, open: Bool) async -> Bool {
        guard let session, let contactId = Int(conversationId) else { return false }
        do {
            _ = try await api.updateOpenStatus(session: session, contactId: contactId, status: open)
            return true
        } catch {
            return false
        }
    }

    // Full endpoint coverage from Postman collection.
    func getContactsList(page: Int, limit: Int = 25) async -> [String: Any]? {
        guard let session else { return nil }
        guard let payload = try? await api.getContactsList(session: session, page: page, limit: limit) else { return nil }
        let rows = payload.firstArray(keys: ["contacts", "data", "rows", "result"])
        var map = contactPhonesById
        for item in rows {
            guard let id = item.firstString(keys: ["id", "contact_id"]),
                  let phone = item.firstString(keys: ["phone", "wa_id", "number"]),
                  !phone.isEmpty
            else { continue }
            map[id] = phone
        }
        contactPhonesById = map
        return payload
    }

    func getContactsList() async -> [String: Any]? {
        await getContactsList(page: 1, limit: 25)
    }
    func getTemplatesList() async -> [String: Any]? { guard let session else { return nil }; return try? await api.getTemplatesList(session: session) }
    func getTagsList() async -> [String: Any]? { guard let session else { return nil }; return try? await api.getTagsList(session: session) }
    func getRepliesList() async -> [String: Any]? { guard let session else { return nil }; return try? await api.getRepliesList(session: session) }
    func getFlowsList() async -> [String: Any]? { guard let session else { return nil }; return try? await api.getFlowsList(session: session) }
    func getAgentsList() async -> [String: Any]? { guard let session else { return nil }; return try? await api.getAgentsList(session: session) }
    func getContactCustomFields(contactId: Int) async -> [String: Any]? { guard let session else { return nil }; return try? await api.getContactCustomFields(session: session, contactId: contactId) }
    func syncContactCustomFields(contactId: Int, custom: [String: Any]) async -> [String: Any]? { guard let session else { return nil }; return try? await api.syncContactCustomFields(session: session, contactId: contactId, custom: custom) }
    func attachTag(contactId: Int, tagId: Int) async -> [String: Any]? { guard let session else { return nil }; return try? await api.attachTagToChat(session: session, contactId: contactId, tagId: tagId) }
    func detachTag(contactId: Int, tagId: Int) async -> [String: Any]? { guard let session else { return nil }; return try? await api.detachTagFromChat(session: session, contactId: contactId, tagId: tagId) }
    func searchChats(keyword: String, page: Int = 1, limit: Int = 50) async -> [String: Any]? { guard let session else { return nil }; return try? await api.searchChats(session: session, keyword: keyword, page: page, limit: limit) }
    func searchConversations(keyword: String, page: Int = 1, limit: Int = 50) async -> [Conversation] {
        guard let payload = await searchChats(keyword: keyword, page: page, limit: limit) else { return [] }
        let searchRows = payload.firstArray(keys: ["search"])
        if !searchRows.isEmpty {
            return mapSearchConversations(searchRows)
        }
        let rows = payload.firstArray(keys: ["conversations", "chats", "data", "rows", "result"])
        return mapConversations(rows)
    }
    func sendTemplateMessage(contactId: Int, templateId: Int) async -> [String: Any]? { guard let session else { return nil }; return try? await api.sendTemplateMessage(session: session, contactId: contactId, templateId: templateId) }
    func sendFlow(contactId: Int, flowId: Int) async -> [String: Any]? { guard let session else { return nil }; return try? await api.sendFlow(session: session, contactId: contactId, flowId: flowId) }
    func assignAgent(contactId: Int, agent: Int) async -> [String: Any]? { guard let session else { return nil }; return try? await api.assignAgent(session: session, contactId: contactId, agent: agent) }
    func unassignAgent(contactId: Int) async -> [String: Any]? { guard let session else { return nil }; return try? await api.unassignAgent(session: session, contactId: contactId) }
    func updateMute(contactId: Int, status: Bool) async -> [String: Any]? { guard let session else { return nil }; return try? await api.updateMuteStatus(session: session, contactId: contactId, status: status) }
    func updateRead(contactId: Int, status: Bool) async -> [String: Any]? { guard let session else { return nil }; return try? await api.updateReadStatus(session: session, contactId: contactId, status: status) }
    func deleteChat(contactId: Int) async -> [String: Any]? { guard let session else { return nil }; return try? await api.deleteChat(session: session, contactId: contactId) }
    func addContact(name: String, phone: String, email: String?) async -> [String: Any]? { guard let session else { return nil }; return try? await api.addContact(session: session, name: name, phone: phone, email: email) }
    func searchContacts(query: String) async -> [String: Any]? { guard let session else { return nil }; return try? await api.searchContacts(session: session, query: query) }
    func updateContact(contactId: Int, name: String, phone: String, email: String?) async -> [String: Any]? { guard let session else { return nil }; return try? await api.updateContact(session: session, contactId: contactId, name: name, phone: phone, email: email) }
    func createOrUpdateTag(name: String, color: String, tagId: Int?) async -> [String: Any]? { guard let session else { return nil }; return try? await api.createOrUpdateTag(session: session, name: name, color: color, tagId: tagId) }
    func createOrUpdateReply(name: String, text: String, replyId: Int?) async -> [String: Any]? { guard let session else { return nil }; return try? await api.createOrUpdateReply(session: session, name: name, text: text, replyId: replyId) }
    func registerPushToken(token: String, platform: String) async -> Bool {
        guard let session else { return false }
        let normalized = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }
        if latestRegisteredPushToken == normalized { return true }
        do {
            _ = try await api.registerPushToken(session: session, pushToken: normalized, platform: platform)
            latestRegisteredPushToken = normalized
            return true
        } catch {
            return false
        }
    }

    func currentSessionSnapshot() -> APISession? {
        session
    }

    func currentUserSnapshot() -> (name: String?, email: String?) {
        (sessionUserName, sessionUserEmail)
    }

    func restoreSession(token: String, companyId: Int) {
        guard !token.isEmpty, companyId > 0 else { return }
        session = APISession(token: token, companyId: companyId)
        if !sessionWorkspaces.contains(where: { $0.companyId == companyId }) {
            sessionWorkspaces = [WorkspaceOption(companyId: companyId, name: "Workspace #\(companyId)")]
        }
    }

    func clearSession() {
        session = nil
        sessionWorkspaces = []
        conversationsCache = []
        contactPhonesById = [:]
        messagePagingByConversation = [:]
        conversationsNextPage = 1
        conversationsHasMore = false
        conversationsLoading = false
        latestRegisteredPushToken = nil
    }

    func availableWorkspacesSnapshot() -> [WorkspaceOption] {
        sessionWorkspaces
    }

    func currentCompanyIdSnapshot() -> Int? {
        session?.companyId
    }

    func switchWorkspace(companyId: Int) -> Bool {
        guard let current = session, companyId > 0, current.companyId != companyId else { return false }
        session = APISession(token: current.token, companyId: companyId)
        conversationsCache = []
        contactPhonesById = [:]
        messagePagingByConversation = [:]
        conversationsNextPage = 1
        conversationsHasMore = true
        conversationsLoading = false
        latestRegisteredPushToken = nil
        return true
    }

    func hasMoreConversationsSnapshot() -> Bool {
        conversationsHasMore
    }

    func isLoadingMoreConversationsSnapshot() -> Bool {
        conversationsLoading
    }

    func hasMoreMessagesSnapshot(conversationId: String) -> Bool {
        messagePagingByConversation[conversationId]?.hasMore ?? false
    }

    func isLoadingMoreMessagesSnapshot(conversationId: String) -> Bool {
        messagePagingByConversation[conversationId]?.isLoading ?? false
    }

}

private func mapConversations(_ rows: [[String: Any]]) -> [Conversation] {
    let mapped: [Conversation] = rows.compactMap { item in
        guard let id = item.firstString(keys: ["contact_id", "id", "conversation_id"]) else { return nil }
        let statusRaw = (item["chats_status"] as? [String: Any])?.firstInt(keys: ["is_open"]) == 0 ? "closed" : (item.firstString(keys: ["status"]) ?? "open")
        let assignedAgentName = (item["agent"] as? [String: Any])?.firstString(keys: ["name", "full_name", "username"])
        let tags = parseConversationTags(item)
        let rawLastTime = item.firstString(keys: ["updated_at", "last_reply_at", "last_message_time", "created_at", "time"]) ?? ""
        let satisfaction = parseConversationSatisfaction(item)
        let isWindowExpired = item.firstBool(
            keys: ["is_window_expired", "window_expired", "is_24h_expired", "expired_24h", "meta_window_expired"]
        ) ?? false
        return Conversation(
            id: id,
            customerName: item.firstString(keys: ["name", "customer_name", "contact_name", "title"]) ?? "Customer",
            customerPhone: item.firstString(keys: ["phone", "contact_phone", "wa_id", "number"]) ?? "",
            lastMessage: sanitizeConversationPreview(item.firstString(keys: ["last_message", "last_value", "value", "text", "body"]) ?? ""),
            lastMessageTime: formatApiDateTime(rawLastTime),
            lastMessageEpochMs: parseApiEpochMs(rawLastTime),
            satisfaction: satisfaction,
            unreadCount: {
                let rawUnread = item.firstInt(keys: ["unread_messages", "unread_count", "unread"]) ?? 0
                let isReaded = (item["chats_status"] as? [String: Any])?.firstBool(keys: ["is_readed"]) ?? item.firstBool(keys: ["is_readed"])
                if isReaded == true { return 0 }
                if isReaded == false { return rawUnread > 0 ? rawUnread : 1 }
                return rawUnread
            }(),
            status: statusRaw == "closed" ? .closed : .open,
            isWindowExpired: isWindowExpired,
            isOnline: item.firstBool(keys: ["is_online", "online"]) ?? false,
            assignedAgentName: assignedAgentName,
            tags: tags
        )
    }
    var seen = Set<String>()
    return mapped.filter { seen.insert($0.id).inserted }
}

private func mapSearchConversations(_ rows: [[String: Any]]) -> [Conversation] {
    var seen = Set<String>()
    return rows.compactMap { item in
        let contact = item["contact"] as? [String: Any]
        let id = contact?.firstString(keys: ["id", "contact_id"])
            ?? item.firstString(keys: ["contact_id", "conversation_id", "id"])
        guard let id, !id.isEmpty, seen.insert(id).inserted else { return nil }
        let name = contact?.firstString(keys: ["name"])
            ?? item.firstString(keys: ["name", "text", "title"])
            ?? "Customer"
        let phone = contact?.firstString(keys: ["phone"])
            ?? item.firstString(keys: ["phone", "wa_id", "number"])
            ?? ""
        let text = item.firstString(keys: ["text", "message", "value"]) ?? ""
        return Conversation(
            id: id,
            customerName: name,
            customerPhone: phone,
            lastMessage: sanitizeConversationPreview(text),
            lastMessageTime: "",
            lastMessageEpochMs: 0,
            satisfaction: .noRating,
            unreadCount: 0,
            status: .open,
            isWindowExpired: false,
            isOnline: false,
            assignedAgentName: nil,
            tags: []
        )
    }
}

private func parseMessageRows(conversationId: String, rows: [[String: Any]]) -> [ChatMessage] {
    var normalizedRows = rows
    if shouldReverseMessageOrder(normalizedRows) {
        normalizedRows.reverse()
    }
    let mapped = normalizedRows.enumerated().compactMap { index, item -> ChatMessage? in
        let kind = item.firstString(keys: ["type", "message_type"]) ?? "text"
        let messageTypeCode = item.firstInt(keys: ["message_type"]) ?? 1
        let isNote = (item.firstInt(keys: ["is_note"]) ?? 0) == 1 || kind == "note"
        let isSystem = item.firstBool(keys: ["is_system", "system"]) == true ||
            {
                let raw = item.firstString(keys: ["type", "message_type", "sender_type", "event_type"])?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() ?? ""
                return raw == "system" || raw == "activity" || raw == "event" || raw == "timeline" || raw == "audit"
            }()
        let media = item.extractMediaPayload()
        let content = item.extractDisplayContent()
        if item.isSkippableEmptyOutgoing(content: content, media: media, messageTypeCode: messageTypeCode) {
            return nil
        }
        let isAgent: Bool = {
            if let explicit = item.firstBool(keys: ["from_me", "is_agent", "agent"]) {
                return explicit
            }
            if let contactFlag = item.firstInt(keys: ["is_message_by_contact"]) {
                return contactFlag == 0
            }
            return item.firstString(keys: ["sender", "sender_type"]) == "agent"
        }()
        return ChatMessage(
            id: item.firstString(keys: ["id", "message_id", "wamid"]) ?? "msg-\(index)",
            conversationId: conversationId,
            content: content,
            timestamp: formatApiDateTime(item.firstString(keys: ["created_at", "time", "timestamp"]) ?? ""),
            type: isSystem ? .system : (isNote ? .note : (media != nil || messageTypeCode != 1 ? .media : .text)),
            sender: isSystem ? .agent : (isAgent ? .agent : .customer),
            status: .read,
            noteAuthor: isNote ? "You" : nil,
            mediaUrl: media?.1,
            mediaKind: media?.0
        )
    }
    return dedupeMessages(mapped)
}

private func dedupeMessages(_ items: [ChatMessage]) -> [ChatMessage] {
    var seen = Set<String>()
    return items.filter { seen.insert($0.id).inserted }
}

private func parseWorkspaceOptions(response: [String: Any], fallbackCompanyId: Int) -> [WorkspaceOption] {
    var result: [WorkspaceOption] = []
    func addWorkspace(_ item: [String: Any]?) {
        guard let item else { return }
        guard let id = item.firstInt(keys: ["company_id", "id"]), id > 0 else { return }
        let name = (item.firstString(keys: ["name", "company_name", "title"]) ?? "Workspace #\(id)")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = name.isEmpty ? "Workspace #\(id)" : name
        if !result.contains(where: { $0.companyId == id }) {
            result.append(WorkspaceOption(companyId: id, name: resolvedName))
        }
    }

    (response["companies"] as? [[String: Any]])?.forEach { addWorkspace($0) }
    if let data = response["data"] as? [String: Any] {
        (data["companies"] as? [[String: Any]])?.forEach { addWorkspace($0) }
        if let merchant = (data["user"] as? [String: Any])?["merchant"] as? [String: Any] {
            addWorkspace(merchant["company"] as? [String: Any])
        }
    }
    if result.isEmpty {
        result = [WorkspaceOption(companyId: fallbackCompanyId, name: "Workspace #\(fallbackCompanyId)")]
    }
    return result
}

private func shouldReverseMessageOrder(_ rows: [[String: Any]]) -> Bool {
    guard rows.count >= 2 else { return false }
    let first = rows[0]
    let last = rows[rows.count - 1]

    if let firstId = first.firstInt(keys: ["id", "message_id"]),
       let lastId = last.firstInt(keys: ["id", "message_id"]) {
        return firstId > lastId
    }

    if let firstTs = first.firstString(keys: ["created_at", "timestamp", "time"]),
       let lastTs = last.firstString(keys: ["created_at", "timestamp", "time"]) {
        let firstEpoch = parseApiEpochMs(firstTs)
        let lastEpoch = parseApiEpochMs(lastTs)
        if firstEpoch > 0, lastEpoch > 0 {
            return firstEpoch > lastEpoch
        }
    }

    return false
}

private func sanitizeConversationPreview(_ raw: String) -> String {
    let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { return raw }
    let lower = text.lowercased()
    let looksLikeURL = lower.hasPrefix("http://") || lower.hasPrefix("https://")
    let isMediaUpload = lower.contains("/uploads/media/")
    if !looksLikeURL && !isMediaUpload { return raw }

    if lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".png") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") {
        return "Photo"
    }
    if lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".mkv") || lower.hasSuffix(".avi") || lower.hasSuffix(".webm") {
        return "Video"
    }
    if lower.hasSuffix(".mp3") || lower.hasSuffix(".m4a") || lower.hasSuffix(".aac") || lower.hasSuffix(".wav") || lower.hasSuffix(".ogg") || lower.hasSuffix(".opus") {
        return "Voice message"
    }
    if lower.hasSuffix(".pdf") || lower.hasSuffix(".doc") || lower.hasSuffix(".docx") || lower.hasSuffix(".xls") || lower.hasSuffix(".xlsx") || lower.hasSuffix(".ppt") || lower.hasSuffix(".pptx") || lower.hasSuffix(".txt") || lower.hasSuffix(".zip") || lower.hasSuffix(".rar") {
        return "Document"
    }
    return "Media"
}

private func parseConversationTags(_ item: [String: Any]) -> [ConversationTag] {
    let source = (item["tags_with_duplicates"] as? [[String: Any]])
        ?? (item["chats_tags"] as? [[String: Any]])
        ?? []
    var seen = Set<Int>()
    return source.compactMap { tag in
        guard let id = tag.firstInt(keys: ["id", "chats_tag_id", "tag_id"]) else { return nil }
        guard seen.insert(id).inserted else { return nil }
        let name = (tag.firstString(keys: ["name", "title"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let colorHex = (tag.firstString(keys: ["color", "hex"]) ?? "#64748B")
        let attachedAt = (tag["pivot"] as? [String: Any])?.firstString(keys: ["created_at"]) ?? tag.firstString(keys: ["created_at"])
        let repeatedRows = (tag["duplicates"] as? [[String: Any]]) ?? []
        let repeatedAt = repeatedRows.compactMap { $0.firstString(keys: ["created_at", "updated_at"]) }
        return ConversationTag(
            id: id,
            name: name,
            colorHex: colorHex.isEmpty ? "#64748B" : colorHex,
            attachedAt: attachedAt,
            repeatedAt: repeatedAt
        )
    }
}

private func formatApiDateTime(_ value: String) -> String {
    let raw = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if raw.isEmpty { return value }

    let output = DateFormatter()
    output.dateFormat = "h:mm a"
    output.locale = Locale(identifier: "en_US_POSIX")
    output.timeZone = TimeZone(identifier: "Asia/Riyadh")

    let inputPatterns = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss'Z'"
    ]

    for pattern in inputPatterns {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = pattern
        if let date = formatter.date(from: raw) {
            return output.string(from: date)
        }
    }
    return value
}

private func parseApiEpochMs(_ value: String) -> Int64 {
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

private func parseConversationSatisfaction(_ item: [String: Any]) -> ConversationSatisfaction {
    let lastRatingRaw = (item["last_rating"] as? [String: Any])?.firstString(keys: ["rating", "status", "label", "name"])
        ?? (item["last_rating_data"] as? [String: Any])?.firstString(keys: ["rating", "status", "label", "name"])
    let top = item.firstString(keys: [
        "satisfaction",
        "satisfaction_status",
        "customer_satisfaction",
        "rating_label",
        "csat",
        "sentiment"
    ])
    let nested = (item["rating"] as? [String: Any])?.firstString(keys: ["status", "label", "name"])
        ?? (item["satisfaction"] as? [String: Any])?.firstString(keys: ["status", "label", "name"])
    let numeric = (item["rating"] as? [String: Any])?.firstInt(keys: ["value", "score", "rating"])
        ?? (item["satisfaction"] as? [String: Any])?.firstInt(keys: ["value", "score", "rating"])
        ?? item.firstInt(keys: ["rating", "rating_value"])
    if let numeric {
        if numeric >= 4 { return .satisfied }
        if numeric == 3 { return .neutral }
        if (1...2).contains(numeric) { return .unsatisfied }
    }
    let raw = (lastRatingRaw ?? nested ?? top ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if raw.isEmpty || raw == "all" || raw == "none" || raw == "null" {
        return .noRating
    }
    if raw.contains("satisfied") || raw == "happy" || raw == "positive" || raw == "1" {
        return .satisfied
    }
    if raw.contains("neutral") || raw == "0" || raw == "normal" {
        return .neutral
    }
    if raw.contains("unsatisfied") || raw.contains("angry") || raw == "-1" || raw == "negative" {
        return .unsatisfied
    }
    return .noRating
}

