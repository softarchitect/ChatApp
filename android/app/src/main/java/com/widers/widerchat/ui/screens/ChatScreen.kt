package com.widers.widerchat.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.NoteAlt
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Done
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.widers.widerchat.core.TextKey
import com.widers.widerchat.core.tr
import com.widers.widerchat.domain.model.AppLocale
import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.domain.model.MessageSender
import com.widers.widerchat.domain.model.MessageType

@Composable
fun ChatScreen(
    modifier: Modifier = Modifier,
    locale: AppLocale,
    darkMode: Boolean,
    conversations: List<Conversation>,
    activeChatId: String?,
    messages: List<ChatMessage>,
    onBack: () -> Unit,
    onSend: (String) -> Unit,
    onAddNote: (String) -> Unit,
    onToggleStatus: () -> Unit
) {
    val conversation = conversations.firstOrNull { it.id == activeChatId } ?: return
    var text by remember { mutableStateOf("") }
    var noteText by remember { mutableStateOf("") }
    var showNote by remember { mutableStateOf(false) }
    var menuOpen by remember { mutableStateOf(false) }

    Column(modifier = modifier.fillMaxSize()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surface)
                .padding(horizontal = 8.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack, modifier = Modifier.size(36.dp)) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, null) }
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(avatarColor(conversation.customerName)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    conversation.customerName.split(" ").mapNotNull { it.firstOrNull()?.toString() }.take(2).joinToString("").uppercase(),
                    color = Color.White,
                    fontWeight = FontWeight.Bold
                )
            }
            Spacer(Modifier.size(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(conversation.customerName, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(
                    if (conversation.isOnline) tr(locale, TextKey.ONLINE) else "${tr(locale, TextKey.LAST_SEEN)} ${conversation.lastMessageTime}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            IconButton(onClick = {}, modifier = Modifier.size(36.dp)) { Icon(Icons.Outlined.Call, null, tint = MaterialTheme.colorScheme.onSurfaceVariant) }
            Box {
                IconButton(onClick = { menuOpen = true }, modifier = Modifier.size(36.dp)) { Icon(Icons.Outlined.MoreVert, null, tint = MaterialTheme.colorScheme.onSurfaceVariant) }
                DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                    DropdownMenuItem(
                        text = { Text(tr(locale, TextKey.INTERNAL_NOTE)) },
                        leadingIcon = { Icon(Icons.Outlined.NoteAlt, null, tint = Color(0xFFF59E0B)) },
                        onClick = {
                            showNote = !showNote
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = {
                            Text(
                                if (conversation.status == ConversationStatus.OPEN) tr(locale, TextKey.CLOSE_CONVERSATION) else tr(locale, TextKey.REOPEN_CONVERSATION),
                                color = if (conversation.status == ConversationStatus.OPEN) Color(0xFFEF4444) else MaterialTheme.colorScheme.primary
                            )
                        },
                        leadingIcon = {
                            Icon(
                                if (conversation.status == ConversationStatus.OPEN) Icons.Outlined.Close else Icons.Outlined.Refresh,
                                null,
                                tint = if (conversation.status == ConversationStatus.OPEN) Color(0xFFEF4444) else MaterialTheme.colorScheme.primary
                            )
                        },
                        onClick = {
                            onToggleStatus()
                            menuOpen = false
                        }
                    )
                }
            }
        }

        if (conversation.status == ConversationStatus.CLOSED) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.secondary)
                    .padding(vertical = 6.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(tr(locale, TextKey.CONVERSATION_CLOSED), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(top = 6.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            item {
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Text(
                        tr(locale, TextKey.TODAY),
                        style = MaterialTheme.typography.labelSmall,
                        modifier = Modifier
                            .clip(RoundedCornerShape(14.dp))
                            .background(MaterialTheme.colorScheme.secondary)
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    )
                }
            }
            items(messages, key = { it.id }) { msg ->
                MessageBubble(msg = msg, darkMode = darkMode)
            }
        }

        if (showNote) {
            ElevatedCard(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.elevatedCardColors(containerColor = Color(0xFFFEF3C7))
            ) {
                Column(modifier = Modifier.padding(10.dp)) {
                    Text(tr(locale, TextKey.INTERNAL_NOTE), style = MaterialTheme.typography.labelLarge, color = Color(0xFF92400E))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        OutlinedTextField(
                            modifier = Modifier.weight(1f),
                            value = noteText,
                            onValueChange = { noteText = it },
                            placeholder = { Text(tr(locale, TextKey.INTERNAL_NOTE_PLACEHOLDER), maxLines = 1, overflow = TextOverflow.Ellipsis) },
                            shape = RoundedCornerShape(10.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedContainerColor = Color(0xFFFFF7ED),
                                unfocusedContainerColor = Color(0xFFFFF7ED)
                            )
                        )
                        TextButton(onClick = {
                            onAddNote(noteText)
                            noteText = ""
                            showNote = false
                        }) { Text(tr(locale, TextKey.ADD_NOTE), color = Color(0xFF92400E)) }
                    }
                }
            }
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surface)
                .padding(horizontal = 10.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = {}, modifier = Modifier.size(36.dp)) {
                Icon(Icons.Outlined.Image, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            OutlinedTextField(
                modifier = Modifier.weight(1f),
                value = text,
                onValueChange = { text = it },
                placeholder = { Text(tr(locale, TextKey.TYPE_MESSAGE), color = MaterialTheme.colorScheme.onSurfaceVariant) },
                enabled = conversation.status == ConversationStatus.OPEN,
                shape = RoundedCornerShape(24.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.secondary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.secondary,
                    focusedContainerColor = MaterialTheme.colorScheme.secondary,
                    unfocusedContainerColor = MaterialTheme.colorScheme.secondary
                )
            )
            Spacer(Modifier.size(8.dp))
            IconButton(
                onClick = {
                    onSend(text)
                    text = ""
                },
                enabled = text.isNotBlank() && conversation.status == ConversationStatus.OPEN,
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary)
            ) {
                Icon(Icons.AutoMirrored.Outlined.Send, null, tint = MaterialTheme.colorScheme.onPrimary)
            }
        }
    }
}

