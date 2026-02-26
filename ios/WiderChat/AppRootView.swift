import SwiftUI

struct AppRootView: View {
    @StateObject private var vm = AppViewModel()

    var body: some View {
        Group {
            if !vm.isLoggedIn || vm.screen == .login {
                LoginView(vm: vm)
            } else {
                MainShellView(vm: vm)
            }
        }
        .environment(\.layoutDirection, vm.locale == .ar ? .rightToLeft : .leftToRight)
        .preferredColorScheme(vm.darkMode ? .dark : .light)
    }
}

private struct MainShellView: View {
    @ObservedObject var vm: AppViewModel

    var hideBottomNav: Bool {
        vm.screen == .chat || vm.screen == .privacy || vm.screen == .terms || vm.screen == .version
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppPalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                switch vm.screen {
                case .conversations:
                    ConversationsView(vm: vm)
                case .chat:
                    ChatView(vm: vm)
                case .settings:
                    SettingsView(vm: vm)
                case .privacy:
                    InfoPageView(vm: vm, title: tr(vm.locale, .privacyPolicy), sections: privacySections(vm.locale))
                case .terms:
                    InfoPageView(vm: vm, title: tr(vm.locale, .termsOfService), sections: termsSections(vm.locale))
                case .version:
                    VersionView(vm: vm)
                case .login:
                    EmptyView()
                }
                if !hideBottomNav {
                    BottomNav(vm: vm)
                }
            }
        }
    }
}

