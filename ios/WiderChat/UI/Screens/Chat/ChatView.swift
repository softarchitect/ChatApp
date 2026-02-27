import SwiftUI

import AVFoundation
import UniformTypeIdentifiers
import UIKit

typealias ChatScreenView = ChatView

struct ChatView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.openURL) private var openURL
    @State private var messageInput = ""
    @State private var showingInternalNoteComposer = false
    @State private var noteInput = ""
    @State private var showAssignAgentDialog = false
    @State private var showTagDialog = false
    @State private var showTemplateDialog = false
    @State private var showFlowDialog = false
    @State private var showCustomFieldDialog = false
    @State private var showDeleteConfirm = false
    @State private var agentInput = ""
    @State private var tagInput = ""
    @State private var templateInput = ""
    @State private var flowInput = ""
    @State private var customFieldId = ""
    @State private var customFieldValue = ""
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
    @State private var showCallUnavailableAlert = false
    @State private var showEmojiPicker = false
    @State private var selectedEmojiCategory = "recent"
    @State private var emojiSearchQuery = ""
    @State private var recentEmojis = ["😀", "❤️", "👍"]
    @State private var skeletonOpacity = 0.55
    @State private var skeletonShimmerOffset: CGFloat = -240
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
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Button {
                    startCallToCurrentContact()
                } label: {
                    Image(systemName: "phone")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                }
                .buttonStyle(.plain)
                Menu {
                    Button(tr(vm.locale, .internalNote)) { showingInternalNoteComposer.toggle() }
                    Button((currentConversation?.status ?? .open) == .open ? tr(vm.locale, .closeConversation) : tr(vm.locale, .reopenConversation)) {
                        vm.toggleConversationStatus()
                    }
                    Button("Assign agent") { showAssignAgentDialog = true }
                    Button("Unassign agent") { vm.unassignCurrentChat() }
                    Button("Mute conversation") { vm.muteCurrentChat(true) }
                    Button("Unmute conversation") { vm.muteCurrentChat(false) }
                    Button("Mark as read") { vm.markCurrentChatRead(true) }
                    Button("Mark as unread") { vm.markCurrentChatRead(false) }
                    Button("Attach / detach tag") { showTagDialog = true }
                    Button("Send template") { showTemplateDialog = true }
                    Button("Send flow") { showFlowDialog = true }
                    Button("Sync custom field") { showCustomFieldDialog = true }
                    Button("Delete chat", role: .destructive) { showDeleteConfirm = true }
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
                Text(status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppPalette.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(AppPalette.secondarySoft)
            }

            ZStack {
                ScrollViewReader { proxy in
                    GeometryReader { scrollGeo in
                        ZStack(alignment: .bottomTrailing) {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(vm.activeMessages) { msg in
                                    MessageBubble(message: msg, darkMode: vm.darkMode)
                                        .frame(maxWidth: .infinity, alignment: msg.sender == .agent ? .trailing : .leading)
                                        .id(msg.id)
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

            if showEmojiPicker {
                VStack(spacing: 6) {
                    TextField(vm.locale == .ar ? "ابحث عن ايموجي" : "Search emoji", text: $emojiSearchQuery)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 12)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(["recent", "smileys", "gestures", "hearts", "celebration"], id: \.self) { category in
                                Button {
                                    selectedEmojiCategory = category
                                } label: {
                                    Text(localizedEmojiCategoryLabel(category))
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 10)
                                        .frame(height: 34)
                                        .background(category == selectedEmojiCategory ? AppPalette.primary.opacity(0.16) : .clear)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(filteredEmojisForSelectedCategory, id: \.self) { emoji in
                                Button {
                                    addEmojiToInput(emoji)
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 24))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 6)
                .background(AppPalette.surface)
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
                    Button(isRecordingVoice ? tr(vm.locale, .stopSendVoice) : tr(vm.locale, .audio)) {
                        if isRecordingVoice {
                            stopRecordingAndSend()
                        } else {
                            startVoiceRecording()
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppPalette.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(AppPalette.card)
                        .clipShape(Circle())
                }
                Button {
                    showEmojiPicker.toggle()
                } label: {
                    Text("😀")
                        .font(.system(size: 18))
                        .frame(width: 36, height: 36)
                        .background(AppPalette.card)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

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
                    showEmojiPicker = false
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
                onToggleStatus: { vm.toggleConversationStatus() },
                onDeleteChat: { vm.deleteCurrentChat() }
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
        .alert("Assign agent", isPresented: $showAssignAgentDialog) {
            TextField("Agent ID", text: $agentInput)
            Button("Cancel", role: .cancel) {}
            Button("Assign") {
                if let value = Int(agentInput) { vm.assignCurrentChat(agentId: value) }
                agentInput = ""
            }
        }
        .alert("Attach / detach tag", isPresented: $showTagDialog) {
            TextField("Tag ID", text: $tagInput)
            Button("Cancel", role: .cancel) {}
            Button("Attach") {
                if let value = Int(tagInput) { vm.attachTagToCurrentChat(tagId: value) }
                tagInput = ""
            }
            Button("Detach") {
                if let value = Int(tagInput) { vm.detachTagFromCurrentChat(tagId: value) }
                tagInput = ""
            }
        }
        .alert("Send template", isPresented: $showTemplateDialog) {
            TextField("Template ID", text: $templateInput)
            Button("Cancel", role: .cancel) {}
            Button("Send") {
                if let value = Int(templateInput) { vm.sendTemplateToCurrentChat(templateId: value) }
                templateInput = ""
            }
        }
        .alert("Send flow", isPresented: $showFlowDialog) {
            TextField("Flow ID", text: $flowInput)
            Button("Cancel", role: .cancel) {}
            Button("Send") {
                if let value = Int(flowInput) { vm.sendFlowToCurrentChat(flowId: value) }
                flowInput = ""
            }
        }
        .alert("Sync custom field", isPresented: $showCustomFieldDialog) {
            TextField("Field ID", text: $customFieldId)
            TextField("Field Value", text: $customFieldValue)
            Button("Cancel", role: .cancel) {}
            Button("Sync") {
                vm.syncCurrentContactCustomField(fieldId: customFieldId, fieldValue: customFieldValue)
                customFieldId = ""
                customFieldValue = ""
            }
        }
        .alert("Delete chat?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                vm.deleteCurrentChat()
            }
        } message: {
            Text("This calls delete chat endpoint for this contact.")
        }
        .alert("Call unavailable", isPresented: $showCallUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Phone number is unavailable for this contact.")
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

    private func startCallToCurrentContact() {
        let raw = currentConversation?.customerPhone ?? ""
        let phone = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        guard !phone.isEmpty else {
            showCallUnavailableAlert = true
            return
        }
        guard let url = URL(string: "tel://\(phone)") else {
            showCallUnavailableAlert = true
            return
        }
        openURL(url) { accepted in
            if !accepted {
                showCallUnavailableAlert = true
            }
        }
    }

    private var emojisForSelectedCategory: [String] {
        if selectedEmojiCategory == "recent" {
            return recentEmojis
        }
        return emojiCategories[selectedEmojiCategory] ?? []
    }

    private var filteredEmojisForSelectedCategory: [String] {
        let query = emojiSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return emojisForSelectedCategory }
        let combined = recentEmojis + emojiCategories.values.flatMap { $0 }
        var seen = Set<String>()
        let all = combined.filter { seen.insert($0).inserted }
        return all.filter { emojiMatchesSearch($0, query: query) || $0.contains(query) }
    }

    private func localizedEmojiCategoryLabel(_ key: String) -> String {
        let ar = vm.locale == .ar
        switch key {
        case "recent": return ar ? "الأخيرة" : "Recent"
        case "smileys": return ar ? "وجوه" : "Smileys"
        case "gestures": return ar ? "إشارات" : "Gestures"
        case "hearts": return ar ? "قلوب" : "Hearts"
        case "celebration": return ar ? "احتفال" : "Celebration"
        default: return key
        }
    }

    private func emojiMatchesSearch(_ emoji: String, query: String) -> Bool {
        let category: String
        switch emoji {
        case "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "🙂", "😉", "😍", "🥰", "😘", "😎", "🤔", "😭":
            category = "smileys"
        case "👍", "👎", "👏", "🙌", "🙏", "🤝", "💪", "👌", "✌️", "🤞", "👋", "🤲", "🫶", "💯", "✅", "❌":
            category = "gestures"
        case "❤️", "🩷", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💖", "💗", "🔥":
            category = "hearts"
        case "🎉", "🎊", "✨", "⭐", "🌟", "⚡", "☀️", "🌈", "🍀", "🎁", "🏆", "🎵", "🎶", "📌", "📣", "📷":
            category = "celebration"
        default:
            category = "recent"
        }

        let enKeywords: [String]
        let arKeywords: [String]
        switch category {
        case "smileys":
            enKeywords = ["smile", "face", "happy", "sad", "cry", "laugh"]
            arKeywords = ["وجه", "ابتسامة", "ضحك", "بكاء", "حزين", "سعيد"]
        case "gestures":
            enKeywords = ["hand", "ok", "thumb", "clap", "pray", "check"]
            arKeywords = ["يد", "اشارة", "تصفيق", "دعاء", "موافق"]
        case "hearts":
            enKeywords = ["heart", "love", "fire", "broken"]
            arKeywords = ["قلب", "حب", "نار", "مكسور"]
        case "celebration":
            enKeywords = ["party", "star", "music", "gift", "celebrate"]
            arKeywords = ["حفلة", "احتفال", "نجمة", "موسيقى", "هدية"]
        default:
            enKeywords = ["recent"]
            arKeywords = ["اخير", "الأخيرة"]
        }
        let keywords = vm.locale == .ar ? (arKeywords + enKeywords) : (enKeywords + arKeywords)
        return keywords.contains { $0.contains(query) || query.contains($0) }
    }

    private func addEmojiToInput(_ emoji: String) {
        messageInput += emoji
        recentEmojis.removeAll { $0 == emoji }
        recentEmojis.insert(emoji, at: 0)
        if recentEmojis.count > 24 {
            recentEmojis = Array(recentEmojis.prefix(24))
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
    let onDeleteChat: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showMediaLinksDocsSheet = false

    private var mediaLinksDocsCount: Int {
        mediaLinksDocsItems.count
    }

    private var mediaLinksDocsItems: [MediaLinksDocsItem] {
        messages.compactMap { message in
            let kind = (message.mediaKind ?? "").lowercased()
            if kind == "image", let url = sanitizeRemoteURL(message.mediaUrl) {
                return MediaLinksDocsItem(type: "Photo", url: url, category: .media, previewKind: "image")
            }
            if kind == "video", let url = sanitizeRemoteURL(message.mediaUrl) {
                return MediaLinksDocsItem(type: "Video", url: url, category: .media, previewKind: "video")
            }
            if kind == "audio", let url = sanitizeRemoteURL(message.mediaUrl) {
                return MediaLinksDocsItem(type: "Audio", url: url, category: .media, previewKind: "audio", isAvailable: true)
            }
            if kind == "audio" {
                return MediaLinksDocsItem(type: "Audio", url: "", category: .media, previewKind: "audio", isAvailable: false)
            }
            if kind == "document", let url = sanitizeRemoteURL(message.mediaUrl) {
                return MediaLinksDocsItem(type: "Document", url: url, category: .docs, previewKind: "document")
            }
            if let link = firstURL(in: message.content) {
                return MediaLinksDocsItem(type: "Link", url: link, category: .links, previewKind: "link")
            }
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Contact info")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                Button(tr(vm.locale, .cancel)) { dismiss() }
                    .foregroundStyle(AppPalette.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Circle()
                .fill(AppPalette.primary.opacity(0.14))
                .frame(width: 82, height: 82)
                .overlay(
                    Text(String((conversation?.customerName.first ?? "C")).uppercased())
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppPalette.primary)
                )

            Text(conversation?.customerName ?? "Contact")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppPalette.textPrimary)

            Text(((conversation?.customerPhone ?? "").isEmpty ? "-" : (conversation?.customerPhone ?? "-")))
                .font(.system(size: 15))
                .foregroundStyle(AppPalette.textMuted)

            VStack(spacing: 8) {
                infoRow(
                    label: "Status",
                    value: (conversation?.status ?? .open) == .open ? tr(vm.locale, .open) : tr(vm.locale, .closed)
                )
                infoRow(
                    label: "Presence",
                    value: (conversation?.isOnline ?? false) ? tr(vm.locale, .online) : tr(vm.locale, .lastSeen)
                )
                Button {
                    showMediaLinksDocsSheet = true
                } label: {
                    infoRow(label: "Media, links and docs", value: "\(mediaLinksDocsCount)")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            HStack(spacing: 10) {
                Button("Mute") {
                    onMute()
                }
                .buttonStyle(.bordered)
                .tint(AppPalette.primary)

                Button("Unmute") {
                    onUnmute()
                }
                .buttonStyle(.bordered)
                .tint(AppPalette.primary)
            }

            HStack(spacing: 10) {
                Button((conversation?.status ?? .open) == .open ? "Close chat" : "Reopen chat") {
                    onToggleStatus()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppPalette.primary)

                Button("Delete", role: .destructive) {
                    onDeleteChat()
                    dismiss()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .presentationDetents([.medium])
        .background(AppPalette.background.ignoresSafeArea())
        .sheet(isPresented: $showMediaLinksDocsSheet) {
            MediaLinksDocsSheet(items: mediaLinksDocsItems)
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
        .background(AppPalette.surface)
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
                Text("Media, links and docs")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                Button("Close") { dismiss() }
                    .foregroundStyle(AppPalette.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            HStack(spacing: 8) {
                tabChip(label: "Media (\(mediaCount))", tab: .media)
                tabChip(label: "Docs (\(docsCount))", tab: .docs)
                tabChip(label: "Links (\(linksCount))", tab: .links)
                Spacer()
            }
            .padding(.horizontal, 16)

            if filteredItems.isEmpty {
                Spacer()
                Text("No items in this tab.")
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
                                            Text(item.url.isEmpty ? "No URL from backend" : item.url)
                                                .font(.system(size: 12))
                                                .foregroundStyle(AppPalette.textMuted)
                                                .lineLimit(1)
                                            if !item.isAvailable {
                                                Text("Unavailable")
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
                    Text("Audio")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Button("Close") { showAudioPreview = false }
                        .foregroundStyle(AppPalette.primary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if let url = previewAudioURL {
                    InlineAudioMessageView(audioURL: url, darkMode: colorScheme == .dark)
                        .padding(.horizontal, 16)
                } else {
                    Text("Unable to load audio.")
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
                do {
                    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } catch {
                    continuation.resume(returning: nil)
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
