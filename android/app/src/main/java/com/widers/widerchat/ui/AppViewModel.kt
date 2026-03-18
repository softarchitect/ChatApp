package com.widers.widerchat.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.widers.widerchat.BuildConfig
import com.widers.widerchat.data.remote.ApiHttpException
import com.widers.widerchat.data.realtime.PusherRealtimeClient
import com.widers.widerchat.data.repository.NetworkChatRepository
import com.widers.widerchat.domain.model.AppLocale
import com.widers.widerchat.domain.model.AppScreen
import com.widers.widerchat.domain.model.AvailableAgent
import com.widers.widerchat.domain.model.AvailableCustomField
import com.widers.widerchat.domain.model.AvailableFlow
import com.widers.widerchat.domain.model.AvailableReply
import com.widers.widerchat.domain.model.AvailableTag
import com.widers.widerchat.domain.model.AvailableTemplate
import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.domain.model.MessageDeliveryStatus
import com.widers.widerchat.domain.model.MessageSender
import com.widers.widerchat.domain.model.MessageType
import com.widers.widerchat.domain.model.WorkspaceOption
import com.widers.widerchat.domain.repository.ChatRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
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
    val hasMoreActiveMessages: Boolean = false,
    val isLoadingMoreActiveMessages: Boolean = false,
    val profileName: String = "",
    val profileEmail: String = "",
    val currentCompanyId: Long? = null,
    val availableWorkspaces: List<WorkspaceOption> = emptyList(),
    val hasMoreConversations: Boolean = false,
    val isLoadingMoreConversations: Boolean = false,
    val hasMoreNewConversationContacts: Boolean = false,
    val isLoadingMoreNewConversationContacts: Boolean = false,
    val pushDebugInfo: String? = null,
    val pushDebugRawToken: String? = null,
    val availableTags: List<AvailableTag> = emptyList(),
    val availableAgents: List<AvailableAgent> = emptyList(),
    val availableCustomFields: List<AvailableCustomField> = emptyList(),
    val availableTemplates: List<AvailableTemplate> = emptyList(),
    val availableFlows: List<AvailableFlow> = emptyList(),
    val availableReplies: List<AvailableReply> = emptyList(),
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

data class ConversationsServerFilters(
    val status: String = "all",
    val tag: String = "all",
    val agent: String = "all",
    val rating: String = "all",
    val tap: String = "all",
    val orderBy: String = "default"
)

