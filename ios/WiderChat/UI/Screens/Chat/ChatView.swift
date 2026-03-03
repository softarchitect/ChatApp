import SwiftUI

import AVFoundation
import UniformTypeIdentifiers
import UIKit

typealias ChatScreenView = ChatView

struct ChatView: View {
    @ObservedObject var vm: AppViewModel
    @State private var messageInput = ""
    @State private var showingInternalNoteComposer = false
    @State private var noteInput = ""
    @State private var showAssignAgentDialog = false
    @State private var showTagDialog = false
    @State private var showTemplateDialog = false
    @State private var showFlowDialog = false
    @State private var showReplyDialog = false
    @State private var showCustomFieldDialog = false
    @State private var showUpdateContactDialog = false
    @State private var agentSearch = ""
    @State private var tagSearch = ""
    @State private var templateSearch = ""
    @State private var templateInput = ""
    @State private var flowSearch = ""
    @State private var flowInput = ""
    @State private var replySearch = ""
    @State private var customFieldId = ""
    @State private var customFieldValue = ""
    @State private var customFieldSearch = ""
    @State private var updateContactName = ""
    @State private var updateContactPhone = ""
    @State private var updateContactEmail = ""
    @State private var isNearBottom = true
    @State private var forceAutoScroll = false
    @State private var shouldScrollToLatestOnOpen = true
    @State private var pendingNewMessages = 0
    @State private var showCameraPicker = false
    @State private var showImageImporter = false
    @State private var showDocumentImporter = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecordingVoice = false
    @State private var showContactInfoSheet = false
    @State private var skeletonOpacity = 0.55
    @State private var skeletonShimmerOffset: CGFloat = -240
    @State private var olderAnchorMessageId: String?
    private let emojiCategories: [String: [String]] = [
        "smileys": ["😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "🙂", "😉", "😍", "🥰", "😘", "😎", "🤔", "😭"],
        "gestures": ["👍", "👎", "👏", "🙌", "🙏", "🤝", "💪", "👌", "✌️", "🤞", "👋", "🤲", "🫶", "💯", "✅", "❌"],
        "hearts": ["❤️", "🩷", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💖", "💗", "🔥"],
        "celebration": ["🎉", "🎊", "✨", "⭐", "🌟", "⚡", "☀️", "🌈", "🍀", "🎁", "🏆", "🎵", "🎶", "📌", "📣", "📷"]
    ]

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
                Button {
                    showContactInfoSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(AppPalette.primary.opacity(0.14))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Text(String((currentConversation?.customerName.first ?? "C")).uppercased())
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(AppPalette.primary)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(currentConversation?.customerName ?? "-")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppPalette.textPrimary)
                                    .lineLimit(1)
                                    .layoutPriority(1)
                                if let satisfaction = currentConversation?.satisfaction {
                                    SatisfactionBadge(value: satisfaction, locale: vm.locale, variant: .regular)
                                }
                            }
                            HStack(spacing: 6) {
                                Circle().fill((currentConversation?.isOnline ?? false) ? AppPalette.primary : AppPalette.textMuted).frame(width: 7, height: 7)
                                Text((currentConversation?.isOnline ?? false) ? tr(vm.locale, .online) : "\(tr(vm.locale, .lastSeen)) \(tr(vm.locale, .today))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppPalette.textMuted)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Menu {
                    Button(tr(vm.locale, .internalNote)) { showingInternalNoteComposer.toggle() }
                    Button((currentConversation?.status ?? .open) == .open ? tr(vm.locale, .closeConversation) : tr(vm.locale, .reopenConversation)) {
                        vm.toggleConversationStatus()
                    }
                    Button(tr(vm.locale, .assignAgent)) {
                        showAssignAgentDialog = true
                        agentSearch = ""
                        Task { await vm.refreshAvailableAgents() }
                    }
                    Button(tr(vm.locale, .unassignAgent)) { vm.unassignCurrentChat() }
                    Button(tr(vm.locale, .muteConversation)) { vm.muteCurrentChat(true) }
                    Button(tr(vm.locale, .unmuteConversation)) { vm.muteCurrentChat(false) }
                    Button(tr(vm.locale, .markAsRead)) { vm.markCurrentChatRead(true) }
                    Button(tr(vm.locale, .markAsUnread)) { vm.markCurrentChatRead(false) }
                    Button(tr(vm.locale, .attachDetachTag)) {
                        showTagDialog = true
                        tagSearch = ""
                        Task { await vm.refreshAvailableTags() }
                    }
                    Button(tr(vm.locale, .sendTemplate)) {
                        showTemplateDialog = true
                        templateSearch = ""
                        templateInput = ""
                        Task { await vm.refreshAvailableTemplates() }
                    }
                    Button(tr(vm.locale, .sendFlow)) {
                        showFlowDialog = true
                        flowSearch = ""
                        flowInput = ""
                        Task { await vm.refreshAvailableFlows() }
                    }
                    Button(tr(vm.locale, .sendQuickReply)) {
                        showReplyDialog = true
                        replySearch = ""
                        Task { await vm.refreshAvailableReplies() }
                    }
                    Button(tr(vm.locale, .syncCustomField)) {
                        showCustomFieldDialog = true
                        customFieldSearch = ""
                        Task { await vm.refreshCurrentContactCustomFields() }
                    }
                    Button(tr(vm.locale, .updateContact)) {
                        updateContactName = currentConversation?.customerName ?? ""
                        updateContactPhone = currentConversation?.customerPhone ?? ""
                        updateContactEmail = ""
                        showUpdateContactDialog = true
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
            if let status = vm.actionStatus, !status.isEmpty {
                let isMetaWindowWarning = status.localizedCaseInsensitiveContains("24")
                    && status.localizedCaseInsensitiveContains("template")
                Text(status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isMetaWindowWarning ? Color.white : AppPalette.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(isMetaWindowWarning ? Color.red : AppPalette.secondarySoft)
            }

            ZStack {
                ScrollViewReader { proxy in
                    GeometryReader { scrollGeo in
                        ZStack(alignment: .bottomTrailing) {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                if vm.isLoadingMoreActiveMessages {
                                    Text(vm.locale == .ar ? "جارٍ تحميل الرسائل الأقدم..." : "Loading older messages...")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(AppPalette.textMuted)
                                        .padding(.top, 4)
                                }
                                ForEach(vm.activeMessages) { msg in
                                    MessageBubble(message: msg, darkMode: vm.darkMode)
                                        .frame(maxWidth: .infinity, alignment: msg.sender == .agent ? .trailing : .leading)
                                        .id(msg.id)
                                        .onAppear {
                                            if msg.id == vm.activeMessages.first?.id,
                                               vm.hasMoreActiveMessages,
                                               !vm.isLoadingMoreActiveMessages {
                                                olderAnchorMessageId = msg.id
                                                Task { await vm.loadOlderMessagesForActiveChat() }
                                            }
                                        }
                                }
                                Color.clear
                                    .frame(height: 1)
                                    .id("chat-bottom-anchor")
                                    .background(
                                        GeometryReader { anchorGeo in
                                            Color.clear.preference(
                                                key: ChatBottomPreferenceKey.self,
                                                value: anchorGeo.frame(in: .named("chat-scroll-space")).maxY
                                            )
                                        }
                                    )
                            }
                            .padding(12)
                        }
                        .coordinateSpace(name: "chat-scroll-space")
                        .onPreferenceChange(ChatBottomPreferenceKey.self) { bottomY in
                            let threshold: CGFloat = 120
                            isNearBottom = bottomY <= (scrollGeo.size.height + threshold)
                        }
                        .onAppear {
                            shouldScrollToLatestOnOpen = true
                            if let last = vm.activeMessages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                                shouldScrollToLatestOnOpen = false
                            }
                            pendingNewMessages = 0
                        }
                        .onChange(of: vm.activeChatId) { _, _ in
                            shouldScrollToLatestOnOpen = true
                            if let last = vm.activeMessages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                                shouldScrollToLatestOnOpen = false
                            }
                            pendingNewMessages = 0
                        }
                        .onChange(of: vm.activeMessages.last?.id) { _, newId in
                            guard let newId else { return }
                            let latestIsIncoming = vm.activeMessages.last?.sender != .agent
                            if !isNearBottom, !forceAutoScroll, latestIsIncoming {
                                pendingNewMessages += 1
                            }
                            if shouldScrollToLatestOnOpen || isNearBottom || forceAutoScroll {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(newId, anchor: .bottom)
                                }
                                pendingNewMessages = 0
                                shouldScrollToLatestOnOpen = false
                            }
                            forceAutoScroll = false
                        }
                        .onChange(of: vm.activeMessages.first?.id) { _, _ in
                            guard let anchorId = olderAnchorMessageId else { return }
                            withAnimation(.none) {
                                proxy.scrollTo(anchorId, anchor: .top)
                            }
                            olderAnchorMessageId = nil
                        }
                        .onChange(of: isNearBottom) { _, nearBottom in
                            if nearBottom {
                                pendingNewMessages = 0
                            }
                        }
                        if !isNearBottom, !vm.activeMessages.isEmpty {
                            Button {
                                if let last = vm.activeMessages.last {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        proxy.scrollTo(last.id, anchor: .bottom)
                                    }
                                }
                                pendingNewMessages = 0
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 38, height: 38)
                                        .background(AppPalette.primary)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                    if pendingNewMessages > 0 {
                                        Text(pendingNewMessages > 99 ? "99+" : "\(pendingNewMessages)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.red)
                                            .clipShape(Capsule())
                                            .offset(x: 8, y: -6)
                                    }
                                }
                            }
                            .padding(.trailing, 14)
                            .padding(.bottom, 14)
                        }
                        }
                    }
                }
                if vm.isChatLoading && vm.activeMessages.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { idx in
                            HStack {
                                if idx % 2 != 0 { Spacer(minLength: 30) }
                                VStack(alignment: .leading, spacing: 6) {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppPalette.card)
                                        .frame(width: idx % 3 == 0 ? 230 : (idx % 3 == 1 ? 180 : 260), height: 52)
                                        .overlay(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.0), Color.white.opacity(0.34), Color.white.opacity(0.0)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            .rotationEffect(.degrees(18))
                                            .offset(x: skeletonShimmerOffset)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(AppPalette.card)
                                        .frame(width: 44, height: 10)
                                        .overlay(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.0), Color.white.opacity(0.34), Color.white.opacity(0.0)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            .rotationEffect(.degrees(18))
                                            .offset(x: skeletonShimmerOffset)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                if idx % 2 == 0 { Spacer(minLength: 30) }
                            }
                        }
                    }
                    .opacity(skeletonOpacity)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppPalette.background.opacity(0.65))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            skeletonOpacity = 1.0
                        }
                        withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                            skeletonShimmerOffset = 260
                        }
                    }
                    .onDisappear {
                        skeletonOpacity = 0.55
                        skeletonShimmerOffset = -240
                    }
                }
            }

            if showingInternalNoteComposer {
                VStack(alignment: .leading, spacing: 8) {
                    Text(tr(vm.locale, .internalNote))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0.58, green: 0.25, blue: 0.05))
                    HStack(spacing: 8) {
                        TextField(tr(vm.locale, .internalNotePlaceholder), text: $noteInput)
                            .padding(.horizontal, 12)
                            .frame(height: 48)
                            .background(Color(red: 1.0, green: 0.97, blue: 0.93))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 0.58, green: 0.25, blue: 0.05).opacity(0.4), lineWidth: 1)
                            )
                        Button(tr(vm.locale, .addNote)) {
                            vm.addNote(noteInput)
                            noteInput = ""
                            showingInternalNoteComposer = false
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.58, green: 0.25, blue: 0.05))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(red: 0.99, green: 0.95, blue: 0.78))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            let commandInput = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
            let commandQuery = String(commandInput.dropFirst()).lowercased()
            let replyCommandItems = commandInput.hasPrefix("/")
                ? vm.availableReplies.filter {
                    commandQuery.isEmpty
                        || $0.name.lowercased().contains(commandQuery)
                        || $0.text.lowercased().contains(commandQuery)
                }.prefix(8)
                : vm.availableReplies.prefix(0)
            let agentCommandItems = commandInput.hasPrefix("@")
                ? vm.availableAgents.filter {
                    commandQuery.isEmpty || $0.name.lowercased().contains(commandQuery)
                }.prefix(8)
                : vm.availableAgents.prefix(0)
            let tagCommandItems = commandInput.hasPrefix("#")
                ? vm.availableTags.filter {
                    commandQuery.isEmpty || $0.name.lowercased().contains(commandQuery)
                }.prefix(8)
                : vm.availableTags.prefix(0)

            if commandInput.hasPrefix("/") || commandInput.hasPrefix("@") || commandInput.hasPrefix("#") {
                VStack(spacing: 0) {
                    if commandInput.hasPrefix("/") {
                        ForEach(Array(replyCommandItems), id: \.id) { reply in
                            Button {
                                vm.sendQuickReplyToCurrentChat(replyId: reply.id)
                                messageInput = ""
                                forceAutoScroll = true
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reply.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(AppPalette.textPrimary)
                                    Text(reply.text)
                                        .font(.system(size: 12))
                                        .lineLimit(1)
                                        .foregroundStyle(AppPalette.textMuted)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            Divider().overlay(AppPalette.border.opacity(0.4))
                        }
                    } else if commandInput.hasPrefix("@") {
                        ForEach(Array(agentCommandItems), id: \.id) { agent in
                            Button {
                                vm.assignCurrentChat(agentId: agent.id)
                                messageInput = ""
                            } label: {
                                Text(agent.name)
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppPalette.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            Divider().overlay(AppPalette.border.opacity(0.4))
                        }
                    } else if commandInput.hasPrefix("#") {
                        ForEach(Array(tagCommandItems), id: \.id) { tag in
                            Button {
                                vm.attachTagToCurrentChat(tagId: tag.id)
                                messageInput = ""
                            } label: {
                                Text(tag.name)
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppPalette.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            Divider().overlay(AppPalette.border.opacity(0.4))
                        }
                    }
                }
                .background(AppPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }

            HStack(spacing: 10) {
                Menu {
                    Button(tr(vm.locale, .camera)) {
                        showCameraPicker = true
                    }
                    Button(tr(vm.locale, .gallery)) {
                        showImageImporter = true
                    }
                    Button(tr(vm.locale, .document)) {
                        showDocumentImporter = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppPalette.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(AppPalette.card)
                        .clipShape(Circle())
                }
                Circle()
                    .fill(isRecordingVoice ? .red : AppPalette.card)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isRecordingVoice ? Color.white : AppPalette.textSecondary)
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isRecordingVoice {
                                    startVoiceRecording()
                                }
                            }
                            .onEnded { _ in
                                if isRecordingVoice {
                                    stopRecordingAndSend()
                                }
                            }
                    )

                TextField(tr(vm.locale, .typeMessage), text: $messageInput, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    forceAutoScroll = true
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
        .sheet(isPresented: $showCameraPicker) {
            CameraImagePicker { image in
                handleCapturedImage(image)
            }
        }
        .sheet(isPresented: $showContactInfoSheet) {
            ContactInfoSheet(
                vm: vm,
                conversation: currentConversation,
                messages: vm.activeMessages,
                onMute: { vm.muteCurrentChat(true) },
                onUnmute: { vm.muteCurrentChat(false) },
                onToggleStatus: { vm.toggleConversationStatus() }
            )
        }
        .fileImporter(
            isPresented: $showImageImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result, kindLabel: "Image")
        }
        .fileImporter(
            isPresented: $showDocumentImporter,
            allowedContentTypes: [.pdf, .plainText, .data, .item],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result, kindLabel: "Document")
        }
        .onDisappear {
            audioRecorder?.stop()
            audioRecorder = nil
            isRecordingVoice = false
        }
        .sheet(isPresented: $showAssignAgentDialog) {
            NavigationStack {
                let q = agentSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let filteredAgents = q.isEmpty
                    ? vm.availableAgents
                    : vm.availableAgents.filter { $0.name.lowercased().contains(q) || "\($0.id)".contains(q) }
                Group {
                    if vm.availableAgents.isEmpty {
                        VStack(spacing: 10) {
                            Text(vm.locale == .ar ? "لا يوجد وكلاء متاحون" : "No agents available")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppPalette.textPrimary)
                            Text(vm.locale == .ar ? "قم بمزامنة بيانات الدعم ثم حاول مرة أخرى." : "Sync support data, then try again.")
                                .font(.system(size: 12))
                                .foregroundStyle(AppPalette.textMuted)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.horizontal, 20)
                    } else {
                        List {
                            ForEach(filteredAgents) { agent in
                                Button {
                                    vm.assignCurrentChat(agentId: agent.id)
                                    showAssignAgentDialog = false
                                    agentSearch = ""
                                } label: {
                                    HStack {
                                        Text(agent.name)
                                            .foregroundStyle(AppPalette.textPrimary)
                                        Spacer()
                                        Text("#\(agent.id)")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppPalette.textMuted)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .searchable(
                    text: $agentSearch,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: vm.locale == .ar ? "بحث الوكلاء" : "Search agents"
                )
                .navigationTitle(tr(vm.locale, .assignAgentTitle))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(tr(vm.locale, .close)) {
                            showAssignAgentDialog = false
                            agentSearch = ""
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTagDialog) {
            NavigationStack {
                let attachedTagIds = Set((currentConversation?.tags ?? []).map(\.id))
                let q = tagSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let filteredTags = q.isEmpty
                    ? vm.availableTags
                    : vm.availableTags.filter { $0.name.lowercased().contains(q) || "\($0.id)".contains(q) }
                VStack(spacing: 0) {
                    if let convo = currentConversation, !convo.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(vm.locale == .ar ? "الوسوم الحالية:" : "Attached tags:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppPalette.textSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(convo.tags, id: \.id) { tag in
                                        Button {
                                            vm.detachTagFromCurrentChat(tagId: tag.id)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(tagAccentColor(hex: tag.colorHex))
                                                    .frame(width: 8, height: 8)
                                                Text(tag.name)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(AppPalette.textPrimary)
                                                Text("×")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(.red)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(AppPalette.card)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }

                    List {
                        ForEach(filteredTags) { tag in
                            let isAttached = attachedTagIds.contains(tag.id)
                            Button {
                                if isAttached {
                                    vm.detachTagFromCurrentChat(tagId: tag.id)
                                } else {
                                    vm.attachTagToCurrentChat(tagId: tag.id)
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(tagAccentColor(hex: tag.colorHex))
                                        .frame(width: 10, height: 10)
                                    Text(tag.name)
                                        .foregroundStyle(AppPalette.textPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(isAttached ? (vm.locale == .ar ? "مرفق" : "Attached") : "#\(tag.id)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(isAttached ? AppPalette.primary : AppPalette.textMuted)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
                .searchable(
                    text: $tagSearch,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: vm.locale == .ar ? "بحث الوسوم" : "Search tags"
                )
                .navigationTitle(tr(vm.locale, .attachDetachTagTitle))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(tr(vm.locale, .close)) {
                            showTagDialog = false
                            tagSearch = ""
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTemplateDialog) {
            NavigationStack {
                let q = templateSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let filteredTemplates = q.isEmpty
                    ? vm.availableTemplates
                    : vm.availableTemplates.filter {
                        $0.name.lowercased().contains(q) || String($0.id).contains(q)
                    }
                VStack(spacing: 10) {
                    TextField(tr(vm.locale, .templateId), text: $templateInput)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(AppPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.horizontal, 12)

                    if !templateInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            if let value = Int(templateInput) { vm.sendTemplateToCurrentChat(templateId: value) }
                            showTemplateDialog = false
                            templateInput = ""
                            templateSearch = ""
                        } label: {
                            Text(tr(vm.locale, .send))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(AppPalette.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                    }

                    List {
                        if filteredTemplates.isEmpty {
                            Text(vm.locale == .ar ? "لا توجد قوالب مطابقة" : "No matching templates")
                                .foregroundStyle(AppPalette.textMuted)
                        } else {
                            ForEach(filteredTemplates) { template in
                                Button {
                                    vm.sendTemplateToCurrentChat(templateId: template.id)
                                    showTemplateDialog = false
                                    templateInput = ""
                                    templateSearch = ""
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(template.name)
                                            .foregroundStyle(AppPalette.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("#\(template.id)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(AppPalette.textMuted)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .searchable(
                    text: $templateSearch,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: vm.locale == .ar ? "بحث القوالب" : "Search templates"
                )
                .navigationTitle(tr(vm.locale, .sendTemplateTitle))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(tr(vm.locale, .close)) {
                            showTemplateDialog = false
                            templateInput = ""
                            templateSearch = ""
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showFlowDialog) {
            NavigationStack {
                let q = flowSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let filteredFlows = q.isEmpty
                    ? vm.availableFlows
                    : vm.availableFlows.filter {
                        $0.name.lowercased().contains(q) || String($0.id).contains(q)
                    }
                VStack(spacing: 10) {
                    TextField(tr(vm.locale, .flowId), text: $flowInput)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(AppPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.horizontal, 12)

                    if !flowInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            if let value = Int(flowInput) { vm.sendFlowToCurrentChat(flowId: value) }
                            showFlowDialog = false
                            flowInput = ""
                            flowSearch = ""
                        } label: {
                            Text(tr(vm.locale, .send))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(AppPalette.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                    }

                    List {
                        if filteredFlows.isEmpty {
                            Text(vm.locale == .ar ? "لا توجد تدفقات مطابقة" : "No matching flows")
                                .foregroundStyle(AppPalette.textMuted)
                        } else {
                            ForEach(filteredFlows) { flow in
                                Button {
                                    vm.sendFlowToCurrentChat(flowId: flow.id)
                                    showFlowDialog = false
                                    flowInput = ""
                                    flowSearch = ""
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(flow.name)
                                            .foregroundStyle(AppPalette.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("#\(flow.id)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(AppPalette.textMuted)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .searchable(
                    text: $flowSearch,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: vm.locale == .ar ? "بحث التدفقات" : "Search flows"
                )
                .navigationTitle(tr(vm.locale, .sendFlowTitle))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(tr(vm.locale, .close)) {
                            showFlowDialog = false
                            flowInput = ""
                            flowSearch = ""
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showReplyDialog) {
            NavigationStack {
                let q = replySearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let filteredReplies = q.isEmpty
                    ? vm.availableReplies
                    : vm.availableReplies.filter {
                        $0.name.lowercased().contains(q) ||
                        $0.text.lowercased().contains(q) ||
                        String($0.id).contains(q)
                    }
                VStack(spacing: 10) {
                    List {
                        if filteredReplies.isEmpty {
                            Text(vm.locale == .ar ? "لا توجد ردود مطابقة" : "No matching replies")
                                .foregroundStyle(AppPalette.textMuted)
                        } else {
                            ForEach(filteredReplies, id: \.id) { reply in
                                Button {
                                    vm.sendQuickReplyToCurrentChat(replyId: reply.id)
                                    showReplyDialog = false
                                    replySearch = ""
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(reply.name)
                                            .foregroundStyle(AppPalette.textPrimary)
                                            .lineLimit(1)
                                        Text(reply.text)
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppPalette.textMuted)
                                            .lineLimit(2)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .searchable(
                    text: $replySearch,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: vm.locale == .ar ? "بحث الردود" : "Search replies"
                )
                .navigationTitle(tr(vm.locale, .sendQuickReplyTitle))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(tr(vm.locale, .close)) {
                            showReplyDialog = false
                            replySearch = ""
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .alert(tr(vm.locale, .updateContact), isPresented: $showUpdateContactDialog) {
            TextField(tr(vm.locale, .nameLabel), text: $updateContactName)
            TextField(tr(vm.locale, .phoneLabel), text: $updateContactPhone)
            TextField(tr(vm.locale, .emailOptional), text: $updateContactEmail)
            Button(tr(vm.locale, .cancel), role: .cancel) {}
            Button(tr(vm.locale, .save)) {
                vm.updateCurrentContact(
                    name: updateContactName,
                    phone: updateContactPhone,
                    email: updateContactEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : updateContactEmail
                )
            }
        }
        .sheet(isPresented: $showCustomFieldDialog) {
            NavigationStack {
                let q = customFieldSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let filteredFields = q.isEmpty
                    ? vm.availableCustomFields
                    : vm.availableCustomFields.filter {
                        $0.label.lowercased().contains(q) || $0.id.lowercased().contains(q)
                    }
                VStack(spacing: 0) {
                    List {
                        ForEach(filteredFields) { field in
                            Button {
                                customFieldId = field.id
                                if customFieldValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    customFieldValue = field.value ?? ""
                                }
                            } label: {
                                HStack {
                                    Text(field.label)
                                        .foregroundStyle(AppPalette.textPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("#\(field.id)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(AppPalette.textMuted)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)

                    VStack(spacing: 10) {
                        TextField(tr(vm.locale, .fieldId), text: $customFieldId)
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(AppPalette.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        TextField(tr(vm.locale, .fieldValue), text: $customFieldValue)
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(AppPalette.card)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Button(tr(vm.locale, .sync)) {
                            vm.syncCurrentContactCustomField(fieldId: customFieldId, fieldValue: customFieldValue)
                            showCustomFieldDialog = false
                            customFieldId = ""
                            customFieldValue = ""
                            customFieldSearch = ""
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(customFieldId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppPalette.textMuted.opacity(0.3) : AppPalette.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .disabled(customFieldId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .searchable(
                    text: $customFieldSearch,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: vm.locale == .ar ? "بحث الحقول" : "Search fields"
                )
                .navigationTitle(tr(vm.locale, .syncCustomFieldTitle))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(tr(vm.locale, .close)) {
                            showCustomFieldDialog = false
                            customFieldSearch = ""
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>, kindLabel: String) {
        guard case let .success(urls) = result, let url = urls.first else { return }
        do {
            let access = url.startAccessingSecurityScopedResource()
            defer {
                if access { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent.isEmpty ? "\(kindLabel.lowercased())-\(Int(Date().timeIntervalSince1970)).bin" : url.lastPathComponent
            vm.sendAttachment(fileName: fileName, fileData: data, kindLabel: kindLabel)
            forceAutoScroll = true
        } catch {
            vm.actionStatus = "Failed: unable to read selected \(kindLabel.lowercased())"
        }
    }

    private func handleCapturedImage(_ image: UIImage?) {
        guard let image, let data = image.jpegData(compressionQuality: 0.9) else {
            vm.actionStatus = "Failed: unable to capture image"
            return
        }
        let fileName = "camera-\(Int(Date().timeIntervalSince1970)).jpg"
        vm.sendAttachment(fileName: fileName, fileData: data, kindLabel: "Image")
        forceAutoScroll = true
    }

    private func startVoiceRecording() {
        let session = AVAudioSession.sharedInstance()
        let requestPermission: (@escaping (Bool) -> Void) -> Void = { completion in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission(completionHandler: completion)
            } else {
                session.requestRecordPermission(completion)
            }
        }
        requestPermission { granted in
            guard granted else {
                DispatchQueue.main.async {
                    vm.actionStatus = "Failed: microphone permission denied"
                }
                return
            }
            DispatchQueue.main.async {
                do {
                    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    try session.setActive(true)
                    let fileURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("voice-\(Int(Date().timeIntervalSince1970)).m4a")
                    let settings: [String: Any] = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44_100,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
                    recorder.record()
                    audioRecorder = recorder
                    isRecordingVoice = true
                } catch {
                    vm.actionStatus = "Failed: unable to start voice recording"
                }
            }
        }
    }

    private func stopRecordingAndSend() {
        guard let recorder = audioRecorder else { return }
        recorder.stop()
        let fileURL = recorder.url
        audioRecorder = nil
        isRecordingVoice = false
        do {
            let data = try Data(contentsOf: fileURL)
            vm.sendVoiceMessage(fileName: fileURL.lastPathComponent, fileData: data)
            forceAutoScroll = true
            try? FileManager.default.removeItem(at: fileURL)
        } catch {
            vm.actionStatus = "Failed: unable to send voice message"
        }
    }

}

private struct ContactInfoSheet: View {
    @ObservedObject var vm: AppViewModel
    let conversation: Conversation?
    let messages: [ChatMessage]
    let onMute: () -> Void
    let onUnmute: () -> Void
    let onToggleStatus: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showMediaLinksDocsSheet = false

    private var mediaLinksDocsCount: Int {
        mediaLinksDocsItems.count
    }

    private var isConversationOpen: Bool {
        (conversation?.status ?? .open) == .open
    }

    private var mediaLinksDocsItems: [MediaLinksDocsItem] {
        messages.compactMap { message in
            let kind = (message.mediaKind ?? "").lowercased()
            if kind == "image", let url = sanitizeRemoteURL(message.mediaUrl) {
                return MediaLinksDocsItem(type: tr(vm.locale, .photo), url: url, category: .media, previewKind: "image")
            }
            if kind == "video", let url = sanitizeRemoteURL(message.mediaUrl) {
                return MediaLinksDocsItem(type: tr(vm.locale, .video), url: url, category: .media, previewKind: "video")
            }
            if kind == "audio", let url = sanitizeRemoteURL(message.mediaUrl) {
                return MediaLinksDocsItem(type: tr(vm.locale, .audio), url: url, category: .media, previewKind: "audio", isAvailable: true)
            }
            if kind == "audio" {
                return MediaLinksDocsItem(type: tr(vm.locale, .audio), url: "", category: .media, previewKind: "audio", isAvailable: false)
            }
            if kind == "document", let url = sanitizeRemoteURL(message.mediaUrl) {
                return MediaLinksDocsItem(type: tr(vm.locale, .document), url: url, category: .docs, previewKind: "document")
            }
            if let link = firstURL(in: message.content) {
                return MediaLinksDocsItem(type: tr(vm.locale, .link), url: link, category: .links, previewKind: "link")
            }
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(tr(vm.locale, .contactInfo))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                Button(tr(vm.locale, .cancel)) { dismiss() }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppPalette.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(AppPalette.primary.opacity(0.14))
                            .frame(width: 86, height: 86)
                            .overlay(
                                Text(String((conversation?.customerName.first ?? "C")).uppercased())
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(AppPalette.primary)
                            )

                        Text(conversation?.customerName ?? "Contact")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppPalette.textPrimary)

                        Text(((conversation?.customerPhone ?? "").isEmpty ? "-" : (conversation?.customerPhone ?? "-")))
                            .font(.system(size: 15))
                            .foregroundStyle(AppPalette.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)

                    VStack(spacing: 0) {
                        infoRow(
                            label: tr(vm.locale, .status),
                            value: isConversationOpen ? tr(vm.locale, .open) : tr(vm.locale, .closed)
                        )
                        Divider().overlay(AppPalette.border.opacity(0.45))
                        infoRow(
                            label: tr(vm.locale, .presence),
                            value: (conversation?.isOnline ?? false) ? tr(vm.locale, .online) : tr(vm.locale, .lastSeen)
                        )
                        Divider().overlay(AppPalette.border.opacity(0.45))
                        Button {
                            showMediaLinksDocsSheet = true
                        } label: {
                            infoRow(label: tr(vm.locale, .mediaLinksDocs), value: "\(mediaLinksDocsCount)")
                        }
                        .buttonStyle(.plain)
                    }
                    .background(AppPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    HStack(spacing: 10) {
                        actionButton(tr(vm.locale, .mute), tint: AppPalette.primary, fill: false) {
                            onMute()
                        }
                        actionButton(tr(vm.locale, .unmute), tint: AppPalette.primary, fill: false) {
                            onUnmute()
                        }
                    }

                    HStack(spacing: 10) {
                        actionButton(
                            isConversationOpen ? tr(vm.locale, .closeConversation) : tr(vm.locale, .reopenConversation),
                            tint: AppPalette.primary,
                            fill: true
                        ) {
                            onToggleStatus()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .background(AppPalette.background.ignoresSafeArea())
        .sheet(isPresented: $showMediaLinksDocsSheet) {
            MediaLinksDocsSheet(items: mediaLinksDocsItems, locale: vm.locale)
        }
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppPalette.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppPalette.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func actionButton(_ title: String, tint: Color, fill: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(fill ? Color.white : tint)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(fill ? tint : tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct MediaLinksDocsItem: Identifiable {
    let id = UUID()
    let type: String
    let url: String
    let category: MediaLinksDocsCategory
    let previewKind: String
    let isAvailable: Bool

    init(type: String, url: String, category: MediaLinksDocsCategory, previewKind: String, isAvailable: Bool = true) {
        self.type = type
        self.url = url
        self.category = category
        self.previewKind = previewKind
        self.isAvailable = isAvailable
    }
}

private enum MediaLinksDocsCategory: String {
    case media = "Media"
    case docs = "Docs"
    case links = "Links"
}

private struct MediaLinksDocsSheet: View {
    let items: [MediaLinksDocsItem]
    let locale: AppLocale
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: MediaLinksDocsCategory = .media
    @State private var previewImageURL: URL?
    @State private var previewVideoURL: URL?
    @State private var previewDocumentURL: URL?
    @State private var previewAudioURL: URL?
    @State private var showImagePreview = false
    @State private var showVideoPreview = false
    @State private var showDocumentPreview = false
    @State private var showAudioPreview = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    private var mediaCount: Int { items.filter { $0.category == .media }.count }
    private var docsCount: Int { items.filter { $0.category == .docs }.count }
    private var linksCount: Int { items.filter { $0.category == .links }.count }
    private var filteredItems: [MediaLinksDocsItem] { items.filter { $0.category == selectedTab } }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(tr(locale, .mediaLinksDocsTitle))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                Button(tr(locale, .close)) { dismiss() }
                    .foregroundStyle(AppPalette.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            HStack(spacing: 8) {
                tabChip(label: "\(tr(locale, .mediaTab)) (\(mediaCount))", tab: .media)
                tabChip(label: "\(tr(locale, .docsTab)) (\(docsCount))", tab: .docs)
                tabChip(label: "\(tr(locale, .linksTab)) (\(linksCount))", tab: .links)
                Spacer()
            }
            .padding(.horizontal, 16)

            if filteredItems.isEmpty {
                Spacer()
                Text(tr(locale, .noItemsInTab))
                    .font(.system(size: 14))
                    .foregroundStyle(AppPalette.textMuted)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredItems) { item in
                            HStack {
                                Button {
                                    handleItemTap(item)
                                } label: {
                                    HStack {
                                        mediaThumb(item)
                                        Spacer().frame(width: 10)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.type)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(AppPalette.primary)
                                            Text(item.url.isEmpty ? tr(locale, .noUrlFromBackend) : item.url)
                                                .font(.system(size: 12))
                                                .foregroundStyle(AppPalette.textMuted)
                                                .lineLimit(1)
                                            if !item.isAvailable {
                                                Text(tr(locale, .unavailable))
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundStyle(AppPalette.textMuted)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(!item.isAvailable)
                                Button {
                                    shareItems = [item.url]
                                    showShareSheet = true
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(AppPalette.textSecondary)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                                .disabled(!item.isAvailable)
                                Button {
                                    Task { await downloadAndShare(item) }
                                } label: {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(AppPalette.textSecondary)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                                .disabled(!item.isAvailable)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            Divider().overlay(AppPalette.border.opacity(0.5))
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .background(AppPalette.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $showImagePreview) {
            if let url = previewImageURL {
                ZoomableImageViewer(imageURL: url)
            }
        }
        .sheet(isPresented: $showVideoPreview) {
            if let url = previewVideoURL {
                VideoPlayerSheet(videoURL: url)
            }
        }
        .sheet(isPresented: $showDocumentPreview) {
            if let url = previewDocumentURL {
                DocumentPreviewSheet(documentURL: url)
            }
        }
        .sheet(isPresented: $showAudioPreview) {
            VStack(spacing: 10) {
                HStack {
                    Text(tr(locale, .audio))
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Button(tr(locale, .close)) { showAudioPreview = false }
                        .foregroundStyle(AppPalette.primary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if let url = previewAudioURL {
                    InlineAudioMessageView(audioURL: url, darkMode: colorScheme == .dark)
                        .padding(.horizontal, 16)
                } else {
                    Text(tr(locale, .unableToLoadAudio))
                        .foregroundStyle(AppPalette.textMuted)
                        .padding()
                }
                Spacer()
            }
            .presentationDetents([.medium])
            .background(AppPalette.background.ignoresSafeArea())
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(activityItems: shareItems)
        }
    }

    @ViewBuilder
    private func tabChip(label: String, tab: MediaLinksDocsCategory) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selectedTab == tab ? Color.white : AppPalette.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(selectedTab == tab ? AppPalette.primary : AppPalette.card)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func mediaThumb(_ item: MediaLinksDocsItem) -> some View {
        if item.previewKind == "image", let url = URL(string: item.url) {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "photo")
                        .foregroundStyle(AppPalette.primary)
                }
            }
            .frame(width: 44, height: 44)
            .background(AppPalette.card)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if item.previewKind == "video", let url = URL(string: item.url) {
            VideoListThumbnail(url: url)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if item.previewKind == "audio" {
            Image(systemName: "waveform")
                .foregroundStyle(AppPalette.primary)
                .frame(width: 44, height: 44)
                .background(AppPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if item.previewKind == "document" {
            Image(systemName: "doc.fill")
                .foregroundStyle(AppPalette.primary)
                .frame(width: 44, height: 44)
                .background(AppPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Image(systemName: "link")
                .foregroundStyle(AppPalette.primary)
                .frame(width: 44, height: 44)
                .background(AppPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func handleItemTap(_ item: MediaLinksDocsItem) {
        guard item.isAvailable else { return }
        guard let url = URL(string: item.url) else { return }
        switch item.previewKind {
        case "image":
            previewImageURL = url
            showImagePreview = true
        case "video":
            previewVideoURL = url
            showVideoPreview = true
        case "document":
            previewDocumentURL = url
            showDocumentPreview = true
        case "audio":
            previewAudioURL = url
            showAudioPreview = true
        default:
            openURL(url)
        }
    }

    private func downloadAndShare(_ item: MediaLinksDocsItem) async {
        guard item.isAvailable else { return }
        guard let remoteURL = URL(string: item.url) else { return }
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
            let extensionPart = remoteURL.pathExtension.isEmpty ? "bin" : remoteURL.pathExtension
            let localName = "\(item.type.lowercased())-\(UUID().uuidString).\(extensionPart)"
            let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(localName)
            try? FileManager.default.removeItem(at: localURL)
            try FileManager.default.moveItem(at: tempURL, to: localURL)
            await MainActor.run {
                shareItems = [localURL]
                showShareSheet = true
            }
        } catch {
            await MainActor.run {
                if let url = URL(string: item.url) {
                    openURL(url)
                }
            }
        }
    }

}

private func tagAccentColor(hex: String?) -> Color {
    guard var hex else { return Color(red: 0.39, green: 0.45, blue: 0.55) }
    hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if hex.hasPrefix("#") { hex.removeFirst() }
    guard let value = UInt64(hex, radix: 16) else { return Color(red: 0.39, green: 0.45, blue: 0.55) }
    switch hex.count {
    case 6:
        return Color(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    case 8:
        return Color(
            red: Double((value >> 24) & 0xFF) / 255.0,
            green: Double((value >> 16) & 0xFF) / 255.0,
            blue: Double((value >> 8) & 0xFF) / 255.0,
            opacity: Double(value & 0xFF) / 255.0
        )
    default:
        return Color(red: 0.39, green: 0.45, blue: 0.55)
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct VideoListThumbnail: View {
    let url: URL
    @State private var thumb: UIImage?

    var body: some View {
        ZStack {
            if let thumb {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(UIColor.systemGray5)
                Image(systemName: "play.fill")
                    .foregroundStyle(AppPalette.primary)
            }
        }
        .task(id: url) {
            thumb = await makeThumb(url: url)
        }
    }

    private func makeThumb(url: URL) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = AVURLAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                let time = CMTime(seconds: 0.2, preferredTimescale: 600)
                generator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
                    if let cgImage, error == nil {
                        continuation.resume(returning: UIImage(cgImage: cgImage))
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
}

private func firstURL(in text: String) -> String? {
    let pattern = "https?://[^\\s]+"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(location: 0, length: text.utf16.count)
    guard let match = regex.firstMatch(in: text, range: range),
          let swiftRange = Range(match.range, in: text)
    else { return nil }
    return String(text[swiftRange])
}

private func sanitizeRemoteURL(_ value: String?) -> String? {
    let normalized = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalized.isEmpty else { return nil }
    guard normalized.lowercased() != "null" else { return nil }
    return normalized
}

struct CameraImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage?) -> Void
        let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage?) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImagePicked(nil)
            dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            onImagePicked(image)
            dismiss()
        }
    }
}

private struct ChatBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
