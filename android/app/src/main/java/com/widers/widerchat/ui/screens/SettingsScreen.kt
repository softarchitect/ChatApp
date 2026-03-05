package com.widers.widerchat.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.automirrored.outlined.Reply
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Shield
import androidx.compose.material.icons.outlined.NotificationsActive
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material.icons.outlined.Tag
import androidx.compose.material.icons.outlined.PersonAdd
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.widers.widerchat.BuildConfig
import com.widers.widerchat.core.TextKey
import com.widers.widerchat.core.tr
import com.widers.widerchat.domain.model.AppLocale
import com.widers.widerchat.domain.model.AvailableReply
import com.widers.widerchat.domain.model.AvailableTag
import com.widers.widerchat.domain.model.WorkspaceOption
import kotlinx.coroutines.delay

@Composable
fun SettingsScreen(
    modifier: Modifier = Modifier,
    locale: AppLocale,
    darkMode: Boolean,
    profileName: String,
    profileEmail: String,
    currentCompanyId: Long?,
    availableWorkspaces: List<WorkspaceOption>,
    onLocaleChange: (AppLocale) -> Unit,
    onDarkModeChange: (Boolean) -> Unit,
    onSwitchWorkspace: (Long) -> Unit,
    onOpenPrivacy: () -> Unit,
    onOpenTerms: () -> Unit,
    onOpenVersion: () -> Unit,
    onLogout: () -> Unit,
    onUpdateProfile: (String, String) -> Unit,
    onSyncSupportData: () -> Unit,
    onCreateTag: (String, String, Long?) -> Unit,
    onCreateReply: (String, String, Long?) -> Unit,
    availableTags: List<AvailableTag>,
    availableReplies: List<AvailableReply>,
    onAddContact: (String, String, String?) -> Unit,
    pushDebugInfo: String?,
    pushDebugRawToken: String?,
    actionStatus: String?
) {
    var pushEnabled by remember { mutableStateOf(true) }
    var soundEnabled by remember { mutableStateOf(true) }
    var showLangDialog by remember { mutableStateOf(false) }
    var showLogoutDialog by remember { mutableStateOf(false) }
    var showProfileDialog by remember { mutableStateOf(false) }
    var showWorkspaceDialog by remember { mutableStateOf(false) }
    var showTagDialog by remember { mutableStateOf(false) }
    var showReplyDialog by remember { mutableStateOf(false) }
    var showContactDialog by remember { mutableStateOf(false) }
    var tagName by remember { mutableStateOf("") }
    var tagColor by remember { mutableStateOf("#ffffff") }
    var selectedTagId by remember { mutableStateOf<Long?>(null) }
    var replyName by remember { mutableStateOf("") }
    var replyText by remember { mutableStateOf("") }
    var selectedReplyId by remember { mutableStateOf<Long?>(null) }
    var contactName by remember { mutableStateOf("") }
    var contactPhone by remember { mutableStateOf("") }
    var contactEmail by remember { mutableStateOf("") }
    val accountName = profileName.trim().ifBlank { tr(locale, TextKey.ACCOUNT) }
    val accountEmail = profileEmail
        .trim()
        .takeIf {
            it.isNotBlank() &&
                !it.equals(".", ignoreCase = true) &&
                !it.equals("-", ignoreCase = true) &&
                !it.equals("null", ignoreCase = true)
        }
    val avatarInitials = remember(accountName) { initialsFrom(accountName) }
    var profileNameInput by remember { mutableStateOf(accountName) }
    var profileEmailInput by remember { mutableStateOf(accountEmail.orEmpty()) }
    var tokenCopied by remember { mutableStateOf(false) }
    val clipboardManager = LocalClipboardManager.current

    LaunchedEffect(tokenCopied) {
        if (tokenCopied) {
            delay(1200)
            tokenCopied = false
        }
    }

    Column(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.surface)
                .padding(horizontal = 20.dp, vertical = 16.dp)
        ) {
            Text(tr(locale, TextKey.SETTINGS), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        }

        Column(
            modifier = Modifier
                .padding(top = 12.dp)
                .verticalScroll(rememberScrollState())
        ) {
            Surface(
                modifier = Modifier
                    .padding(horizontal = 20.dp)
                    .clickable {
                        profileNameInput = accountName
                        profileEmailInput = accountEmail.orEmpty()
                        showProfileDialog = true
                    },
                shape = RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.surface
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 14.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(modifier = Modifier.size(56.dp), shape = CircleShape, color = MaterialTheme.colorScheme.primary) {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text(avatarInitials, color = MaterialTheme.colorScheme.onPrimary, fontWeight = FontWeight.Bold)
                        }
                    }
                    Spacer(Modifier.size(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(accountName, fontWeight = FontWeight.SemiBold)
                        if (!accountEmail.isNullOrBlank()) {
                            Text(accountEmail, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                    Icon(Icons.Outlined.ChevronRight, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }

            Spacer(Modifier.height(16.dp))
            SettingsTitle(tr(locale, TextKey.ACCOUNT).uppercase())
            FlatGroup {
                FlatRow(
                    icon = { Icon(Icons.Outlined.Person, null, tint = Color.White) },
                    iconBg = Color(0xFF3B82F6),
                    label = tr(locale, TextKey.PROFILE),
                    onClick = {
                        profileNameInput = accountName
                        profileEmailInput = accountEmail.orEmpty()
                        showProfileDialog = true
                    }
                )
                if (availableWorkspaces.size > 1) {
                    HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.18f))
                    FlatRow(
                        icon = { Icon(Icons.Outlined.Person, null, tint = Color.White) },
                        iconBg = Color(0xFF0EA5E9),
                        label = if (locale == AppLocale.AR) "مساحة العمل" else "Workspace",
                        value = availableWorkspaces.firstOrNull { it.companyId == currentCompanyId }?.name,
                        onClick = { showWorkspaceDialog = true }
                    )
                }
            }

            Spacer(Modifier.height(8.dp))
            SettingsTitle(tr(locale, TextKey.NOTIFICATION_SETTINGS).uppercase())
            FlatGroup {
                FlatToggleRow(icon = { Icon(Icons.Outlined.NotificationsActive, null, tint = Color.White) }, iconBg = Color(0xFFF43F5E), label = tr(locale, TextKey.PUSH_NOTIFICATIONS), checked = pushEnabled) { pushEnabled = it }
                HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.18f))
                FlatToggleRow(icon = { Icon(Icons.AutoMirrored.Outlined.VolumeUp, null, tint = Color.White) }, iconBg = Color(0xFFF59E0B), label = tr(locale, TextKey.SOUND_ALERTS), checked = soundEnabled) { soundEnabled = it }
            }
            if (BuildConfig.DEBUG && !pushDebugInfo.isNullOrBlank()) {
                Text(
                    text = pushDebugInfo,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 6.dp),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (!pushDebugRawToken.isNullOrBlank()) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        TextButton(
                            onClick = {
                                clipboardManager.setText(AnnotatedString(pushDebugRawToken))
                                tokenCopied = true
                            }
                        ) {
                            Text(if (locale == AppLocale.AR) "نسخ الرمز" else "Copy token")
                        }
                        if (tokenCopied) {
                            Text(
                                text = if (locale == AppLocale.AR) "تم النسخ" else "Copied",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }

            Spacer(Modifier.height(8.dp))
            SettingsTitle(tr(locale, TextKey.APPEARANCE).uppercase())
            FlatGroup {
                FlatRow(icon = { Icon(Icons.Outlined.Language, null, tint = Color.White) }, iconBg = Color(0xFF06B6D4), label = tr(locale, TextKey.LANGUAGE), value = if (locale == AppLocale.EN) tr(locale, TextKey.ENGLISH) else tr(locale, TextKey.ARABIC), onClick = { showLangDialog = true })
                HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.18f))
                FlatToggleRow(icon = { Icon(Icons.Outlined.DarkMode, null, tint = Color.White) }, iconBg = Color(0xFF6366F1), label = tr(locale, TextKey.DARK_MODE), checked = darkMode, onCheckedChange = onDarkModeChange)
            }

            Spacer(Modifier.height(8.dp))
            SettingsTitle(tr(locale, TextKey.BACKEND_TOOLS).uppercase())
            FlatGroup {
                FlatRow(icon = { Icon(Icons.Outlined.Sync, null, tint = Color.White) }, iconBg = Color(0xFF0E8C56), label = tr(locale, TextKey.SYNC_SUPPORT_DATA), onClick = onSyncSupportData)
                HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.18f))
                FlatRow(icon = { Icon(Icons.Outlined.Tag, null, tint = Color.White) }, iconBg = Color(0xFF7C3AED), label = tr(locale, TextKey.CREATE_UPDATE_TAG), onClick = { showTagDialog = true })
                HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.18f))
                FlatRow(icon = { Icon(Icons.AutoMirrored.Outlined.Reply, null, tint = Color.White) }, iconBg = Color(0xFF0284C7), label = tr(locale, TextKey.CREATE_UPDATE_REPLY), onClick = { showReplyDialog = true })
                HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.18f))
                FlatRow(icon = { Icon(Icons.Outlined.PersonAdd, null, tint = Color.White) }, iconBg = Color(0xFFF59E0B), label = tr(locale, TextKey.ADD_CONTACT_TITLE), onClick = { showContactDialog = true })
            }

            if (!actionStatus.isNullOrBlank()) {
                Spacer(Modifier.height(6.dp))
                Text(
                    actionStatus,
                    modifier = Modifier.padding(horizontal = 20.dp),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary
                )
            }

            Spacer(Modifier.height(8.dp))
            SettingsTitle(tr(locale, TextKey.ABOUT).uppercase())
            FlatGroup {
                FlatRow(icon = { Icon(Icons.Outlined.Shield, null, tint = Color.White) }, iconBg = Color(0xFF10B981), label = tr(locale, TextKey.PRIVACY_POLICY), onClick = onOpenPrivacy)
                HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.18f))
                FlatRow(icon = { Icon(Icons.Outlined.Description, null, tint = Color.White) }, iconBg = Color(0xFF14B8A6), label = tr(locale, TextKey.TERMS_OF_SERVICE), onClick = onOpenTerms)
                HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.18f))
                FlatRow(icon = { Icon(Icons.Outlined.Info, null, tint = Color.White) }, iconBg = Color(0xFF64748B), label = tr(locale, TextKey.VERSION), value = "1.0.0", onClick = onOpenVersion)
            }

            Spacer(Modifier.height(14.dp))
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .clickable { showLogoutDialog = true },
                shape = RoundedCornerShape(12.dp),
                color = Color(0xFFEF4444).copy(alpha = 0.1f)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 12.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.AutoMirrored.Outlined.Logout, null, tint = Color(0xFFEF4444))
                    Text(" ${tr(locale, TextKey.LOGOUT)}", color = Color(0xFFEF4444), fontWeight = FontWeight.Medium)
                }
            }
        }
    }

    if (showLangDialog) {
        AlertDialog(
            onDismissRequest = { showLangDialog = false },
            title = { Text(tr(locale, TextKey.LANGUAGE)) },
            text = {
                Column {
                    TextButton(onClick = { onLocaleChange(AppLocale.EN); showLangDialog = false }) { Text(tr(locale, TextKey.ENGLISH)) }
                    TextButton(onClick = { onLocaleChange(AppLocale.AR); showLangDialog = false }) { Text(tr(locale, TextKey.ARABIC)) }
                }
            },
            confirmButton = {}
        )
    }

    if (showProfileDialog) {
        AlertDialog(
            onDismissRequest = { showProfileDialog = false },
            title = { Text(tr(locale, TextKey.PROFILE)) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    androidx.compose.material3.OutlinedTextField(
                        value = profileNameInput,
                        onValueChange = { profileNameInput = it },
                        singleLine = true,
                        label = { Text(tr(locale, TextKey.NAME_LABEL)) }
                    )
                    androidx.compose.material3.OutlinedTextField(
                        value = profileEmailInput,
                        onValueChange = { profileEmailInput = it },
                        singleLine = true,
                        label = { Text(tr(locale, TextKey.EMAIL_LABEL)) }
                    )
                }
            },
            dismissButton = { TextButton(onClick = { showProfileDialog = false }) { Text(tr(locale, TextKey.CLOSE)) } },
            confirmButton = {
                TextButton(onClick = {
                    onUpdateProfile(profileNameInput, profileEmailInput)
                    showProfileDialog = false
                }) { Text(tr(locale, TextKey.SAVE)) }
            }
        )
    }

    if (showWorkspaceDialog) {
        AlertDialog(
            onDismissRequest = { showWorkspaceDialog = false },
            title = { Text(if (locale == AppLocale.AR) "تبديل مساحة العمل" else "Switch workspace") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    availableWorkspaces.forEach { workspace ->
                        TextButton(
                            onClick = {
                                showWorkspaceDialog = false
                                onSwitchWorkspace(workspace.companyId)
                            },
                            enabled = workspace.companyId != currentCompanyId
                        ) {
                            val prefix = if (workspace.companyId == currentCompanyId) "✓ " else ""
                            Text(prefix + workspace.name)
                        }
                    }
                }
            },
            dismissButton = { TextButton(onClick = { showWorkspaceDialog = false }) { Text(tr(locale, TextKey.CLOSE)) } },
            confirmButton = {}
        )
    }

    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = { Text(tr(locale, TextKey.LOGOUT)) },
            text = { Text(tr(locale, TextKey.LOGOUT_CONFIRM)) },
            dismissButton = { TextButton(onClick = { showLogoutDialog = false }) { Text(tr(locale, TextKey.CANCEL)) } },
            confirmButton = {
                TextButton(onClick = {
                    showLogoutDialog = false
                    onLogout()
                }) { Text(tr(locale, TextKey.CONFIRM)) }
            }
        )
    }

    if (showTagDialog) {
        AlertDialog(
            onDismissRequest = { showTagDialog = false },
            title = { Text(tr(locale, TextKey.CREATE_UPDATE_TAG)) },
            text = {
                Column {
                    androidx.compose.material3.OutlinedTextField(tagName, { tagName = it }, label = { Text(tr(locale, TextKey.TAG_NAME)) })
                    Spacer(Modifier.size(8.dp))
                    androidx.compose.material3.OutlinedTextField(tagColor, { tagColor = it }, label = { Text(tr(locale, TextKey.TAG_COLOR_HEX)) })
                    Spacer(Modifier.size(8.dp))
                    TextButton(onClick = {
                        val first = availableTags.firstOrNull()
                        if (first != null) {
                            selectedTagId = first.id
                            tagName = first.name
                            tagColor = first.colorHex
                        }
                    }) {
                        Text(
                            if (locale == AppLocale.AR) {
                                "اختر من الوسوم المتاحة (${availableTags.size})"
                            } else {
                                "Select available tag (${availableTags.size})"
                            }
                        )
                    }
                    availableTags.take(8).forEach { tag ->
                        TextButton(onClick = {
                            selectedTagId = tag.id
                            tagName = tag.name
                            tagColor = tag.colorHex
                        }) {
                            Text("${tag.name} (#${tag.id})")
                        }
                    }
                }
            },
            dismissButton = { TextButton(onClick = { showTagDialog = false }) { Text(tr(locale, TextKey.CANCEL)) } },
            confirmButton = {
                TextButton(onClick = {
                    onCreateTag(tagName, tagColor, selectedTagId)
                    selectedTagId = null
                    showTagDialog = false
                }) { Text(tr(locale, TextKey.SAVE)) }
            }
        )
    }

    if (showReplyDialog) {
        AlertDialog(
            onDismissRequest = { showReplyDialog = false },
            title = { Text(tr(locale, TextKey.CREATE_UPDATE_REPLY)) },
            text = {
                Column {
                    androidx.compose.material3.OutlinedTextField(replyName, { replyName = it }, label = { Text(tr(locale, TextKey.REPLY_NAME)) })
                    Spacer(Modifier.size(8.dp))
                    androidx.compose.material3.OutlinedTextField(replyText, { replyText = it }, label = { Text(tr(locale, TextKey.REPLY_TEXT)) })
                    Spacer(Modifier.size(8.dp))
                    TextButton(onClick = {
                        val first = availableReplies.firstOrNull()
                        if (first != null) {
                            selectedReplyId = first.id
                            replyName = first.name
                            replyText = first.text
                        }
                    }) {
                        Text(
                            if (locale == AppLocale.AR) {
                                "اختر من الردود المتاحة (${availableReplies.size})"
                            } else {
                                "Select available quick reply (${availableReplies.size})"
                            }
                        )
                    }
                    availableReplies.take(8).forEach { reply ->
                        TextButton(onClick = {
                            selectedReplyId = reply.id
                            replyName = reply.name
                            replyText = reply.text
                        }) {
                            Text("${reply.name} (#${reply.id})")
                        }
                    }
                }
            },
            dismissButton = { TextButton(onClick = { showReplyDialog = false }) { Text(tr(locale, TextKey.CANCEL)) } },
            confirmButton = {
                TextButton(onClick = {
                    onCreateReply(replyName, replyText, selectedReplyId)
                    selectedReplyId = null
                    showReplyDialog = false
                }) { Text(tr(locale, TextKey.SAVE)) }
            }
        )
    }

    if (showContactDialog) {
        AlertDialog(
            onDismissRequest = { showContactDialog = false },
            title = { Text(tr(locale, TextKey.ADD_CONTACT_TITLE)) },
            text = {
                Column {
                    androidx.compose.material3.OutlinedTextField(contactName, { contactName = it }, label = { Text(tr(locale, TextKey.NAME_LABEL)) })
                    Spacer(Modifier.size(8.dp))
                    androidx.compose.material3.OutlinedTextField(contactPhone, { contactPhone = it }, label = { Text(tr(locale, TextKey.PHONE_LABEL)) })
                    Text(
                        if (locale == AppLocale.AR) "مثال: +96654377556" else "Example: +96654377556",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.size(8.dp))
                    androidx.compose.material3.OutlinedTextField(contactEmail, { contactEmail = it }, label = { Text(tr(locale, TextKey.EMAIL_OPTIONAL)) })
                }
            },
            dismissButton = { TextButton(onClick = { showContactDialog = false }) { Text(tr(locale, TextKey.CANCEL)) } },
            confirmButton = {
                TextButton(onClick = {
                    onAddContact(contactName, contactPhone, contactEmail.ifBlank { null })
                    showContactDialog = false
                }) { Text(tr(locale, TextKey.ADD)) }
            }
        )
    }
}