@Composable
private fun MessageBubble(msg: ChatMessage, darkMode: Boolean) {
    if (msg.type == MessageType.NOTE) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp),
            contentAlignment = Alignment.Center
        ) {
            ElevatedCard(
                modifier = Modifier.widthIn(max = 360.dp),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.elevatedCardColors(
                    containerColor = if (darkMode) Color(0xFF422006) else Color(0xFFFEF3C7)
                )
            ) {
                Column(modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)) {
                    val noteTitle = if (darkMode) Color(0xFFFCD34D) else Color(0xFFB45309)
                    val noteBody = if (darkMode) Color(0xFFFFF7ED) else Color(0xFF78350F)
                    val noteMeta = if (darkMode) Color(0xFFF59E0B) else Color(0xFFB45309)
                    Text("Note by ${msg.noteAuthor ?: "You"}", fontWeight = FontWeight.Bold, color = noteTitle)
                    Text(msg.content, color = noteBody)
                    Text(msg.timestamp, style = MaterialTheme.typography.labelSmall, color = noteMeta)
                }
            }
        }
        return
    }

    val isAgent = msg.sender == MessageSender.AGENT
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp),
        horizontalArrangement = if (isAgent) Arrangement.End else Arrangement.Start
    ) {
        val bubbleShape = if (isAgent) {
            RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp, bottomStart = 16.dp, bottomEnd = 6.dp)
        } else {
            RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp, bottomStart = 6.dp, bottomEnd = 16.dp)
        }
        Box(
            modifier = Modifier
                .widthIn(max = 340.dp)
                .clip(bubbleShape)
                .background(
                    if (isAgent) {
                        if (darkMode) Color(0xFF0D3D2E) else Color(0xFFE8FAF0)
                    } else {
                        if (darkMode) Color(0xFF1E293B) else MaterialTheme.colorScheme.surface
                    }
                )
                .border(
                    width = if (isAgent) 0.dp else 1.dp,
                    color = if (isAgent) {
                        Color.Transparent
                    } else {
                        if (darkMode) Color(0xFF334155) else MaterialTheme.colorScheme.outline
                    },
                    shape = bubbleShape
                )
                .padding(horizontal = 12.dp, vertical = 8.dp)
        ) {
            Column {
                val messageColor = if (isAgent) {
                    if (darkMode) Color(0xFFF1F5F9) else Color(0xFF0F172A)
                } else {
                    if (darkMode) Color(0xFFF1F5F9) else MaterialTheme.colorScheme.onSurface
                }
                val metaColor = if (isAgent) {
                    if (darkMode) Color(0xFF93C5FD) else Color(0xFF475569)
                } else {
                    if (darkMode) Color(0xFF94A3B8) else MaterialTheme.colorScheme.onSurfaceVariant
                }
                Text(msg.content, color = messageColor)
                Row(
                    modifier = Modifier.fillMaxWidth().padding(top = 2.dp),
                    horizontalArrangement = if (isAgent) Arrangement.End else Arrangement.Start,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(msg.timestamp, style = MaterialTheme.typography.labelSmall, color = metaColor)
                    if (isAgent) {
                        Spacer(Modifier.size(2.dp))
                        when (msg.status.name) {
                            "READ" -> Icon(Icons.Outlined.DoneAll, null, tint = Color(0xFF3B82F6), modifier = Modifier.size(12.dp))
                            "DELIVERED" -> Icon(Icons.Outlined.DoneAll, null, tint = metaColor, modifier = Modifier.size(12.dp))
                            else -> Icon(Icons.Outlined.Done, null, tint = metaColor, modifier = Modifier.size(12.dp))
                        }
                    }
                }
            }
        }
    }
}

private fun avatarColor(name: String): Color {
    val colors = listOf(
        Color(0xFF3B82F6),
        Color(0xFF10B981),
        Color(0xFFF59E0B),
        Color(0xFFF43F5E),
        Color(0xFF06B6D4),
        Color(0xFF6366F1),
        Color(0xFF14B8A6),
        Color(0xFFF97316)
    )
    val i = name.firstOrNull()?.code?.rem(colors.size) ?: 0
    return colors[i]
}
