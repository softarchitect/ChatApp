import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: AppViewModel
    @State private var pushEnabled = true
    @State private var soundEnabled = true
    @State private var showingLanguageDialog = false
    @State private var showingLogoutAlert = false
    @State private var showTagDialog = false
    @State private var showReplyDialog = false
    @State private var showContactDialog = false
    @State private var tagName = ""
    @State private var tagColor = "#ffffff"
    @State private var tagId = ""
    @State private var replyName = ""
    @State private var replyText = ""
    @State private var replyId = ""
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var contactEmail = ""

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
                    let displayName = vm.profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Account" : vm.profileName
                    let displayEmail = vm.profileEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : vm.profileEmail
                    HStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(AppPalette.primary)
                            .frame(width: 56, height: 56)
                            .overlay(Text(initialsFromName(displayName)).font(.system(size: 16, weight: .bold)).foregroundStyle(.white))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppPalette.textPrimary)
                            Text(displayEmail)
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
                    settingsTitle("BACKEND TOOLS")
                    flatGroup {
                        flatRow(icon: "arrow.clockwise.circle.fill", iconBg: Color(red: 0.02, green: 0.55, blue: 0.34), label: "Sync support data", value: nil, onTap: { vm.preloadSupportData() })
                        sectionDivider()
                        flatRow(icon: "tag.fill", iconBg: Color(red: 0.40, green: 0.25, blue: 0.93), label: "Create / Update Tag", value: nil, onTap: { showTagDialog = true })
                        sectionDivider()
                        flatRow(icon: "arrowshape.turn.up.left.fill", iconBg: Color(red: 0.01, green: 0.47, blue: 0.78), label: "Create / Update Reply", value: nil, onTap: { showReplyDialog = true })
                        sectionDivider()
                        flatRow(icon: "person.crop.circle.badge.plus", iconBg: Color(red: 0.96, green: 0.62, blue: 0.04), label: "Add Contact", value: nil, onTap: { showContactDialog = true })
                    }
                    if let status = vm.actionStatus, !status.isEmpty {
                        Text(status)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppPalette.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
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
        .alert("Create / Update Tag", isPresented: $showTagDialog) {
            TextField("Tag name", text: $tagName)
            TextField("Tag color (#hex)", text: $tagColor)
            TextField("Tag ID (optional)", text: $tagId)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                vm.createOrUpdateTag(name: tagName, color: tagColor, tagId: Int(tagId))
            }
        }
        .alert("Create / Update Reply", isPresented: $showReplyDialog) {
            TextField("Reply name", text: $replyName)
            TextField("Reply text", text: $replyText)
            TextField("Reply ID (optional)", text: $replyId)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                vm.createOrUpdateReply(name: replyName, text: replyText, replyId: Int(replyId))
            }
        }
        .alert("Add Contact", isPresented: $showContactDialog) {
            TextField("Name", text: $contactName)
            TextField("Phone", text: $contactPhone)
            TextField("Email (optional)", text: $contactEmail)
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                vm.addContact(name: contactName, phone: contactPhone, email: contactEmail.isEmpty ? nil : contactEmail)
            }
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

    private func initialsFromName(_ name: String) -> String {
        let words = name
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if words.isEmpty { return "A" }
        return words.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }.joined()
    }
}
