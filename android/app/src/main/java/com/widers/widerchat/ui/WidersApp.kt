package com.widers.widerchat.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgeDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.Alignment
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.widers.widerchat.core.TextKey
import com.widers.widerchat.core.tr
import com.widers.widerchat.domain.model.AppLocale
import com.widers.widerchat.domain.model.AppScreen
import com.widers.widerchat.ui.screens.ChatScreen
import com.widers.widerchat.ui.screens.ConversationsScreen
import com.widers.widerchat.ui.screens.LoginScreen
import com.widers.widerchat.ui.screens.PrivacyScreen
import com.widers.widerchat.ui.screens.SettingsScreen
import com.widers.widerchat.ui.screens.TermsScreen
import com.widers.widerchat.ui.screens.VersionScreen
import com.widers.widerchat.ui.theme.WiderChatTheme

@Composable
fun WidersApp(viewModel: AppViewModel = viewModel()) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val dir = if (state.locale == AppLocale.AR) LayoutDirection.Rtl else LayoutDirection.Ltr
    val hideBottomNav = state.screen in setOf(AppScreen.CHAT, AppScreen.PRIVACY, AppScreen.TERMS, AppScreen.VERSION)

    WiderChatTheme(darkTheme = state.darkMode, dynamicColor = false) {
        CompositionLocalProvider(androidx.compose.ui.platform.LocalLayoutDirection provides dir) {
            if (!state.isLoggedIn || state.screen == AppScreen.LOGIN) {
                LoginScreen(
                    locale = state.locale,
                    onToggleLocale = {
                        viewModel.setLocale(if (state.locale == AppLocale.EN) AppLocale.AR else AppLocale.EN)
                    },
                    onLogin = viewModel::login
                )
                return@CompositionLocalProvider
            }

            Scaffold(
                bottomBar = {
                    if (!hideBottomNav) {
                        BottomNav(
                            screen = state.screen,
                            unread = state.conversations.sumOf { it.unreadCount },
                            locale = state.locale,
                            onScreenSelected = viewModel::setScreen
                        )
                    }
                }
            ) { padding ->
                when (state.screen) {
                    AppScreen.CONVERSATIONS -> ConversationsScreen(
                        modifier = Modifier.padding(padding),
                        locale = state.locale,
                        conversations = state.conversations,
                        onOpenChat = viewModel::openChat
                    )

                    AppScreen.CHAT -> ChatScreen(
                        modifier = Modifier.padding(padding),
                        locale = state.locale,
                        darkMode = state.darkMode,
                        conversations = state.conversations,
                        activeChatId = state.activeChatId,
                        messages = state.activeMessages,
                        onBack = viewModel::backToConversations,
                        onSend = viewModel::sendMessage,
                        onAddNote = viewModel::addNote,
                        onToggleStatus = viewModel::toggleConversationStatus
                    )

                    AppScreen.SETTINGS -> SettingsScreen(
                        modifier = Modifier.padding(padding),
                        locale = state.locale,
                        darkMode = state.darkMode,
                        onLocaleChange = viewModel::setLocale,
                        onDarkModeChange = viewModel::setDarkMode,
                        onOpenPrivacy = { viewModel.setScreen(AppScreen.PRIVACY) },
                        onOpenTerms = { viewModel.setScreen(AppScreen.TERMS) },
                        onOpenVersion = { viewModel.setScreen(AppScreen.VERSION) },
                        onLogout = viewModel::logout
                    )

                    AppScreen.PRIVACY -> PrivacyScreen(
                        modifier = Modifier.padding(padding),
                        locale = state.locale,
                        onBack = { viewModel.setScreen(AppScreen.SETTINGS) }
                    )

                    AppScreen.TERMS -> TermsScreen(
                        modifier = Modifier.padding(padding),
                        locale = state.locale,
                        onBack = { viewModel.setScreen(AppScreen.SETTINGS) }
                    )

                    AppScreen.VERSION -> VersionScreen(
                        modifier = Modifier.padding(padding),
                        locale = state.locale,
                        onBack = { viewModel.setScreen(AppScreen.SETTINGS) }
                    )

                    AppScreen.LOGIN -> Unit
                }
            }
        }
    }
}

@Composable
private fun BottomNav(
    screen: AppScreen,
    unread: Int,
    locale: AppLocale,
    onScreenSelected: (AppScreen) -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surface)) {
        HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.35f))
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(58.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            NavItem(
                selected = screen == AppScreen.CONVERSATIONS,
                label = tr(locale, TextKey.CHATS),
                badge = unread,
                onClick = { onScreenSelected(AppScreen.CONVERSATIONS) },
                icon = { selected ->
                    Icon(
                        Icons.Outlined.ChatBubbleOutline,
                        null,
                        modifier = Modifier.size(20.dp),
                        tint = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            )
            NavItem(
                selected = screen == AppScreen.SETTINGS,
                label = tr(locale, TextKey.SETTINGS),
                badge = 0,
                onClick = { onScreenSelected(AppScreen.SETTINGS) },
                icon = { selected ->
                    Icon(
                        Icons.Outlined.Settings,
                        null,
                        modifier = Modifier.size(20.dp),
                        tint = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            )
        }
    }
}

@Composable
private fun NavItem(
    selected: Boolean,
    label: String,
    badge: Int,
    onClick: () -> Unit,
    icon: @Composable (Boolean) -> Unit
) {
    Column(
        modifier = Modifier.clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .background(
                    if (selected) MaterialTheme.colorScheme.primary else Color.Transparent,
                    RoundedCornerShape(999.dp)
                )
                .size(width = 18.dp, height = 2.dp)
        )
        Spacer(Modifier.height(5.dp))
        Box {
            icon(selected)
            if (badge > 0) {
                Badge(
                    modifier = Modifier.align(Alignment.TopEnd),
                    containerColor = Color(0xFFEF4444),
                    contentColor = Color.White
                ) { Text("$badge", style = MaterialTheme.typography.labelSmall) }
            }
        }
        Spacer(Modifier.height(2.dp))
        Text(
            label,
            style = MaterialTheme.typography.labelSmall,
            color = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = if (selected) FontWeight.Medium else FontWeight.Normal
        )
    }
}
