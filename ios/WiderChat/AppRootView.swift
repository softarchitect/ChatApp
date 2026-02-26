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
                    PrivacyPolicyView(vm: vm)
                case .terms:
                    TermsOfServiceView(vm: vm)
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
    @State private var showingLanguageDialog = false
    @State private var showingLogoutAlert = false

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                HStack {
                    Text(tr(vm.locale, .settings))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppPalette.textPrimary)
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppPalette.surface)

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(AppPalette.primary)
                            .frame(width: 56, height: 56)
                            .overlay(Text("MK").font(.system(size: 16, weight: .bold)).foregroundStyle(.white))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Merchant Admin")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppPalette.textPrimary)
                            Text("admin@widers.com")
                                .font(.system(size: 13))
                                .foregroundStyle(AppPalette.textMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppPalette.textMuted)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 16)
                    settingsTitle("ACCOUNT")
                    flatGroup {
                        flatRow(icon: "person.fill", iconBg: Color(red: 0.23, green: 0.51, blue: 0.96), label: "Profile", value: nil, onTap: {})
                    }

                    Spacer().frame(height: 8)
                    settingsTitle("NOTIFICATION SETTINGS")
                    flatGroup {
                        flatToggleRow(icon: "bell.badge.fill", iconBg: Color(red: 0.96, green: 0.25, blue: 0.37), label: tr(vm.locale, .pushNotifications), isOn: $pushEnabled)
                        sectionDivider()
                        flatToggleRow(icon: "speaker.wave.3.fill", iconBg: Color(red: 0.96, green: 0.62, blue: 0.04), label: tr(vm.locale, .soundAlerts), isOn: $soundEnabled)
                    }

                    Spacer().frame(height: 8)
                    settingsTitle("APPEARANCE")
                    flatGroup {
                        flatRow(
                            icon: "globe",
                            iconBg: Color(red: 0.02, green: 0.71, blue: 0.83),
                            label: tr(vm.locale, .language),
                            value: vm.locale == .en ? "English" : "العربية",
                            onTap: { showingLanguageDialog = true }
                        )
                        sectionDivider()
                        flatToggleRow(icon: "moon.fill", iconBg: Color(red: 0.39, green: 0.40, blue: 0.95), label: tr(vm.locale, .darkMode), isOn: $vm.darkMode)
                    }

                    Spacer().frame(height: 8)
                    settingsTitle("ABOUT")
                    flatGroup {
                        flatRow(icon: "shield.fill", iconBg: Color(red: 0.06, green: 0.73, blue: 0.51), label: tr(vm.locale, .privacyPolicy), value: nil, onTap: { vm.setScreen(.privacy) })
                        sectionDivider()
                        flatRow(icon: "doc.text.fill", iconBg: Color(red: 0.08, green: 0.72, blue: 0.65), label: tr(vm.locale, .termsOfService), value: nil, onTap: { vm.setScreen(.terms) })
                        sectionDivider()
                        flatRow(icon: "info.circle.fill", iconBg: Color(red: 0.39, green: 0.45, blue: 0.55), label: tr(vm.locale, .version), value: "1.0.0", onTap: { vm.setScreen(.version) })
                    }
                    Spacer().frame(height: 14)
                    Button {
                        showingLogoutAlert = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text(tr(vm.locale, .logout))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(Color(red: 0.94, green: 0.27, blue: 0.27))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.94, green: 0.27, blue: 0.27).opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .alert(tr(vm.locale, .logout), isPresented: $showingLogoutAlert) {
            Button(tr(vm.locale, .cancel), role: .cancel) {}
            Button(tr(vm.locale, .confirm), role: .destructive) { vm.logout() }
        } message: {
            Text(tr(vm.locale, .logoutConfirm))
        }
        .confirmationDialog(tr(vm.locale, .language), isPresented: $showingLanguageDialog, titleVisibility: .visible) {
            Button("English") { vm.locale = .en }
            Button("العربية") { vm.locale = .ar }
            Button(tr(vm.locale, .cancel), role: .cancel) {}
        }
    }

    @ViewBuilder
    private func settingsTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppPalette.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 3)
    }

    @ViewBuilder
    private func flatGroup(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) { content() }
            .background(AppPalette.surface)
    }

    @ViewBuilder
    private func flatRow(icon: String, iconBg: Color, label: String, value: String?, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconBg)
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white))

                Spacer().frame(width: 10)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                if let value {
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundStyle(AppPalette.textMuted)
                    Spacer().frame(width: 8)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppPalette.textMuted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func flatToggleRow(icon: String, iconBg: Color, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconBg)
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white))
            Spacer().frame(width: 10)
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(AppPalette.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
    }

    @ViewBuilder
    private func sectionDivider() -> some View {
        Divider()
            .overlay(AppPalette.border.opacity(0.55))
            .padding(.leading, 62)
    }
}