class AppViewModel(
    private val repository: ChatRepository = NetworkChatRepository()
) : ViewModel() {
    private val _uiState = MutableStateFlow(AppUiState())
    val uiState: StateFlow<AppUiState> = _uiState.asStateFlow()
    private val localOutgoingByConversation = mutableMapOf<String, MutableList<ChatMessage>>()
    private var activeChatPollingJob: Job? = null
    private var realtimeConversationsRefreshJob: Job? = null
    private var realtimeActiveChatRefreshJob: Job? = null
    private val realtimeClient = PusherRealtimeClient(
        key = BuildConfig.PUSHER_KEY,
        cluster = BuildConfig.PUSHER_CLUSTER,
        onGeneralEvent = ::onRealtimeGeneralEvent
    )
    private var pendingNotificationChatId: String? = null
    private var latestPushToken: String? = null
    private var activeConversationFilters: ConversationsServerFilters = ConversationsServerFilters()
    private var contactsNextPage: Int = 1
    private var contactsHasMore: Boolean = true
    private val contactsPageSize: Int = 25
    private var contactsSearchMode: Boolean = false

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
                val (profileName, profileEmail) = networkRepo()?.currentUserSnapshot() ?: (null to null)
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    isLoggedIn = true,
                    screen = AppScreen.CONVERSATIONS,
                    loginError = false,
                    profileName = profileName.orEmpty(),
                    profileEmail = profileEmail.orEmpty(),
                    currentCompanyId = networkRepo()?.currentCompanyIdSnapshot(),
                    availableWorkspaces = networkRepo()?.availableWorkspacesSnapshot().orEmpty(),
                    hasMoreConversations = networkRepo()?.hasMoreConversationsSnapshot() ?: false,
                    isLoadingMoreConversations = networkRepo()?.isLoadingMoreConversationsSnapshot() ?: false
                )
                networkRepo()?.currentCompanyIdSnapshot()?.let { realtimeClient.connect(it) }
                tryRegisterLatestPushToken()
                launchPostLoginDataWarmup()
                pendingNotificationChatId?.let {
                    pendingNotificationChatId = null
                    openChat(it)
                }
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, loginError = true)
            }
        }
    }

    fun restoreSession(
        token: String,
        companyId: Long,
        fallbackProfileName: String = "",
        fallbackProfileEmail: String = ""
    ) {
        if (token.isBlank() || companyId <= 0) return
        val repo = networkRepo() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            try {
                _uiState.value = _uiState.value.copy(isLoading = true, loginError = false)
                repo.restoreSession(token = token, companyId = companyId)
                val (profileName, profileEmail) = repo.currentUserSnapshot()
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    isLoggedIn = true,
                    screen = AppScreen.CONVERSATIONS,
                    loginError = false,
                    profileName = profileName.orEmpty().ifBlank { fallbackProfileName.trim() },
                    profileEmail = profileEmail.orEmpty().ifBlank { fallbackProfileEmail.trim() },
                    currentCompanyId = repo.currentCompanyIdSnapshot(),
                    availableWorkspaces = repo.availableWorkspacesSnapshot(),
                    hasMoreConversations = repo.hasMoreConversationsSnapshot(),
                    isLoadingMoreConversations = repo.isLoadingMoreConversationsSnapshot()
                )
                repo.currentCompanyIdSnapshot()?.let { realtimeClient.connect(it) }
                tryRegisterLatestPushToken()
                launchPostLoginDataWarmup()
                pendingNotificationChatId?.let {
                    pendingNotificationChatId = null
                    openChat(it)
                }
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, isLoggedIn = false, loginError = true)
            }
        }
    }

    fun sessionSnapshot(): Pair<String, Long>? {
        val current = networkRepo()?.currentSessionSnapshot() ?: return null
        return current.token to current.companyId
    }

    fun switchWorkspace(companyId: Long) {
        val repo = networkRepo() ?: return
        if (companyId <= 0L || repo.currentCompanyIdSnapshot() == companyId) return
        viewModelScope.launch(Dispatchers.IO) {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                val switched = repo.switchWorkspace(companyId)
                if (!switched) {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        actionStatus = "Failed: unable to switch workspace"
                    )
                    return@launch
                }
                val conversations = repository.getConversations()
                realtimeClient.setActiveChat(null)
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    screen = AppScreen.CONVERSATIONS,
                    activeChatId = null,
                    activeMessages = emptyList(),
                    isChatLoading = false,
                    conversations = conversations,
                    currentCompanyId = repo.currentCompanyIdSnapshot(),
                    availableWorkspaces = repo.availableWorkspacesSnapshot(),
                    actionStatus = "Workspace switched"
                )
                repo.currentCompanyIdSnapshot()?.let { realtimeClient.connect(it) }
                tryRegisterLatestPushToken()
                refreshAvailableTags()
                refreshAvailableAgents()
                refreshAvailableTemplates()
                refreshAvailableFlows()
                refreshAvailableReplies()
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    actionStatus = "Failed: unable to switch workspace"
                )
            }
        }
    }

    fun logout() {
        stopActiveChatPolling()
        realtimeClient.setActiveChat(null)
        realtimeClient.disconnect()
        pendingNotificationChatId = null
        activeConversationFilters = ConversationsServerFilters()
        contactsNextPage = 1
        contactsHasMore = true
        contactsSearchMode = false
        _uiState.value = _uiState.value.copy(
            isLoggedIn = false,
            screen = AppScreen.LOGIN,
            activeChatId = null,
            activeMessages = emptyList(),
            isChatLoading = false,
            hasMoreActiveMessages = false,
            isLoadingMoreActiveMessages = false,
            actionStatus = null,
            profileName = "",
            profileEmail = "",
            currentCompanyId = null,
            availableWorkspaces = emptyList(),
            hasMoreConversations = false,
            isLoadingMoreConversations = false,
            hasMoreNewConversationContacts = false,
            isLoadingMoreNewConversationContacts = false,
            pushDebugInfo = null,
            pushDebugRawToken = null,
            newConversationContacts = emptyList(),
            availableAgents = emptyList(),
            availableCustomFields = emptyList(),
            availableTemplates = emptyList(),
            availableFlows = emptyList(),
            availableReplies = emptyList()
        )
    }

    fun setScreen(screen: AppScreen) {
        _uiState.value = _uiState.value.copy(screen = screen)
    }

    fun onNotificationOpenChat(chatId: String) {
        val normalized = chatId.trim()
        if (normalized.isEmpty()) return
        if (_uiState.value.isLoggedIn) {
            openChat(normalized)
        } else {
            pendingNotificationChatId = normalized
        }
    }

    fun onPushTokenReceived(token: String) {
        val normalized = token.trim()
        if (normalized.isEmpty() || normalized == latestPushToken) return
        latestPushToken = normalized
        updatePushDebugStatus("Token received", normalized)
        tryRegisterLatestPushToken()
    }

    private fun tryRegisterLatestPushToken() {
        val pushToken = latestPushToken ?: return
        if (!_uiState.value.isLoggedIn) {
            updatePushDebugStatus("Waiting for login", pushToken)
            return
        }
        viewModelScope.launch(Dispatchers.IO) {
            updatePushDebugStatus("Registering...", pushToken)
            val ok = repository.registerPushToken(pushToken, platform = "android")
            updatePushDebugStatus(if (ok) "Registered" else "Registration failed", pushToken)
        }
    }

    private fun updatePushDebugStatus(status: String, token: String?) {
        if (!BuildConfig.DEBUG) return
        val masked = token?.let(::maskPushToken).orEmpty().ifBlank { "n/a" }
        _uiState.value = _uiState.value.copy(
            pushDebugInfo = "Token: $masked\nLast attempt: ${nowLabel()}\nResult: $status",
            pushDebugRawToken = token
        )
    }

    private fun maskPushToken(token: String): String {
        val normalized = token.trim()
        if (normalized.length <= 10) return "***"
        return "${normalized.take(6)}...${normalized.takeLast(4)}"
    }

    fun setLocale(locale: AppLocale) {
        _uiState.value = _uiState.value.copy(locale = locale)
    }

    fun setDarkMode(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(darkMode = enabled)
    }

    fun openChat(conversationId: String) {
        stopActiveChatPolling()
        realtimeClient.setActiveChat(conversationId)
        val preselectedConversation = _uiState.value.conversations.firstOrNull { it.id == conversationId }
        _uiState.value = _uiState.value.copy(
            activeChatId = conversationId,
            screen = AppScreen.CHAT,
            activeMessages = emptyList(),
            isChatLoading = true,
            hasMoreActiveMessages = false,
            isLoadingMoreActiveMessages = false,
            conversations = _uiState.value.conversations.map {
                if (it.id == conversationId) it.copy(unreadCount = 0) else it
            }
        )
        viewModelScope.launch(Dispatchers.IO) {
            try {
                conversationId.toLongOrNull()?.let { contactId ->
                    networkRepo()?.updateRead(contactId, true)
                }
                val messages = mergeWithLocalOutgoing(
                    conversationId,
                    fetchLatestMessages(conversationId, resetHistory = true)
                )
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
                        isOnline = false,
                        assignedAgentName = null,
                        tags = emptyList()
                    )
                    conversations + fallback
                }
                if (_uiState.value.activeChatId == conversationId) {
                    _uiState.value = _uiState.value.copy(
                        activeMessages = messages,
                        conversations = mergedConversations.map {
                            if (it.id == conversationId) it.copy(unreadCount = 0) else it
                        },
                        hasMoreActiveMessages = networkRepo()?.hasMoreMessagesSnapshot(conversationId) ?: false,
                        isLoadingMoreActiveMessages = networkRepo()?.isLoadingMoreMessagesSnapshot(conversationId) ?: false
                    )
                }
                startActiveChatPolling(conversationId)
            } finally {
                if (_uiState.value.activeChatId == conversationId) {
                    _uiState.value = _uiState.value.copy(isChatLoading = false)
                }
            }
        }
    }

    fun backToConversations() {
        val lastActive = _uiState.value.activeChatId
        stopActiveChatPolling()
        realtimeClient.setActiveChat(null)
        _uiState.value = _uiState.value.copy(
            screen = AppScreen.CONVERSATIONS,
            activeChatId = null,
            activeMessages = emptyList(),
            isChatLoading = false,
            hasMoreActiveMessages = false,
            isLoadingMoreActiveMessages = false
        )
        refreshConversations(lastOpenedConversationId = lastActive)
    }

    fun loadOlderMessagesForActiveChat() {
        val conversationId = _uiState.value.activeChatId ?: return
        val repo = networkRepo() ?: return
        if (_uiState.value.isLoadingMoreActiveMessages || !_uiState.value.hasMoreActiveMessages) return
        viewModelScope.launch(Dispatchers.IO) {
            _uiState.value = _uiState.value.copy(isLoadingMoreActiveMessages = true)
            try {
                val older = mergeWithLocalOutgoing(conversationId, repo.loadOlderMessagesPage(conversationId))
                if (_uiState.value.activeChatId == conversationId) {
                    _uiState.value = _uiState.value.copy(
                        activeMessages = older,
                        hasMoreActiveMessages = repo.hasMoreMessagesSnapshot(conversationId),
                        isLoadingMoreActiveMessages = false
                    )
                }
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(isLoadingMoreActiveMessages = false)
            }
        }
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
                val messages = mergeWithLocalOutgoing(convoId, fetchLatestMessages(convoId))
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
                val messages = fetchLatestMessages(convoId)
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
                val messages = mergeWithLocalOutgoing(convoId, fetchLatestMessages(convoId))
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
                val messages = fetchLatestMessages(convoId)
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(
                    activeMessages = messages,
                    conversations = conversations,
                    actionStatus = if (newStatus == ConversationStatus.OPEN) "Conversation reopened" else "Conversation closed"
                )
            }
        }
    }

    fun toggleConversationStatusById(conversationId: String) {
        val convo = _uiState.value.conversations.firstOrNull { it.id == conversationId } ?: return
        val newStatus = if (convo.status == ConversationStatus.OPEN) {
            ConversationStatus.CLOSED
        } else {
            ConversationStatus.OPEN
        }
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                repository.updateConversationStatus(conversationId, newStatus)
                val conversations = repository.getConversations()
                val activeMessages = if (_uiState.value.activeChatId == conversationId) {
                    fetchLatestMessages(conversationId)
                } else {
                    _uiState.value.activeMessages
                }
                _uiState.value = _uiState.value.copy(
                    conversations = conversations,
                    activeMessages = activeMessages,
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
        val convoId = _uiState.value.activeChatId ?: return
        val contactId = convoId.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.attachTag(contactId, tagId)
                val conversations = repository.getConversations()
                val activeMessages = if (_uiState.value.activeChatId == convoId) {
                    fetchLatestMessages(convoId)
                } else {
                    _uiState.value.activeMessages
                }
                _uiState.value = _uiState.value.copy(
                    conversations = conversations,
                    activeMessages = activeMessages,
                    actionStatus = "Tag attached"
                )
            }
        }
    }

    fun detachTagFromCurrentChat(tagId: Long) {
        val convoId = _uiState.value.activeChatId ?: return
        val contactId = convoId.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.detachTag(contactId, tagId)
                val conversations = repository.getConversations()
                val activeMessages = if (_uiState.value.activeChatId == convoId) {
                    fetchLatestMessages(convoId)
                } else {
                    _uiState.value.activeMessages
                }
                _uiState.value = _uiState.value.copy(
                    conversations = conversations,
                    activeMessages = activeMessages,
                    actionStatus = "Tag detached"
                )
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

    fun sendQuickReplyToCurrentChat(replyId: Long) {
        val convoId = _uiState.value.activeChatId ?: return
        val reply = _uiState.value.availableReplies.firstOrNull { it.id == replyId } ?: return
        if (reply.text.isBlank()) return
        sendMessage(reply.text)
        _uiState.value = _uiState.value.copy(actionStatus = "Reply sent")
        viewModelScope.launch(Dispatchers.IO) {
            // Keep replies fresh in case backend-side text changed.
            refreshAvailableReplies()
            if (_uiState.value.activeChatId == convoId) {
                val refreshed = mergeWithLocalOutgoing(convoId, fetchLatestMessages(convoId))
                _uiState.value = _uiState.value.copy(activeMessages = refreshed)
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

    fun refreshCurrentContactCustomFields() {
        val contactId = _uiState.value.activeChatId?.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val payload = networkRepo()?.getContactCustomFields(contactId)
                val parsed = parseAvailableCustomFields(payload)
                _uiState.value = _uiState.value.copy(availableCustomFields = parsed)
            } catch (e: ApiHttpException) {
                _uiState.value = _uiState.value.copy(
                    availableCustomFields = emptyList(),
                    actionStatus = if (e.statusCode == 401) {
                        "Session expired. Please login again."
                    } else {
                        "Failed: unable to load custom fields"
                    }
                )
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(
                    availableCustomFields = emptyList(),
                    actionStatus = "Failed: unable to load custom fields"
                )
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

    fun deleteConversationsByIds(conversationIds: List<String>) {
        val ids = conversationIds.mapNotNull { it.toLongOrNull() }.distinct()
        if (ids.isEmpty()) return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                val repo = networkRepo() ?: return@runAction
                ids.forEach { repo.deleteChat(it) }
                val conversations = repository.getConversations()
                val activeId = _uiState.value.activeChatId
                val activeCleared = if (activeId != null && conversationIds.contains(activeId)) null else activeId
                _uiState.value = _uiState.value.copy(
                    conversations = conversations,
                    activeChatId = activeCleared,
                    activeMessages = if (activeCleared == null) emptyList() else _uiState.value.activeMessages,
                    screen = if (activeCleared == null) AppScreen.CONVERSATIONS else _uiState.value.screen,
                    actionStatus = "Conversations removed"
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
                refreshAvailableTags()
                refreshAvailableAgents()
                refreshAvailableTemplates()
                refreshAvailableFlows()
                refreshAvailableReplies()
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
                val conversations = networkRepo()?.searchConversations(keyword, page = 1, limit = 50)
                    ?: repository.getConversations().filter { convo ->
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
        val normalizedPhone = normalizeInternationalPhone(phone)
        if (normalizedPhone == null) {
            _uiState.value = _uiState.value.copy(
                actionStatus = "Failed: phone must be in international format, e.g. +96654377556"
            )
            return
        }
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.addContact(name.trim(), normalizedPhone, email?.trim())
                setActionStatus("Contact added")
            }
        }
    }

    fun startNewConversation(name: String, phone: String) {
        if (name.isBlank() || phone.isBlank()) return
        val normalizedPhone = normalizeInternationalPhone(phone)
        if (normalizedPhone == null) {
            _uiState.value = _uiState.value.copy(
                actionStatus = "Failed: phone must be in international format, e.g. +96654377556"
            )
            return
        }
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                val addResult = networkRepo()?.addContact(name.trim(), normalizedPhone, null)
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
                val normalizedPhoneDigits = normalizedPhone.filter { it.isDigit() }
                val created = when {
                    !createdId.isNullOrBlank() -> conversations.firstOrNull { it.id == createdId }
                    else -> conversations.firstOrNull { convo ->
                        convo.customerName.equals(name.trim(), ignoreCase = true) ||
                            convo.customerPhone.filter { it.isDigit() }.endsWith(normalizedPhoneDigits)
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
        contactsSearchMode = false
        contactsNextPage = 1
        contactsHasMore = true
        viewModelScope.launch(Dispatchers.IO) {
            _uiState.value = _uiState.value.copy(contactsLoading = true)
            try {
                val payload = networkRepo()?.getContactsPage(page = contactsNextPage, limit = contactsPageSize)
                val parsed = parseNewConversationContacts(payload)
                contactsHasMore = parsed.size >= contactsPageSize
                contactsNextPage = if (contactsHasMore) 2 else 1
                _uiState.value = _uiState.value.copy(
                    newConversationContacts = parsed,
                    hasMoreNewConversationContacts = contactsHasMore,
                    isLoadingMoreNewConversationContacts = false,
                    contactsLoading = false
                )
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(
                    contactsLoading = false,
                    isLoadingMoreNewConversationContacts = false
                )
            }
        }
    }

    fun loadMoreContactsForNewConversation() {
        if (contactsSearchMode || !contactsHasMore || _uiState.value.contactsLoading || _uiState.value.isLoadingMoreNewConversationContacts) {
            return
        }
        viewModelScope.launch(Dispatchers.IO) {
            _uiState.value = _uiState.value.copy(isLoadingMoreNewConversationContacts = true)
            try {
                val payload = networkRepo()?.getContactsPage(page = contactsNextPage, limit = contactsPageSize)
                val parsed = parseNewConversationContacts(payload)
                if (parsed.isEmpty()) {
                    contactsHasMore = false
                } else {
                    contactsHasMore = parsed.size >= contactsPageSize
                    if (contactsHasMore) contactsNextPage += 1
                }
                _uiState.value = _uiState.value.copy(
                    newConversationContacts = (_uiState.value.newConversationContacts + parsed).distinctBy { it.id },
                    hasMoreNewConversationContacts = contactsHasMore,
                    isLoadingMoreNewConversationContacts = false
                )
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(isLoadingMoreNewConversationContacts = false)
            }
        }
    }

    fun searchContactsForNewConversation(query: String) {
        val trimmed = query.trim()
        if (trimmed.isBlank()) {
            loadContactsForNewConversation()
            return
        }
        contactsSearchMode = true
        contactsHasMore = false
        viewModelScope.launch(Dispatchers.IO) {
            _uiState.value = _uiState.value.copy(contactsLoading = true)
            try {
                val payload = networkRepo()?.searchContacts(trimmed)
                _uiState.value = _uiState.value.copy(
                    newConversationContacts = parseNewConversationContacts(payload),
                    hasMoreNewConversationContacts = false,
                    isLoadingMoreNewConversationContacts = false,
                    contactsLoading = false
                )
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(
                    contactsLoading = false,
                    isLoadingMoreNewConversationContacts = false
                )
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
                isOnline = false,
                assignedAgentName = null,
                tags = emptyList()
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
        val normalizedPhone = normalizeInternationalPhone(phone)
        if (normalizedPhone == null) {
            _uiState.value = _uiState.value.copy(
                actionStatus = "Failed: phone must be in international format, e.g. +96654377556"
            )
            return
        }
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.updateContact(contactId, name.trim(), normalizedPhone, email?.trim())
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(conversations = conversations, actionStatus = "Contact updated")
            }
        }
    }

    fun updateProfile(name: String, email: String) {
        val normalizedName = name.trim()
        val normalizedEmail = email.trim()
        if (normalizedName.isBlank()) return
        _uiState.value = _uiState.value.copy(
            profileName = normalizedName,
            profileEmail = normalizedEmail
        )
    }

    fun clearActionStatus() {
        _uiState.value = _uiState.value.copy(actionStatus = null)
    }

    fun attachTagToConversation(conversationId: String, tagId: Long) {
        val contactId = conversationId.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.attachTag(contactId, tagId)
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(
                    conversations = conversations,
                    actionStatus = "Tag attached"
                )
            }
        }
    }

    fun detachTagFromConversation(conversationId: String, tagId: Long) {
        val contactId = conversationId.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.detachTag(contactId, tagId)
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(
                    conversations = conversations,
                    actionStatus = "Tag detached"
                )
            }
        }
    }

    fun repeatTagOnConversation(conversationId: String, tagId: Long) {
        attachTagToConversation(conversationId, tagId)
    }

    fun markConversationRead(conversationId: String, read: Boolean) {
        val contactId = conversationId.toLongOrNull() ?: return
        viewModelScope.launch(Dispatchers.IO) {
            runAction {
                networkRepo()?.updateRead(contactId, read)
                val conversations = repository.getConversations()
                _uiState.value = _uiState.value.copy(
                    conversations = conversations,
                    actionStatus = if (read) "Marked as read" else "Marked as unread"
                )
            }
        }
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

    private fun normalizeInternationalPhone(raw: String): String? {
        val compact = raw.filterNot { it.isWhitespace() }
        if (!compact.startsWith("+")) return null
        val digits = compact.drop(1)
        if (digits.length !in 8..15) return null
        if (!digits.all { it.isDigit() }) return null
        return "+$digits"
    }

    private fun refreshConversations(lastOpenedConversationId: String? = null) {
        viewModelScope.launch(Dispatchers.IO) {
            val repo = networkRepo()
            val fetched = if (repo != null) {
                repo.refreshConversationsFirstPage(
                    NetworkChatRepository.ConversationsRequestFilters(
                        status = activeConversationFilters.status,
                        tag = activeConversationFilters.tag,
                        agent = activeConversationFilters.agent,
                        rating = "all",
                        tap = activeConversationFilters.tap,
                        orderBy = activeConversationFilters.orderBy
                    )
                )
            } else {
                repository.getConversations()
            }
            val conversations = if (lastOpenedConversationId.isNullOrBlank()) {
                fetched
            } else {
                fetched.map {
                    if (it.id == lastOpenedConversationId) it.copy(unreadCount = 0) else it
                }
            }
            _uiState.value = _uiState.value.copy(
                conversations = conversations,
                hasMoreConversations = repo?.hasMoreConversationsSnapshot() ?: false,
                isLoadingMoreConversations = repo?.isLoadingMoreConversationsSnapshot() ?: false
            )
        }
    }

    fun refreshConversationsList(filters: ConversationsServerFilters = activeConversationFilters) {
        activeConversationFilters = filters
        viewModelScope.launch(Dispatchers.IO) {
            val repo = networkRepo()
            val requestFilters = NetworkChatRepository.ConversationsRequestFilters(
                status = activeConversationFilters.status,
                tag = activeConversationFilters.tag,
                agent = activeConversationFilters.agent,
                rating = "all",
                tap = activeConversationFilters.tap,
                orderBy = activeConversationFilters.orderBy
            )
            val conversations = if (repo != null) {
                var loaded = repo.refreshConversationsFirstPage(requestFilters)
                if (activeConversationFilters.rating != "all") {
                    while (repo.hasMoreConversationsSnapshot()) {
                        loaded = repo.loadMoreConversationsPage(requestFilters)
                    }
                }
                loaded
            } else {
                repository.getConversations()
            }
            _uiState.value = _uiState.value.copy(
                conversations = conversations,
                hasMoreConversations = repo?.hasMoreConversationsSnapshot() ?: false,
                isLoadingMoreConversations = repo?.isLoadingMoreConversationsSnapshot() ?: false
            )
        }
    }

    fun loadMoreConversations() {
        val repo = networkRepo() ?: return
        if (_uiState.value.isLoadingMoreConversations || !_uiState.value.hasMoreConversations) return
        viewModelScope.launch(Dispatchers.IO) {
            _uiState.value = _uiState.value.copy(isLoadingMoreConversations = true)
            try {
                val conversations = repo.loadMoreConversationsPage(
                    NetworkChatRepository.ConversationsRequestFilters(
                        status = activeConversationFilters.status,
                        tag = activeConversationFilters.tag,
                        agent = activeConversationFilters.agent,
                        rating = "all",
                        tap = activeConversationFilters.tap,
                        orderBy = activeConversationFilters.orderBy
                    )
                )
                _uiState.value = _uiState.value.copy(
                    conversations = conversations,
                    hasMoreConversations = repo.hasMoreConversationsSnapshot(),
                    isLoadingMoreConversations = false
                )
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(isLoadingMoreConversations = false)
            }
        }
    }

    fun refreshAvailableTags() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                refreshAvailableTagsInternal()
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(availableTags = emptyList())
            }
        }
    }

    private suspend fun refreshAvailableTagsInternal() {
        val tags = networkRepo()?.listAvailableTags().orEmpty()
        _uiState.value = _uiState.value.copy(availableTags = tags)
    }

    fun refreshAvailableAgents() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                refreshAvailableAgentsInternal()
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(availableAgents = emptyList())
            }
        }
    }

    fun refreshAvailableTemplates() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val payload = networkRepo()?.getTemplates()
                val parsed = parseAvailableTemplates(payload)
                _uiState.value = _uiState.value.copy(availableTemplates = parsed)
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(availableTemplates = emptyList())
            }
        }
    }

    fun refreshAvailableFlows() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val payload = networkRepo()?.getFlows()
                val parsed = parseAvailableFlows(payload)
                _uiState.value = _uiState.value.copy(availableFlows = parsed)
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(availableFlows = emptyList())
            }
        }
    }

    fun refreshAvailableReplies() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val payload = networkRepo()?.getReplies()
                val parsed = parseAvailableReplies(payload)
                _uiState.value = _uiState.value.copy(availableReplies = parsed)
            } catch (_: Exception) {
                _uiState.value = _uiState.value.copy(availableReplies = emptyList())
            }
        }
    }

    private suspend fun refreshAvailableAgentsInternal() {
        val payload = networkRepo()?.getAgents()
        val parsed = parseAvailableAgents(payload)
        _uiState.value = _uiState.value.copy(availableAgents = parsed)
    }

    private fun parseAvailableAgents(payload: JSONObject?): List<AvailableAgent> {
        val items = payload?.optJSONArray("agents")
            ?: payload?.optJSONArray("data")
            ?: payload?.optJSONArray("rows")
            ?: payload?.optJSONArray("result")
            ?: return emptyList()
        val parsed = buildList {
            for (i in 0 until items.length()) {
                val item = items.optJSONObject(i) ?: continue
                val id = sequenceOf("id", "agent_id", "user_id")
                    .mapNotNull { key -> item.opt(key)?.toString()?.toLongOrNull() }
                    .firstOrNull()
                    ?: continue
                val name = sequenceOf("name", "full_name", "username")
                    .map { key -> item.optString(key).trim() }
                    .firstOrNull { it.isNotBlank() }
                    ?: continue
                add(AvailableAgent(id = id, name = name))
            }
        }
        return parsed.distinctBy { it.id }
    }

    private fun parseAvailableCustomFields(payload: JSONObject?): List<AvailableCustomField> {
        if (payload == null) return emptyList()
        val result = mutableListOf<AvailableCustomField>()
        val seen = mutableSetOf<String>()

        fun addField(idRaw: String?, labelRaw: String?, valueRaw: String?) {
            val id = idRaw?.trim().orEmpty()
            if (id.isEmpty() || !seen.add(id)) return
            val label = labelRaw?.trim().takeUnless { it.isNullOrEmpty() } ?: id
            result += AvailableCustomField(id = id, label = label, value = valueRaw?.trim()?.takeIf { it.isNotEmpty() })
        }

        fun parseArray(array: org.json.JSONArray?) {
            if (array == null) return
            for (i in 0 until array.length()) {
                val item = array.optJSONObject(i) ?: continue
                val id = sequenceOf("id", "field_id", "key", "name")
                    .mapNotNull { key -> item.opt(key)?.toString()?.trim() }
                    .firstOrNull { it.isNotEmpty() }
                val label = sequenceOf("label", "name", "title", "key")
                    .map { key -> item.optString(key).trim() }
                    .firstOrNull { it.isNotEmpty() }
                val value = sequenceOf("value", "field_value", "current", "default")
                    .map { key -> item.opt(key)?.toString()?.trim() }
                    .firstOrNull { !it.isNullOrEmpty() }
                addField(id, label, value)
            }
        }

        fun parseObjectMap(obj: JSONObject?) {
            if (obj == null) return
            val keys = obj.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                val raw = obj.opt(key)
                when (raw) {
                    is JSONObject -> {
                        val id = sequenceOf("id", "field_id", "key").mapNotNull { raw.opt(it)?.toString() }.firstOrNull() ?: key
                        val label = sequenceOf("label", "name", "title", "key").map { raw.optString(it).trim() }.firstOrNull { it.isNotEmpty() } ?: key
                        val value = sequenceOf("value", "field_value", "current", "default")
                            .map { raw.opt(it)?.toString()?.trim() }
                            .firstOrNull { !it.isNullOrEmpty() }
                        addField(id, label, value)
                    }
                    else -> addField(key, key, raw?.toString())
                }
            }
        }

        parseArray(payload.optJSONArray("fields"))
        parseArray(payload.optJSONArray("custom_fields"))
        parseArray(payload.optJSONArray("data"))
        parseArray(payload.optJSONArray("rows"))
        parseArray(payload.optJSONArray("result"))
        val dataObj = payload.optJSONObject("data")
        parseArray(dataObj?.optJSONArray("fields"))
        parseArray(dataObj?.optJSONArray("custom_fields"))
        parseObjectMap(payload.optJSONObject("custom"))
        parseObjectMap(payload.optJSONObject("fields"))
        parseObjectMap(dataObj?.optJSONObject("custom"))
        parseObjectMap(dataObj?.optJSONObject("fields"))

        return result
    }

    private fun parseAvailableTemplates(payload: JSONObject?): List<AvailableTemplate> {
        var items = payload?.optJSONArray("templates")
            ?: payload?.optJSONArray("data")
            ?: payload?.optJSONArray("rows")
            ?: payload?.optJSONArray("result")
        if (items == null) {
            val dataObj = payload?.optJSONObject("data")
            items = dataObj?.optJSONArray("templates")
                ?: dataObj?.optJSONArray("rows")
                ?: dataObj?.optJSONArray("result")
        }
        if (items == null) return emptyList()
        val parsed = buildList {
            for (i in 0 until items.length()) {
                val item = items.optJSONObject(i) ?: continue
                val id = sequenceOf("id", "template_id")
                    .mapNotNull { key -> item.opt(key)?.toString()?.toLongOrNull() }
                    .firstOrNull()
                    ?: continue
                val name = sequenceOf("name", "title")
                    .map { key -> item.optString(key).trim() }
                    .firstOrNull { it.isNotEmpty() }
                    ?: continue
                add(AvailableTemplate(id = id, name = name))
            }
        }
        return parsed.distinctBy { it.id }
    }

    private fun parseAvailableFlows(payload: JSONObject?): List<AvailableFlow> {
        var items = payload?.optJSONArray("flows")
            ?: payload?.optJSONArray("data")
            ?: payload?.optJSONArray("rows")
            ?: payload?.optJSONArray("result")
        if (items == null) {
            val dataObj = payload?.optJSONObject("data")
            items = dataObj?.optJSONArray("flows")
                ?: dataObj?.optJSONArray("rows")
                ?: dataObj?.optJSONArray("result")
        }
        if (items == null) return emptyList()
        val parsed = buildList {
            for (i in 0 until items.length()) {
                val item = items.optJSONObject(i) ?: continue
                val id = sequenceOf("id", "flow_id")
                    .mapNotNull { key -> item.opt(key)?.toString()?.toLongOrNull() }
                    .firstOrNull()
                    ?: continue
                val name = sequenceOf("name", "title")
                    .map { key -> item.optString(key).trim() }
                    .firstOrNull { it.isNotEmpty() }
                    ?: continue
                add(AvailableFlow(id = id, name = name))
            }
        }
        return parsed.distinctBy { it.id }
    }

    private fun parseAvailableReplies(payload: JSONObject?): List<AvailableReply> {
        var items = payload?.optJSONArray("replies")
            ?: payload?.optJSONArray("data")
            ?: payload?.optJSONArray("rows")
            ?: payload?.optJSONArray("result")
        if (items == null) {
            val dataObj = payload?.optJSONObject("data")
            items = dataObj?.optJSONArray("replies")
                ?: dataObj?.optJSONArray("rows")
                ?: dataObj?.optJSONArray("result")
        }
        if (items == null) return emptyList()
        val parsed = buildList {
            for (i in 0 until items.length()) {
                val item = items.optJSONObject(i) ?: continue
                val id = sequenceOf("id", "reply_id")
                    .mapNotNull { key -> item.opt(key)?.toString()?.toLongOrNull() }
                    .firstOrNull()
                    ?: continue
                val name = sequenceOf("name", "title")
                    .map { key -> item.optString(key).trim() }
                    .firstOrNull { it.isNotEmpty() }
                    ?: continue
                val text = sequenceOf("text", "value", "message")
                    .map { key -> item.optString(key).trim() }
                    .firstOrNull { it.isNotEmpty() }
                    ?: continue
                add(AvailableReply(id = id, name = name, text = text))
            }
        }
        return parsed.distinctBy { it.id }
    }

    private fun networkRepo(): NetworkChatRepository? = repository as? NetworkChatRepository

    private suspend fun fetchLatestMessages(conversationId: String, resetHistory: Boolean = false): List<ChatMessage> {
        val repo = networkRepo()
        return if (repo != null) {
            repo.refreshMessagesFirstPage(conversationId, resetLoaded = resetHistory)
        } else {
            repository.getMessages(conversationId)
        }
    }

    private fun launchPostLoginDataWarmup() {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val repo = networkRepo()
                val conversations = if (repo != null) {
                    repo.refreshConversationsFirstPage(
                        NetworkChatRepository.ConversationsRequestFilters(
                            status = activeConversationFilters.status,
                            tag = activeConversationFilters.tag,
                            agent = activeConversationFilters.agent,
                            rating = "all",
                            tap = activeConversationFilters.tap,
                            orderBy = activeConversationFilters.orderBy
                        )
                    )
                } else {
                    repository.getConversations()
                }
                _uiState.value = _uiState.value.copy(
                    conversations = conversations,
                    hasMoreConversations = repo?.hasMoreConversationsSnapshot() ?: false,
                    isLoadingMoreConversations = repo?.isLoadingMoreConversationsSnapshot() ?: false
                )
            } catch (_: Exception) {
            }
        }
        refreshAvailableTags()
        refreshAvailableAgents()
        refreshAvailableTemplates()
        refreshAvailableFlows()
        refreshAvailableReplies()
    }

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

    private fun startActiveChatPolling(conversationId: String) {
        activeChatPollingJob?.cancel()
        activeChatPollingJob = viewModelScope.launch(Dispatchers.IO) {
            while (isActive) {
                delay(4000)
                if (_uiState.value.activeChatId != conversationId || _uiState.value.screen != AppScreen.CHAT) {
                    break
                }
                val latest = mergeWithLocalOutgoing(conversationId, fetchLatestMessages(conversationId))
                val conversations = repository.getConversations()
                if (_uiState.value.activeChatId == conversationId) {
                    _uiState.value = _uiState.value.copy(
                        activeMessages = latest,
                        conversations = conversations,
                        hasMoreActiveMessages = networkRepo()?.hasMoreMessagesSnapshot(conversationId) ?: false,
                        isLoadingMoreActiveMessages = networkRepo()?.isLoadingMoreMessagesSnapshot(conversationId) ?: false
                    )
                }
            }
        }
    }

    private fun stopActiveChatPolling() {
        activeChatPollingJob?.cancel()
        activeChatPollingJob = null
    }

    private fun onRealtimeGeneralEvent(channel: String) {
        if (!_uiState.value.isLoggedIn) return
        if (channel.startsWith("chatupdate.")) {
            scheduleRealtimeConversationsRefresh()
            _uiState.value.activeChatId?.let { scheduleRealtimeActiveChatRefresh(it) }
        } else if (channel.startsWith("chat.")) {
            val activeId = _uiState.value.activeChatId ?: return
            val eventChatId = channel.removePrefix("chat.").trim()
            if (eventChatId == activeId) {
                scheduleRealtimeActiveChatRefresh(activeId)
            }
            scheduleRealtimeConversationsRefresh()
        }
    }

    private fun scheduleRealtimeConversationsRefresh() {
        realtimeConversationsRefreshJob?.cancel()
        realtimeConversationsRefreshJob = viewModelScope.launch(Dispatchers.IO) {
            delay(250)
            val repo = networkRepo()
            val conversations = if (repo != null) {
                repo.refreshConversationsFirstPage(
                    NetworkChatRepository.ConversationsRequestFilters(
                        status = activeConversationFilters.status,
                        tag = activeConversationFilters.tag,
                        agent = activeConversationFilters.agent,
                        rating = "all",
                        tap = activeConversationFilters.tap,
                        orderBy = activeConversationFilters.orderBy
                    )
                )
            } else {
                repository.getConversations()
            }
            _uiState.value = _uiState.value.copy(
                conversations = conversations,
                hasMoreConversations = repo?.hasMoreConversationsSnapshot() ?: false,
                isLoadingMoreConversations = repo?.isLoadingMoreConversationsSnapshot() ?: false
            )
        }
    }

    private fun scheduleRealtimeActiveChatRefresh(conversationId: String) {
        realtimeActiveChatRefreshJob?.cancel()
        realtimeActiveChatRefreshJob = viewModelScope.launch(Dispatchers.IO) {
            delay(150)
            if (_uiState.value.activeChatId != conversationId || _uiState.value.screen != AppScreen.CHAT) return@launch
            val latest = mergeWithLocalOutgoing(conversationId, fetchLatestMessages(conversationId))
            if (_uiState.value.activeChatId == conversationId) {
                _uiState.value = _uiState.value.copy(
                    activeMessages = latest,
                    hasMoreActiveMessages = networkRepo()?.hasMoreMessagesSnapshot(conversationId) ?: false,
                    isLoadingMoreActiveMessages = networkRepo()?.isLoadingMoreMessagesSnapshot(conversationId) ?: false
                )
            }
        }
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

    override fun onCleared() {
        super.onCleared()
        realtimeClient.disconnect()
    }
}
