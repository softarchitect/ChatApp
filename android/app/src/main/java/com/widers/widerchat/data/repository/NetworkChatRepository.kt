package com.widers.widerchat.data.repository

import com.widers.widerchat.BuildConfig
import com.widers.widerchat.data.remote.SessionContext
import com.widers.widerchat.data.remote.WidersApiService
import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationSatisfaction
import com.widers.widerchat.domain.model.ConversationTag
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.domain.model.MessageDeliveryStatus
import com.widers.widerchat.domain.model.MessageSender
import com.widers.widerchat.domain.model.MessageType
import com.widers.widerchat.domain.model.AvailableTag
import com.widers.widerchat.domain.model.WorkspaceOption
import com.widers.widerchat.domain.repository.ChatRepository
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

class NetworkChatRepository(
    private val api: WidersApiService = WidersApiService(BuildConfig.API_BASE_URL)
) : ChatRepository {
    data class ConversationsRequestFilters(
        val status: String = "all",
        val tag: String = "all",
        val agent: String = "all",
        val rating: String = "all",
        val tap: String = "all",
        val orderBy: String = "default"
    )

    private data class MessagePagingState(
        val pageSize: Int = 60,
        var nextPage: Int = 1,
        var hasMore: Boolean = true,
        var isLoading: Boolean = false,
        var loaded: List<ChatMessage> = emptyList()
    )

    private var session: SessionContext? = null
    private var cacheConversations: List<Conversation> = emptyList()
    private var cacheContactsById: Map<String, String> = emptyMap()
    private var sessionUserName: String? = null
    private var sessionUserEmail: String? = null
    private var sessionWorkspaces: List<WorkspaceOption> = emptyList()
    private var conversationsNextPage: Int = 1
    private var conversationsHasMore: Boolean = true
    private var conversationsPageSize: Int = 30
    private var conversationsLoading: Boolean = false
    private var conversationsFilters: ConversationsRequestFilters = ConversationsRequestFilters()
    private var latestRegisteredPushToken: String? = null
    private val messagePagingByConversation = mutableMapOf<String, MessagePagingState>()

    override suspend fun login(email: String, password: String): Boolean {
        val response = api.login(email, password)
        val token = response.firstString("token", "access_token", "api_token")
            ?: response.firstObject("data", "user")?.firstString("token", "access_token", "api_token")
        val companyId = response.firstLong("company_id")
            ?: response.firstObject("data", "user", "merchant", "company")?.firstLong("company_id", "id")
            ?: response.firstArray("companies")?.optJSONObject(0)?.firstLong("company_id", "id")
            ?: response.firstObject("data")?.firstArray("companies")?.optJSONObject(0)?.firstLong("company_id", "id")

        if (token.isNullOrBlank() || companyId == null) {
            return false
        }
        session = SessionContext(token = token, companyId = companyId)
        sessionWorkspaces = parseWorkspaceOptions(response, companyId)
        val data = response.optJSONObject("data")
        val user = response.optJSONObject("user")
            ?: data?.optJSONObject("user")
            ?: response.optJSONObject("data_user")
        val firstCompany = response.firstArray("companies")?.optJSONObject(0)
            ?: data?.optJSONArray("companies")?.optJSONObject(0)
        val merchant = user?.optJSONObject("merchant")
            ?: data?.optJSONObject("merchant")
            ?: response.optJSONObject("merchant")
        val responseName = response.firstString("name", "full_name", "username")
        sessionUserName = user?.firstString("name", "full_name", "username")
            ?: responseName
            ?: firstCompany?.firstString("name", "company_name")
            ?: merchant?.firstString("name", "company_name")
            ?: email.substringBefore("@").trim().replaceFirstChar { it.uppercaseChar() }
        val responseEmail = response.firstString("email", "user_email")
            ?: responseName?.takeIf { it.contains("@") }
        sessionUserEmail = user?.firstString("email", "user_email")
            ?: responseEmail
            ?: response.firstString("email")
            ?: email.trim()
        return true
    }

    override suspend fun getConversations(): List<Conversation> {
        if (cacheConversations.isNotEmpty()) return cacheConversations
        return refreshConversationsFirstPage()
    }

    suspend fun refreshConversationsFirstPage(
        filters: ConversationsRequestFilters = ConversationsRequestFilters()
    ): List<Conversation> {
        val activeSession = session ?: return emptyList()
        conversationsFilters = filters
        conversationsNextPage = 1
        conversationsHasMore = true
        cacheConversations = emptyList()
        val response = api.getChatsList(
            activeSession,
            page = conversationsNextPage,
            limit = conversationsPageSize,
            status = conversationsFilters.status,
            tag = conversationsFilters.tag,
            agent = conversationsFilters.agent,
            rating = conversationsFilters.rating,
            tap = conversationsFilters.tap,
            orderBy = conversationsFilters.orderBy
        )
        val pageItems = response.firstArray("conversations", "chats", "data", "rows", "result")
            ?: emptyArrayFrom(response)
        val parsed = parseConversationRows(pageItems)
        cacheConversations = parsed.distinctBy { it.id }
        conversationsHasMore = hasMorePages(
            response = response,
            fetchedCount = parsed.size,
            pageSize = conversationsPageSize
        )
        conversationsNextPage = if (conversationsHasMore) 2 else 1
        return cacheConversations
    }

    suspend fun loadMoreConversationsPage(
        filters: ConversationsRequestFilters? = null
    ): List<Conversation> {
        val activeSession = session ?: return cacheConversations
        val activeFilters = filters ?: conversationsFilters
        if (filters != null) {
            conversationsFilters = filters
        }
        if (!conversationsHasMore || conversationsLoading) return cacheConversations
        conversationsLoading = true
        try {
            val response = api.getChatsList(
                activeSession,
                page = conversationsNextPage,
                limit = conversationsPageSize,
                status = activeFilters.status,
                tag = activeFilters.tag,
                agent = activeFilters.agent,
                rating = activeFilters.rating,
                tap = activeFilters.tap,
                orderBy = activeFilters.orderBy
            )
            val pageItems = response.firstArray("conversations", "chats", "data", "rows", "result")
                ?: emptyArrayFrom(response)
            val parsed = parseConversationRows(pageItems)
            if (parsed.isEmpty()) {
                conversationsHasMore = false
                return cacheConversations
            }
            val merged = (cacheConversations + parsed).distinctBy { it.id }
            cacheConversations = merged
            conversationsHasMore = hasMorePages(
                response = response,
                fetchedCount = parsed.size,
                pageSize = conversationsPageSize
            )
            if (conversationsHasMore) conversationsNextPage += 1
            return cacheConversations
        } finally {
            conversationsLoading = false
        }
    }

    override suspend fun getMessages(conversationId: String): List<ChatMessage> {
        val state = messagePagingByConversation[conversationId]
        if (state != null && state.loaded.isNotEmpty()) return state.loaded
        return refreshMessagesFirstPage(conversationId)
    }

    suspend fun refreshMessagesFirstPage(conversationId: String, resetLoaded: Boolean = false): List<ChatMessage> {
        val activeSession = session ?: return emptyList()
        val contactId = conversationId.toLongOrNull() ?: return emptyList()
        val existing = messagePagingByConversation[conversationId]
        val pageSize = existing?.pageSize ?: 60
        val previous = if (resetLoaded) emptyList() else existing?.loaded.orEmpty()
        var merged = previous
        var cursorAfterId = previous.maxNumericMessageId()

        if (previous.isEmpty()) {
            val seedResponse = api.getChatMessages(
                activeSession,
                contactId = contactId,
                page = 1,
                limit = pageSize
            )
            val seedItems = seedResponse.firstArray("messages", "data", "rows", "result") ?: emptyArrayFrom(seedResponse)
            val seedParsed = parseMessageRows(conversationId, seedItems)
            merged = seedParsed.distinctBy { it.id }
            cursorAfterId = merged.maxNumericMessageId()
        }

        while (cursorAfterId != null) {
            val response = api.getChatMessages(
                activeSession,
                contactId = contactId,
                afterId = cursorAfterId
            )
            val pageItems = response.firstArray("messages", "data", "rows", "result") ?: emptyArrayFrom(response)
            val parsed = parseMessageRows(conversationId, pageItems)
            if (parsed.isEmpty()) break
            val nextMerged = (merged + parsed).distinctBy { it.id }
            val nextCursor = nextMerged.maxNumericMessageId()
            merged = nextMerged
            if (nextCursor == null || nextCursor == cursorAfterId) break
            cursorAfterId = nextCursor
        }

        messagePagingByConversation[conversationId] = MessagePagingState(
            pageSize = pageSize,
            nextPage = 1,
            hasMore = false,
            isLoading = false,
            loaded = merged
        )
        return merged
    }

    suspend fun loadOlderMessagesPage(conversationId: String): List<ChatMessage> {
        if (!messagePagingByConversation.containsKey(conversationId)) return emptyList()
        val state = messagePagingByConversation.getOrPut(conversationId) { MessagePagingState() }
        state.hasMore = false
        return state.loaded
    }

    override suspend fun appendMessage(message: ChatMessage) {
        val activeSession = session ?: return
        val phone = cacheConversations.firstOrNull { it.id == message.conversationId }?.customerPhone
            ?: cacheContactsById[message.conversationId]
            ?: return
        api.sendMessageMedia(
            session = activeSession,
            phone = phone,
            fileName = null,
            fileBytes = null,
            text = message.content
        )
    }

    suspend fun sendMediaMessage(
        conversationId: String,
        fileName: String,
        fileBytes: ByteArray,
        text: String? = null
    ) {
        val activeSession = session ?: return
        val phone = cacheConversations.firstOrNull { it.id == conversationId }?.customerPhone
            ?: cacheContactsById[conversationId]
            ?: return
        api.sendMessageMedia(
            session = activeSession,
            phone = phone,
            fileName = fileName,
            fileBytes = fileBytes,
            text = text
        )
    }

    override suspend fun updateConversationStatus(conversationId: String, status: ConversationStatus) {
        val activeSession = session ?: return
        val contactId = conversationId.toLongOrNull() ?: return
        api.updateOpenStatus(
            session = activeSession,
            contactId = contactId,
            status = status == ConversationStatus.OPEN
        )
    }

    override suspend fun addNote(conversationId: String, note: String) {
        val activeSession = session ?: return
        val contactId = conversationId.toLongOrNull() ?: return
        api.addNote(activeSession, contactId, note)
    }

    override suspend fun registerPushToken(token: String, platform: String): Boolean {
        val activeSession = session ?: return false
        val normalized = token.trim()
        if (normalized.isBlank()) return false
        if (latestRegisteredPushToken == normalized) return true
        return try {
            api.registerPushToken(
                session = activeSession,
                pushToken = normalized
            )
            latestRegisteredPushToken = normalized
            true
        } catch (_: Exception) {
            false
        }
    }

    // Full endpoint coverage from Postman collection.
    suspend fun getContactsPage(page: Int, limit: Int = 25): JSONObject? {
        val activeSession = session ?: return null
        val payload = api.getContactsList(activeSession, page = page, limit = limit)
        val rows = payload.firstArray("contacts", "data", "rows", "result") ?: JSONArray()
        if (rows.length() > 0) {
            val cache = cacheContactsById.toMutableMap()
            for (i in 0 until rows.length()) {
                val item = rows.optJSONObject(i) ?: continue
                val id = item.firstString("id", "contact_id") ?: continue
                val phone = item.firstString("phone", "wa_id", "number") ?: continue
                if (phone.isNotBlank()) cache[id] = phone
            }
            cacheContactsById = cache
        }
        return payload
    }

    // Backward-compatible helper used by sync actions.
    suspend fun getContacts(): JSONObject? {
        val payload = getContactsPage(page = 1, limit = 25) ?: return null
        val rows = payload.firstArray("contacts", "data", "rows", "result") ?: JSONArray()
        val cache = cacheContactsById.toMutableMap()
        for (i in 0 until rows.length()) {
            val item = rows.optJSONObject(i) ?: continue
            val id = item.firstString("id", "contact_id") ?: continue
            val phone = item.firstString("phone", "wa_id", "number") ?: continue
            if (phone.isNotBlank()) cache[id] = phone
        }
        cacheContactsById = cache
        return JSONObject().put("contacts", rows)
    }
    suspend fun getTemplates() = session?.let(api::getTemplatesList)
    suspend fun getTags() = session?.let(api::getTagsList)
    suspend fun listAvailableTags(): List<AvailableTag> {
        val response = getTags() ?: return emptyList()
        val items = response.firstArray("tags", "data", "rows", "result") ?: return emptyList()
        return buildList {
            for (i in 0 until items.length()) {
                val item = items.optJSONObject(i) ?: continue
                val id = item.firstLong("id", "tag_id") ?: continue
                val name = item.firstString("name", "title")?.trim().orEmpty()
                if (name.isBlank()) continue
                val color = item.firstString("color", "hex", "tag_color").orEmpty().ifBlank { "#64748B" }
                add(AvailableTag(id = id, name = name, colorHex = color))
            }
        }
    }
    suspend fun getReplies() = session?.let(api::getRepliesList)
    suspend fun getFlows() = session?.let(api::getFlowsList)
    suspend fun getAgents() = session?.let(api::getAgentsList)
    suspend fun getContactCustomFields(contactId: Long) = session?.let { api.getContactCustomFields(it, contactId) }
    suspend fun syncContactCustomFields(contactId: Long, custom: JSONObject) = session?.let { api.syncContactCustomFields(it, contactId, custom) }
    suspend fun attachTag(contactId: Long, tagId: Long) = session?.let { api.attachTagToChat(it, contactId, tagId) }
    suspend fun detachTag(contactId: Long, tagId: Long) = session?.let { api.detachTagFromChat(it, contactId, tagId) }
    suspend fun searchChats(keyword: String, page: Int, limit: Int) = session?.let { api.searchChats(it, keyword, page, limit) }
    suspend fun searchConversations(keyword: String, page: Int = 1, limit: Int = 50): List<Conversation> {
        val payload = searchChats(keyword, page, limit) ?: return emptyList()
        val searchRows = payload.firstArray("search")
        if (searchRows != null && searchRows.length() > 0) {
            return parseSearchRows(searchRows)
        }
        val rows = payload.firstArray("conversations", "chats", "data", "rows", "result")
            ?: emptyArrayFrom(payload)
        return parseConversationRows(rows)
    }
    suspend fun sendTemplate(contactId: Long, templateId: Long) = session?.let { api.sendTemplateMessage(it, contactId, templateId) }
    suspend fun sendFlow(contactId: Long, flowId: Long) = session?.let { api.sendFlow(it, contactId, flowId) }
    suspend fun assignAgent(contactId: Long, agent: Long) = session?.let { api.assignAgent(it, contactId, agent) }
    suspend fun unassignAgent(contactId: Long) = session?.let { api.unassignAgent(it, contactId) }
    suspend fun updateMute(contactId: Long, status: Boolean) = session?.let { api.updateMuteStatus(it, contactId, status) }
    suspend fun updateRead(contactId: Long, status: Boolean) = session?.let { api.updateReadStatus(it, contactId, status) }
    suspend fun deleteChat(contactId: Long) = session?.let { api.deleteChat(it, contactId) }
    suspend fun addContact(name: String, phone: String, email: String?) = session?.let { api.addContact(it, name, phone, email) }
    suspend fun searchContacts(query: String) = session?.let { api.searchContacts(it, query) }
    suspend fun updateContact(contactId: Long, name: String, phone: String, email: String?) =
        session?.let { api.updateContact(it, contactId, name, phone, email) }

    suspend fun createOrUpdateTag(name: String, color: String, tagId: Long?) =
        session?.let { api.createOrUpdateTag(it, name, color, tagId) }

    suspend fun createOrUpdateReply(name: String, text: String, replyId: Long?) =
        session?.let { api.createOrUpdateReply(it, name, text, replyId) }

    fun currentSessionSnapshot(): SessionContext? = session

    fun restoreSession(token: String, companyId: Long) {
        session = SessionContext(token = token, companyId = companyId)
        if (sessionWorkspaces.none { it.companyId == companyId }) {
            sessionWorkspaces = listOf(
                WorkspaceOption(companyId = companyId, name = "Workspace #$companyId")
            )
        }
    }

    fun currentUserSnapshot(): Pair<String?, String?> = sessionUserName to sessionUserEmail

    fun availableWorkspacesSnapshot(): List<WorkspaceOption> = sessionWorkspaces

    fun currentCompanyIdSnapshot(): Long? = session?.companyId

    fun hasMoreConversationsSnapshot(): Boolean = conversationsHasMore

    fun isLoadingMoreConversationsSnapshot(): Boolean = conversationsLoading

    fun hasMoreMessagesSnapshot(conversationId: String): Boolean =
        messagePagingByConversation[conversationId]?.hasMore ?: false

    fun isLoadingMoreMessagesSnapshot(conversationId: String): Boolean =
        messagePagingByConversation[conversationId]?.isLoading ?: false

    fun switchWorkspace(companyId: Long): Boolean {
        val active = session ?: return false
        if (companyId <= 0L || active.companyId == companyId) return false
        session = active.copy(companyId = companyId)
        cacheConversations = emptyList()
        cacheContactsById = emptyMap()
        messagePagingByConversation.clear()
        conversationsNextPage = 1
        conversationsHasMore = true
        conversationsLoading = false
        latestRegisteredPushToken = null
        return true
    }
}