private struct PrivacyPolicyView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            AppBackHeader(title: tr(vm.locale, .privacyPolicy)) { vm.setScreen(.settings) }

            ScrollView {
                VStack(spacing: 0) {
                    PolicyHero(
                        date: "February 25, 2026",
                        intro: "Widers is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our WhatsApp Business Cloud API platform and mobile application."
                    )

                    ForEach(Array(privacySections.enumerated()), id: \.offset) { idx, item in
                        PolicySectionCard(
                            icon: item.icon,
                            iconTint: Color(red: 0.06, green: 0.73, blue: 0.51),
                            title: item.title,
                            text: item.body,
                            index: idx + 1
                        )
                    }
                }
            }
        }
    }
}

private struct TermsOfServiceView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            AppBackHeader(title: tr(vm.locale, .termsOfService)) { vm.setScreen(.settings) }

            ScrollView {
                VStack(spacing: 0) {
                    PolicyHero(
                        date: "February 25, 2026",
                        intro: "These Terms of Service govern your access and use of the Widers platform, including our WhatsApp Business Cloud API services and mobile application."
                    )

                    ForEach(Array(termsSections.enumerated()), id: \.offset) { idx, item in
                        PolicySectionCard(
                            icon: item.icon,
                            iconTint: Color(red: 0.05, green: 0.65, blue: 0.91),
                            title: item.title,
                            text: item.body,
                            index: idx + 1
                        )
                    }
                }
            }
        }
    }
}

private struct VersionView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            AppBackHeader(title: vm.locale == .ar ? "حول وايدرز" : "About Widers") { vm.setScreen(.settings) }

            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppPalette.primary)
                            .frame(width: 80, height: 80)
                            .overlay(Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 32, weight: .medium)).foregroundStyle(.white))

                        Text("Widers")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppPalette.textPrimary)
                        Text("META APPROVED PARTNER")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppPalette.primary)
                        Text(
                            vm.locale == .ar
                                ? "وايدرز منصة معتمدة من ميتا لإدارة محادثات واتساب للأعمال في الوقت الفعلي مع فرق متعددة."
                                : "Widers is a Meta-approved WhatsApp Business Cloud API provider helping teams manage customer conversations at scale."
                        )
                        .font(.system(size: 16))
                        .foregroundStyle(AppPalette.textMuted)
                        .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(AppPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(spacing: 0) {
                        versionInfoRow("Version", "1.0.0")
                        versionInfoRow("Build", "2026.02.25")
                        versionInfoRow("Environment", "Production")
                        versionInfoRow("API Version", "v2.0")
                        versionInfoRow("WhatsApp Cloud API", "v21.0", drawDivider: false)
                    }
                    .background(AppPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("KEY FEATURES")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppPalette.textMuted)

                        VStack(spacing: 10) {
                            ForEach(versionFeatures, id: \.self) { feature in
                                HStack(alignment: .center, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppPalette.primary)
                                    Text(feature)
                                        .font(.system(size: 15))
                                        .foregroundStyle(AppPalette.textPrimary)
                                    Spacer()
                                }
                            }
                        }
                        .padding(14)
                        .background(AppPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }
}

private struct AppBackHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
            }
            Spacer()
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppPalette.textPrimary)
            Spacer()
            Color.clear.frame(width: 16, height: 16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppPalette.surface)
    }
}

private struct PolicyHero: View {
    let date: String
    let intro: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Rectangle().fill(AppPalette.border.opacity(0.9)).frame(height: 1)
                Text("LAST UPDATED")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppPalette.textMuted)
                Rectangle().fill(AppPalette.border.opacity(0.9)).frame(height: 1)
            }

            Text(date)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .padding(.top, 8)

            Text(intro)
                .font(.system(size: 14))
                .foregroundStyle(AppPalette.textMuted)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppPalette.secondarySoft)
    }
}

private struct PolicySectionCard: View {
    let icon: String
    let iconTint: Color
    let title: String
    let text: String
    let index: Int

