package com.widers.widerchat.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
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
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.ui.NewConversationContact

@Composable
fun ConversationsScreen(
    modifier: Modifier = Modifier,
    locale: AppLocale,
    conversations: List<Conversation>,
    contacts: List<NewConversationContact>,
    contactsLoading: Boolean,
    onOpenChat: (String) -> Unit,
    onSearchChats: (String) -> Unit,
    onLoadContacts: () -> Unit,
    onSearchContacts: (String) -> Unit,
    onStartConversationForContact: (NewConversationContact) -> Unit,
    onStartNewConversation: (String, String) -> Unit,
    actionStatus: String?
) {
    var search by remember { mutableStateOf("") }
    var tab by remember { mutableStateOf("all") }
    var showNewConversationDialog by remember { mutableStateOf(false) }
    var newName by remember { mutableStateOf("") }
    var newPhone by remember { mutableStateOf("") }
    var contactSearch by remember { mutableStateOf("") }

    val filtered = conversations.filter {
        val tabOk = when (tab) {
            "open" -> it.status == ConversationStatus.OPEN
            "closed" -> it.status == ConversationStatus.CLOSED
            else -> true
        }
        val q = search.trim().lowercase()
        tabOk && (q.isBlank() || it.customerName.lowercase().contains(q) || it.lastMessage.lowercase().contains(q))
    }
    val totalUnread = conversations.sumOf { it.unreadCount }

    Column(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surface)
                .padding(horizontal = 20.dp, vertical = 16.dp)
        ) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column {
                    Text(
                        tr(locale, TextKey.CONVERSATIONS_TITLE),
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    if (totalUnread > 0) {
                        Text(
                            "$totalUnread ${tr(locale, TextKey.UNREAD)}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f))
                        .clickable {
                            showNewConversationDialog = true
                            contactSearch = ""
                            onLoadContacts()
                        },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Outlined.ChatBubbleOutline, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                }
            }

            Spacer(Modifier.height(14.dp))
            TextField(
                value = search,
                onValueChange = {
                    search = it
                    onSearchChats(it)
                },
                modifier = Modifier.fillMaxWidth().height(48.dp),
                leadingIcon = { Icon(Icons.Outlined.Search, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant) },
                placeholder = { Text(tr(locale, TextKey.SEARCH_PLACEHOLDER), color = MaterialTheme.colorScheme.onSurfaceVariant) },
                singleLine = true,
                shape = RoundedCornerShape(12.dp),
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = MaterialTheme.colorScheme.secondary,
                    unfocusedContainerColor = MaterialTheme.colorScheme.secondary,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent
                )
            )
            if (!actionStatus.isNullOrBlank()) {
                Spacer(Modifier.height(6.dp))
                Text(
                    actionStatus,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary
                )
            }
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                TabChip(tr(locale, TextKey.ALL), conversations.size, tab == "all") { tab = "all" }
                TabChip(tr(locale, TextKey.OPEN), conversations.count { it.status == ConversationStatus.OPEN }, tab == "open") { tab = "open" }
                TabChip(tr(locale, TextKey.CLOSED), conversations.count { it.status == ConversationStatus.CLOSED }, tab == "closed") { tab = "closed" }
            }
        }
        HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.28f))

        if (filtered.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(tr(locale, TextKey.NO_CONVERSATIONS), fontWeight = FontWeight.SemiBold)
                    Text(
                        tr(locale, TextKey.NO_CONVERSATIONS_DESC),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            LazyColumn {
                items(filtered, key = { it.id }) { convo ->
                    ConversationRow(
                        convo = convo,
                        locale = locale,
                        onClick = { onOpenChat(convo.id) }
                    )
                }
            }
        }
    }

    if (showNewConversationDialog) {
        AlertDialog(
            onDismissRequest = { showNewConversationDialog = false },
            title = { Text(tr(locale, TextKey.NEW_CONVERSATION_TITLE)) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = newName,
                        onValueChange = { newName = it },
                        singleLine = true,
                        label = { Text(tr(locale, TextKey.NAME_LABEL)) }
                    )
                    OutlinedTextField(
                        value = newPhone,
                        onValueChange = { newPhone = it },
                        singleLine = true,
                        label = { Text(tr(locale, TextKey.PHONE_LABEL)) }
                    )
                    OutlinedTextField(
                        value = contactSearch,
                        onValueChange = {
                            contactSearch = it
                            onSearchContacts(it)
                        },
                        singleLine = true,
                        label = { Text(tr(locale, TextKey.SEARCH_CONTACTS)) }
                    )
                    Text(
                        text = tr(locale, TextKey.NEW_CONVERSATION_MESSAGE),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.height(10.dp))
                    if (contactsLoading) {
                        Text(
                            text = tr(locale, TextKey.LOADING_CONTACTS),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } else {
                        contacts
                            .filter { item ->
                                val qName = contactSearch.trim().lowercase()
                                val qPhone = contactSearch.filter { it.isDigit() }
                                val nameMatch = qName.isBlank() || item.name.lowercase().contains(qName)
                                val phoneMatch = qPhone.isBlank() || item.phone.filter { it.isDigit() }.contains(qPhone)
                                nameMatch && phoneMatch
                            }
                            .take(8)
                            .forEach { item ->
                                HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f))
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable {
                                            onStartConversationForContact(item)
                                            showNewConversationDialog = false
                                            newName = ""
                                            newPhone = ""
                                        }
                                        .padding(vertical = 8.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Text(item.name, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                    Text(
                                        item.phone,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = { showNewConversationDialog = false }) { Text(tr(locale, TextKey.CANCEL)) }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        onStartNewConversation(newName, newPhone)
                        showNewConversationDialog = false
                        newName = ""
                        newPhone = ""
                    },
                    enabled = newName.isNotBlank() && newPhone.isNotBlank()
                ) { Text(tr(locale, TextKey.CREATE)) }
            }
        )
    }
}