private fun hasMorePages(
    response: JSONObject,
    fetchedCount: Int,
    pageSize: Int
): Boolean {
    val pagination = extractPagination(response)
    if (pagination != null) {
        return pagination.first < pagination.second
    }
    return fetchedCount >= pageSize
}

private fun extractPagination(response: JSONObject): Pair<Int, Int>? {
    extractPaginationFromObject(response)?.let { return it }
    response.optJSONObject("data")?.let { extractPaginationFromObject(it)?.let { p -> return p } }
    response.optJSONObject("meta")?.let { extractPaginationFromObject(it)?.let { p -> return p } }
    response.optJSONObject("pagination")?.let { extractPaginationFromObject(it)?.let { p -> return p } }
    return null
}

private fun extractPaginationFromObject(obj: JSONObject): Pair<Int, Int>? {
    val current = obj.firstIntOrNull("current_page", "page")
    val total = obj.firstIntOrNull("total_pages", "last_page", "pages_count")
    if (current == null || total == null || total <= 0) return null
    return current to total
}

private fun parseMessageRows(conversationId: String, items: JSONArray): List<ChatMessage> {
    val indices = if (shouldReverseMessageOrder(items)) {
        (items.length() - 1 downTo 0).toList()
    } else {
        (0 until items.length()).toList()
    }
    return buildList {
        for (i in indices) {
            val item = items.optJSONObject(i) ?: continue
            val messageId = item.firstString("id", "message_id", "wamid") ?: "msg-$i"
            val content = item.extractDisplayContent()
            val messageTypeCode = item.firstInt("message_type")
            val isNote = (item.firstInt("is_note") == 1) || item.firstString("type", "message_type") == "note"
            val isSystem = item.firstBoolean("is_system", "system") == true ||
                item.firstString("type", "message_type", "sender_type", "event_type")
                    ?.trim()
                    ?.lowercase(Locale.US)
                    ?.let { value ->
                        value == "system" || value == "activity" || value == "event" ||
                            value == "timeline" || value == "audit"
                    } == true
            val media = item.extractMediaPayload()
            if (item.isSkippableEmptyOutgoing(content = content, media = media, messageTypeCode = messageTypeCode)) {
                continue
            }
            val messageType = when {
                isSystem -> MessageType.SYSTEM
                isNote -> MessageType.NOTE
                media != null || messageTypeCode in setOf(2, 3, 4, 5, 6, 7) -> MessageType.IMAGE
                else -> MessageType.TEXT
            }
            val isAgent = item.firstBoolean("from_me", "is_agent", "agent")
                ?: (item.firstInt("is_message_by_contact") == 0)
                ?: (item.firstString("sender_type", "sender") in setOf("agent", "admin"))
            add(
                ChatMessage(
                    id = messageId,
                    conversationId = conversationId,
                    content = content,
                    timestamp = item.firstString("created_at", "time", "timestamp")
                        ?.let(::formatApiDateTime)
                        .orEmpty(),
                    type = messageType,
                    sender = when {
                        messageType == MessageType.SYSTEM -> MessageSender.AGENT
                        isAgent -> MessageSender.AGENT
                        else -> MessageSender.CUSTOMER
                    },
                    status = MessageDeliveryStatus.READ,
                    noteAuthor = if (messageType == MessageType.NOTE) "You" else null,
                    mediaUrl = media?.second,
                    mediaKind = media?.first
                )
            )
        }
    }
}