    var bodyView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(iconTint.opacity(0.10))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(iconTint))
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .padding(.leading, 10)
                Spacer()
                Text(String(format: "%02d", index))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppPalette.textMuted)
            }
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(AppPalette.textMuted)
                .padding(.top, 8)
        }
        .padding(14)
        .background(AppPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var body: some View {
        bodyView
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

@ViewBuilder
private func versionInfoRow(_ label: String, _ value: String, drawDivider: Bool = true) -> some View {
    VStack(spacing: 0) {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(AppPalette.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppPalette.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        if drawDivider {
            Divider().overlay(AppPalette.border.opacity(0.6))
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
    static let secondarySoft = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.22, green: 0.25, blue: 0.30, alpha: 1) : UIColor(red: 0.89, green: 0.93, blue: 0.97, alpha: 1) })
    static let card = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.16, green: 0.19, blue: 0.24, alpha: 1) : UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1) })
    static let textPrimary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.95, green: 0.97, blue: 0.99, alpha: 1) : UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1) })
    static let textSecondary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.82, green: 0.86, blue: 0.90, alpha: 1) : UIColor(red: 0.20, green: 0.25, blue: 0.33, alpha: 1) })
    static let textMuted = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.58, green: 0.63, blue: 0.70, alpha: 1) : UIColor(red: 0.40, green: 0.46, blue: 0.54, alpha: 1) })
    static let border = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.14) : UIColor(red: 0.88, green: 0.91, blue: 0.94, alpha: 1) })
}

private struct PolicySectionData {
    let icon: String
    let title: String
    let body: String
}

private let privacySections: [PolicySectionData] = [
    .init(icon: "eye.fill", title: "Information We Collect", body: "We collect information you provide directly, including your name, email address, phone number, and business details when you register for an account. We also collect message content, conversation metadata, and usage analytics to provide and improve our services."),
    .init(icon: "internaldrive.fill", title: "How We Use Your Information", body: "We use the information we collect to operate, maintain, and provide platform features, including routing and managing WhatsApp Business messages, enabling team collaboration through internal notes, and sending service-related notifications."),
    .init(icon: "lock.fill", title: "Data Storage & Security", body: "Your data is stored on secure servers with encryption at rest and in transit. We implement role-based access controls, regular security checks, and automated threat detection."),
    .init(icon: "globe", title: "WhatsApp & Meta Compliance", body: "As a Meta-approved WhatsApp Business Cloud API provider, we comply with Meta Platform Terms and WhatsApp Business policies."),
    .init(icon: "shield.fill", title: "Third-Party Services", body: "We may share data with trusted third-party providers who assist us in operating our platform under confidentiality agreements."),
    .init(icon: "checkmark.shield.fill", title: "Your Rights", body: "You can request access, correction, or deletion of your personal data by contacting support."),
    .init(icon: "envelope.fill", title: "Contact Us", body: "privacy@widers.com")
]

private let termsSections: [PolicySectionData] = [
    .init(icon: "person.crop.circle.fill", title: "Account Registration", body: "To use Widers, you must register for a merchant account and provide accurate information. You are responsible for keeping account credentials secure."),
    .init(icon: "shield.fill", title: "Acceptable Use", body: "You agree to use the service only for lawful purposes and in compliance with WhatsApp Business policies. No spam, abuse, or impersonation."),
    .init(icon: "creditcard.fill", title: "Subscription & Billing", body: "Access to Widers is subscription-based. Plans are billed monthly or annually according to the selected package."),
    .init(icon: "clock.fill", title: "Service Level Agreement", body: "We strive to maintain high platform uptime. Scheduled maintenance windows will be communicated in advance."),
    .init(icon: "doc.text.fill", title: "Intellectual Property", body: "Widers platform design and features are protected. You retain ownership of your own customer content and messages."),
    .init(icon: "exclamationmark.triangle.fill", title: "Limitation of Liability", body: "To the maximum extent permitted by law, Widers is not liable for indirect or consequential damages."),
    .init(icon: "xmark.octagon.fill", title: "Termination", body: "Either party may terminate the service. Data retention and deletion policies apply as defined in the agreement."),
    .init(icon: "building.columns.fill", title: "Governing Law", body: "Any disputes are resolved according to applicable governing law and dispute-resolution terms.")
]

private let versionFeatures: [String] = [
    "Real-time WhatsApp Business messaging",
    "Multi-agent conversation management",
    "Internal notes and team collaboration",
    "Conversation analytics and reporting",
    "Automated message routing and assignment",
    "Template message management"
]

#Preview {
    AppRootView()
}
