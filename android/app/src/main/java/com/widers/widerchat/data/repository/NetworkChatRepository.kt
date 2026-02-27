package com.widers.widerchat.data.repository

import com.widers.widerchat.BuildConfig
import com.widers.widerchat.data.remote.SessionContext
import com.widers.widerchat.data.remote.WidersApiService
import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.domain.model.MessageDeliveryStatus
import com.widers.widerchat.domain.model.MessageSender
import com.widers.widerchat.domain.model.MessageType
import com.widers.widerchat.domain.repository.ChatRepository
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

class NetworkChatRepository(
    private val api: WidersApiService = WidersApiService(BuildConfig.API_BASE_URL)
) : ChatRepository {
    private var session: SessionContext? = null
    private var cacheConversations: List<Conversation> = emptyList()
    private var cacheContactsById: Map<String, String> = emptyMap()
    private var sessionUserName: String? = null
    private var sessionUserEmail: String? = null

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
        val data = response.optJSONObject("data")
        val user = response.optJSONObject("user")
            ?: data?.optJSONObject("user")
            ?: response.optJSONObject("data_user")
        val merchant = user?.optJSONObject("merchant")
            ?: data?.optJSONObject("merchant")
            ?: response.optJSONObject("merchant")
        sessionUserName = user?.firstString("name", "full_name", "username")
            ?: merchant?.firstString("name", "company_name")
            ?: email.substringBefore("@").trim().replaceFirstChar { it.uppercaseChar() }
        sessionUserEmail = user?.firstString("email", "user_email")
            ?: response.firstString("email")
            ?: email.trim()
        return true
    }

    override suspend fun getConversations(): List<Conversation> {
        val activeSession = session ?: return emptyList()
        val response = api.getChatsList(activeSession)
        val items = response.firstArray(
            "conversations",
            "chats",
            "data",
            "rows",
            "result"
        ) ?: emptyArrayFrom(response)

        val mapped = buildList {
            for (i in 0 until items.length()) {
                val item = items.optJSONObject(i) ?: continue
                val id = item.firstString("contact_id", "id", "conversation_id") ?: continue
                val customerName = item.firstString("name", "customer_name", "contact_name", "title") ?: "Customer"
                val phone = item.firstString("phone", "contact_phone", "wa_id", "number").orEmpty()
                val lastMessageRaw = item.firstString("last_message", "last_value", "value", "text", "body").orEmpty()
                val lastMessage = sanitizeConversationPreview(lastMessageRaw)
                val lastMessageTime = item.firstString("updated_at", "last_reply_at", "last_message_time", "created_at", "time")
                    ?.let(::formatApiDateTime)
                    .orEmpty()
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

                add(
                    Conversation(
                        id = id,
                        customerName = customerName,
                        customerPhone = phone,
                        lastMessage = lastMessage,
                        lastMessageTime = lastMessageTime,
                        unreadCount = unreadCount,
                        status = if (isOpen) ConversationStatus.OPEN else ConversationStatus.CLOSED,
                        isOnline = item.firstBoolean("is_online", "online") ?: false
                    )
                )
            }
        }
        cacheConversations = mapped
        return mapped
    }

    override suspend fun getMessages(conversationId: String): List<ChatMessage> {
        val activeSession = session ?: return emptyList()
        val contactId = conversationId.toLongOrNull() ?: return emptyList()
        val items = loadAllMessageItems(activeSession, contactId)
        val indices = if (shouldReverseMessageOrder(items)) {
            (items.length() - 1 downTo 0).toList()
        } else {
            (0 until items.length()).toList()
        }
        val remoteMessages = buildList {
            for (i in indices) {
                val item = items.optJSONObject(i) ?: continue
                val messageId = item.firstString("id", "message_id", "wamid") ?: "msg-$i"
                val content = item.extractDisplayContent()
                val messageTypeCode = item.firstInt("message_type")
                val isNote = (item.firstInt("is_note") == 1) || item.firstString("type", "message_type") == "note"
                val media = item.extractMediaPayload()
                if (item.isSkippableEmptyOutgoing(content = content, media = media, messageTypeCode = messageTypeCode)) {
                    continue
                }
                val messageType = when {
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
                        sender = if (isAgent) MessageSender.AGENT else MessageSender.CUSTOMER,
                        status = MessageDeliveryStatus.READ,
                        noteAuthor = if (messageType == MessageType.NOTE) "You" else null,
                        mediaUrl = media?.second,
                        mediaKind = media?.first
                    )
                )
            }
        }
        return remoteMessages
    }

    private suspend fun loadAllMessageItems(
        session: SessionContext,
        contactId: Long
    ): JSONArray {
        val collected = JSONArray()
        var afterId = 0L
        var pageCount = 0
        val maxPages = 60
        val pageSize = 150

        while (pageCount < maxPages) {
            val response = api.getChatMessages(session, contactId = contactId, afterId = afterId)
            val pageItems = response.firstArray("messages", "data", "rows", "result") ?: emptyArrayFrom(response)
            if (pageItems.length() == 0) break

            var pageMaxId = afterId
            for (i in 0 until pageItems.length()) {
                val item = pageItems.optJSONObject(i) ?: continue
                collected.put(item)
                val messageId = item.firstLong("id", "message_id") ?: continue
                if (messageId > pageMaxId) pageMaxId = messageId
            }

            if (pageMaxId <= afterId) break
            afterId = pageMaxId
            pageCount += 1
            if (pageItems.length() < pageSize) break
        }

        return collected
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

    // Full endpoint coverage from Postman collection.
    suspend fun getContacts(): JSONObject? {
        val payload = session?.let(api::getContactsList) ?: return null
        val contacts = payload.firstArray("contacts", "data", "rows", "result") ?: JSONArray()
        val cache = mutableMapOf<String, String>()
        for (i in 0 until contacts.length()) {
            val item = contacts.optJSONObject(i) ?: continue
            val id = item.firstString("id", "contact_id") ?: continue
            val phone = item.firstString("phone", "wa_id", "number") ?: continue
            if (phone.isNotBlank()) cache[id] = phone
        }
        cacheContactsById = cache
        return payload
    }
    suspend fun getTemplates() = session?.let(api::getTemplatesList)
    suspend fun getTags() = session?.let(api::getTagsList)
    suspend fun getReplies() = session?.let(api::getRepliesList)
    suspend fun getFlows() = session?.let(api::getFlowsList)
    suspend fun getAgents() = session?.let(api::getAgentsList)
    suspend fun getContactCustomFields(contactId: Long) = session?.let { api.getContactCustomFields(it, contactId) }
    suspend fun syncContactCustomFields(contactId: Long, custom: JSONObject) = session?.let { api.syncContactCustomFields(it, contactId, custom) }
    suspend fun attachTag(contactId: Long, tagId: Long) = session?.let { api.attachTagToChat(it, contactId, tagId) }
    suspend fun detachTag(contactId: Long, tagId: Long) = session?.let { api.detachTagFromChat(it, contactId, tagId) }
    suspend fun searchChats(keyword: String, page: Int, limit: Int) = session?.let { api.searchChats(it, keyword, page, limit) }
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
    }

    fun currentUserSnapshot(): Pair<String?, String?> = sessionUserName to sessionUserEmail
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
    val output = SimpleDateFormat("h:mm a", Locale.US)
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
            return output.format(date)
        } catch (_: Exception) {
            // Try next known pattern.
        }
    }
    return raw
}