private fun List<ChatMessage>.maxNumericMessageId(): Long? =
    asSequence().mapNotNull { it.id.toLongOrNull() }.maxOrNull()

private fun parseWorkspaceOptions(response: JSONObject, fallbackCompanyId: Long): List<WorkspaceOption> {
    val result = buildList {
        fun addWorkspace(item: JSONObject?) {
            val id = item?.firstLong("company_id", "id") ?: return
            if (id <= 0L) return
            val name = item.firstString("name", "company_name", "title")
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
                ?: "Workspace #$id"
            add(WorkspaceOption(companyId = id, name = name))
        }

        val top = response.firstArray("companies")
        if (top != null) {
            for (i in 0 until top.length()) addWorkspace(top.optJSONObject(i))
        }
        val nested = response.firstObject("data")?.firstArray("companies")
        if (nested != null) {
            for (i in 0 until nested.length()) addWorkspace(nested.optJSONObject(i))
        }
        val merchantCompany = response.firstObject("data", "user", "merchant", "company")
        addWorkspace(merchantCompany)
    }.distinctBy { it.companyId }

    if (result.isNotEmpty()) return result
    return listOf(WorkspaceOption(companyId = fallbackCompanyId, name = "Workspace #$fallbackCompanyId"))
}

private fun parseConversationRows(items: JSONArray): List<Conversation> = buildList {
    for (i in 0 until items.length()) {
        val item = items.optJSONObject(i) ?: continue
        val id = item.firstString("contact_id", "id", "conversation_id") ?: continue
        val customerName = item.firstString("name", "customer_name", "contact_name", "title") ?: "Customer"
        val phone = item.firstString("phone", "contact_phone", "wa_id", "number").orEmpty()
        val lastMessageRaw = item.firstString("last_message", "last_value", "value", "text", "body").orEmpty()
        val lastMessage = sanitizeConversationPreview(lastMessageRaw)
        val rawLastTime = item.firstString("updated_at", "last_reply_at", "last_message_time", "created_at", "time").orEmpty()
        val lastMessageTime = rawLastTime.let(::formatApiDateTime)
        val lastMessageEpochMs = parseApiEpochMillis(rawLastTime)
        val statusObj = item.optJSONObject("chats_status")
        val isReaded = statusObj?.firstBoolean("is_readed")
            ?: item.firstBoolean("is_readed")
        val rawUnread = item.firstInt("unread_messages", "unread_count", "unread").coerceAtLeast(0)
        val unreadCount = when (isReaded) {
            true -> 0
            false -> if (rawUnread > 0) rawUnread else 1
            null -> rawUnread
        }
        val isOpen = statusObj?.firstBoolean("is_open")
            ?: item.firstBoolean("open", "is_open")
            ?: (item.firstString("status") != "closed")
        val agentName = item.optJSONObject("agent")
            ?.firstString("name", "full_name", "username")
        val tags = parseConversationTags(item)
        val satisfaction = parseConversationSatisfaction(item)
        val isWindowExpired = item.firstBoolean(
            "is_window_expired",
            "window_expired",
            "is_24h_expired",
            "expired_24h",
            "meta_window_expired"
        ) ?: false

        add(
            Conversation(
                id = id,
                customerName = customerName,
                customerPhone = phone,
                lastMessage = lastMessage,
                lastMessageTime = lastMessageTime,
                lastMessageEpochMs = lastMessageEpochMs,
                unreadCount = unreadCount,
                status = if (isOpen) ConversationStatus.OPEN else ConversationStatus.CLOSED,
                isWindowExpired = isWindowExpired,
                isOnline = item.firstBoolean("is_online", "online") ?: false,
                assignedAgentName = agentName,
                tags = tags,
                satisfaction = satisfaction
            )
        )
    }
}