private struct LoginView: View {
    @ObservedObject var vm: AppViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 32)

                RoundedRectangle(cornerRadius: 18)
                    .fill(AppPalette.primary)
                    .frame(width: 72, height: 72)
                    .overlay(Text("W").font(.system(size: 32, weight: .bold)).foregroundStyle(.white))

                Text(tr(vm.locale, .appName))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)
                Text(tr(vm.locale, .appTagline))
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.textMuted)

                VStack(alignment: .leading, spacing: 10) {
                    Text(tr(vm.locale, .loginTitle))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppPalette.textPrimary)
                    Text(tr(vm.locale, .loginSubtitle))
                        .font(.system(size: 14))
                        .foregroundStyle(AppPalette.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(tr(vm.locale, .emailLabel)).font(.system(size: 13, weight: .medium)).foregroundStyle(AppPalette.textSecondary)
                    TextField(tr(vm.locale, .emailPlaceholder), text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background(AppPalette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(tr(vm.locale, .passwordLabel)).font(.system(size: 13, weight: .medium)).foregroundStyle(AppPalette.textSecondary)
                    SecureField(tr(vm.locale, .passwordPlaceholder), text: $password)
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background(AppPalette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let error = vm.loginError {
                    Text(error).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    vm.login(email: email, password: password)
                } label: {
                    Text(tr(vm.locale, .loginButton))
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppPalette.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(tr(vm.locale, .forgotPassword)) {}
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.primary)

                Button {
                    vm.locale = vm.locale == .en ? .ar : .en
                } label: {
                    Text(vm.locale == .en ? "AR" : "EN")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppPalette.card)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .background(AppPalette.background.ignoresSafeArea())
    }
}

private struct ConversationsView: View {
    @ObservedObject var vm: AppViewModel
    @State private var search = ""
    @State private var selectedTab = 0

    var filtered: [Conversation] {
        vm.conversations.filter { conversation in
            let tabMatches: Bool = {
                if selectedTab == 1 { return conversation.status == .open }
                if selectedTab == 2 { return conversation.status == .closed }
                return true
            }()
            if search.trimmingCharacters(in: .whitespaces).isEmpty { return tabMatches }
            let q = search.lowercased()
            return tabMatches && (conversation.customerName.lowercased().contains(q) || conversation.lastMessage.lowercased().contains(q))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(tr(vm.locale, .conversationsTitle))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().overlay(AppPalette.border)

            TextField(tr(vm.locale, .searchPlaceholder), text: $search)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(AppPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            HStack(spacing: 8) {
                TabChip(title: tr(vm.locale, .all), selected: selectedTab == 0) { selectedTab = 0 }
                TabChip(title: tr(vm.locale, .open), selected: selectedTab == 1) { selectedTab = 1 }
                TabChip(title: tr(vm.locale, .closed), selected: selectedTab == 2) { selectedTab = 2 }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Text(tr(vm.locale, .noConversations)).font(.system(size: 16, weight: .semibold)).foregroundStyle(AppPalette.textPrimary)
                    Text(tr(vm.locale, .noConversationsDesc)).font(.system(size: 13)).foregroundStyle(AppPalette.textMuted).multilineTextAlignment(.center)
                }
                .padding(.top, 42)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filtered) { convo in
                            ConversationRow(conversation: convo, locale: vm.locale) {
                                vm.openChat(id: convo.id)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

private struct ChatView: View {
    @ObservedObject var vm: AppViewModel
    @State private var messageInput = ""
    @State private var showingNoteSheet = false
    @State private var noteInput = ""

    var currentConversation: Conversation? {
        vm.conversations.first { $0.id == vm.activeChatId }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button { vm.backToConversations() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentConversation?.customerName ?? "-")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                    HStack(spacing: 6) {
                        Circle().fill((currentConversation?.isOnline ?? false) ? AppPalette.primary : AppPalette.textMuted).frame(width: 7, height: 7)
                        Text((currentConversation?.isOnline ?? false) ? tr(vm.locale, .online) : "\(tr(vm.locale, .lastSeen)) \(tr(vm.locale, .today))")
                            .font(.system(size: 12))
                            .foregroundStyle(AppPalette.textMuted)
                    }
                }
                Spacer()
                Menu {
                    Button(tr(vm.locale, .internalNote)) { showingNoteSheet = true }
                    Button((currentConversation?.status ?? .open) == .open ? tr(vm.locale, .closeConversation) : tr(vm.locale, .reopenConversation)) {
                        vm.toggleConversationStatus()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(AppPalette.textPrimary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppPalette.surface)
            Divider().overlay(AppPalette.border)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(vm.activeMessages) { msg in
                        MessageBubble(message: msg, darkMode: vm.darkMode)
                            .frame(maxWidth: .infinity, alignment: msg.sender == .agent ? .trailing : .leading)
                    }
                }
                .padding(12)
            }

            HStack(spacing: 10) {
                TextField(tr(vm.locale, .typeMessage), text: $messageInput, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    vm.sendMessage(messageInput)
                    messageInput = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .frame(width: 40, height: 40)
                        .background(AppPalette.primary)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            }
            .padding(12)
            .background(AppPalette.surface)
        }
        .sheet(isPresented: $showingNoteSheet) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 10) {
                    TextEditor(text: $noteInput)
                        .frame(minHeight: 160)
                        .padding(8)
                        .background(AppPalette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Spacer()
                }
                .padding(16)
                .navigationTitle(tr(vm.locale, .internalNote))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(tr(vm.locale, .cancel)) { showingNoteSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(tr(vm.locale, .addNote)) {
                            vm.addNote(noteInput)
                            noteInput = ""
                            showingNoteSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var vm: AppViewModel
    @State private var pushEnabled = true
    @State private var soundEnabled = true
    @State private var showingLogoutAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                card {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Widers Team").font(.system(size: 16, weight: .semibold)).foregroundStyle(AppPalette.textPrimary)
                        Text("support@widers.app").font(.system(size: 13)).foregroundStyle(AppPalette.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                section(title: tr(vm.locale, .notificationSettings)) {
                    Toggle(tr(vm.locale, .pushNotifications), isOn: $pushEnabled)
                    Divider().overlay(AppPalette.border)
                    Toggle(tr(vm.locale, .soundAlerts), isOn: $soundEnabled)
                }

                section(title: tr(vm.locale, .appearance)) {
                    Toggle(tr(vm.locale, .darkMode), isOn: $vm.darkMode)
                    Divider().overlay(AppPalette.border)
                    HStack {
                        Text(tr(vm.locale, .language))
                        Spacer()
                        Picker("", selection: $vm.locale) {
                            Text("EN").tag(AppLocale.en)
                            Text("AR").tag(AppLocale.ar)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                }

                section(title: tr(vm.locale, .about)) {
                    settingsLink(tr(vm.locale, .privacyPolicy)) { vm.setScreen(.privacy) }
                    Divider().overlay(AppPalette.border)
                    settingsLink(tr(vm.locale, .termsOfService)) { vm.setScreen(.terms) }
                    Divider().overlay(AppPalette.border)
                    settingsLink(tr(vm.locale, .version)) { vm.setScreen(.version) }
                }

                Button(role: .destructive) {
                    showingLogoutAlert = true
                } label: {
                    Text(tr(vm.locale, .logout))
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .alert(tr(vm.locale, .logout), isPresented: $showingLogoutAlert) {
            Button(tr(vm.locale, .cancel), role: .cancel) {}
            Button(tr(vm.locale, .confirm), role: .destructive) { vm.logout() }
        } message: {
            Text(tr(vm.locale, .logoutConfirm))
        }
    }

    @ViewBuilder
    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(AppPalette.textMuted)
            card { content() }
        }
    }

    @ViewBuilder
    private func card(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 12) { content() }
            .padding(14)
            .background(AppPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func settingsLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(AppPalette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(AppPalette.textMuted)
            }
        }
    }
}

private struct InfoPageView: View {
    @ObservedObject var vm: AppViewModel
    let title: String
    let sections: [(String, String)]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                topBar
                hero(title: title)
                ForEach(Array(sections.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.0).font(.system(size: 16, weight: .semibold)).foregroundStyle(AppPalette.textPrimary)
                        Text(item.1).font(.system(size: 14)).foregroundStyle(AppPalette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(AppPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(16)
        }
    }

    private var topBar: some View {
        HStack {
            Button { vm.setScreen(.settings) } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(AppPalette.textPrimary)
            }
            Spacer()
            Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(AppPalette.textPrimary)
            Spacer()
            Color.clear.frame(width: 18, height: 18)
        }
    }

    @ViewBuilder
    private func hero(title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LAST UPDATED").font(.system(size: 11, weight: .bold)).foregroundStyle(AppPalette.primary)
            Text(title).font(.system(size: 22, weight: .bold)).foregroundStyle(AppPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct VersionView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Button { vm.setScreen(.settings) } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(AppPalette.textPrimary)
                    }
                    Spacer()
                    Text(tr(vm.locale, .version)).font(.system(size: 16, weight: .semibold)).foregroundStyle(AppPalette.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 18, height: 18)
                }

                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppPalette.primary)
                        .frame(width: 60, height: 60)
                        .overlay(Text("W").font(.system(size: 26, weight: .bold)).foregroundStyle(.white))
                    Text("Widers").font(.system(size: 20, weight: .bold)).foregroundStyle(AppPalette.textPrimary)
                    Text("v1.0.0").font(.system(size: 13)).foregroundStyle(AppPalette.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(AppPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(16)
        }
    }
}

private struct BottomNav: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        HStack(spacing: 0) {
            navItem(
                selected: vm.screen == .conversations,
                title: tr(vm.locale, .chats),
                icon: "bubble.left.and.bubble.right",
                badge: vm.unreadCount
            ) { vm.setScreen(.conversations) }
            navItem(
                selected: vm.screen == .settings,
                title: tr(vm.locale, .settings),
                icon: "gearshape",
                badge: 0
            ) { vm.setScreen(.settings) }
        }
        .frame(height: 58)
        .background(AppPalette.surface)
        .overlay(alignment: .top) { Rectangle().fill(AppPalette.border).frame(height: 1) }
    }

    @ViewBuilder
    private func navItem(selected: Bool, title: String, icon: String, badge: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Capsule()
                    .fill(selected ? AppPalette.primary : .clear)
                    .frame(width: 18, height: 2)
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(selected ? AppPalette.primary : AppPalette.textMuted)
                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 12, y: -8)
                    }
                }
                Text(title)
                    .font(.system(size: 11, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? AppPalette.primary : AppPalette.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private struct ConversationRow: View {
    let conversation: Conversation
    let locale: AppLocale
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(AppPalette.primary.opacity(0.12))
                    .frame(width: 42, height: 42)
                    .overlay(Text(String(conversation.customerName.prefix(1))).font(.system(size: 16, weight: .semibold)).foregroundStyle(AppPalette.primary))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.customerName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppPalette.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(conversation.lastMessageTime)
                            .font(.system(size: 12))
                            .foregroundStyle(AppPalette.textMuted)
                    }
                    Text(conversation.lastMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(AppPalette.textSecondary)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        if conversation.status == .closed {
                            StatusPill(text: tr(locale, .closed), color: AppPalette.textMuted.opacity(0.2), textColor: AppPalette.textMuted)
                        } else if conversation.unreadCount > 0 {
                            StatusPill(text: "\(conversation.unreadCount) \(tr(locale, .unread))", color: AppPalette.primary.opacity(0.12), textColor: AppPalette.primary)
                        }
                    }
                }
            }
            .padding(12)
            .background(AppPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let darkMode: Bool

    var isAgent: Bool { message.sender == .agent }

    var body: some View {
        VStack(alignment: isAgent ? .trailing : .leading, spacing: 4) {
            if message.type == .note {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INTERNAL NOTE").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.orange)
                    Text(message.content).font(.system(size: 14)).foregroundStyle(darkMode ? Color(red: 0.96, green: 0.91, blue: 0.65) : Color(red: 0.53, green: 0.33, blue: 0.08))
                    Text("\(message.noteAuthor ?? "You") • \(message.timestamp)").font(.system(size: 11)).foregroundStyle(AppPalette.textMuted)
                }
                .padding(10)
                .background(Color.orange.opacity(darkMode ? 0.25 : 0.16))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 320, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 14))
                        .foregroundStyle(isAgent ? (darkMode ? Color(red: 0.95, green: 0.97, blue: 0.99) : Color(red: 0.06, green: 0.09, blue: 0.16)) : AppPalette.textPrimary)
                    HStack(spacing: 4) {
                        Text(message.timestamp)
                            .font(.system(size: 11))
                            .foregroundStyle(isAgent ? (darkMode ? Color(red: 0.58, green: 0.77, blue: 0.99) : Color(red: 0.28, green: 0.35, blue: 0.44)) : AppPalette.textMuted)
                        if isAgent {
                            Image(systemName: deliveryIcon(message.status))
                                .font(.system(size: 10))
                                .foregroundStyle(isAgent ? (darkMode ? Color(red: 0.58, green: 0.77, blue: 0.99) : Color(red: 0.28, green: 0.35, blue: 0.44)) : AppPalette.textMuted)
                        }
                    }
                }
                .padding(10)
                .background(isAgent ? AppPalette.primary.opacity(darkMode ? 0.35 : 0.14) : AppPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: 320, alignment: isAgent ? .trailing : .leading)
            }
        }
    }

    private func deliveryIcon(_ status: MessageDeliveryStatus) -> String {
        switch status {
        case .sending: return "clock"
        case .sent: return "checkmark"
        case .delivered: return "checkmark.circle"
        case .read: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle"
        }
    }
}

private struct StatusPill: View {
    let text: String
    let color: Color
    let textColor: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

private struct TabChip: View {
    let title: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(selected ? .white : AppPalette.textSecondary)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(selected ? AppPalette.primary : AppPalette.card)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private enum AppPalette {
    static let primary = Color(red: 0.07, green: 0.60, blue: 0.42)
    static let background = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.06, green: 0.08, blue: 0.11, alpha: 1) : UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1) })
    static let surface = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.14, blue: 0.18, alpha: 1) : UIColor.white })
    static let card = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.16, green: 0.19, blue: 0.24, alpha: 1) : UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1) })
    static let textPrimary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.95, green: 0.97, blue: 0.99, alpha: 1) : UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1) })
    static let textSecondary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.82, green: 0.86, blue: 0.90, alpha: 1) : UIColor(red: 0.20, green: 0.25, blue: 0.33, alpha: 1) })
    static let textMuted = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.58, green: 0.63, blue: 0.70, alpha: 1) : UIColor(red: 0.40, green: 0.46, blue: 0.54, alpha: 1) })
    static let border = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.14) : UIColor(red: 0.88, green: 0.91, blue: 0.94, alpha: 1) })
}