private fun JSONObject.extractDisplayContent(): String {
    firstString("value", "text", "body", "message", "caption", "original_message", "last_message", "note")
        ?.takeIf { it.isNotBlank() }
        ?.let { return it }

    val audio = firstString("header_audio")
    if (!audio.isNullOrBlank()) return "[Audio message]"
    val image = firstString("header_image")
    if (!image.isNullOrBlank()) return "[Image]"
    val video = firstString("header_video")
    if (!video.isNullOrBlank()) return "[Video]"
    val document = firstString("header_document")
    if (!document.isNullOrBlank()) return "[Document]"
    val location = firstString("header_location")
    if (!location.isNullOrBlank()) return "[Location]"

    val buttonsRaw = firstString("buttons")
    if (!buttonsRaw.isNullOrBlank() && buttonsRaw != "[]") return "[Interactive message]"
    val componentsRaw = firstString("components")
    if (!componentsRaw.isNullOrBlank()) return "[Interactive message]"

    return "[Unsupported message]"
}

private fun JSONObject.extractMediaPayload(): Pair<String, String>? {
    val audio = firstString("header_audio")
    if (!audio.isNullOrBlank()) return "audio" to audio
    val image = firstString("header_image")
    if (!image.isNullOrBlank()) return "image" to image
    val video = firstString("header_video")
    if (!video.isNullOrBlank()) return "video" to video
    val document = firstString("header_document")
    if (!document.isNullOrBlank()) return "document" to document
    val location = firstString("header_location")
    if (!location.isNullOrBlank()) return "location" to location
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
        return firstTs > lastTs
    }

    return false
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