private fun parseConversationSatisfaction(item: JSONObject): ConversationSatisfaction {
    val lastRatingRaw = item.optJSONObject("last_rating")?.firstString("rating", "status", "label", "name")
        ?: item.optJSONObject("last_rating_data")?.firstString("rating", "status", "label", "name")
    val top = item.firstString(
        "satisfaction",
        "satisfaction_status",
        "customer_satisfaction",
        "rating_label",
        "csat",
        "sentiment"
    )
    val nested = item.optJSONObject("rating")?.firstString("status", "label", "name")
        ?: item.optJSONObject("satisfaction")?.firstString("status", "label", "name")
    val numeric = item.optJSONObject("rating")?.firstInt("value", "score", "rating")
        ?: item.optJSONObject("satisfaction")?.firstInt("value", "score", "rating")
        ?: item.firstInt("rating", "rating_value").takeIf { it != 0 }
    if (numeric != null) {
        return when {
            numeric >= 4 -> ConversationSatisfaction.SATISFIED
            numeric == 3 -> ConversationSatisfaction.NEUTRAL
            numeric in 1..2 -> ConversationSatisfaction.UNSATISFIED
            else -> ConversationSatisfaction.NO_RATING
        }
    }
    val raw = (lastRatingRaw ?: nested ?: top).orEmpty().trim().lowercase(Locale.US)
    if (raw.isBlank() || raw == "all" || raw == "none" || raw == "null") {
        return ConversationSatisfaction.NO_RATING
    }
    return when {
        raw.contains("satisfied") || raw == "happy" || raw == "positive" || raw == "1" -> ConversationSatisfaction.SATISFIED
        raw.contains("neutral") || raw == "0" || raw == "normal" -> ConversationSatisfaction.NEUTRAL
        raw.contains("unsatisfied") || raw.contains("angry") || raw == "-1" || raw == "negative" -> ConversationSatisfaction.UNSATISFIED
        else -> ConversationSatisfaction.NO_RATING
    }
}

