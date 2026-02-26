package com.widers.widerchat.ui

import androidx.lifecycle.ViewModel
import com.widers.widerchat.data.repository.MockChatRepository
import com.widers.widerchat.domain.model.AppLocale
import com.widers.widerchat.domain.model.AppScreen
import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.domain.model.MessageDeliveryStatus
import com.widers.widerchat.domain.model.MessageSender
import com.widers.widerchat.domain.model.MessageType
import com.widers.widerchat.domain.repository.ChatRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.random.Random

data class AppUiState(
    val locale: AppLocale = AppLocale.EN,
    val darkMode: Boolean = false,
    val isLoggedIn: Boolean = false,
    val screen: AppScreen = AppScreen.LOGIN,
    val activeChatId: String? = null,
    val conversations: List<Conversation> = emptyList(),
    val activeMessages: List<ChatMessage> = emptyList()
)

class AppViewModel(
    private val repository: ChatRepository = MockChatRepository()
) : ViewModel() {
    private val _uiState = MutableStateFlow(
        AppUiState(conversations = repository.getConversations())
    )
    val uiState: StateFlow<AppUiState> = _uiState.asStateFlow()

    fun login(email: String, password: String): Boolean {
        if (email.isBlank() || password.isBlank()) return false
        _uiState.value = _uiState.value.copy(
            isLoggedIn = true,
            screen = AppScreen.CONVERSATIONS,
            conversations = repository.getConversations()
        )
        return true
    }

    fun logout() {
        _uiState.value = _uiState.value.copy(
            isLoggedIn = false,
            screen = AppScreen.LOGIN,
            activeChatId = null,
            activeMessages = emptyList()
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
        _uiState.value = _uiState.value.copy(
            activeChatId = conversationId,
            screen = AppScreen.CHAT,
            activeMessages = repository.getMessages(conversationId)
        )
    }

    fun backToConversations() {
        _uiState.value = _uiState.value.copy(
            screen = AppScreen.CONVERSATIONS,
            conversations = repository.getConversations()
        )
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
        repository.appendMessage(msg)
        _uiState.value = _uiState.value.copy(
            activeMessages = repository.getMessages(convoId),
            conversations = repository.getConversations()
        )
    }

    fun addNote(text: String) {
        val convoId = _uiState.value.activeChatId ?: return
        if (text.isBlank()) return
        val note = ChatMessage(
            id = "note-${System.currentTimeMillis()}",
            conversationId = convoId,
            content = text.trim(),
            timestamp = nowLabel(),
            type = MessageType.NOTE,
            sender = MessageSender.AGENT,
            status = MessageDeliveryStatus.READ,
            noteAuthor = "You"
        )
        repository.appendMessage(note)
        _uiState.value = _uiState.value.copy(
            activeMessages = repository.getMessages(convoId),
            conversations = repository.getConversations()
        )
    }

    fun toggleConversationStatus() {
        val convoId = _uiState.value.activeChatId ?: return
        val convo = _uiState.value.conversations.firstOrNull { it.id == convoId } ?: return
        val newStatus = if (convo.status == ConversationStatus.OPEN) {
            ConversationStatus.CLOSED
        } else {
            ConversationStatus.OPEN
        }
        repository.updateConversationStatus(convoId, newStatus)
        _uiState.value = _uiState.value.copy(
            activeMessages = repository.getMessages(convoId),
            conversations = repository.getConversations()
        )
    }

    fun randomIncomingMessage() {
        val openConversations = _uiState.value.conversations.filter { it.status == ConversationStatus.OPEN }
        if (openConversations.isEmpty()) return
        val randomConvo = openConversations[Random.nextInt(openConversations.size)]
        val inbound = ChatMessage(
            id = "in-${System.currentTimeMillis()}",
            conversationId = randomConvo.id,
            content = "New customer message",
            timestamp = nowLabel(),
            type = MessageType.TEXT,
            sender = MessageSender.CUSTOMER,
            status = MessageDeliveryStatus.READ
        )
        repository.appendMessage(inbound)
        _uiState.value = _uiState.value.copy(
            activeMessages = if (_uiState.value.activeChatId == randomConvo.id) repository.getMessages(randomConvo.id) else _uiState.value.activeMessages,
            conversations = repository.getConversations()
        )
    }

    private fun nowLabel(): String {
        val locale = if (_uiState.value.locale == AppLocale.AR) Locale.forLanguageTag("ar-SA") else Locale.US
        return SimpleDateFormat("h:mm a", locale).format(Date())
    }
}
