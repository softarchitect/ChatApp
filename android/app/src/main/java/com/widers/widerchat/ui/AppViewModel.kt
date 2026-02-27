package com.widers.widerchat.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.widers.widerchat.data.repository.NetworkChatRepository
import com.widers.widerchat.domain.model.AppLocale
import com.widers.widerchat.domain.model.AppScreen
import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.domain.model.MessageDeliveryStatus
import com.widers.widerchat.domain.model.MessageSender
import com.widers.widerchat.domain.model.MessageType
import com.widers.widerchat.domain.repository.ChatRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class AppUiState(
    val locale: AppLocale = AppLocale.EN,
    val darkMode: Boolean = false,
    val isLoggedIn: Boolean = false,
    val isLoading: Boolean = false,
    val isActionLoading: Boolean = false,
    val loginError: Boolean = false,
    val actionStatus: String? = null,
    val contactsLoading: Boolean = false,
    val isChatLoading: Boolean = false,
    val profileName: String = "",
    val profileEmail: String = "",
    val screen: AppScreen = AppScreen.LOGIN,
    val activeChatId: String? = null,
    val conversations: List<Conversation> = emptyList(),
    val activeMessages: List<ChatMessage> = emptyList(),
    val newConversationContacts: List<NewConversationContact> = emptyList()
)

data class NewConversationContact(
    val id: String,
    val name: String,
    val phone: String
)