private fun parseConversationTags(item: JSONObject): List<ConversationTag> {
    val withDuplicates = item.optJSONArray("tags_with_duplicates")
    val fallback = item.optJSONArray("chats_tags")
    val source = withDuplicates ?: fallback ?: return emptyList()
    return buildList {
        for (i in 0 until source.length()) {
            val tag = source.optJSONObject(i) ?: continue
            val id = tag.firstLong("id", "chats_tag_id", "tag_id") ?: continue
            val name = tag.firstString("name", "title")?.trim().orEmpty()
            if (name.isBlank()) continue
            val colorHex = tag.firstString("color", "hex").orEmpty().ifBlank { "#64748B" }
            val attachedAtRaw = tag.optJSONObject("pivot")?.firstString("created_at")
                ?: tag.firstString("created_at")
            val repeated = tag.optJSONArray("duplicates")
            val repeatedAt = buildList {
                if (repeated != null) {
                    for (r in 0 until repeated.length()) {
                        val d = repeated.optJSONObject(r) ?: continue
                        val at = d.firstString("created_at", "updated_at") ?: continue
                        add(at)
                    }
                }
            }
            add(
                ConversationTag(
                    id = id,
                    name = name,
                    colorHex = colorHex,
                    attachedAt = attachedAtRaw,
                    repeatedAt = repeatedAt
                )
            )
        }
    }.distinctBy { it.id }
}