private fun initialsFrom(name: String): String {
    val parts = name.trim().split(" ").filter { it.isNotBlank() }
    if (parts.isEmpty()) return "U"
    return parts.take(2).mapNotNull { it.firstOrNull()?.uppercaseChar() }.joinToString("")
}

@Composable
private fun SettingsTitle(title: String) {
    Text(
        title,
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 3.dp),
        style = MaterialTheme.typography.labelLarge,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        fontWeight = FontWeight.SemiBold
    )
}

@Composable
private fun FlatGroup(content: @Composable ColumnScope.() -> Unit) {
    Surface(color = MaterialTheme.colorScheme.surface) {
        Column(content = content)
    }
}

@Composable
private fun FlatRow(
    icon: @Composable () -> Unit,
    iconBg: Color,
    label: String,
    value: String? = null,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(modifier = Modifier.size(32.dp), shape = RoundedCornerShape(10.dp), color = iconBg) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { icon() }
        }
        Spacer(Modifier.size(10.dp))
        Text(label, modifier = Modifier.weight(1f))
        if (value != null) {
            Text(value, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.size(8.dp))
        }
        Icon(Icons.Outlined.ChevronRight, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun FlatToggleRow(
    icon: @Composable () -> Unit,
    iconBg: Color,
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(modifier = Modifier.size(32.dp), shape = RoundedCornerShape(10.dp), color = iconBg) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { icon() }
        }
        Spacer(Modifier.size(10.dp))
        Text(label, modifier = Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}
