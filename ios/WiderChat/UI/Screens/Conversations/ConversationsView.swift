import SwiftUI

struct ConversationsView: View {
    @ObservedObject var vm: AppViewModel
    @State private var search = ""
    @State private var selectedTab = 0
    @State private var showNewConversationDialog = false
    @State private var newConversationName = ""
    @State private var newConversationPhone = ""
    @State private var contactSearch = ""

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

    var filteredContacts: [NewConversationContact] {
        let q = contactSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return vm.newConversationContacts }
        return vm.newConversationContacts.filter { item in
            item.name.lowercased().contains(q) || item.phone.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(tr(vm.locale, .conversationsTitle))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                Button {
                    showNewConversationDialog = true
                    vm.loadContactsForNewConversation()
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppPalette.primary)
                        .frame(width: 36, height: 36)
                        .background(AppPalette.primary.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
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
                .onChange(of: search) { _, newValue in
                    vm.searchChats(newValue)
                }

            HStack(spacing: 8) {
                TabChip(title: tr(vm.locale, .all), selected: selectedTab == 0) { selectedTab = 0 }
                TabChip(title: tr(vm.locale, .open), selected: selectedTab == 1) { selectedTab = 1 }
                TabChip(title: tr(vm.locale, .closed), selected: selectedTab == 2) { selectedTab = 2 }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            if let status = vm.actionStatus, !status.isEmpty {
                Text(status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppPalette.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

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
        .sheet(isPresented: $showNewConversationDialog) {
            VStack(spacing: 12) {
                HStack {
                    Text(tr(vm.locale, .newConversationTitle))
                        .font(.system(size: 22, weight: .bold))
                    Spacer()
                    Button(tr(vm.locale, .cancel)) {
                        showNewConversationDialog = false
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                TextField(tr(vm.locale, .nameLabel), text: $newConversationName)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(AppPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)

                TextField(tr(vm.locale, .phoneLabel), text: $newConversationPhone)
                    .keyboardType(.phonePad)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(AppPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)

                Button(tr(vm.locale, .create)) {
                    vm.startNewConversation(name: newConversationName, phone: newConversationPhone)
                    newConversationName = ""
                    newConversationPhone = ""
                    showNewConversationDialog = false
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background((newConversationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newConversationPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? AppPalette.textMuted.opacity(0.3) : AppPalette.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .disabled(newConversationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newConversationPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Divider().overlay(AppPalette.border)

                TextField("Search contacts...", text: $contactSearch)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(AppPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .onChange(of: contactSearch) { _, value in
                        vm.searchContactsForNewConversation(value)
                    }

                if vm.contactsLoading {
                    ProgressView()
                        .padding(.vertical, 20)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredContacts.prefix(20)) { contact in
                                Button {
                                    vm.startConversationForContact(contact)
                                    showNewConversationDialog = false
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(contact.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(AppPalette.textPrimary)
                                                .lineLimit(1)
                                            Text(contact.phone)
                                                .font(.system(size: 13))
                                                .foregroundStyle(AppPalette.textMuted)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                Divider().overlay(AppPalette.border.opacity(0.5))
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .presentationDetents([.large])
        }
    }
}