private fun JSONObject.firstObject(vararg keys: String): JSONObject? {
    keys.forEach { key ->
        val obj = optJSONObject(key)
        if (obj != null) return obj
    }
    return null
}

private fun JSONObject.firstArray(vararg keys: String): JSONArray? {
    keys.forEach { key ->
        val arr = optJSONArray(key)
        if (arr != null) return arr
    }
    return null
}

private fun JSONObject.firstString(vararg keys: String): String? {
    keys.forEach { key ->
        val value = optString(key, "")
        if (value.isNotBlank()) return value
    }
    return null
}

private fun JSONObject.firstLong(vararg keys: String): Long? {
    keys.forEach { key ->
        if (!has(key)) return@forEach
        val value = opt(key)
        val number = when (value) {
            is Number -> value.toLong()
            is String -> value.toLongOrNull()
            else -> null
        }
        if (number != null) return number
    }
    return null
}

private fun JSONObject.firstInt(vararg keys: String): Int {
    keys.forEach { key ->
        if (!has(key)) return@forEach
        val value = opt(key)
        val number = when (value) {
            is Number -> value.toInt()
            is String -> value.toIntOrNull()
            else -> null
        }
        if (number != null) return number
    }
    return 0
}

private fun JSONObject.firstIntOrNull(vararg keys: String): Int? {
    keys.forEach { key ->
        if (!has(key)) return@forEach
        val value = opt(key)
        val number = when (value) {
            is Number -> value.toInt()
            is String -> value.toIntOrNull()
            else -> null
        }
        if (number != null) return number
    }
    return null
}