private func privacySections(_ locale: AppLocale) -> [(String, String)] {
    if locale == .ar {
        return [
            ("جمع البيانات", "نجمع معلومات أساسية لتحسين الدعم وتجربة الرسائل."),
            ("استخدام البيانات", "تُستخدم البيانات لإدارة المحادثات وتقديم خدمة أفضل."),
            ("أمن المعلومات", "نستخدم ممارسات قياسية لحماية البيانات من الوصول غير المصرح."),
        ]
    }
    return [
        ("Data Collection", "We collect essential data to improve support quality and messaging workflows."),
        ("Data Usage", "Data is used to manage conversations and provide better customer support."),
        ("Information Security", "We apply standard safeguards to protect data from unauthorized access."),
    ]
}

private func termsSections(_ locale: AppLocale) -> [(String, String)] {
    if locale == .ar {
        return [
            ("استخدام الخدمة", "باستخدام التطبيق فأنت توافق على الالتزام بسياسات المنصة."),
            ("مسؤولية الحساب", "أنت مسؤول عن حماية بيانات الدخول واستخدام الحساب بشكل صحيح."),
            ("التحديثات", "قد نقوم بتحديث الشروط دورياً، واستمرار الاستخدام يعني الموافقة."),
        ]
    }
    return [
        ("Service Usage", "By using the app, you agree to follow the platform policies and applicable laws."),
        ("Account Responsibility", "You are responsible for your credentials and all activity under your account."),
        ("Updates", "Terms may be updated periodically; continued use implies acceptance."),
    ]
}

#Preview {
    AppRootView()
}
