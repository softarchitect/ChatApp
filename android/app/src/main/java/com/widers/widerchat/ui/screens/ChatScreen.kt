package com.widers.widerchat.ui.screens

import android.Manifest
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaPlayer
import android.media.MediaMetadataRetriever
import android.media.MediaRecorder
import android.net.Uri
import android.app.DownloadManager
import android.content.Intent
import android.os.Environment
import android.provider.OpenableColumns
import android.widget.Toast
import android.widget.MediaController
import android.widget.VideoView
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.Image
import androidx.compose.foundation.rememberScrollState
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.NoteAlt
import androidx.compose.material.icons.outlined.Pause
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material.icons.outlined.Done
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.core.content.ContextCompat
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.window.DialogProperties
import com.widers.widerchat.core.TextKey
import com.widers.widerchat.core.tr
import com.widers.widerchat.domain.model.AppLocale
import com.widers.widerchat.domain.model.ChatMessage
import com.widers.widerchat.domain.model.Conversation
import com.widers.widerchat.domain.model.ConversationStatus
import com.widers.widerchat.domain.model.MessageSender
import com.widers.widerchat.domain.model.MessageType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.ByteArrayOutputStream
import java.net.URL
import java.util.Locale

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
    onSendAttachment: (String, ByteArray, String) -> Unit,
    onSendVoice: (String, ByteArray) -> Unit,
    onAddNote: (String) -> Unit,
    onToggleStatus: () -> Unit,
    onAssignAgent: (Long) -> Unit,
    onUnassignAgent: () -> Unit,
    onMute: (Boolean) -> Unit,
    onMarkRead: (Boolean) -> Unit,
    onAttachTag: (Long) -> Unit,
    onDetachTag: (Long) -> Unit,
    onSendTemplate: (Long) -> Unit,
    onSendFlow: (Long) -> Unit,
    onSyncCustomField: (String, String) -> Unit,
    onDeleteChat: () -> Unit,
    isHistoryLoading: Boolean,
    actionStatus: String?
) {
    val conversationId = activeChatId ?: return
    val conversation = conversations.firstOrNull { it.id == conversationId } ?: Conversation(
        id = conversationId,
        customerName = "Contact",
        customerPhone = "",
        lastMessage = "",
        lastMessageTime = "",
        unreadCount = 0,
        status = ConversationStatus.OPEN,
        isOnline = false
    )
    val listState = rememberLazyListState()
    val coroutineScope = rememberCoroutineScope()
    var forceAutoScroll by remember(activeChatId) { mutableStateOf(false) }
    var initialOpenScrollPending by remember(activeChatId) { mutableStateOf(true) }
    var pendingNewMessages by remember(activeChatId) { mutableStateOf(0) }
    var lastObservedMessageId by remember(activeChatId) { mutableStateOf(messages.lastOrNull()?.id) }
    val isNearBottom by remember(listState) {
        derivedStateOf {
            val lastVisible = listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0
            val lastIndex = (listState.layoutInfo.totalItemsCount - 1).coerceAtLeast(0)
            lastVisible >= (lastIndex - 2).coerceAtLeast(0)
        }
    }
    var text by remember { mutableStateOf("") }
    var noteText by remember { mutableStateOf("") }
    var showNote by remember { mutableStateOf(false) }
    var menuOpen by remember { mutableStateOf(false) }
    var agentInput by remember { mutableStateOf("") }
    var tagInput by remember { mutableStateOf("") }
    var templateInput by remember { mutableStateOf("") }
    var flowInput by remember { mutableStateOf("") }
    var customFieldId by remember { mutableStateOf("") }
    var customFieldValue by remember { mutableStateOf("") }
    var showAssignDialog by remember { mutableStateOf(false) }
    var showTagDialog by remember { mutableStateOf(false) }
    var showTemplateDialog by remember { mutableStateOf(false) }
    var showFlowDialog by remember { mutableStateOf(false) }
    var showCustomDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showContactInfoDialog by remember { mutableStateOf(false) }
    var showMediaLinksDocsDialog by remember { mutableStateOf(false) }
    var browserImageUrl by remember { mutableStateOf<String?>(null) }
    var browserVideoUrl by remember { mutableStateOf<String?>(null) }
    var browserDocumentUrl by remember { mutableStateOf<String?>(null) }
    var browserAudioUrl by remember { mutableStateOf<String?>(null) }
    var showAttachMenu by remember { mutableStateOf(false) }
    var showEmojiPicker by remember { mutableStateOf(false) }
    var selectedEmojiCategory by remember { mutableStateOf("recent") }
    var emojiSearchQuery by remember { mutableStateOf("") }
    var mediaRecorder by remember { mutableStateOf<MediaRecorder?>(null) }
    var recordingFile by remember { mutableStateOf<File?>(null) }
    var isRecordingVoice by remember { mutableStateOf(false) }
    val recentEmojis = remember { mutableStateListOf("😀", "❤️", "👍") }
    val emojiCategories = remember {
        linkedMapOf(
            "recent" to emptyList<String>(),
            "smileys" to listOf("😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "🙂", "😉", "😍", "🥰", "😘", "😎", "🤔", "😭"),
            "gestures" to listOf("👍", "👎", "👏", "🙌", "🙏", "🤝", "💪", "👌", "✌️", "🤞", "👋", "🤲", "🫶", "💯", "✅", "❌"),
            "hearts" to listOf("❤️", "🩷", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💖", "💗", "🔥"),
            "celebration" to listOf("🎉", "🎊", "✨", "⭐", "🌟", "⚡", "☀️", "🌈", "🍀", "🎁", "🏆", "🎵", "🎶", "📌", "📣", "📷")
        )
    }
    val emojisForCategory = if (selectedEmojiCategory == "recent") recentEmojis.toList() else emojiCategories[selectedEmojiCategory].orEmpty()
    val filteredEmojis = remember(selectedEmojiCategory, emojiSearchQuery, emojisForCategory, recentEmojis) {
        val query = emojiSearchQuery.trim().lowercase(Locale.ROOT)
        if (query.isBlank()) return@remember emojisForCategory
        val allEmojis = (recentEmojis + emojiCategories.values.flatten()).distinct()
        allEmojis.filter { emoji -> emojiMatchesSearch(emoji, query, locale) || emoji.contains(query) }
    }
    val addEmoji: (String) -> Unit = { emoji ->
        text += emoji
        recentEmojis.remove(emoji)
        recentEmojis.add(0, emoji)
        if (recentEmojis.size > 24) {
            recentEmojis.removeLast()
        }
    }
    val context = LocalContext.current
    val uriHandler = LocalUriHandler.current
    val mediaLinksDocsItems = remember(messages) {
        buildList {
            messages.forEach { message ->
                val kind = message.mediaKind?.lowercase(Locale.US)
                when (kind) {
                    "image" -> {
                        val url = normalizeRemoteUrl(message.mediaUrl)
                        if (url != null) {
                            add(
                                ContactMediaItem(
                                    type = "Photo",
                                    url = url,
                                    category = ContactItemCategory.MEDIA,
                                    previewKind = "image"
                                )
                            )
                        }
                    }

                    "video" -> {
                        val url = normalizeRemoteUrl(message.mediaUrl)
                        if (url != null) {
                            add(
                                ContactMediaItem(
                                    type = "Video",
                                    url = url,
                                    category = ContactItemCategory.MEDIA,
                                    previewKind = "video"
                                )
                            )
                        }
                    }

                    "audio" -> {
                        val url = normalizeRemoteUrl(message.mediaUrl)
                        if (url != null) {
                            add(
                                ContactMediaItem(
                                    type = "Audio",
                                    url = url,
                                    category = ContactItemCategory.MEDIA,
                                    previewKind = "audio",
                                    isAvailable = true
                                )
                            )
                        } else {
                            add(
                                ContactMediaItem(
                                    type = "Audio",
                                    url = "",
                                    category = ContactItemCategory.MEDIA,
                                    previewKind = "audio",
                                    isAvailable = false
                                )
                            )
                        }
                    }

                    "document" -> {
                        val url = normalizeRemoteUrl(message.mediaUrl)
                        if (url != null) {
                            add(
                                ContactMediaItem(
                                    type = "Document",
                                    url = url,
                                    category = ContactItemCategory.DOCS,
                                    previewKind = "document"
                                )
                            )
                        }
                    }

                    else -> {
                        val extractedLink = extractFirstUrl(message.content)
                        if (!extractedLink.isNullOrBlank()) {
                            add(
                                ContactMediaItem(
                                    type = "Link",
                                    url = extractedLink,
                                    category = ContactItemCategory.LINKS,
                                    previewKind = "link"
                                )
                            )
                        }
                    }
                }
            }
        }
    }
    val mediaLinksDocsCount = remember(mediaLinksDocsItems) { mediaLinksDocsItems.size }

    fun beginVoiceRecording() {
        val output = File(context.cacheDir, "voice-${System.currentTimeMillis()}.m4a")
        val recorder = MediaRecorder()
        try {
            recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            recorder.setOutputFile(output.absolutePath)
            recorder.prepare()
            recorder.start()
            mediaRecorder = recorder
            recordingFile = output
            isRecordingVoice = true
        } catch (_: Exception) {
            recorder.release()
            mediaRecorder = null
            recordingFile = null
            isRecordingVoice = false
        }
    }

    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        val data = context.contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return@rememberLauncherForActivityResult
        val fileName = context.contentResolver.resolveFileName(uri) ?: "image-${System.currentTimeMillis()}.jpg"
        onSendAttachment(fileName, data, "Image")
    }
    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) { bitmap: Bitmap? ->
        if (bitmap == null) return@rememberLauncherForActivityResult
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
        val bytes = out.toByteArray()
        if (bytes.isNotEmpty()) {
            onSendAttachment("camera-${System.currentTimeMillis()}.jpg", bytes, "Image")
        }
    }
    val documentPicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        val data = context.contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return@rememberLauncherForActivityResult
        val fileName = context.contentResolver.resolveFileName(uri) ?: "document-${System.currentTimeMillis()}.pdf"
        onSendAttachment(fileName, data, "Document")
    }
    val audioPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
        onResult = { granted ->
            if (!granted) return@rememberLauncherForActivityResult
            beginVoiceRecording()
        }
    )

    Column(modifier = modifier.fillMaxSize()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surface)
                .padding(horizontal = 8.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack, modifier = Modifier.size(36.dp)) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, null) }
            Row(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(12.dp))
                    .clickable { showContactInfoDialog = true }
                    .padding(vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(avatarColor(conversation.customerName)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        initialsFromName(conversation.customerName),
                        color = Color.White,
                        fontWeight = FontWeight.Bold
                    )
                }
                Spacer(Modifier.size(10.dp))
                Column {
                    Text(conversation.customerName, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text(
                        if (conversation.isOnline) tr(locale, TextKey.ONLINE) else "${tr(locale, TextKey.LAST_SEEN)} ${conversation.lastMessageTime}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            IconButton(
                onClick = {
                    val ok = openDialer(context, conversation.customerPhone)
                    if (!ok) {
                        Toast.makeText(context, "Phone number is unavailable", Toast.LENGTH_SHORT).show()
                    }
                },
                modifier = Modifier.size(36.dp)
            ) {
                Icon(Icons.Outlined.Call, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
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
                    DropdownMenuItem(
                        text = { Text("Assign agent") },
                        onClick = {
                            showAssignDialog = true
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Unassign agent") },
                        onClick = {
                            onUnassignAgent()
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Mute conversation") },
                        onClick = {
                            onMute(true)
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Unmute conversation") },
                        onClick = {
                            onMute(false)
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Mark as read") },
                        onClick = {
                            onMarkRead(true)
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Mark as unread") },
                        onClick = {
                            onMarkRead(false)
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Attach/Detach tag") },
                        onClick = {
                            showTagDialog = true
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Send template") },
                        onClick = {
                            showTemplateDialog = true
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Send flow") },
                        onClick = {
                            showFlowDialog = true
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Sync custom field") },
                        onClick = {
                            showCustomDialog = true
                            menuOpen = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Delete chat", color = Color(0xFFEF4444)) },
                        onClick = {
                            showDeleteDialog = true
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
        if (!actionStatus.isNullOrBlank()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.secondary)
                    .padding(vertical = 6.dp, horizontal = 10.dp),
                contentAlignment = Alignment.CenterStart
            ) {
                Text(actionStatus, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
            }
        }

        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
        ) {
            if (isHistoryLoading && messages.isEmpty()) {
                val skeletonTransition = rememberInfiniteTransition(label = "chat-skeleton")
                val skeletonAlpha by skeletonTransition.animateFloat(
                    initialValue = 0.45f,
                    targetValue = 0.95f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(durationMillis = 950, easing = LinearEasing),
                        repeatMode = RepeatMode.Reverse
                    ),
                    label = "chat-skeleton-alpha"
                )
                val shimmerX by skeletonTransition.animateFloat(
                    initialValue = -240f,
                    targetValue = 640f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(durationMillis = 1200, easing = LinearEasing),
                        repeatMode = RepeatMode.Restart
                    ),
                    label = "chat-skeleton-shimmer"
                )
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 12.dp, vertical = 10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    repeat(6) { idx ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = if (idx % 2 == 0) Arrangement.Start else Arrangement.End
                        ) {
                            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                val bubbleWidth = when (idx % 3) {
                                    0 -> 230.dp
                                    1 -> 180.dp
                                    else -> 260.dp
                                }
                                Box(
                                    modifier = Modifier
                                        .widthIn(min = 120.dp, max = bubbleWidth)
                                        .height(52.dp)
                                        .clip(RoundedCornerShape(14.dp))
                                        .background(
                                            Brush.linearGradient(
                                                colors = listOf(
                                                    MaterialTheme.colorScheme.secondary.copy(alpha = skeletonAlpha),
                                                    MaterialTheme.colorScheme.surface.copy(alpha = (skeletonAlpha * 0.85f).coerceAtMost(1f)),
                                                    MaterialTheme.colorScheme.secondary.copy(alpha = skeletonAlpha)
                                                ),
                                                start = Offset(shimmerX - 180f, 0f),
                                                end = Offset(shimmerX, 180f)
                                            )
                                        )
                                )
                                Box(
                                    modifier = Modifier
                                        .width(44.dp)
                                        .height(10.dp)
                                        .clip(RoundedCornerShape(6.dp))
                                        .background(
                                            Brush.linearGradient(
                                                colors = listOf(
                                                    MaterialTheme.colorScheme.secondary.copy(alpha = skeletonAlpha),
                                                    MaterialTheme.colorScheme.surface.copy(alpha = (skeletonAlpha * 0.85f).coerceAtMost(1f)),
                                                    MaterialTheme.colorScheme.secondary.copy(alpha = skeletonAlpha)
                                                ),
                                                start = Offset(shimmerX - 90f, 0f),
                                                end = Offset(shimmerX, 90f)
                                            )
                                        )
                                )
                            }
                        }
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(top = 6.dp),
                    state = listState,
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
            }
            if (!isHistoryLoading && messages.isNotEmpty() && !isNearBottom) {
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(end = 14.dp, bottom = 14.dp)
                ) {
                    FloatingActionButton(
                        onClick = {
                            coroutineScope.launch {
                                listState.animateScrollToItem(messages.size)
                            }
                            pendingNewMessages = 0
                        },
                        containerColor = MaterialTheme.colorScheme.primary,
                        contentColor = MaterialTheme.colorScheme.onPrimary
                    ) {
                        Text("↓")
                    }
                    if (pendingNewMessages > 0) {
                        Box(
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .padding(end = 2.dp)
                                .size(18.dp)
                                .clip(CircleShape)
                                .background(Color(0xFFEF4444)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                if (pendingNewMessages > 99) "99+" else pendingNewMessages.toString(),
                                color = Color.White,
                                style = MaterialTheme.typography.labelSmall
                            )
                        }
                    }
                }
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

        if (showEmojiPicker) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surface)
                    .padding(horizontal = 10.dp, vertical = 6.dp)
            ) {
                OutlinedTextField(
                    modifier = Modifier.fillMaxWidth(),
                    value = emojiSearchQuery,
                    onValueChange = { emojiSearchQuery = it },
                    placeholder = {
                        Text(if (locale == AppLocale.AR) "ابحث عن ايموجي" else "Search emoji")
                    },
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp)
                )
                Spacer(Modifier.size(6.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                ) {
                    emojiCategories.keys.forEach { category ->
                        TextButton(
                            onClick = { selectedEmojiCategory = category },
                            enabled = conversation.status == ConversationStatus.OPEN && !isHistoryLoading
                        ) {
                            val label = emojiCategoryLabel(category, locale)
                            Text(label)
                        }
                    }
                }
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                ) {
                    filteredEmojis.forEach { emoji ->
                        TextButton(
                            onClick = { addEmoji(emoji) },
                            enabled = conversation.status == ConversationStatus.OPEN && !isHistoryLoading
                        ) {
                            Text(emoji)
                        }
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
            IconButton(
                onClick = { showEmojiPicker = !showEmojiPicker },
                modifier = Modifier.size(36.dp),
                enabled = conversation.status == ConversationStatus.OPEN && !isHistoryLoading
            ) {
                Text("😀")
            }
            Box {
                IconButton(
                    onClick = { showAttachMenu = true },
                    modifier = Modifier.size(36.dp),
                    enabled = conversation.status == ConversationStatus.OPEN && !isHistoryLoading
                ) {
                    Icon(Icons.Outlined.Add, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                DropdownMenu(
                    expanded = showAttachMenu,
                    onDismissRequest = { showAttachMenu = false }
                ) {
                    DropdownMenuItem(
                        text = { Text(tr(locale, TextKey.CAMERA)) },
                        onClick = {
                            cameraLauncher.launch(null)
                            showAttachMenu = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text(tr(locale, TextKey.GALLERY)) },
                        onClick = {
                            imagePicker.launch("image/*")
                            showAttachMenu = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text(tr(locale, TextKey.DOCUMENT)) },
                        onClick = {
                            documentPicker.launch("*/*")
                            showAttachMenu = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text(if (isRecordingVoice) tr(locale, TextKey.STOP_SEND_VOICE) else tr(locale, TextKey.AUDIO)) },
                        onClick = {
                            if (isRecordingVoice) {
                                val recorder = mediaRecorder
                                val file = recordingFile
                                try {
                                    recorder?.stop()
                                } catch (_: Exception) {
                                }
                                recorder?.release()
                                mediaRecorder = null
                                isRecordingVoice = false
                                if (file != null && file.exists()) {
                                    val bytes = file.readBytes()
                                    if (bytes.isNotEmpty()) {
                                        onSendVoice("voice-${System.currentTimeMillis()}.m4a", bytes)
                                        forceAutoScroll = true
                                    }
                                    file.delete()
                                }
                                recordingFile = null
                            } else {
                                val hasPermission = ContextCompat.checkSelfPermission(
                                    context,
                                    Manifest.permission.RECORD_AUDIO
                                ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                                if (hasPermission) {
                                    beginVoiceRecording()
                                } else {
                                    audioPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                                }
                            }
                            showAttachMenu = false
                        }
                    )
                }
            }
            OutlinedTextField(
                modifier = Modifier.weight(1f),
                value = text,
                onValueChange = { text = it },
                placeholder = { Text(tr(locale, TextKey.TYPE_MESSAGE), color = MaterialTheme.colorScheme.onSurfaceVariant) },
                enabled = conversation.status == ConversationStatus.OPEN && !isHistoryLoading,
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
                    forceAutoScroll = true
                    text = ""
                    showEmojiPicker = false
                },
                enabled = text.isNotBlank() && conversation.status == ConversationStatus.OPEN && !isHistoryLoading,
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary)
            ) {
                Icon(Icons.AutoMirrored.Outlined.Send, null, tint = MaterialTheme.colorScheme.onPrimary)
            }
        }
    }
    LaunchedEffect(activeChatId, messages.lastOrNull()?.id) {
        val latest = messages.lastOrNull()
        if (latest != null && latest.id != lastObservedMessageId) {
            if (!isNearBottom && !forceAutoScroll && latest.sender != MessageSender.AGENT) {
                pendingNewMessages += 1
            }
            lastObservedMessageId = latest.id
        }
        if (messages.isNotEmpty() && (initialOpenScrollPending || isNearBottom || forceAutoScroll)) {
            listState.animateScrollToItem(messages.size)
            pendingNewMessages = 0
            initialOpenScrollPending = false
        }
        forceAutoScroll = false
    }
    LaunchedEffect(isNearBottom) {
        if (isNearBottom) pendingNewMessages = 0
    }
    DisposableEffect(Unit) {
        onDispose {
            try {
                mediaRecorder?.stop()
            } catch (_: Exception) {
            }
            mediaRecorder?.release()
            mediaRecorder = null
            recordingFile?.delete()
            recordingFile = null
        }
    }

    if (showAssignDialog) {
        AlertDialog(
            onDismissRequest = { showAssignDialog = false },
            title = { Text("Assign Agent") },
            text = {
                OutlinedTextField(value = agentInput, onValueChange = { agentInput = it }, label = { Text("Agent ID") })
            },
            dismissButton = { TextButton(onClick = { showAssignDialog = false }) { Text("Cancel") } },
            confirmButton = {
                TextButton(onClick = {
                    agentInput.toLongOrNull()?.let(onAssignAgent)
                    showAssignDialog = false
                    agentInput = ""
                }) { Text("Assign") }
            }
        )
    }

    if (showTagDialog) {
        AlertDialog(
            onDismissRequest = { showTagDialog = false },
            title = { Text("Attach / Detach Tag") },
            text = { OutlinedTextField(value = tagInput, onValueChange = { tagInput = it }, label = { Text("Tag ID") }) },
            dismissButton = { TextButton(onClick = { showTagDialog = false }) { Text("Cancel") } },
            confirmButton = {
                Row {
                    TextButton(onClick = {
                        tagInput.toLongOrNull()?.let(onAttachTag)
                        showTagDialog = false
                        tagInput = ""
                    }) { Text("Attach") }
                    TextButton(onClick = {
                        tagInput.toLongOrNull()?.let(onDetachTag)
                        showTagDialog = false
                        tagInput = ""
                    }) { Text("Detach") }
                }
            }
        )
    }

    if (showTemplateDialog) {
        AlertDialog(
            onDismissRequest = { showTemplateDialog = false },
            title = { Text("Send Template") },
            text = { OutlinedTextField(value = templateInput, onValueChange = { templateInput = it }, label = { Text("Template ID") }) },
            dismissButton = { TextButton(onClick = { showTemplateDialog = false }) { Text("Cancel") } },
            confirmButton = {
                TextButton(onClick = {
                    templateInput.toLongOrNull()?.let(onSendTemplate)
                    showTemplateDialog = false
                    templateInput = ""
                }) { Text("Send") }
            }
        )
    }

    if (showFlowDialog) {
        AlertDialog(
            onDismissRequest = { showFlowDialog = false },
            title = { Text("Send Flow") },
            text = { OutlinedTextField(value = flowInput, onValueChange = { flowInput = it }, label = { Text("Flow ID") }) },
            dismissButton = { TextButton(onClick = { showFlowDialog = false }) { Text("Cancel") } },
            confirmButton = {
                TextButton(onClick = {
                    flowInput.toLongOrNull()?.let(onSendFlow)
                    showFlowDialog = false
                    flowInput = ""
                }) { Text("Send") }
            }
        )
    }

    if (showCustomDialog) {
        AlertDialog(
            onDismissRequest = { showCustomDialog = false },
            title = { Text("Sync Custom Field") },
            text = {
                Column {
                    OutlinedTextField(value = customFieldId, onValueChange = { customFieldId = it }, label = { Text("Field ID") })
                    Spacer(Modifier.size(8.dp))
                    OutlinedTextField(value = customFieldValue, onValueChange = { customFieldValue = it }, label = { Text("Field Value") })
                }
            },
            dismissButton = { TextButton(onClick = { showCustomDialog = false }) { Text("Cancel") } },
            confirmButton = {
                TextButton(onClick = {
                    onSyncCustomField(customFieldId, customFieldValue)
                    showCustomDialog = false
                    customFieldId = ""
                    customFieldValue = ""
                }) { Text("Sync") }
            }
        )
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete chat?") },
            text = { Text("This calls the delete chat endpoint for this contact.") },
            dismissButton = { TextButton(onClick = { showDeleteDialog = false }) { Text("Cancel") } },
            confirmButton = {
                TextButton(onClick = {
                    onDeleteChat()
                    showDeleteDialog = false
                }) { Text("Delete", color = Color(0xFFEF4444)) }
            }
        )
    }

    if (showContactInfoDialog) {
        AlertDialog(
            onDismissRequest = { showContactInfoDialog = false },
            title = { Text("Contact info") },
            text = {
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(46.dp)
                                .clip(CircleShape)
                                .background(avatarColor(conversation.customerName)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                initialsFromName(conversation.customerName),
                                color = Color.White,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        Spacer(Modifier.size(10.dp))
                        Column {
                            Text(conversation.customerName, fontWeight = FontWeight.SemiBold)
                            Text(
                                if (conversation.customerPhone.isBlank()) "-" else conversation.customerPhone,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                    Spacer(Modifier.size(12.dp))
                    Text(
                        if (conversation.isOnline) tr(locale, TextKey.ONLINE) else "${tr(locale, TextKey.LAST_SEEN)} ${conversation.lastMessageTime}",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(Modifier.size(4.dp))
                    Text(
                        if (conversation.status == ConversationStatus.OPEN) tr(locale, TextKey.OPEN) else tr(locale, TextKey.CLOSED),
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (conversation.status == ConversationStatus.OPEN) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.size(6.dp))
                    Text(
                        "Media, links and docs · $mediaLinksDocsCount",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.clickable {
                            showContactInfoDialog = false
                            showMediaLinksDocsDialog = true
                        }
                    )
                }
            },
            dismissButton = {
                Row {
                    TextButton(onClick = {
                        onMute(true)
                    }) { Text("Mute") }
                    TextButton(onClick = {
                        onMute(false)
                    }) { Text("Unmute") }
                }
            },
            confirmButton = {
                Row {
                    TextButton(onClick = {
                        onToggleStatus()
                    }) {
                        Text(if (conversation.status == ConversationStatus.OPEN) "Close chat" else "Reopen chat")
                    }
                    TextButton(onClick = {
                        showContactInfoDialog = false
                        showDeleteDialog = true
                    }) {
                        Text("Delete", color = Color(0xFFEF4444))
                    }
                }
            }
        )
    }

    if (showMediaLinksDocsDialog) {
        Dialog(onDismissRequest = { showMediaLinksDocsDialog = false }) {
            MediaLinksDocsBrowserDialog(
                items = mediaLinksDocsItems,
                onOpenItem = { item ->
                    if (!item.isAvailable || item.url.isBlank()) {
                        Toast.makeText(context, "Audio file URL is unavailable", Toast.LENGTH_SHORT).show()
                    } else {
                        when (item.previewKind) {
                            "image" -> browserImageUrl = item.url
                            "video" -> browserVideoUrl = item.url
                            "document" -> browserDocumentUrl = item.url
                            "audio" -> browserAudioUrl = item.url
                            else -> uriHandler.openUri(item.url)
                        }
                    }
                },
                onShareItem = { item ->
                    if (!item.isAvailable || item.url.isBlank()) {
                        Toast.makeText(context, "Cannot share unavailable item", Toast.LENGTH_SHORT).show()
                    } else {
                        shareMediaItem(context, item.url)
                    }
                },
                onDownloadItem = { item ->
                    if (!item.isAvailable || item.url.isBlank()) {
                        Toast.makeText(context, "Cannot download unavailable item", Toast.LENGTH_SHORT).show()
                    } else {
                        val ok = downloadMediaItem(context, item.url)
                        Toast.makeText(
                            context,
                            if (ok) "Downloading..." else "Unable to start download",
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                },
                onClose = { showMediaLinksDocsDialog = false }
            )
        }
    }

    if (!browserImageUrl.isNullOrBlank()) {
        FullScreenImageDialog(
            imageUrl = browserImageUrl!!,
            onDismiss = { browserImageUrl = null }
        )
    }
    if (!browserVideoUrl.isNullOrBlank()) {
        VideoPreviewDialog(
            videoUrl = browserVideoUrl!!,
            onDismiss = { browserVideoUrl = null }
        )
    }
    if (!browserDocumentUrl.isNullOrBlank()) {
        DocumentPreviewDialog(
            documentUrl = browserDocumentUrl!!,
            onDismiss = { browserDocumentUrl = null }
        )
    }
    if (!browserAudioUrl.isNullOrBlank()) {
        Dialog(onDismissRequest = { browserAudioUrl = null }) {
            ElevatedCard(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 14.dp),
                shape = RoundedCornerShape(14.dp)
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Audio", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                        Spacer(Modifier.weight(1f))
                        TextButton(onClick = { browserAudioUrl = null }) { Text("Close") }
                    }
                    InlineAudioPlayer(
                        mediaUrl = browserAudioUrl,
                        darkMode = darkMode,
                        labelColor = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
}

@Composable
private fun MediaLinksDocsBrowserDialog(
    items: List<ContactMediaItem>,
    onOpenItem: (ContactMediaItem) -> Unit,
    onShareItem: (ContactMediaItem) -> Unit,
    onDownloadItem: (ContactMediaItem) -> Unit,
    onClose: () -> Unit
) {
    var selectedTab by remember { mutableStateOf(ContactItemCategory.MEDIA) }
    val mediaCount = remember(items) { items.count { it.category == ContactItemCategory.MEDIA } }
    val docsCount = remember(items) { items.count { it.category == ContactItemCategory.DOCS } }
    val linksCount = remember(items) { items.count { it.category == ContactItemCategory.LINKS } }
    val filteredItems = remember(items, selectedTab) { items.filter { it.category == selectedTab } }

    ElevatedCard(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Media, links and docs", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.weight(1f))
                TextButton(onClick = onClose) { Text("Close") }
            }
            Spacer(Modifier.size(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ContactTabChip(
                    text = "Media ($mediaCount)",
                    selected = selectedTab == ContactItemCategory.MEDIA,
                    onClick = { selectedTab = ContactItemCategory.MEDIA }
                )
                ContactTabChip(
                    text = "Docs ($docsCount)",
                    selected = selectedTab == ContactItemCategory.DOCS,
                    onClick = { selectedTab = ContactItemCategory.DOCS }
                )
                ContactTabChip(
                    text = "Links ($linksCount)",
                    selected = selectedTab == ContactItemCategory.LINKS,
                    onClick = { selectedTab = ContactItemCategory.LINKS }
                )
            }
            Spacer(Modifier.size(10.dp))
            if (filteredItems.isEmpty()) {
                Text(
                    "No items in this tab.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            } else {
                LazyColumn(modifier = Modifier.height(340.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(filteredItems) { item ->
                        ContactMediaListRow(
                            item = item,
                            onOpen = onOpenItem,
                            onShare = onShareItem,
                            onDownload = onDownloadItem
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ContactTabChip(
    text: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelMedium,
        color = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.secondary)
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp, vertical = 6.dp)
    )
}

@Composable
private fun ContactMediaListRow(
    item: ContactMediaItem,
    onOpen: (ContactMediaItem) -> Unit,
    onShare: (ContactMediaItem) -> Unit,
    onDownload: (ContactMediaItem) -> Unit
) {
    val title = item.url.substringAfterLast('/').substringBefore('?').trim()
        .takeIf { it.isNotBlank() && !it.equals("null", ignoreCase = true) }
        ?: if (item.isAvailable) "${item.type} file" else "Unavailable file"
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(MaterialTheme.colorScheme.secondary)
            .clickable(enabled = item.isAvailable && item.url.isNotBlank()) { onOpen(item) }
            .padding(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        when (item.previewKind) {
            "image" -> ContactImageThumb(url = item.url)
            "video" -> ContactVideoThumb(url = item.url)
            "audio" -> Icon(Icons.Outlined.PlayArrow, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(34.dp))
            "document" -> Icon(Icons.Outlined.Description, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(34.dp))
            else -> Icon(Icons.Outlined.Call, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(34.dp))
        }
        Spacer(Modifier.size(10.dp))
        Column {
            Text(item.type, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.primary)
            Text(
                title,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                style = MaterialTheme.typography.bodySmall,
                color = if (item.isAvailable) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Spacer(Modifier.weight(1f))
        IconButton(
            onClick = { onDownload(item) },
            enabled = item.isAvailable && item.url.isNotBlank(),
            modifier = Modifier.size(28.dp)
        ) {
            Icon(Icons.Outlined.Download, null, tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
        }
        IconButton(
            onClick = { onShare(item) },
            enabled = item.isAvailable && item.url.isNotBlank(),
            modifier = Modifier.size(28.dp)
        ) {
            Icon(Icons.Outlined.Share, null, tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(18.dp))
        }
    }
}

@Composable
private fun ContactImageThumb(url: String) {
    val bitmapState = produceState<android.graphics.Bitmap?>(initialValue = null, url) {
        value = withContext(Dispatchers.IO) {
            try {
                URL(url).openStream().use { BitmapFactory.decodeStream(it) }
            } catch (_: Exception) {
                null
            }
        }
    }
    Box(
        modifier = Modifier
            .size(44.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(Color(0xFFDCEBFF)),
        contentAlignment = Alignment.Center
    ) {
        val bitmap = bitmapState.value
        if (bitmap != null) {
            Image(bitmap = bitmap.asImageBitmap(), contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
        } else {
            Icon(Icons.Outlined.Image, null, tint = Color(0xFF1D4ED8))
        }
    }
}

@Composable
private fun ContactVideoThumb(url: String) {
    val frameState = produceState<android.graphics.Bitmap?>(initialValue = null, url) {
        value = withContext(Dispatchers.IO) {
            try {
                val retriever = MediaMetadataRetriever()
                retriever.setDataSource(url, hashMapOf())
                val frame = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                retriever.release()
                frame
            } catch (_: Exception) {
                null
            }
        }
    }
    Box(
        modifier = Modifier
            .size(44.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(Color(0xFFDCEBFF)),
        contentAlignment = Alignment.Center
    ) {
        val frame = frameState.value
        if (frame != null) {
            Image(bitmap = frame.asImageBitmap(), contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
        } else {
            Icon(Icons.Outlined.PlayArrow, null, tint = Color(0xFF1D4ED8))
        }
    }
}

private enum class ContactItemCategory {
    MEDIA,
    DOCS,
    LINKS
}

private data class ContactMediaItem(
    val type: String,
    val url: String,
    val category: ContactItemCategory,
    val previewKind: String,
    val isAvailable: Boolean = true
)
 
@Composable
private fun MessageBubble(msg: ChatMessage, darkMode: Boolean) {
    val uriHandler = LocalUriHandler.current
    var fullImageUrl by remember(msg.id) { mutableStateOf<String?>(null) }
    var previewDocumentUrl by remember(msg.id) { mutableStateOf<String?>(null) }
    var previewVideoUrl by remember(msg.id) { mutableStateOf<String?>(null) }
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
            RoundedCornerShape(topStart = 14.dp, topEnd = 14.dp, bottomStart = 14.dp, bottomEnd = 4.dp)
        } else {
            RoundedCornerShape(topStart = 14.dp, topEnd = 14.dp, bottomStart = 4.dp, bottomEnd = 14.dp)
        }
        Box(
            modifier = Modifier
                .widthIn(max = 320.dp)
                .clip(bubbleShape)
                .background(
                    if (isAgent) {
                        if (darkMode) Color(0xFF1E3A2B) else Color(0xFFDCF8C6)
                    } else {
                        if (darkMode) Color(0xFF202C33) else Color.White
                    }
                )
                .border(
                    width = if (isAgent) 0.dp else 1.dp,
                    color = if (isAgent) {
                        Color.Transparent
                    } else {
                        if (darkMode) Color(0xFF2F3B43) else Color(0xFFE5E7EB)
                    },
                    shape = bubbleShape
                )
                .padding(horizontal = 10.dp, vertical = 7.dp)
        ) {
            Column {
                val messageColor = if (isAgent) {
                    if (darkMode) Color(0xFFE7FCEB) else Color(0xFF111827)
                } else {
                    if (darkMode) Color(0xFFEFF7FF) else Color(0xFF111827)
                }
                val metaColor = if (isAgent) {
                    if (darkMode) Color(0xFF8DE0A5) else Color(0xFF4B5563)
                } else {
                    if (darkMode) Color(0xFF8DA3B1) else Color(0xFF6B7280)
                }
                if (msg.type == MessageType.IMAGE && !msg.mediaKind.isNullOrBlank()) {
                    MediaMessageCard(
                        mediaKind = msg.mediaKind,
                        mediaUrl = msg.mediaUrl,
                        darkMode = darkMode,
                        onOpen = { url ->
                            if (msg.mediaKind?.equals("image", ignoreCase = true) == true) {
                                fullImageUrl = url
                            } else if (msg.mediaKind?.equals("video", ignoreCase = true) == true) {
                                previewVideoUrl = url
                            } else if (msg.mediaKind?.equals("document", ignoreCase = true) == true) {
                                previewDocumentUrl = url
                            } else {
                                uriHandler.openUri(url)
                            }
                        }
                    )
                    if (msg.content.isNotBlank() && !msg.content.startsWith("[")) {
                        Spacer(Modifier.size(6.dp))
                        Text(msg.content, color = messageColor)
                    }
                } else {
                    Text(msg.content, color = messageColor)
                }
                Row(
                    modifier = Modifier.fillMaxWidth().padding(top = 3.dp),
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
    if (!fullImageUrl.isNullOrBlank()) {
        FullScreenImageDialog(
            imageUrl = fullImageUrl!!,
            onDismiss = { fullImageUrl = null }
        )
    }
    if (!previewDocumentUrl.isNullOrBlank()) {
        DocumentPreviewDialog(
            documentUrl = previewDocumentUrl!!,
            onDismiss = { previewDocumentUrl = null }
        )
    }
    if (!previewVideoUrl.isNullOrBlank()) {
        VideoPreviewDialog(
            videoUrl = previewVideoUrl!!,
            onDismiss = { previewVideoUrl = null }
        )
    }
}

@Composable
private fun MediaMessageCard(
    mediaKind: String,
    mediaUrl: String?,
    darkMode: Boolean,
    onOpen: (String) -> Unit
) {
    val title = when (mediaKind.lowercase()) {
        "image" -> "Image"
        "audio" -> "Audio"
        "video" -> "Video"
        "document" -> "Document"
        "location" -> "Location"
        else -> "Media"
    }
    val cardBg = if (darkMode) Color(0xFF16232C) else Color(0xFFEAF6FF)
    val labelColor = if (darkMode) Color(0xFF9FD8FF) else Color(0xFF1D4ED8)

    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(cardBg)
            .then(
                if (!mediaUrl.isNullOrBlank()) {
                    Modifier.clickable { onOpen(mediaUrl) }
                } else {
                    Modifier
                }
            )
            .padding(horizontal = 10.dp, vertical = 8.dp)
    ) {
        when (mediaKind.lowercase()) {
            "image" -> {
                RemoteImagePreview(
                    mediaUrl = mediaUrl,
                    darkMode = darkMode,
                    labelColor = labelColor,
                    onOpen = onOpen
                )
            }
            "video" -> {
                VideoMessagePreview(
                    mediaUrl = mediaUrl,
                    darkMode = darkMode,
                    labelColor = labelColor,
                    onOpen = onOpen
                )
            }
            "audio" -> {
                InlineAudioPlayer(
                    mediaUrl = mediaUrl,
                    darkMode = darkMode,
                    labelColor = labelColor
                )
            }
            else -> {
                val fileName = mediaUrl?.substringAfterLast('/')?.substringBefore('?')?.ifBlank { null }
                val fileSizeLabel = produceState<String?>(initialValue = null, mediaUrl) {
                    value = mediaUrl?.let { fetchRemoteFileSize(it) }
                }.value
                Row(verticalAlignment = Alignment.CenterVertically) {
                    val icon = when (mediaKind.lowercase()) {
                        "video" -> Icons.Outlined.Image
                        "location" -> Icons.Outlined.Call
                        else -> Icons.Outlined.Description
                    }
                    Icon(imageVector = icon, contentDescription = null, tint = labelColor)
                    Spacer(Modifier.size(8.dp))
                    Column {
                        Text("$title message", color = labelColor, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                        if (!fileName.isNullOrBlank()) {
                            Text(fileName, color = labelColor.copy(alpha = 0.85f), style = MaterialTheme.typography.labelSmall)
                        }
                        if (!fileSizeLabel.isNullOrBlank()) {
                            Text(fileSizeLabel, color = labelColor.copy(alpha = 0.75f), style = MaterialTheme.typography.labelSmall)
                        }
                        if (!mediaUrl.isNullOrBlank()) {
                            Text("Tap to open", color = labelColor.copy(alpha = 0.75f), style = MaterialTheme.typography.labelSmall)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun RemoteImagePreview(
    mediaUrl: String?,
    darkMode: Boolean,
    labelColor: Color,
    onOpen: (String) -> Unit
) {
    val imageBitmapState = produceState<android.graphics.Bitmap?>(initialValue = null, mediaUrl) {
        value = if (mediaUrl.isNullOrBlank()) {
            null
        } else {
            withContext(Dispatchers.IO) {
                try {
                    URL(mediaUrl).openStream().use { BitmapFactory.decodeStream(it) }
                } catch (_: Exception) {
                    null
                }
            }
        }
    }

    Box(
        modifier = Modifier
            .size(width = 220.dp, height = 160.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(if (darkMode) Color(0xFF1E293B) else Color(0xFFDCEBFF))
            .then(
                if (!mediaUrl.isNullOrBlank()) {
                    Modifier.clickable { onOpen(mediaUrl) }
                } else {
                    Modifier
                }
            ),
        contentAlignment = Alignment.Center
    ) {
        val bitmap = imageBitmapState.value
        if (bitmap != null) {
            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
            Box(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .fillMaxWidth()
                    .background(Color.Black.copy(alpha = 0.38f))
                    .padding(horizontal = 8.dp, vertical = 6.dp)
            ) {
                Text("Photo", color = Color.White, style = MaterialTheme.typography.labelSmall)
            }
        } else {
            Text("Tap to open image", color = labelColor, style = MaterialTheme.typography.bodyMedium)
        }
    }
    Spacer(Modifier.size(6.dp))
}

@Composable
private fun VideoMessagePreview(
    mediaUrl: String?,
    darkMode: Boolean,
    labelColor: Color,
    onOpen: (String) -> Unit
) {
    val frameState = produceState<android.graphics.Bitmap?>(initialValue = null, mediaUrl) {
        value = if (mediaUrl.isNullOrBlank()) {
            null
        } else {
            withContext(Dispatchers.IO) {
                try {
                    val retriever = MediaMetadataRetriever()
                    retriever.setDataSource(mediaUrl, hashMapOf())
                    val frame = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                    retriever.release()
                    frame
                } catch (_: Exception) {
                    null
                }
            }
        }
    }
    val fileName = mediaUrl?.substringAfterLast('/')?.substringBefore('?')?.ifBlank { null }

    Box(
        modifier = Modifier
            .size(width = 220.dp, height = 150.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(if (darkMode) Color(0xFF1E293B) else Color(0xFFDCEBFF))
            .then(
                if (!mediaUrl.isNullOrBlank()) {
                    Modifier.clickable { onOpen(mediaUrl) }
                } else {
                    Modifier
                }
            )
    ) {
        val bitmap = frameState.value
        if (bitmap != null) {
            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            Text(
                "Tap to open video",
                color = labelColor,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.align(Alignment.Center)
            )
        }
        Box(
            modifier = Modifier
                .align(Alignment.Center)
                .size(42.dp)
                .clip(CircleShape)
                .background(Color.Black.copy(alpha = 0.45f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Outlined.PlayArrow,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(24.dp)
            )
        }
        Box(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .fillMaxWidth()
                .background(Color.Black.copy(alpha = 0.42f))
                .padding(horizontal = 8.dp, vertical = 6.dp)
        ) {
            Text(
                fileName?.let { "Video · $it" } ?: "Video",
                color = Color.White,
                style = MaterialTheme.typography.labelSmall
            )
        }
    }
    Spacer(Modifier.size(6.dp))
}

@Composable
private fun InlineAudioPlayer(
    mediaUrl: String?,
    darkMode: Boolean,
    labelColor: Color
) {
    val context = LocalContext.current
    var mediaPlayer by remember(mediaUrl) { mutableStateOf<MediaPlayer?>(null) }
    var isPrepared by remember(mediaUrl) { mutableStateOf(false) }
    var isPlaying by remember(mediaUrl) { mutableStateOf(false) }
    var positionMs by remember(mediaUrl) { mutableStateOf(0) }
    var durationMs by remember(mediaUrl) { mutableStateOf(0) }

    DisposableEffect(mediaUrl) {
        if (!mediaUrl.isNullOrBlank()) {
            val player = MediaPlayer()
            mediaPlayer = player
            try {
                player.setDataSource(mediaUrl)
                player.setOnPreparedListener {
                    isPrepared = true
                    durationMs = it.duration.coerceAtLeast(0)
                }
                player.setOnCompletionListener {
                    isPlaying = false
                    positionMs = durationMs
                }
                player.prepareAsync()
            } catch (_: Exception) {
                isPrepared = false
            }
        }
        onDispose {
            mediaPlayer?.release()
            mediaPlayer = null
        }
    }

    LaunchedEffect(isPlaying, mediaPlayer) {
        while (isPlaying) {
            val player = mediaPlayer ?: break
            positionMs = player.currentPosition.coerceAtLeast(0)
            durationMs = player.duration.coerceAtLeast(0)
            delay(250)
        }
    }

    LaunchedEffect(mediaUrl) {
        if (durationMs <= 0 && !mediaUrl.isNullOrBlank()) {
            val fallback = withContext(Dispatchers.IO) { fetchAudioDurationMs(mediaUrl, context.cacheDir) }
            if (fallback > 0) durationMs = fallback
        }
    }

    Column {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(
                onClick = {
                    val player = mediaPlayer ?: return@IconButton
                    if (!isPrepared) return@IconButton
                    if (isPlaying) {
                        player.pause()
                        isPlaying = false
                    } else {
                        player.start()
                        isPlaying = true
                    }
                },
                enabled = isPrepared
            ) {
                Icon(
                    imageVector = if (isPlaying) Icons.Outlined.Pause else Icons.Outlined.PlayArrow,
                    contentDescription = null,
                    tint = labelColor
                )
            }
            Text("Audio message", color = labelColor, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
        }
        AudioWaveform(
            progress = if (durationMs > 0) positionMs.toFloat() / durationMs.toFloat() else 0f,
            darkMode = darkMode,
            activeColor = labelColor
        )
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(
                formatDuration(positionMs),
                color = labelColor.copy(alpha = 0.85f),
                style = MaterialTheme.typography.labelSmall
            )
            Text(
                formatDuration(durationMs),
                color = labelColor.copy(alpha = 0.85f),
                style = MaterialTheme.typography.labelSmall
            )
        }
    }
}

@Composable
private fun AudioWaveform(
    progress: Float,
    darkMode: Boolean,
    activeColor: Color
) {
    val bars = listOf(4, 10, 7, 12, 5, 9, 11, 6, 13, 8, 10, 5, 12, 7, 9, 4, 11, 8, 10, 6, 12, 5)
    val activeBars = (bars.size * progress.coerceIn(0f, 1f)).toInt()
    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        bars.forEachIndexed { index, h ->
            Box(
                modifier = Modifier
                    .padding(end = 2.dp)
                    .width(4.dp)
                    .height(h.dp)
                    .clip(RoundedCornerShape(99.dp))
                    .background(
                        if (index <= activeBars) activeColor
                        else if (darkMode) Color(0xFF334155) else Color(0xFFCFE0FF)
                    )
            )
        }
    }
}

@Composable
private fun FullScreenImageDialog(
    imageUrl: String,
    onDismiss: () -> Unit
) {
    val bitmapState = produceState<android.graphics.Bitmap?>(initialValue = null, imageUrl) {
        value = withContext(Dispatchers.IO) {
            try {
                URL(imageUrl).openStream().use { BitmapFactory.decodeStream(it) }
            } catch (_: Exception) {
                null
            }
        }
    }

    Dialog(onDismissRequest = onDismiss) {
        var scale by remember { mutableStateOf(1f) }
        var offset by remember { mutableStateOf(Offset.Zero) }
        var containerSize by remember { mutableStateOf(IntSize.Zero) }
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFF3F4F6))
                .clickable { onDismiss() },
            contentAlignment = Alignment.Center
        ) {
            val bmp = bitmapState.value
            if (bmp != null) {
                Image(
                    bitmap = bmp.asImageBitmap(),
                    contentDescription = null,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp)
                        .onSizeChanged { containerSize = it }
                        .graphicsLayer {
                            scaleX = scale
                            scaleY = scale
                            translationX = offset.x
                            translationY = offset.y
                        }
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color.Black)
                        .then(
                            Modifier
                                .pointerInput(Unit) {
                                    detectTapGestures(
                                        onDoubleTap = {
                                            if (scale > 1f) {
                                                scale = 1f
                                                offset = Offset.Zero
                                            } else {
                                                scale = 2.5f
                                            }
                                        }
                                    )
                                }
                                .pointerInput(scale, containerSize) {
                                    detectTransformGestures { _, pan, zoom, _ ->
                                        val newScale = (scale * zoom).coerceIn(1f, 4f)
                                        val scaleChange = if (scale == 0f) 1f else newScale / scale
                                        scale = newScale
                                        if (newScale > 1f) {
                                            val candidate = Offset(
                                                x = offset.x + pan.x * scaleChange,
                                                y = offset.y + pan.y * scaleChange
                                            )
                                            offset = candidate.clampToBounds(containerSize, newScale)
                                        } else {
                                            offset = Offset.Zero
                                        }
                                    }
                                }
                        ),
                    contentScale = ContentScale.Fit
                )
            } else {
                Text("Loading image...", color = Color(0xFF1F2937))
            }
        }
    }
}

private fun Offset.clampToBounds(containerSize: IntSize, scale: Float): Offset {
    if (containerSize.width == 0 || containerSize.height == 0 || scale <= 1f) return Offset.Zero
    val maxX = (containerSize.width * (scale - 1f)) / 2f
    val maxY = (containerSize.height * (scale - 1f)) / 2f
    return Offset(
        x = x.coerceIn(-maxX, maxX),
        y = y.coerceIn(-maxY, maxY)
    )
}

@Composable
private fun DocumentPreviewDialog(
    documentUrl: String,
    onDismiss: () -> Unit
) {
    val wrappedUrl = remember(documentUrl) {
        "https://docs.google.com/gview?embedded=1&url=${Uri.encode(documentUrl)}"
    }
    Dialog(onDismissRequest = onDismiss) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White)
        ) {
            AndroidView(
                modifier = Modifier.fillMaxSize(),
                factory = { context ->
                    WebView(context).apply {
                        settings.javaScriptEnabled = true
                        settings.domStorageEnabled = true
                        webChromeClient = WebChromeClient()
                        webViewClient = WebViewClient()
                        loadUrl(wrappedUrl)
                    }
                },
                update = { it.loadUrl(wrappedUrl) }
            )
        }
    }
}

@Composable
private fun VideoPreviewDialog(
    videoUrl: String,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    var videoViewRef by remember { mutableStateOf<VideoView?>(null) }
    var isPlaying by remember(videoUrl) { mutableStateOf(false) }
    var durationMs by remember(videoUrl) { mutableStateOf(0) }
    var positionMs by remember(videoUrl) { mutableStateOf(0) }
    var isScrubbing by remember(videoUrl) { mutableStateOf(false) }
    var scrubPosition by remember(videoUrl) { mutableStateOf(0f) }

    LaunchedEffect(videoViewRef, isPlaying, isScrubbing) {
        while (videoViewRef != null) {
            val view = videoViewRef ?: break
            if (!isScrubbing) {
                positionMs = view.currentPosition.coerceAtLeast(0)
                durationMs = view.duration.coerceAtLeast(0)
            }
            delay(250)
        }
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black)
        ) {
            AndroidView(
                modifier = Modifier.fillMaxSize(),
                factory = {
                    VideoView(context).apply {
                        setVideoURI(Uri.parse(videoUrl))
                        setOnPreparedListener {
                            durationMs = duration.coerceAtLeast(0)
                            start()
                            isPlaying = true
                        }
                        setOnCompletionListener {
                            isPlaying = false
                            positionMs = durationMs
                        }
                        videoViewRef = this
                    }
                },
                update = { view ->
                    if (view.currentPosition <= 0) {
                        view.setVideoURI(Uri.parse(videoUrl))
                        view.start()
                        isPlaying = true
                    }
                    videoViewRef = view
                }
            )

            Column(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .background(Color.Black.copy(alpha = 0.55f))
                    .padding(horizontal = 12.dp, vertical = 10.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    TextButton(onClick = {
                        val view = videoViewRef ?: return@TextButton
                        view.seekTo((view.currentPosition - 10_000).coerceAtLeast(0))
                    }) { Text("<<", color = Color.White) }
                    IconButton(
                        onClick = {
                            val view = videoViewRef ?: return@IconButton
                            if (isPlaying) {
                                view.pause()
                                isPlaying = false
                            } else {
                                view.start()
                                isPlaying = true
                            }
                        }
                    ) {
                        Icon(
                            imageVector = if (isPlaying) Icons.Outlined.Pause else Icons.Outlined.PlayArrow,
                            contentDescription = null,
                            tint = Color.White
                        )
                    }
                    TextButton(onClick = {
                        val view = videoViewRef ?: return@TextButton
                        val next = (view.currentPosition + 10_000).coerceAtMost(durationMs.takeIf { it > 0 } ?: Int.MAX_VALUE)
                        view.seekTo(next)
                    }) { Text(">>", color = Color.White) }
                }

                Slider(
                    value = if (isScrubbing) scrubPosition else positionMs.toFloat(),
                    onValueChange = {
                        isScrubbing = true
                        scrubPosition = it
                    },
                    onValueChangeFinished = {
                        val view = videoViewRef
                        if (view != null) {
                            view.seekTo(scrubPosition.toInt())
                        }
                        isScrubbing = false
                    },
                    valueRange = 0f..(durationMs.coerceAtLeast(1).toFloat())
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(formatDuration(positionMs), color = Color.White, style = MaterialTheme.typography.labelSmall)
                    Text(formatDuration(durationMs), color = Color.White, style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }

    DisposableEffect(videoUrl) {
        onDispose {
            videoViewRef?.stopPlayback()
            videoViewRef = null
        }
    }
}

private fun formatDuration(ms: Int): String {
    if (ms <= 0) return "0:00"
    val totalSeconds = ms / 1000
    val minutes = totalSeconds / 60
    val seconds = totalSeconds % 60
    return "$minutes:${seconds.toString().padStart(2, '0')}"
}

private fun fetchRemoteFileSize(urlText: String): String? {
    return try {
        val connection = URL(urlText).openConnection()
        connection.connectTimeout = 5000
        connection.readTimeout = 5000
        val bytes = connection.contentLengthLong
        if (bytes <= 0) return null
        val kb = bytes / 1024.0
        if (kb < 1024) String.format(Locale.US, "%.0f KB", kb)
        else String.format(Locale.US, "%.2f MB", kb / 1024.0)
    } catch (_: Exception) {
        null
    }
}

private fun fetchAudioDurationMs(urlText: String, cacheDir: File): Int {
    // Try direct URL metadata first.
    try {
        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(urlText, hashMapOf())
        val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toIntOrNull() ?: 0
        retriever.release()
        if (duration > 0) return duration
    } catch (_: Exception) {
        // Fall back to temporary file extraction.
    }

    return try {
        val temp = File.createTempFile("audio-preview-", ".tmp", cacheDir)
        URL(urlText).openStream().use { input ->
            temp.outputStream().use { output -> input.copyTo(output) }
        }
        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(temp.absolutePath)
        val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toIntOrNull() ?: 0
        retriever.release()
        temp.delete()
        duration
    } catch (_: Exception) {
        0
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

private fun initialsFromName(name: String): String {
    return name
        .split(" ")
        .mapNotNull { it.firstOrNull()?.toString() }
        .take(2)
        .joinToString("")
        .uppercase(Locale.getDefault())
}

private fun extractFirstUrl(text: String): String? {
    val match = Regex("""https?://[^\s]+""").find(text)
    return match?.value
}

private fun normalizeRemoteUrl(raw: String?): String? {
    val value = raw?.trim().orEmpty()
    if (value.isBlank()) return null
    if (value.equals("null", ignoreCase = true)) return null
    return value
}

private fun emojiCategoryLabel(key: String, locale: AppLocale): String {
    val ar = locale == AppLocale.AR
    return when (key) {
        "recent" -> if (ar) "الأخيرة" else "Recent"
        "smileys" -> if (ar) "وجوه" else "Smileys"
        "gestures" -> if (ar) "إشارات" else "Gestures"
        "hearts" -> if (ar) "قلوب" else "Hearts"
        "celebration" -> if (ar) "احتفال" else "Celebration"
        else -> key
    }
}

private fun emojiMatchesSearch(emoji: String, query: String, locale: AppLocale): Boolean {
    val category = when (emoji) {
        in setOf("😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "🙂", "😉", "😍", "🥰", "😘", "😎", "🤔", "😭") -> "smileys"
        in setOf("👍", "👎", "👏", "🙌", "🙏", "🤝", "💪", "👌", "✌️", "🤞", "👋", "🤲", "🫶", "💯", "✅", "❌") -> "gestures"
        in setOf("❤️", "🩷", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💖", "💗", "🔥") -> "hearts"
        in setOf("🎉", "🎊", "✨", "⭐", "🌟", "⚡", "☀️", "🌈", "🍀", "🎁", "🏆", "🎵", "🎶", "📌", "📣", "📷") -> "celebration"
        else -> "recent"
    }
    val enKeywords = when (category) {
        "smileys" -> listOf("smile", "face", "happy", "sad", "cry", "laugh")
        "gestures" -> listOf("hand", "ok", "thumb", "clap", "pray", "check")
        "hearts" -> listOf("heart", "love", "fire", "broken")
        "celebration" -> listOf("party", "star", "music", "gift", "celebrate")
        else -> listOf("recent")
    }
    val arKeywords = when (category) {
        "smileys" -> listOf("وجه", "ابتسامة", "ضحك", "بكاء", "حزين", "سعيد")
        "gestures" -> listOf("يد", "اشارة", "تصفيق", "دعاء", "موافق")
        "hearts" -> listOf("قلب", "حب", "نار", "مكسور")
        "celebration" -> listOf("حفلة", "احتفال", "نجمة", "موسيقى", "هدية")
        else -> listOf("اخير", "الأخيرة")
    }
    val keywords = if (locale == AppLocale.AR) arKeywords + enKeywords else enKeywords + arKeywords
    return keywords.any { it.contains(query) || query.contains(it) }
}

private fun openDialer(context: android.content.Context, rawPhone: String?): Boolean {
    val phone = rawPhone.orEmpty().trim()
    if (phone.isBlank()) return false
    return try {
        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:${Uri.encode(phone)}"))
        context.startActivity(intent)
        true
    } catch (_: Exception) {
        false
    }
}

private fun shareMediaItem(context: android.content.Context, url: String) {
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, url)
    }
    context.startActivity(Intent.createChooser(intent, "Share"))
}

private fun downloadMediaItem(context: android.content.Context, url: String): Boolean {
    return try {
        val fileName = url.substringAfterLast('/').substringBefore('?').ifBlank {
            "widers-${System.currentTimeMillis()}"
        }
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle(fileName)
            .setDescription("Downloading from Widers")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
        val manager = context.getSystemService(android.content.Context.DOWNLOAD_SERVICE) as? DownloadManager
            ?: return false
        manager.enqueue(request)
        true
    } catch (_: Exception) {
        false
    }
}

private fun android.content.ContentResolver.resolveFileName(uri: Uri): String? {
    query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
        val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
        if (index >= 0 && cursor.moveToFirst()) {
            return cursor.getString(index)
        }
    }
    return uri.lastPathSegment?.substringAfterLast('/')
}