private fun JSONObject.firstBoolean(vararg keys: String): Boolean? {
    keys.forEach { key ->
        if (!has(key)) return@forEach
        val value = opt(key)
        val result = when (value) {
            is Boolean -> value
            is Number -> value.toInt() == 1
            is String -> value.equals("true", ignoreCase = true) || value == "1"
            else -> null
        }
        if (result != null) return result
    }
    return null
}

private fun emptyArrayFrom(response: JSONObject): JSONArray {
    val dataArray = response.optJSONArray("data")
    if (dataArray != null) return dataArray
    val payload = response.opt("data")
    if (payload is JSONObject) {
        val items = payload.optJSONArray("items")
        if (items != null) return items
    }
    return JSONArray()
}

private fun formatApiDateTime(raw: String): String {
    val value = raw.trim()
    if (value.isEmpty()) return raw
    val timeOnlyOutput = SimpleDateFormat("h:mm a", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("Asia/Riyadh")
    }
    val fullOutput = SimpleDateFormat("MMM d, h:mm a", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("Asia/Riyadh")
    }
    val zone = TimeZone.getTimeZone("Asia/Riyadh")
    val calendar = java.util.Calendar.getInstance(zone)
    val inputPatterns = listOf(
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss'Z'"
    )
    inputPatterns.forEach { pattern ->
        try {
            val input = SimpleDateFormat(pattern, Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }
            val date = input.parse(value) ?: return@forEach
            val dateCal = java.util.Calendar.getInstance(zone).apply { time = date }
            val isToday = dateCal.get(java.util.Calendar.YEAR) == calendar.get(java.util.Calendar.YEAR) &&
                dateCal.get(java.util.Calendar.DAY_OF_YEAR) == calendar.get(java.util.Calendar.DAY_OF_YEAR)
            return if (isToday) timeOnlyOutput.format(date) else fullOutput.format(date)
        } catch (_: Exception) {
            // Try next known pattern.
        }
    }
    return raw
}

private fun parseApiEpochMillis(raw: String): Long {
    val value = raw.trim()
    if (value.isEmpty()) return 0L
    val inputPatterns = listOf(
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss'Z'"
    )
    inputPatterns.forEach { pattern ->
        try {
            val input = SimpleDateFormat(pattern, Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }
            val date = input.parse(value) ?: return@forEach
            return date.time
        } catch (_: Exception) {
        }
    }
    return 0L
}

private fun JSONObject.extractDisplayContent(): String {
    firstString("value", "text", "body", "message", "caption", "original_message", "last_message", "note")
        ?.takeIf { it.isNotBlank() }
        ?.let { return it }
    firstString("action", "event", "activity", "title", "description")
        ?.takeIf { it.isNotBlank() }
        ?.let { return it }

    val audio = firstString("header_audio")
    if (audio.isMeaningfulMediaValue()) return "[Audio message]"
    val image = firstString("header_image")
    if (image.isMeaningfulMediaValue()) return "[Image]"
    val video = firstString("header_video")
    if (video.isMeaningfulMediaValue()) return "[Video]"
    val document = firstString("header_document")
    if (document.isMeaningfulMediaValue()) return "[Document]"
    val location = firstString("header_location")
    if (location.isMeaningfulMediaValue()) return "[Location]"

    val buttonsRaw = firstString("buttons")
    if (!buttonsRaw.isNullOrBlank() && buttonsRaw != "[]") return "[Interactive message]"
    val componentsRaw = firstString("components")
    if (!componentsRaw.isNullOrBlank()) return "[Interactive message]"

    return "[Unsupported message]"
}