@Composable
private fun TabChip(label: String, count: Int, selected: Boolean, onClick: () -> Unit) {
    Surface(
        shape = RoundedCornerShape(10.dp),
        color = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.secondary,
        modifier = Modifier.clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                label,
                color = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                style = MaterialTheme.typography.labelLarge
            )
            Spacer(Modifier.size(6.dp))
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .background(
                        if (selected) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.2f)
                        else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.1f)
                    )
                    .padding(horizontal = 5.dp, vertical = 2.dp)
            ) {
                Text(
                    "$count",
                    style = MaterialTheme.typography.labelSmall,
                    color = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun ConversationRow(convo: Conversation, locale: AppLocale, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(CircleShape)
                .background(avatarColor(convo.customerName)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                convo.customerName.split(" ").mapNotNull { it.firstOrNull()?.toString() }.take(2).joinToString("").uppercase(),
                color = Color.White,
                fontWeight = FontWeight.Bold
            )
        }

        Column(modifier = Modifier.weight(1f)) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(
                    convo.customerName,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    fontWeight = if (convo.unreadCount > 0) FontWeight.SemiBold else FontWeight.Medium
                )
                Text(
                    convo.lastMessageTime,
                    style = MaterialTheme.typography.labelSmall,
                    color = if (convo.unreadCount > 0) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(Modifier.height(2.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(
                    localizedConversationPreview(convo.lastMessage, locale),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (convo.unreadCount > 0) {
                    Box(
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(Color(0xFF0E8C56))
                            .padding(horizontal = 7.dp, vertical = 2.dp)
                    ) {
                        Text("${convo.unreadCount}", color = Color.White, style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
        }
    }
}

private fun localizedConversationPreview(value: String, locale: AppLocale): String {
    if (locale != AppLocale.AR) return value
    return when (value.trim()) {
        "Photo" -> "صورة"
        "Video" -> "فيديو"
        "Voice message" -> "رسالة صوتية"
        "Document" -> "مستند"
        "Media" -> "وسائط"
        else -> value
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
