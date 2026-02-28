package com.widers.widerchat.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Tag
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.widers.widerchat.core.TextKey
import com.widers.widerchat.core.tr
import com.widers.widerchat.domain.model.AvailableTag
import com.widers.widerchat.domain.model.AppLocale
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationTag
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.ui.NewConversationContact
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

private enum class ReadFilter {
    ALL, READ, UNREAD
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun ConversationsScreen(
    modifier: Modifier = Modifier,
    locale: AppLocale,
    conversations: List<Conversation>,
    contacts: List<NewConversationContact>,
    contactsLoading: Boolean,
    availableTags: List<AvailableTag>,
    onOpenChat: (String) -> Unit,
    onSearchChats: (String) -> Unit,
    onLoadContacts: () -> Unit,
    onSearchContacts: (String) -> Unit,
    onStartConversationForContact: (NewConversationContact) -> Unit,
    onStartNewConversation: (String, String) -> Unit,
    onAttachTagQuick: (String, Long) -> Unit,
    onDetachTagQuick: (String, Long) -> Unit,
    onRepeatTagQuick: (String, Long) -> Unit,
    onMarkReadQuick: (String, Boolean) -> Unit,
    onToggleStatusQuick: (String) -> Unit,
    onDeleteConversationsQuick: (List<String>) -> Unit,
    actionStatus: String?
) {
    var search by remember { mutableStateOf("") }
    var tab by remember { mutableStateOf("all") }
    var showNewConversationDialog by remember { mutableStateOf(false) }
    var tagPickerConversationId by remember { mutableStateOf<String?>(null) }
    var tagManageConversationId by remember { mutableStateOf<String?>(null) }
    var tagManageItem by remember { mutableStateOf<ConversationTag?>(null) }
    var swipedConversation by remember { mutableStateOf<Conversation?>(null) }
    var readFilter by remember { mutableStateOf(ReadFilter.ALL) }
    var selectedAgentName by remember { mutableStateOf<String?>(null) }
    var selectedTagId by remember { mutableStateOf<Long?>(null) }
    var showReadFilterDialog by remember { mutableStateOf(false) }
    var showAgentFilterDialog by remember { mutableStateOf(false) }
    var showTagFilterDialog by remember { mutableStateOf(false) }
    var selectedConversationIds by remember { mutableStateOf(setOf<String>()) }
    var newName by remember { mutableStateOf("") }
    var newPhone by remember { mutableStateOf("") }
    var contactSearch by remember { mutableStateOf("") }
    var tagPickerSearch by remember { mutableStateOf("") }
    var tagPickerSearchDebounced by remember { mutableStateOf("") }

    LaunchedEffect(tagPickerSearch) {
        delay(220)
        tagPickerSearchDebounced = tagPickerSearch
    }

    val agentChoices = remember(conversations) {
        conversations.mapNotNull { it.assignedAgentName?.trim() }.filter { it.isNotBlank() }.distinct()
    }
    val filtered = conversations.filter {
        val tabOk = when (tab) {
            "open" -> it.status == ConversationStatus.OPEN
            "closed" -> it.status == ConversationStatus.CLOSED
            else -> true
        }
        val readOk = when (readFilter) {
            ReadFilter.ALL -> true
            ReadFilter.READ -> it.unreadCount == 0
            ReadFilter.UNREAD -> it.unreadCount > 0
        }
        val agentOk = selectedAgentName.isNullOrBlank() || it.assignedAgentName == selectedAgentName
        val tagOk = selectedTagId == null || it.tags.any { tag -> tag.id == selectedTagId }
        val q = search.trim().lowercase()
        tabOk && readOk && agentOk && tagOk &&
            (q.isBlank() || it.customerName.lowercase().contains(q) || it.lastMessage.lowercase().contains(q))
    }
    val selectionMode = selectedConversationIds.isNotEmpty()
    val totalUnread = conversations.sumOf { it.unreadCount }

    Column(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surface)
                .padding(horizontal = 20.dp, vertical = 16.dp)
        ) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                if (selectionMode) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            if (locale == AppLocale.AR) "${selectedConversationIds.size} محدد" else "${selectedConversationIds.size} selected",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        val allSelected = filtered.isNotEmpty() && selectedConversationIds.size == filtered.size
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                            TextButton(
                                onClick = {
                                    selectedConversationIds = if (allSelected) {
                                        emptySet()
                                    } else {
                                        filtered.map { it.id }.toSet()
                                    }
                                }
                            ) {
                                Text(
                                    if (allSelected) {
                                        if (locale == AppLocale.AR) "إلغاء الكل" else "Clear all"
                                    } else {
                                        if (locale == AppLocale.AR) "تحديد الكل" else "Select all"
                                    }
                                )
                            }
                            TextButton(onClick = { selectedConversationIds = emptySet() }) {
                                Text(if (locale == AppLocale.AR) "إلغاء" else "Cancel")
                            }
                            Surface(
                                shape = RoundedCornerShape(999.dp),
                                color = Color(0xFFDC2626).copy(alpha = 0.12f),
                                modifier = Modifier.clickable {
                                    onDeleteConversationsQuick(selectedConversationIds.toList())
                                    selectedConversationIds = emptySet()
                                }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Outlined.Delete, null, tint = Color(0xFFDC2626))
                                    Spacer(Modifier.size(4.dp))
                                    Text(
                                        if (locale == AppLocale.AR) "إزالة" else "Remove",
                                        color = Color(0xFFDC2626),
                                        style = MaterialTheme.typography.labelLarge
                                    )
                                }
                            }
                        }
                    }
                } else {
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
            }

            if (!selectionMode) {
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
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.horizontalScroll(rememberScrollState())
                ) {
                    TabChip(tr(locale, TextKey.ALL), conversations.size, tab == "all") { tab = "all" }
                    TabChip(tr(locale, TextKey.OPEN), conversations.count { it.status == ConversationStatus.OPEN }, tab == "open") { tab = "open" }
                    TabChip(tr(locale, TextKey.CLOSED), conversations.count { it.status == ConversationStatus.CLOSED }, tab == "closed") { tab = "closed" }
                }
                Spacer(Modifier.height(8.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.horizontalScroll(rememberScrollState())
                ) {
                    TabChip(
                        label = if (locale == AppLocale.AR) {
                            when (readFilter) {
                                ReadFilter.ALL -> "القراءة: الكل"
                                ReadFilter.READ -> "القراءة: مقروء"
                                ReadFilter.UNREAD -> "القراءة: غير مقروء"
                            }
                        } else {
                            when (readFilter) {
                                ReadFilter.ALL -> "Read: All"
                                ReadFilter.READ -> "Read: Read"
                                ReadFilter.UNREAD -> "Read: Unread"
                            }
                        },
                        count = conversations.size,
                        selected = readFilter != ReadFilter.ALL,
                        showCaret = true,
                        onClick = { showReadFilterDialog = true }
                    )
                    TabChip(
                        label = if (locale == AppLocale.AR) "الوكيل: ${selectedAgentName ?: "الكل"}" else "Agent: ${selectedAgentName ?: "All"}",
                        count = agentChoices.size,
                        selected = selectedAgentName != null,
                        showCaret = true,
                        onClick = { showAgentFilterDialog = true }
                    )
                    TabChip(
                        label = if (locale == AppLocale.AR) "الوسم: ${selectedTagId ?: "الكل"}" else "Tag: ${selectedTagId ?: "All"}",
                        count = availableTags.size,
                        selected = selectedTagId != null,
                        showCaret = true,
                        onClick = { showTagFilterDialog = true }
                    )
                }
            } else {
                Spacer(Modifier.height(8.dp))
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
                    val isSelected = selectedConversationIds.contains(convo.id)
                    val markReadAction = convo.unreadCount > 0
                    val dismissState = rememberSwipeToDismissBoxState(
                        positionalThreshold = { totalDistance -> totalDistance * 0.18f },
                        confirmValueChange = { target ->
                            if (selectionMode) return@rememberSwipeToDismissBoxState false
                            if (target == SwipeToDismissBoxValue.Settled) return@rememberSwipeToDismissBoxState true
                            when (target) {
                                SwipeToDismissBoxValue.StartToEnd -> {
                                    swipedConversation = convo
                                    false
                                }
                                SwipeToDismissBoxValue.EndToStart -> {
                                    onMarkReadQuick(convo.id, markReadAction)
                                    false
                                }
                                SwipeToDismissBoxValue.Settled -> true
                            }
                        }
                    )
                    if (selectionMode) {
                        Surface(color = MaterialTheme.colorScheme.surface) {
                            Column {
                                ConversationRow(
                                    convo = convo,
                                    locale = locale,
                                    isSelected = isSelected,
                                    selectionMode = selectionMode,
                                    onClick = {
                                        selectedConversationIds = if (isSelected) {
                                            selectedConversationIds - convo.id
                                        } else {
                                            selectedConversationIds + convo.id
                                        }
                                    },
                                    onLongPress = {
                                        selectedConversationIds = selectedConversationIds + convo.id
                                    },
                                    onQuickAddTag = {
                                        tagPickerConversationId = convo.id
                                        tagPickerSearch = ""
                                        tagPickerSearchDebounced = ""
                                    },
                                    onQuickMarkRead = { onMarkReadQuick(convo.id, true) },
                                    onTagInfo = { tag ->
                                        tagManageConversationId = convo.id
                                        tagManageItem = tag
                                    }
                                )
                                HorizontalDivider(
                                    color = MaterialTheme.colorScheme.outline.copy(alpha = 0.14f),
                                    modifier = Modifier.padding(start = 72.dp, end = 16.dp)
                                )
                            }
                        }
                    } else {
                        SwipeToDismissBox(
                            state = dismissState,
                            backgroundContent = {
                            val direction = dismissState.dismissDirection
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp, vertical = 6.dp),
                                horizontalArrangement = if (direction == SwipeToDismissBoxValue.StartToEnd) Arrangement.Start else Arrangement.End
                            ) {
                                if (direction == SwipeToDismissBoxValue.StartToEnd) {
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth(0.52f)
                                            .height(78.dp)
                                            .clip(RoundedCornerShape(10.dp))
                                            .background(Color(0xFFF59E0B)),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                            Icon(Icons.Outlined.ChatBubbleOutline, null, tint = Color.White)
                                            Text(
                                                if (locale == AppLocale.AR) "إجراءات" else "Actions",
                                                color = Color.White,
                                                fontWeight = FontWeight.SemiBold
                                            )
                                        }
                                    }
                                } else if (direction == SwipeToDismissBoxValue.EndToStart) {
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth(0.52f)
                                            .height(78.dp)
                                            .clip(RoundedCornerShape(10.dp))
                                            .background(Color(0xFF10B981)),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                            Icon(Icons.Outlined.Check, null, tint = Color.White)
                                            Text(
                                                if (markReadAction) {
                                                    if (locale == AppLocale.AR) "تحديد كمقروء" else "Mark read"
                                                } else {
                                                    if (locale == AppLocale.AR) "تحديد كغير مقروء" else "Mark unread"
                                                },
                                                color = Color.White,
                                                fontWeight = FontWeight.SemiBold
                                            )
                                        }
                                    }
                                }
                            }
                            }
                        ) {
                            Surface(color = MaterialTheme.colorScheme.surface) {
                                Column {
                                    ConversationRow(
                                        convo = convo,
                                        locale = locale,
                                        isSelected = false,
                                        selectionMode = false,
                                        onClick = { onOpenChat(convo.id) },
                                        onLongPress = {
                                            selectedConversationIds = selectedConversationIds + convo.id
                                        },
                                        onQuickAddTag = {
                                            tagPickerConversationId = convo.id
                                            tagPickerSearch = ""
                                            tagPickerSearchDebounced = ""
                                        },
                                        onQuickMarkRead = { onMarkReadQuick(convo.id, true) },
                                        onTagInfo = { tag ->
                                            tagManageConversationId = convo.id
                                            tagManageItem = tag
                                        }
                                    )
                                    HorizontalDivider(
                                        color = MaterialTheme.colorScheme.outline.copy(alpha = 0.14f),
                                        modifier = Modifier.padding(start = 72.dp, end = 16.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (swipedConversation != null) {
        val active = swipedConversation!!
        val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        ModalBottomSheet(
            onDismissRequest = { swipedConversation = null },
            sheetState = sheetState
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    active.customerName,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                if (!active.assignedAgentName.isNullOrBlank()) {
                    Text(
                        "${if (locale == AppLocale.AR) "الوكيل" else "Agent"}: ${active.assignedAgentName}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
                Text(
                    localizedConversationPreview(active.lastMessage, locale),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                if (active.tags.isNotEmpty()) {
                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        active.tags.take(6).forEach { tag ->
                            Surface(
                                shape = RoundedCornerShape(999.dp),
                                color = parseHexColor(tag.colorHex),
                                modifier = Modifier.clickable {
                                    tagManageConversationId = active.id
                                    tagManageItem = tag
                                    swipedConversation = null
                                }
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        if (tag.repeatedAt.isEmpty()) "1" else "${tag.repeatedAt.size}",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.White
                                    )
                                    Spacer(Modifier.size(5.dp))
                                    Text(
                                        tag.name,
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.White
                                    )
                                }
                            }
                        }
                        if (active.tags.size > 6) {
                            Text(
                                "+${active.tags.size - 6}",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
                HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.2f))
                Text(
                    if (locale == AppLocale.AR) "إجراءات سريعة" else "Quick actions",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                QuickSheetAction(
                    icon = Icons.Outlined.ChatBubbleOutline,
                    label = if (locale == AppLocale.AR) "فتح المحادثة" else "Open chat",
                    subtitle = if (locale == AppLocale.AR) "الانتقال إلى شاشة المحادثة" else "Go to conversation screen",
                    onClick = {
                        onOpenChat(active.id)
                        swipedConversation = null
                    }
                )
                QuickSheetAction(
                    icon = Icons.Outlined.Check,
                    label = if (active.unreadCount > 0) {
                        if (locale == AppLocale.AR) "تحديد كمقروء" else "Mark as read"
                    } else {
                        if (locale == AppLocale.AR) "تحديد كغير مقروء" else "Mark as unread"
                    },
                    subtitle = if (locale == AppLocale.AR) "تحديث حالة القراءة فورًا" else "Update read state immediately",
                    onClick = {
                        onMarkReadQuick(active.id, active.unreadCount > 0)
                        swipedConversation = null
                    }
                )
                QuickSheetAction(
                    icon = Icons.Outlined.Tag,
                    label = if (locale == AppLocale.AR) "إضافة وسم" else "Add tag",
                    subtitle = if (locale == AppLocale.AR) "تطبيق وسم بسرعة على المحادثة" else "Apply a tag quickly to this conversation",
                    onClick = {
                        tagPickerConversationId = active.id
                        tagPickerSearch = ""
                        tagPickerSearchDebounced = ""
                        swipedConversation = null
                    }
                )
                Text(
                    if (locale == AppLocale.AR) "حالة المحادثة" else "Conversation state",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                QuickSheetAction(
                    icon = Icons.Outlined.Close,
                    label = if (active.status == ConversationStatus.OPEN) {
                        if (locale == AppLocale.AR) "إغلاق المحادثة" else "Close conversation"
                    } else {
                        if (locale == AppLocale.AR) "إعادة فتح المحادثة" else "Reopen conversation"
                    },
                    subtitle = if (locale == AppLocale.AR) "تغيير الحالة (مفتوحة/مغلقة)" else "Toggle open/closed status",
                    accent = if (active.status == ConversationStatus.OPEN) Color(0xFFDC2626) else Color(0xFF0E8C56),
                    onClick = {
                        onToggleStatusQuick(active.id)
                        swipedConversation = null
                    }
                )
                TextButton(
                    onClick = { swipedConversation = null },
                    modifier = Modifier.fillMaxWidth()
                ) { Text(tr(locale, TextKey.CLOSE)) }
                Spacer(Modifier.height(8.dp))
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

    if (showReadFilterDialog) {
        AlertDialog(
            onDismissRequest = { showReadFilterDialog = false },
            title = { Text(if (locale == AppLocale.AR) "تصفية القراءة" else "Read filter") },
            text = {
                Column {
                    listOf(ReadFilter.ALL, ReadFilter.READ, ReadFilter.UNREAD).forEach { option ->
                        TextButton(onClick = {
                            readFilter = option
                            showReadFilterDialog = false
                        }) {
                            Text(
                                when (option) {
                                    ReadFilter.ALL -> if (locale == AppLocale.AR) "الكل" else "All"
                                    ReadFilter.READ -> if (locale == AppLocale.AR) "مقروء" else "Read"
                                    ReadFilter.UNREAD -> if (locale == AppLocale.AR) "غير مقروء" else "Unread"
                                }
                            )
                        }
                    }
                }
            },
            confirmButton = {}
        )
    }

    if (showAgentFilterDialog) {
        AlertDialog(
            onDismissRequest = { showAgentFilterDialog = false },
            title = { Text(if (locale == AppLocale.AR) "تصفية الوكيل" else "Agent filter") },
            text = {
                Column {
                    TextButton(onClick = {
                        selectedAgentName = null
                        showAgentFilterDialog = false
                    }) { Text(if (locale == AppLocale.AR) "الكل" else "All") }
                    agentChoices.forEach { agent ->
                        TextButton(onClick = {
                            selectedAgentName = agent
                            showAgentFilterDialog = false
                        }) { Text(agent) }
                    }
                }
            },
            confirmButton = {}
        )
    }

    if (showTagFilterDialog) {
        AlertDialog(
            onDismissRequest = { showTagFilterDialog = false },
            title = { Text(if (locale == AppLocale.AR) "تصفية الوسم" else "Tag filter") },
            text = {
                Column {
                    TextButton(onClick = {
                        selectedTagId = null
                        showTagFilterDialog = false
                    }) { Text(if (locale == AppLocale.AR) "الكل" else "All") }
                    availableTags.take(20).forEach { tag ->
                        TextButton(onClick = {
                            selectedTagId = tag.id
                            showTagFilterDialog = false
                        }) { Text(tag.name) }
                    }
                }
            },
            confirmButton = {}
        )
    }

    if (tagPickerConversationId != null) {
        val q = tagPickerSearchDebounced.trim().lowercase()
        val filteredTags = if (q.isBlank()) {
            availableTags
        } else {
            availableTags.filter { tag ->
                tag.name.lowercase().contains(q) || tag.id.toString().contains(q)
            }
        }
        AlertDialog(
            onDismissRequest = {
                tagPickerConversationId = null
                tagPickerSearch = ""
                tagPickerSearchDebounced = ""
            },
            title = { Text(if (locale == AppLocale.AR) "إضافة وسم سريع" else "Quick add tag") },
            text = {
                Column(
                    modifier = Modifier
                        .heightIn(max = 420.dp)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    OutlinedTextField(
                        value = tagPickerSearch,
                        onValueChange = { tagPickerSearch = it },
                        singleLine = true,
                        label = { Text(if (locale == AppLocale.AR) "بحث الوسوم" else "Search tags") }
                    )
                    if (availableTags.isEmpty()) {
                        Text(
                            if (locale == AppLocale.AR) "لا توجد وسوم متاحة." else "No available tags.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } else {
                        filteredTags.forEach { tag ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        tagPickerConversationId?.let { onAttachTagQuick(it, tag.id) }
                                        tagPickerConversationId = null
                                        tagPickerSearch = ""
                                        tagPickerSearchDebounced = ""
                                    }
                                    .padding(vertical = 8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(tag.name, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                Text(
                                    "#${tag.id}",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.18f))
                        }
                        if (filteredTags.isEmpty()) {
                            Text(
                                if (locale == AppLocale.AR) "لا توجد نتائج." else "No results.",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    tagPickerConversationId = null
                    tagPickerSearch = ""
                    tagPickerSearchDebounced = ""
                }) { Text(tr(locale, TextKey.CLOSE)) }
            },
            confirmButton = {}
        )
    }

    if (tagManageItem != null && tagManageConversationId != null) {
        val initialTag = tagManageItem!!
        val conversationTags = conversations.firstOrNull { it.id == tagManageConversationId }?.tags.orEmpty()
        var activeTag by remember(tagManageItem, tagManageConversationId, conversationTags) {
            mutableStateOf(
                conversationTags.firstOrNull { it.id == initialTag.id } ?: initialTag
            )
        }
        AlertDialog(
            onDismissRequest = {
                tagManageItem = null
                tagManageConversationId = null
            },
            title = { Text(activeTag.name) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (conversationTags.isNotEmpty()) {
                        Text(
                            if (locale == AppLocale.AR) "كل الوسوم:" else "All tags:",
                            fontWeight = FontWeight.SemiBold
                        )
                        Row(
                            modifier = Modifier.horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            conversationTags.forEach { tag ->
                                Surface(
                                    shape = RoundedCornerShape(999.dp),
                                    color = parseHexColor(tag.colorHex),
                                    modifier = Modifier.clickable { activeTag = tag }
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(
                                            if (tag.repeatedAt.isEmpty()) "1" else "${tag.repeatedAt.size}",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = Color.White
                                        )
                                        Spacer(Modifier.size(5.dp))
                                        Text(
                                            tag.name,
                                            style = MaterialTheme.typography.labelSmall,
                                            color = Color.White
                                        )
                                    }
                                }
                            }
                        }
                    }
                    Text(
                        if (locale == AppLocale.AR) "تاريخ الإضافة:" else "Added at:",
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        formatTagHistoryDate(activeTag.attachedAt, locale),
                        style = MaterialTheme.typography.bodySmall
                    )
                    Text(
                        if (locale == AppLocale.AR) "تواريخ التكرار (${activeTag.repeatedAt.size}):" else "Repeat history (${activeTag.repeatedAt.size}):",
                        fontWeight = FontWeight.SemiBold
                    )
                    if (activeTag.repeatedAt.isEmpty()) {
                        Text(
                            if (locale == AppLocale.AR) "لا يوجد تكرار" else "No repeats",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } else {
                        activeTag.repeatedAt.take(5).forEach {
                            Text("• ${formatTagHistoryDate(it, locale)}", style = MaterialTheme.typography.bodySmall)
                        }
                    }
                }
            },
            dismissButton = {
                Row {
                    TextButton(onClick = {
                        tagManageConversationId?.let { onDetachTagQuick(it, activeTag.id) }
                        tagManageItem = null
                        tagManageConversationId = null
                    }) { Text(if (locale == AppLocale.AR) "إزالة" else "Detach") }
                    TextButton(onClick = {
                        tagManageItem = null
                        tagManageConversationId = null
                    }) { Text(tr(locale, TextKey.CLOSE)) }
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    tagManageConversationId?.let { onRepeatTagQuick(it, activeTag.id) }
                    tagManageItem = null
                    tagManageConversationId = null
                }) { Text(if (locale == AppLocale.AR) "تكرار" else "Repeat") }
            }
        )
    }
}

@Composable
private fun TabChip(
    label: String,
    count: Int,
    selected: Boolean,
    showCaret: Boolean = false,
    onClick: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(8.dp),
        color = if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.95f) else MaterialTheme.colorScheme.secondary,
        modifier = Modifier.clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 7.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                if (showCaret) "$label  ▾" else label,
                color = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                style = MaterialTheme.typography.labelLarge
            )
            Spacer(Modifier.size(6.dp))
            Box(
                modifier = Modifier
                    .clip(CircleShape)
                    .background(
                        if (selected) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.2f)
                        else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.1f)
                    )
                    .padding(horizontal = 6.dp, vertical = 1.dp)
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
private fun ConversationRow(
    convo: Conversation,
    locale: AppLocale,
    isSelected: Boolean,
    selectionMode: Boolean,
    onClick: () -> Unit,
    onLongPress: () -> Unit,
    onQuickAddTag: () -> Unit,
    onQuickMarkRead: () -> Unit,
    onTagInfo: (ConversationTag) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(if (isSelected) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f) else Color.Transparent)
            .combinedClickable(onClick = onClick, onLongClick = onLongPress)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
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
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = if (convo.unreadCount > 0) FontWeight.SemiBold else FontWeight.Medium
                )
                Text(
                    convo.lastMessageTime,
                    style = MaterialTheme.typography.labelSmall,
                    color = if (convo.unreadCount > 0) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (!convo.assignedAgentName.isNullOrBlank()) {
                Spacer(Modifier.height(2.dp))
                Text(
                    convo.assignedAgentName,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.primary
                )
            }
            Spacer(Modifier.height(2.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(
                    localizedConversationPreview(convo.lastMessage, locale),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (convo.unreadCount > 0) {
                    Box(
                        modifier = Modifier
                            .size(22.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF0E8C56))
                            .padding(0.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("${convo.unreadCount}", color = Color.White, style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
            if (convo.tags.isNotEmpty()) {
                Spacer(Modifier.height(4.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    convo.tags.take(1).forEach { tag ->
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = parseHexColor(tag.colorHex),
                            modifier = Modifier.clickable { onTagInfo(tag) }
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(16.dp)
                                        .clip(CircleShape)
                                        .background(Color.White.copy(alpha = 0.2f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        if (tag.repeatedAt.isEmpty()) "1" else "${tag.repeatedAt.size}",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.White
                                    )
                                }
                                Spacer(Modifier.size(6.dp))
                                Text(
                                    tag.name,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = Color.White
                                )
                            }
                        }
                    }
                    if (convo.tags.size > 1) {
                        Text(
                            "+${convo.tags.size - 1}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Icon(
                        Icons.Outlined.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier
                            .size(16.dp)
                            .clickable { onTagInfo(convo.tags.first()) }
                    )
                }
            }
            if (!selectionMode) {
                Spacer(Modifier.height(5.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = Color(0xFFEEF2FF),
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .clickable(onClick = onQuickAddTag)
                    ) {
                        Text(
                            if (locale == AppLocale.AR) "إضافة وسم" else "Add tag",
                            style = MaterialTheme.typography.labelSmall,
                            color = Color(0xFF3730A3),
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }
                    if (convo.unreadCount > 0) {
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = Color(0xFFECFDF5),
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .clickable(onClick = onQuickMarkRead)
                        ) {
                            Text(
                                if (locale == AppLocale.AR) "تحديد كمقروء" else "Mark read",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color(0xFF065F46),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                            )
                        }
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

private fun parseHexColor(raw: String): Color {
    val hex = raw.trim().removePrefix("#")
    return runCatching {
        when (hex.length) {
            6 -> Color(android.graphics.Color.parseColor("#$hex"))
            8 -> Color(android.graphics.Color.parseColor("#$hex"))
            else -> Color(0xFF64748B)
        }
    }.getOrElse { Color(0xFF64748B) }
}

private fun formatTagHistoryDate(raw: String?, locale: AppLocale): String {
    if (raw.isNullOrBlank()) return if (locale == AppLocale.AR) "غير متاح" else "Unavailable"
    return runCatching {
        val parser = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        val date = parser.parse(raw) ?: return@runCatching raw
        val targetLocale = if (locale == AppLocale.AR) Locale.forLanguageTag("ar-SA") else Locale.US
        SimpleDateFormat("EEEE, MMM d, yyyy h:mm a", targetLocale).format(date)
    }.getOrElse { raw }
}

@Composable
private fun QuickSheetAction(
    icon: ImageVector,
    label: String,
    subtitle: String,
    accent: Color = MaterialTheme.colorScheme.primary,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onClick),
        color = MaterialTheme.colorScheme.secondary
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(30.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(accent.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(icon, null, tint = accent)
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(label, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                Text(subtitle, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}