private fun JSONObject.extractMediaPayload(): Pair<String, String>? {
    val audio = firstString("header_audio")
    if (audio.isMeaningfulMediaValue()) return "audio" to audio!!
    val image = firstString("header_image")
    if (image.isMeaningfulMediaValue()) return "image" to image!!
    val video = firstString("header_video")
    if (video.isMeaningfulMediaValue()) return "video" to video!!
    val document = firstString("header_document")
    if (document.isMeaningfulMediaValue()) return "document" to document!!
    val location = firstString("header_location")
    if (location.isMeaningfulMediaValue()) return "location" to location!!
    return null
}

private fun JSONObject.isSkippableEmptyOutgoing(
    content: String,
    media: Pair<String, String>?,
    messageTypeCode: Int
): Boolean {
    if (content != "[Unsupported message]") return false
    if (media != null) return false
    if (messageTypeCode != 1) return false
    val isOutgoing = firstBoolean("from_me", "is_agent", "agent")
        ?: (firstInt("is_message_by_contact") == 0)
    return isOutgoing == true
}

private fun shouldReverseMessageOrder(items: JSONArray): Boolean {
    if (items.length() < 2) return false
    val first = items.optJSONObject(0) ?: return false
    val last = items.optJSONObject(items.length() - 1) ?: return false

    val firstId = first.firstLong("id", "message_id")
    val lastId = last.firstLong("id", "message_id")
    if (firstId != null && lastId != null) {
        return firstId > lastId
    }

    val firstTs = first.firstString("created_at", "timestamp", "time")
    val lastTs = last.firstString("created_at", "timestamp", "time")
    if (!firstTs.isNullOrBlank() && !lastTs.isNullOrBlank()) {
        val firstEpoch = parseApiEpochMillis(firstTs)
        val lastEpoch = parseApiEpochMillis(lastTs)
        if (firstEpoch > 0L && lastEpoch > 0L) {
            return firstEpoch > lastEpoch
        }
    }

    return false
}

private fun String?.isMeaningfulMediaValue(): Boolean {
    val value = this?.trim().orEmpty()
    if (value.isBlank()) return false
    val lowered = value.lowercase(Locale.US)
    return lowered != "null" && lowered != "[]" && lowered != "{}"
}

private fun sanitizeConversationPreview(raw: String): String {
    val text = raw.trim()
    if (text.isEmpty()) return raw
    val lower = text.lowercase(Locale.US)
    val looksLikeUrl = lower.startsWith("http://") || lower.startsWith("https://")
    val isMediaUpload = "/uploads/media/" in lower
    if (!looksLikeUrl && !isMediaUpload) return raw

    return when {
        lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".png") || lower.endsWith(".gif") || lower.endsWith(".webp") -> "Photo"
        lower.endsWith(".mp4") || lower.endsWith(".mov") || lower.endsWith(".mkv") || lower.endsWith(".avi") || lower.endsWith(".webm") -> "Video"
        lower.endsWith(".mp3") || lower.endsWith(".m4a") || lower.endsWith(".aac") || lower.endsWith(".wav") || lower.endsWith(".ogg") || lower.endsWith(".opus") -> "Voice message"
        lower.endsWith(".pdf") || lower.endsWith(".doc") || lower.endsWith(".docx") || lower.endsWith(".xls") || lower.endsWith(".xlsx") || lower.endsWith(".ppt") || lower.endsWith(".pptx") || lower.endsWith(".txt") || lower.endsWith(".zip") || lower.endsWith(".rar") -> "Document"
        else -> "Media"
    }
}

private fun parseSearchRows(items: JSONArray): List<Conversation> = buildList {
    for (i in 0 until items.length()) {
        val item = items.optJSONObject(i) ?: continue
        val nestedContact = item.optJSONObject("contact")
        val id = nestedContact?.firstString("id", "contact_id")
            ?: item.firstString("contact_id", "conversation_id", "id")
            ?: continue
        val name = nestedContact?.firstString("name")
            ?: item.firstString("name", "text", "title")
            ?: "Customer"
        val phone = nestedContact?.firstString("phone")
            ?: item.firstString("phone", "wa_id", "number")
            ?: ""
        val text = item.firstString("text", "message", "value").orEmpty()
        add(
            Conversation(
                id = id,
                customerName = name,
                customerPhone = phone,
                lastMessage = sanitizeConversationPreview(text),
                lastMessageTime = "",
                lastMessageEpochMs = 0L,
                unreadCount = 0,
                status = ConversationStatus.OPEN,
                isWindowExpired = false,
                isOnline = false,
                assignedAgentName = null,
                tags = emptyList(),
                satisfaction = ConversationSatisfaction.NO_RATING
            )
        )
    }
}.distinctBy { it.id }