class AppViewModel(
    private val repository: ChatRepository = NetworkChatRepository()
) : ViewModel() {
    private val _uiState = MutableStateFlow(AppUiState())
    val uiState: StateFlow<AppUiState> = _uiState.asStateFlow()
    private val localOutgoingByConversation = mutableMapOf<String, MutableList<ChatMessage>>()

    fun login(email: String, password: String) {
        if (email.isBlank() || password.isBlank()) {
            _uiState.value = _uiState.value.copy(loginError = true)
            return
        }
        viewModelScope.launch(Dispatchers.IO) {
            try {
                _uiState.value = _uiState.value.copy(isLoading = true, loginError = false)
                val loggedIn = repository.login(email, password)
                if (!loggedIn) {
                    _uiState.value = _uiState.value.copy(isLoading = false, loginError = true)
                    return@launch
                }
                val conversations = repository.getConversations()
                val (profileName, profileEmail) = networkRepo()?.currentUserSnapshot() ?: (null to null)
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    isLoggedIn = true,
                    screen = AppScreen.CONVERSATIONS,
                    loginError = false,
                    conversations = conversations,
                    profileName = profileName.orEmpty(),
                    profileEmail = profileEmail.orEmpty()
                )
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, loginError = true)
            }
        }
    }

    fun restoreSession(token: String, companyId: Long) {
        if (token.isBlank() || companyId <= 0) return
        val repo = networkRepo() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            try {
                _uiState.value = _uiState.value.copy(isLoading = true, loginError = false)
                repo.restoreSession(token = token, companyId = companyId)
                val conversations = repository.getConversations()
                val (profileName, profileEmail) = repo.currentUserSnapshot()
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    isLoggedIn = true,
                    screen = AppScreen.CONVERSATIONS,
                    loginError = false,
                    conversations = conversations,
                    profileName = profileName.orEmpty(),
                    profileEmail = profileEmail.orEmpty()
                )
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, isLoggedIn = false, loginError = true)
            }
        }
    }

    fun sessionSnapshot(): Pair<String, Long>? {
        val current = networkRepo()?.currentSessionSnapshot() ?: return null
        return current.token to current.companyId
    }

    fun logout() {
        _uiState.value = _uiState.value.copy(
            isLoggedIn = false,
            screen = AppScreen.LOGIN,
            activeChatId = null,
            activeMessages = emptyList(),
            isChatLoading = false,
            actionStatus = null,
            profileName = "",
            profileEmail = ""
        )
    }

    fun setScreen(screen: AppScreen) {
        _uiState.value = _uiState.value.copy(screen = screen)
    }

    fun setLocale(locale: AppLocale) {
        _uiState.value = _uiState.value.copy(locale = locale)
    }

    fun setDarkMode(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(darkMode = enabled)
    }

    fun openChat(conversationId: String) {
        val preselectedConversation = _uiState.value.conversations.firstOrNull { it.id == conversationId }
        _uiState.value = _uiState.value.copy(
            activeChatId = conversationId,
            screen = AppScreen.CHAT,
            activeMessages = emptyList(),
            isChatLoading = true,
            conversations = _uiState.value.conversations.map {
                if (it.id == conversationId) it.copy(unreadCount = 0) else it
            }
        )
        viewModelScope.launch(Dispatchers.IO) {
            try {
                conversationId.toLongOrNull()?.let { contactId ->
                    networkRepo()?.updateRead(contactId, true)
                }
                val messages = mergeWithLocalOutgoing(conversationId, repository.getMessages(conversationId))
                val conversations = repository.getConversations()
                val mergedConversations = if (conversations.any { it.id == conversationId }) {
                    conversations
                } else {
                    val fallback = preselectedConversation ?: Conversation(
                        id = conversationId,
                        customerName = "Contact",
                        customerPhone = "",
                        lastMessage = "",
                        lastMessageTime = "",
                        unreadCount = 0,
                        status = ConversationStatus.OPEN,
                        isOnline = false
                    )
                    conversations + fallback
                }
                if (_uiState.value.activeChatId == conversationId) {
                    _uiState.value = _uiState.value.copy(
                        activeMessages = messages,
                        conversations = mergedConversations.map {
                            if (it.id == conversationId) it.copy(unreadCount = 0) else it
                        }
                    )
                }
            } finally {
                if (_uiState.value.activeChatId == conversationId) {
                    _uiState.value = _uiState.value.copy(isChatLoading = false)
                }
            }
        }
    }

    fun backToConversations() {
        _uiState.value = _uiState.value.copy(screen = AppScreen.CONVERSATIONS, isChatLoading = false)
        refreshConversations()
    }

    fun sendMessage(text: String) {
        val convoId = _uiState.value.activeChatId ?: return
        if (text.isBlank()) return
        val msg = ChatMessage(
            id = "new-${System.currentTimeMillis()}",
            conversationId = convoId,
            content = text.trim(),
            timestamp = nowLabel(),
            type = MessageType.TEXT,
            sender = MessageSender.AGENT,
            status = MessageDeliveryStatus.SENT
        )
        addLocalOutgoing(msg)
        _uiState.value = _uiState.value.copy(activeMessages = _uiState.value.activeMessages + msg)
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                repository.appendMessage(msg)
                val messages = mergeWithLocalOutgoing(convoId, repository.getMessages(convoId))
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(activeMessages = messages, conversations = conversations, actionStatus = "Message sent")
            }
        }
    }

    fun addNote(text: String) {
        val convoId = _uiState.value.activeChatId ?: return
        if (text.isBlank()) return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                repository.addNote(convoId, text.trim())
                val messages = repository.getMessages(convoId)
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(
                    activeMessages = messages,
                    conversations = conversations,
                    actionStatus = "Note added"
                )
            }
        }
    }

    fun sendAttachment(fileName: String, fileBytes: ByteArray, kindLabel: String) {
        val convoId = _uiState.value.activeChatId ?: return
        if (fileBytes.isEmpty()) return
        val localMediaKind = when {
            kindLabel.equals("Image", ignoreCase = true) -> "image"
            kindLabel.equals("Voice message", ignoreCase = true) -> "audio"
            kindLabel.equals("Document", ignoreCase = true) -> "document"
            else -> "document"
        }
        val localMsg = ChatMessage(
            id = "local-${System.currentTimeMillis()}",
            conversationId = convoId,
            content = "[$kindLabel]",
            timestamp = nowLabel(),
            type = MessageType.IMAGE,
            sender = MessageSender.AGENT,
            status = MessageDeliveryStatus.SENT,
            noteAuthor = null,
            mediaUrl = null,
            mediaKind = localMediaKind
        )
        addLocalOutgoing(localMsg)
        _uiState.value = _uiState.value.copy(activeMessages = _uiState.value.activeMessages + localMsg)
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.sendMediaMessage(
                    conversationId = convoId,
                    fileName = fileName,
                    fileBytes = fileBytes
                )
                val messages = mergeWithLocalOutgoing(convoId, repository.getMessages(convoId))
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(
                    activeMessages = messages,
                    conversations = conversations,
                    actionStatus = "$kindLabel sent"
                )
            }
        }
    }

    fun sendVoiceNote(fileName: String, fileBytes: ByteArray) {
        sendAttachment(fileName = fileName, fileBytes = fileBytes, kindLabel = "Voice message")
    }

    fun toggleConversationStatus() {
        val convoId = _uiState.value.activeChatId ?: return
        val convo = _uiState.value.conversations.firstOrNull { it.id == convoId } ?: return
        val newStatus = if (convo.status == ConversationStatus.OPEN) {
            ConversationStatus.CLOSED
        } else {
            ConversationStatus.OPEN
        }
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                repository.updateConversationStatus(convoId, newStatus)
                val messages = repository.getMessages(convoId)
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(
                    activeMessages = messages,
                    conversations = conversations,
                    actionStatus = if (newStatus == ConversationStatus.OPEN) "Conversation reopened" else "Conversation closed"
                )
            }
        }
    }

    fun assignCurrentChat(agentId: Long) {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.assignAgent(contactId, agentId)
                setActionStatus("Agent assigned")
            }
        }
    }

    fun unassignCurrentChat() {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.unassignAgent(contactId)
                setActionStatus("Agent unassigned")
            }
        }
    }

    fun muteCurrentChat(muted: Boolean) {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.updateMute(contactId, muted)
                setActionStatus(if (muted) "Conversation muted" else "Conversation unmuted")
            }
        }
    }

    fun markCurrentChatRead(read: Boolean) {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.updateRead(contactId, read)
                setActionStatus(if (read) "Marked as read" else "Marked as unread")
            }
        }
    }

    fun attachTagToCurrentChat(tagId: Long) {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.attachTag(contactId, tagId)
                setActionStatus("Tag attached")
            }
        }
    }

    fun detachTagFromCurrentChat(tagId: Long) {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.detachTag(contactId, tagId)
                setActionStatus("Tag detached")
            }
        }
    }

    fun sendTemplateToCurrentChat(templateId: Long) {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.sendTemplate(contactId, templateId)
                setActionStatus("Template sent")
            }
        }
    }

    fun sendFlowToCurrentChat(flowId: Long) {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.sendFlow(contactId, flowId)
                setActionStatus("Flow sent")
            }
        }
    }

    fun syncCurrentContactCustomField(fieldId: String, fieldValue: String) {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        if (fieldId.isBlank()) return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                val custom = JSONObject().put(fieldId, fieldValue)
                networkRepo()?.syncContactCustomFields(contactId, custom)
                setActionStatus("Custom field synced")
            }
        }
    }

    fun deleteCurrentChat() {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.deleteChat(contactId)
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(
                    conversations = conversations,
                    activeChatId = null,
                    activeMessages = emptyList(),
                    screen = AppScreen.CONVERSATIONS,
                    actionStatus = "Conversation deleted"
                )
            }
        }
    }

    fun preloadSupportData() {
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                val repo = networkRepo() ?: return@runAction
                repo.getContacts()
                repo.getTemplates()
                repo.getTags()
                repo.getReplies()
                repo.getFlows()
                repo.getAgents()
                setActionStatus("Support data synced")
            }
        }
    }

    fun searchChats(keyword: String) {
        if (keyword.isBlank()) {
            refreshConversations()
            return
        }
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                val result = networkRepo()?.searchChats(keyword, 1, 50)
                val items = result?.optJSONArray("data") ?: result?.optJSONArray("chats")
                if (items == null) {
                    setActionStatus("Search completed")
                    return@runAction
                }
                val conversations = (repository.getConversations()).filter { convo ->
                    convo.customerName.contains(keyword, ignoreCase = true) ||
                        convo.lastMessage.contains(keyword, ignoreCase = true)
                }
                _uiState.value = _uiState.value.copy(conversations = conversations, actionStatus = "Search completed")
            }
        }
    }

    fun createOrUpdateTag(name: String, color: String, tagId: Long?) {
        if (name.isBlank() || color.isBlank()) return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.createOrUpdateTag(name, color, tagId)
                setActionStatus("Tag saved")
            }
        }
    }

    fun createOrUpdateReply(name: String, text: String, replyId: Long?) {
        if (name.isBlank() || text.isBlank()) return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.createOrUpdateReply(name, text, replyId)
                setActionStatus("Reply saved")
            }
        }
    }

    fun addContact(name: String, phone: String, email: String?) {
        if (name.isBlank() || phone.isBlank()) return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.addContact(name, phone, email)
                setActionStatus("Contact added")
            }
        }
    }

    fun startNewConversation(name: String, phone: String) {
        if (name.isBlank() || phone.isBlank()) return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                val addResult = networkRepo()?.addContact(name.trim(), phone.trim(), null)
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(conversations = conversations)

                val createdPayload = addResult?.optJSONObject("data")
                val createdId = sequenceOf("contact_id", "id")
                    .mapNotNull { key ->
                        createdPayload
                            ?.opt(key)
                            ?.toString()
                            ?.trim()
                            ?.takeIf { it.isNotBlank() && !it.equals("null", ignoreCase = true) }
                    }
                    .firstOrNull()
                val normalizedPhone = phone.filter { it.isDigit() }
                val created = when {
                    !createdId.isNullOrBlank() -> conversations.firstOrNull { it.id == createdId }
                    else -> conversations.firstOrNull { convo ->
                        convo.customerName.equals(name.trim(), ignoreCase = true) ||
                            convo.customerPhone.filter { it.isDigit() }.endsWith(normalizedPhone)
                    }
                }

                if (created != null) {
                    _uiState.value = _uiState.value.copy(
                        actionStatus = "Conversation created"
                    )
                    openChat(created.id)
                } else {
                    setActionStatus("Conversation created. Open it from contacts/search if it has no messages yet.")
                }
            }
        }
    }

    fun loadContactsForNewConversation() {
        viewModelScope.launch(Dispatchers.IO) {
            _uiState.value = _uiState.value.copy(contactsLoading = true)
            try {
                val payload = networkRepo()?.getContacts()
                val parsed = parseNewConversationContacts(payload)
                _uiState.value = _uiState.value.copy(
                    newConversationContacts = parsed,
                    contactsLoading = false
                )
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(contactsLoading = false)
            }
        }
    }

    fun searchContactsForNewConversation(query: String) {
        val trimmed = query.trim()
        if (trimmed.isBlank()) {
            loadContactsForNewConversation()
            return
        }
        viewModelScope.launch(Dispatchers.IO) {
            _uiState.value = _uiState.value.copy(contactsLoading = true)
            try {
                val payload = networkRepo()?.searchContacts(trimmed)
                _uiState.value = _uiState.value.copy(
                    newConversationContacts = parseNewConversationContacts(payload),
                    contactsLoading = false
                )
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(contactsLoading = false)
            }
        }
    }

    fun startConversationForContact(contact: NewConversationContact) {
        viewModelScope.launch(Dispatchers.IO) {
            val conversations = repository.getConversations()
            val normalizedPhone = contact.phone.filter { it.isDigit() }
            val existing = conversations.firstOrNull { convo ->
                convo.id == contact.id ||
                    convo.customerPhone.filter { it.isDigit() }.endsWith(normalizedPhone)
            }
            if (existing != null) {
                _uiState.value = _uiState.value.copy(conversations = conversations)
                openChat(existing.id)
                return@launch
            }

            val synthetic = Conversation(
                id = contact.id,
                customerName = contact.name,
                customerPhone = contact.phone,
                lastMessage = "",
                lastMessageTime = "",
                unreadCount = 0,
                status = ConversationStatus.OPEN,
                isOnline = false
            )
            _uiState.value = _uiState.value.copy(
                conversations = (conversations + synthetic).distinctBy { it.id }
            )
            openChat(contact.id)
        }
    }

    fun updateCurrentContact(name: String, phone: String, email: String?) {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        if (name.isBlank() || phone.isBlank()) return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.updateContact(contactId, name, phone, email)
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(conversations = conversations, actionStatus = "Contact updated")
            }
        }
    }

    fun clearActionStatus() {
        _uiState.value = _uiState.value.copy(actionStatus = null)
    }

    private fun parseNewConversationContacts(payload: JSONObject?): List<NewConversationContact> {
        val array = payload?.optJSONArray("contacts")
            ?: payload?.optJSONArray("data")
            ?: payload?.optJSONArray("rows")
            ?: payload?.optJSONArray("result")
        if (array == null) return emptyList()
        val parsed = buildList {
            for (i in 0 until array.length()) {
                val item = array.optJSONObject(i) ?: continue
                val id = item.opt("id")?.toString()?.trim()
                    ?.takeIf { it.isNotBlank() && !it.equals("null", ignoreCase = true) }
                    ?: item.opt("contact_id")?.toString()?.trim()
                        ?.takeIf { it.isNotBlank() && !it.equals("null", ignoreCase = true) }
                    ?: continue
                val name = item.optString("name").trim().ifBlank { "Contact" }
                val phone = item.optString("phone").trim()
                    .ifBlank { item.optString("wa_id").trim() }
                    .ifBlank { item.optString("number").trim() }
                if (phone.isBlank()) continue
                if (isHiddenTestContact(name, phone)) continue
                add(NewConversationContact(id = id, name = name, phone = phone))
            }
        }
        return parsed.distinctBy { it.id }
    }

    private fun isHiddenTestContact(name: String, phone: String): Boolean {
        val normalizedName = name.trim().lowercase(Locale.US)
        val digits = phone.filter { it.isDigit() }
        if (normalizedName == "cursor qa test") return true
        return digits in setOf("966500000001", "966500000002", "0500000003")
    }

    private fun nowLabel(): String {
        val locale = if (_uiState.value.locale == AppLocale.AR) Locale.forLanguageTag("ar-SA") else Locale.US
        return SimpleDateFormat("h:mm a", locale).format(Date())
    }

    private fun refreshConversations() {
        viewModelScope.launch(Dispatchers.IO) {
            val conversations = repository.getConversations()
            _uiState.value = _uiState.value.copy(conversations = conversations)
        }
    }

    private fun networkRepo(): NetworkChatRepository? = repository as? NetworkChatRepository

    private fun addLocalOutgoing(message: ChatMessage) {
        val bucket = localOutgoingByConversation.getOrPut(message.conversationId) { mutableListOf() }
        bucket += message
    }

    private fun mergeWithLocalOutgoing(conversationId: String, remote: List<ChatMessage>): List<ChatMessage> {
        val local = localOutgoingByConversation[conversationId].orEmpty()
        if (local.isEmpty()) return remote
        val existingIds = remote.map { it.id }.toHashSet()
        val existingSignature = remote.map { it.content.trim() to it.sender }.toHashSet()
        return remote + local.filter { it.id !in existingIds && (it.content.trim() to it.sender) !in existingSignature }
    }

    private fun setActionStatus(message: String) {
        _uiState.value = _uiState.value.copy(actionStatus = message)
    }

    private suspend fun runAction(block: suspend () -> Unit) {
        _uiState.value = _uiState.value.copy(isActionLoading = true)
        try {
            block()
        } catch (e: Exception) {
            val message = e.message?.takeIf { it.isNotBlank() } ?: "Request failed"
            _uiState.value = _uiState.value.copy(actionStatus = "Failed: $message")
        } finally {
            _uiState.value = _uiState.value.copy(isActionLoading = false)
        }
    }
}
