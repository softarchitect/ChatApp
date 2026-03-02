import SwiftUI

struct ConversationsView: View {
    private enum ReadFilter: String {
        case all, read, unread
    }

    private enum AssignmentFilter: String {
        case all, my, unassigned
    }

    private enum SatisfactionFilter: String {
        case all, satisfied, neutral, unsatisfied, noRating
    }

    private enum SortFilter: String {
        case latest, createdNewest, createdOldest, updatedNewest, updatedOldest
    }

    private struct TagManageContext: Identifiable {
        let conversationId: String
        let tag: ConversationTag
        var id: String { "\(conversationId)-\(tag.id)" }
    }

    @ObservedObject var vm: AppViewModel
    @AppStorage("conv.filters.search") private var storedSearch = ""
    @AppStorage("conv.filters.tab") private var storedTab = 0
    @AppStorage("conv.filters.read") private var storedReadFilter = ReadFilter.all.rawValue
    @AppStorage("conv.filters.assignment") private var storedAssignmentFilter = AssignmentFilter.all.rawValue
    @AppStorage("conv.filters.satisfaction") private var storedSatisfactionFilter = SatisfactionFilter.all.rawValue
    @AppStorage("conv.filters.sort") private var storedSortFilter = SortFilter.latest.rawValue
    @AppStorage("conv.filters.tagId") private var storedTagId = 0
    @State private var search = ""
    @State private var selectedTab = 0
    @State private var selectedConversationIds: Set<String> = []
    @State private var showNewConversationDialog = false
    @State private var newConversationName = ""
    @State private var newConversationPhone = ""
    @State private var contactSearch = ""
    @State private var quickActionsConversation: Conversation?
    @State private var tagPickerConversationId: String?
    @State private var tagPickerSearch = ""
    @State private var tagPickerSearchDebounced = ""
    @State private var tagPickerDebounceTask: Task<Void, Never>?
    @State private var tagManageContext: TagManageContext?
    @State private var tagManageSelectedTagId: Int?
    @State private var readFilter: ReadFilter = .all
    @State private var assignmentFilter: AssignmentFilter = .all
    @State private var satisfactionFilter: SatisfactionFilter = .all
    @State private var sortFilter: SortFilter = .latest
    @State private var selectedTagId: Int?
    @State private var showReadFilterDialog = false
    @State private var showAssignmentFilterDialog = false
    @State private var showSatisfactionFilterDialog = false
    @State private var showSortFilterDialog = false
    @State private var showTagFilterDialog = false
    @State private var visibleConversationCount = 30
    @State private var visibleContactCount = 25

    var filtered: [Conversation] {
        let base = vm.conversations.filter { conversation in
            let tabMatches: Bool = {
                if selectedTab == 1 { return conversation.status == .open }
                if selectedTab == 2 { return conversation.status == .closed }
                return true
            }()
            let readMatches: Bool = {
                switch readFilter {
                case .all: return true
                case .read: return conversation.unreadCount == 0
                case .unread: return conversation.unreadCount > 0
                }
            }()
            let assignmentMatches: Bool = {
                switch assignmentFilter {
                case .all: return true
                case .my:
                    return conversation.assignedAgentName?.trimmingCharacters(in: .whitespacesAndNewlines)
                        .caseInsensitiveCompare(vm.profileName.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
                case .unassigned:
                    return (conversation.assignedAgentName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                }
            }()
            let satisfactionMatches: Bool = {
                switch satisfactionFilter {
                case .all: return true
                case .satisfied: return conversation.satisfaction == .satisfied
                case .neutral: return conversation.satisfaction == .neutral
                case .unsatisfied: return conversation.satisfaction == .unsatisfied
                case .noRating: return conversation.satisfaction == .noRating
                }
            }()
            let tagMatches = selectedTagId == nil || conversation.tags.contains(where: { $0.id == selectedTagId })
            if search.trimmingCharacters(in: .whitespaces).isEmpty {
                return tabMatches && readMatches && assignmentMatches && satisfactionMatches && tagMatches
            }
            let q = search.lowercased()
            return tabMatches
                && readMatches
                && assignmentMatches
                && satisfactionMatches
                && tagMatches
                && (conversation.customerName.lowercased().contains(q) || conversation.lastMessage.lowercased().contains(q))
        }
        switch sortFilter {
        case .latest, .createdNewest, .updatedNewest:
            return base.sorted { $0.lastMessageEpochMs > $1.lastMessageEpochMs }
        case .createdOldest, .updatedOldest:
            return base.sorted { $0.lastMessageEpochMs < $1.lastMessageEpochMs }
        }
    }

    var filteredContacts: [NewConversationContact] {
        let q = contactSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return vm.newConversationContacts }
        return vm.newConversationContacts.filter { item in
            item.name.lowercased().contains(q) || item.phone.lowercased().contains(q)
        }
    }

    var filteredTagPickerTags: [AvailableTag] {
        let q = tagPickerSearchDebounced.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return vm.availableTags }
        return vm.availableTags.filter {
            $0.name.lowercased().contains(q) || "\($0.id)".contains(q)
        }
    }

    var selectionMode: Bool { !selectedConversationIds.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if selectionMode {
                    Text(vm.locale == .ar ? "\(selectedConversationIds.count) محدد" : "\(selectedConversationIds.count) selected")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppPalette.textPrimary)
                    Spacer()
                    Button(filtered.count == selectedConversationIds.count && !filtered.isEmpty ? (vm.locale == .ar ? "إلغاء الكل" : "Clear all") : (vm.locale == .ar ? "تحديد الكل" : "Select all")) {
                        if filtered.count == selectedConversationIds.count && !filtered.isEmpty {
                            selectedConversationIds = []
                        } else {
                            selectedConversationIds = Set(filtered.map(\.id))
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(AppPalette.primary)
                    Button(vm.locale == .ar ? "إلغاء" : "Cancel") {
                        selectedConversationIds = []
                    }
                    .font(.system(size: 13, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(AppPalette.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr(vm.locale, .conversationsTitle))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppPalette.textPrimary)
                        if vm.unreadCount > 0 {
                            Text("\(vm.unreadCount) \(tr(vm.locale, .unread))")
                                .font(.system(size: 13))
                                .foregroundStyle(AppPalette.textMuted)
                        }
                    }
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
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider().overlay(AppPalette.border)

            if !selectionMode {
                TextField(tr(vm.locale, .searchPlaceholder), text: $search)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(AppPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TabChip(
                            title: vm.locale == .ar
                                ? (readFilter == .all ? "القراءة: الكل" : (readFilter == .read ? "القراءة: مقروء" : "القراءة: غير مقروء"))
                                : (readFilter == .all ? "Read: All" : (readFilter == .read ? "Read: Read" : "Read: Unread")),
                            selected: readFilter != .all
                        ) { showReadFilterDialog = true }
                        TabChip(
                            title: vm.locale == .ar
                                ? (assignmentFilter == .all ? "التعيين: الكل" : (assignmentFilter == .my ? "التعيين: محادثاتي" : "التعيين: غير معين"))
                                : (assignmentFilter == .all ? "Assignment: All" : (assignmentFilter == .my ? "Assignment: My conversations" : "Assignment: Unassigned")),
                            selected: assignmentFilter != .all
                        ) { showAssignmentFilterDialog = true }
                        TabChip(
                            title: vm.locale == .ar
                                ? {
                                    switch satisfactionFilter {
                                    case .all: return "الرضا: الكل"
                                    case .satisfied: return "الرضا: راضٍ"
                                    case .neutral: return "الرضا: محايد"
                                    case .unsatisfied: return "الرضا: غير راضٍ"
                                    case .noRating: return "الرضا: بدون تقييم"
                                    }
                                }()
                                : {
                                    switch satisfactionFilter {
                                    case .all: return "Satisfaction: All"
                                    case .satisfied: return "Satisfaction: Satisfied"
                                    case .neutral: return "Satisfaction: Neutral"
                                    case .unsatisfied: return "Satisfaction: Unsatisfied"
                                    case .noRating: return "Satisfaction: No rating"
                                    }
                                }(),
                            selected: satisfactionFilter != .all
                        ) { showSatisfactionFilterDialog = true }
                        TabChip(
                            title: vm.locale == .ar
                                ? {
                                    switch sortFilter {
                                    case .latest: return "الترتيب: الأحدث"
                                    case .createdNewest: return "الترتيب: إنشاء (الأحدث)"
                                    case .createdOldest: return "الترتيب: إنشاء (الأقدم)"
                                    case .updatedNewest: return "الترتيب: تحديث (الأحدث)"
                                    case .updatedOldest: return "الترتيب: تحديث (الأقدم)"
                                    }
                                }()
                                : {
                                    switch sortFilter {
                                    case .latest: return "Sort: Latest"
                                    case .createdNewest: return "Sort: Created (Newest)"
                                    case .createdOldest: return "Sort: Created (Oldest)"
                                    case .updatedNewest: return "Sort: Updated (Newest)"
                                    case .updatedOldest: return "Sort: Updated (Oldest)"
                                    }
                                }(),
                            selected: sortFilter != .latest
                        ) { showSortFilterDialog = true }
                        TabChip(
                            title: vm.locale == .ar
                                ? "الوسم: \(selectedTagId.map { "\($0)" } ?? "الكل")"
                                : "Tag: \(selectedTagId.map { "\($0)" } ?? "All")",
                            selected: selectedTagId != nil
                        ) { showTagFilterDialog = true }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
                Text(vm.locale == .ar ? "عدد النتائج: \(filtered.count)" : "Result count: \(filtered.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppPalette.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
            } else {
                if let status = vm.actionStatus, !status.isEmpty {
                    Text(status)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppPalette.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }

            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Text(tr(vm.locale, .noConversations)).font(.system(size: 16, weight: .semibold)).foregroundStyle(AppPalette.textPrimary)
                    Text(tr(vm.locale, .noConversationsDesc)).font(.system(size: 13)).foregroundStyle(AppPalette.textMuted).multilineTextAlignment(.center)
                }
                .padding(.top, 42)
                Spacer()
            } else {
                List {
                    ForEach(Array(filtered.prefix(visibleConversationCount))) { convo in
                        let baseRow = ConversationRow(
                            conversation: convo,
                            locale: vm.locale,
                            isSelected: selectedConversationIds.contains(convo.id),
                            selectionMode: selectionMode,
                            onTap: {
                                if selectionMode {
                                    if selectedConversationIds.contains(convo.id) {
                                        selectedConversationIds.remove(convo.id)
                                    } else {
                                        selectedConversationIds.insert(convo.id)
                                    }
                                } else {
                                    vm.openChat(id: convo.id)
                                }
                            },
                            onLongPress: {
                                if selectedConversationIds.contains(convo.id) {
                                    selectedConversationIds.remove(convo.id)
                                } else {
                                    selectedConversationIds.insert(convo.id)
                                }
                            },
                            onQuickAddTag: {
                                tagPickerConversationId = convo.id
                                tagPickerSearch = ""
                                tagPickerSearchDebounced = ""
                                Task { await vm.refreshAvailableTags() }
                            },
                            onQuickMarkRead: {
                                vm.markConversationRead(conversationId: convo.id, read: true)
                            },
                            onTagInfo: { tag in
                                tagManageContext = TagManageContext(conversationId: convo.id, tag: tag)
                                tagManageSelectedTagId = tag.id
                            }
                        )

                        if selectionMode {
                            baseRow
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(AppPalette.surface)
                        } else {
                            baseRow
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        vm.markConversationRead(conversationId: convo.id, read: convo.unreadCount > 0)
                                    } label: {
                                        Label(
                                            convo.unreadCount > 0
                                                ? (vm.locale == .ar ? "تحديد كمقروء" : "Mark read")
                                                : (vm.locale == .ar ? "تحديد كغير مقروء" : "Mark unread"),
                                            systemImage: convo.unreadCount > 0 ? "checkmark.circle" : "envelope.badge"
                                        )
                                    }
                                    .tint(.blue)

                                    Button {
                                        vm.toggleConversationStatus(conversationId: convo.id)
                                    } label: {
                                        Label(
                                            convo.status == .open
                                                ? (vm.locale == .ar ? "إغلاق" : "Close")
                                                : (vm.locale == .ar ? "إعادة فتح" : "Reopen"),
                                            systemImage: convo.status == .open ? "archivebox" : "arrow.uturn.backward.circle"
                                        )
                                    }
                                    .tint(convo.status == .open ? .orange : .green)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        quickActionsConversation = convo
                                        Task { await vm.refreshAvailableTags() }
                                    } label: {
                                        Label(vm.locale == .ar ? "إجراءات" : "Actions", systemImage: "ellipsis.circle")
                                    }
                                    .tint(AppPalette.primary)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(AppPalette.surface)
                        }
                    }
                    if visibleConversationCount < filtered.count {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(AppPalette.surface)
                        .onAppear {
                            visibleConversationCount = min(visibleConversationCount + 30, filtered.count)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppPalette.surface)
                .refreshable {
                    await vm.refreshConversationsList()
                }
            }
        }
        .onChange(of: filtered.count) { _, newValue in
            if newValue < visibleConversationCount {
                visibleConversationCount = max(30, newValue)
            } else if visibleConversationCount == 0 {
                visibleConversationCount = 30
            }
        }
        .sheet(item: $quickActionsConversation) { convo in
            VStack(alignment: .leading, spacing: 12) {
                Text(convo.customerName)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .lineLimit(1)

                if let agent = convo.assignedAgentName, !agent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("\(vm.locale == .ar ? "الوكيل" : "Agent"): \(agent)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppPalette.primary)
                        .lineLimit(1)
                }

                if !convo.lastMessage.isEmpty {
                    Text(convo.lastMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(AppPalette.textMuted)
                        .lineLimit(2)
                }

                if !convo.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(convo.tags.prefix(6)), id: \.id) { tag in
                                Button {
                                    quickActionsConversation = nil
                                    tagManageContext = TagManageContext(conversationId: convo.id, tag: tag)
                                    tagManageSelectedTagId = tag.id
                                } label: {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(Color.white.opacity(0.22))
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                Text(tag.repeatedAt.isEmpty ? "1" : "\(tag.repeatedAt.count)")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundStyle(.white)
                                            )
                                        Text(tag.name)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(tagAccentColor(hex: tag.colorHex))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                            if convo.tags.count > 6 {
                                Text("+\(convo.tags.count - 6)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(AppPalette.textMuted)
                            }
                        }
                    }
                }

                Divider().overlay(AppPalette.border)

                Button {
                    vm.openChat(id: convo.id)
                    quickActionsConversation = nil
                } label: {
                    quickActionRowLabel(
                        title: vm.locale == .ar ? "فتح المحادثة" : "Open chat",
                        subtitle: vm.locale == .ar ? "الانتقال إلى الرسائل" : "Go to messages",
                        icon: "bubble.left.and.bubble.right.fill",
                        color: AppPalette.primary
                    )
                }
                .buttonStyle(.plain)

                Button {
                    vm.markConversationRead(conversationId: convo.id, read: convo.unreadCount > 0)
                    quickActionsConversation = nil
                } label: {
                    quickActionRowLabel(
                        title: convo.unreadCount > 0
                            ? (vm.locale == .ar ? "تحديد كمقروء" : "Mark as read")
                            : (vm.locale == .ar ? "تحديد كغير مقروء" : "Mark as unread"),
                        subtitle: convo.unreadCount > 0
                            ? (vm.locale == .ar ? "إزالة غير المقروء" : "Clear unread badge")
                            : (vm.locale == .ar ? "إظهار كغير مقروء" : "Show as unread"),
                        icon: convo.unreadCount > 0 ? "checkmark.circle.fill" : "envelope.badge.fill",
                        color: .blue
                    )
                }
                .buttonStyle(.plain)

                Button {
                    quickActionsConversation = nil
                    tagPickerConversationId = convo.id
                    tagPickerSearch = ""
                    tagPickerSearchDebounced = ""
                    Task { await vm.refreshAvailableTags() }
                } label: {
                    quickActionRowLabel(
                        title: vm.locale == .ar ? "إضافة وسم" : "Add tag",
                        subtitle: vm.locale == .ar ? "اختر من كل الوسوم مع البحث" : "Search and pick from all tags",
                        icon: "tag.fill",
                        color: .purple
                    )
                }
                .buttonStyle(.plain)

                Button {
                    vm.toggleConversationStatus(conversationId: convo.id)
                    quickActionsConversation = nil
                } label: {
                    quickActionRowLabel(
                        title: convo.status == .open
                            ? (vm.locale == .ar ? "إغلاق المحادثة" : "Close conversation")
                            : (vm.locale == .ar ? "إعادة فتح المحادثة" : "Reopen conversation"),
                        subtitle: convo.status == .open
                            ? (vm.locale == .ar ? "إخفاءها من المفتوحة" : "Move out of open list")
                            : (vm.locale == .ar ? "إرجاعها إلى المفتوحة" : "Move back to open list"),
                        icon: convo.status == .open ? "lock.circle.fill" : "lock.open.fill",
                        color: convo.status == .open ? .orange : .green
                    )
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)
            }
            .padding(16)
            .presentationDetents([.height(400), .medium])
        }
        .confirmationDialog(
            vm.locale == .ar ? "فلتر القراءة" : "Read filter",
            isPresented: $showReadFilterDialog
        ) {
            Button(vm.locale == .ar ? "الكل" : "All") { readFilter = .all }
            Button(vm.locale == .ar ? "مقروء" : "Read") { readFilter = .read }
            Button(vm.locale == .ar ? "غير مقروء" : "Unread") { readFilter = .unread }
            Button(vm.locale == .ar ? "إلغاء" : "Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            vm.locale == .ar ? "فلتر التعيين" : "Assignment filter",
            isPresented: $showAssignmentFilterDialog
        ) {
            Button(vm.locale == .ar ? "الكل" : "All") { assignmentFilter = .all }
            Button(vm.locale == .ar ? "محادثاتي" : "My conversations") { assignmentFilter = .my }
            Button(vm.locale == .ar ? "غير معين" : "Unassigned") { assignmentFilter = .unassigned }
            Button(vm.locale == .ar ? "إلغاء" : "Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            vm.locale == .ar ? "فلتر الرضا" : "Satisfaction filter",
            isPresented: $showSatisfactionFilterDialog
        ) {
            Button(vm.locale == .ar ? "الكل" : "All") { satisfactionFilter = .all }
            Button(vm.locale == .ar ? "راضٍ" : "Satisfied") { satisfactionFilter = .satisfied }
            Button(vm.locale == .ar ? "محايد" : "Neutral") { satisfactionFilter = .neutral }
            Button(vm.locale == .ar ? "غير راضٍ" : "Unsatisfied") { satisfactionFilter = .unsatisfied }
            Button(vm.locale == .ar ? "بدون تقييم" : "No rating") { satisfactionFilter = .noRating }
            Button(vm.locale == .ar ? "إلغاء" : "Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            vm.locale == .ar ? "الترتيب" : "Sorting",
            isPresented: $showSortFilterDialog
        ) {
            Button(vm.locale == .ar ? "الأحدث" : "Latest") { sortFilter = .latest }
            Button(vm.locale == .ar ? "إنشاء (الأحدث)" : "Created (Newest)") { sortFilter = .createdNewest }
            Button(vm.locale == .ar ? "إنشاء (الأقدم)" : "Created (Oldest)") { sortFilter = .createdOldest }
            Button(vm.locale == .ar ? "تحديث (الأحدث)" : "Updated (Newest)") { sortFilter = .updatedNewest }
            Button(vm.locale == .ar ? "تحديث (الأقدم)" : "Updated (Oldest)") { sortFilter = .updatedOldest }
            Button(vm.locale == .ar ? "إلغاء" : "Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            vm.locale == .ar ? "فلتر الوسم" : "Tag filter",
            isPresented: $showTagFilterDialog
        ) {
            Button(vm.locale == .ar ? "الكل" : "All") { selectedTagId = nil }
            ForEach(vm.availableTags) { tag in
                Button("\(tag.name) (#\(tag.id))") { selectedTagId = tag.id }
            }
            Button(vm.locale == .ar ? "إلغاء" : "Cancel", role: .cancel) {}
        }
        .sheet(
            isPresented: Binding(
                get: { tagPickerConversationId != nil },
                set: {
                    if !$0 {
                        tagPickerConversationId = nil
                        tagPickerSearch = ""
                        tagPickerSearchDebounced = ""
                        tagPickerDebounceTask?.cancel()
                        tagPickerDebounceTask = nil
                    }
                }
            )
        ) {
            NavigationStack {
                Group {
                    if vm.availableTags.isEmpty {
                        VStack(spacing: 10) {
                            Text(vm.locale == .ar ? "لا توجد وسوم متاحة" : "No tags available")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppPalette.textPrimary)
                            Text(vm.locale == .ar ? "تأكد من مزامنة الوسوم من الإعدادات." : "Please sync tags from Settings.")
                                .font(.system(size: 12))
                                .foregroundStyle(AppPalette.textMuted)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.horizontal, 20)
                    } else {
                        List {
                            ForEach(filteredTagPickerTags) { tag in
                                Button {
                                    if let convoId = tagPickerConversationId {
                                        vm.attachTag(conversationId: convoId, tagId: tag.id)
                                    }
                                    tagPickerConversationId = nil
                                    tagPickerSearch = ""
                                } label: {
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(tagAccentColor(hex: tag.colorHex))
                                            .frame(width: 10, height: 10)
                                        Text(tag.name)
                                            .foregroundStyle(AppPalette.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("#\(tag.id)")
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
                    text: $tagPickerSearch,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: vm.locale == .ar ? "بحث الوسوم" : "Search tags"
                )
                .onChange(of: tagPickerSearch) { _, value in
                    tagPickerDebounceTask?.cancel()
                    tagPickerDebounceTask = Task {
                        try? await Task.sleep(nanoseconds: 220_000_000)
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            tagPickerSearchDebounced = value
                        }
                    }
                }
                .navigationTitle(vm.locale == .ar ? "إضافة وسم سريع" : "Quick add tag")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(vm.locale == .ar ? "إغلاق" : "Close") {
                            tagPickerConversationId = nil
                            tagPickerSearch = ""
                            tagPickerSearchDebounced = ""
                            tagPickerDebounceTask?.cancel()
                            tagPickerDebounceTask = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $tagManageContext) { context in
            let conversationTags = vm.conversations.first(where: { $0.id == context.conversationId })?.tags ?? [context.tag]
            let activeTag = conversationTags.first(where: { $0.id == tagManageSelectedTagId }) ?? context.tag
            VStack(alignment: .leading, spacing: 12) {
                Text(activeTag.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)

                if !conversationTags.isEmpty {
                    Text(vm.locale == .ar ? "كل الوسوم:" : "All tags:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppPalette.textSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(conversationTags, id: \.id) { tag in
                                Button {
                                    tagManageSelectedTagId = tag.id
                                } label: {
                                    HStack(spacing: 5) {
                                        Text(tag.repeatedAt.isEmpty ? "1" : "\(tag.repeatedAt.count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, height: 16)
                                            .background(Color.white.opacity(0.22))
                                            .clipShape(Circle())
                                        Text(tag.name)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(tagAccentColor(hex: tag.colorHex))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                tag.id == activeTag.id ? Color.white.opacity(0.9) : Color.clear,
                                                lineWidth: 1.2
                                            )
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Text(vm.locale == .ar ? "تاريخ الإضافة:" : "Added at:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppPalette.textSecondary)
                Text(formatTagHistoryDate(activeTag.attachedAt))
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.textMuted)

                Text(
                    vm.locale == .ar
                        ? "تواريخ التكرار (\(activeTag.repeatedAt.count)):"
                        : "Repeat history (\(activeTag.repeatedAt.count)):"
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppPalette.textSecondary)

                if activeTag.repeatedAt.isEmpty {
                    Text(vm.locale == .ar ? "لا يوجد تكرار" : "No repeats")
                        .font(.system(size: 12))
                        .foregroundStyle(AppPalette.textMuted)
                } else {
                    ForEach(Array(activeTag.repeatedAt.prefix(5)), id: \.self) { value in
                        Text("• \(formatTagHistoryDate(value))")
                            .font(.system(size: 12))
                            .foregroundStyle(AppPalette.textMuted)
                    }
                }

                Spacer(minLength: 8)

                HStack(spacing: 10) {
                    Button(vm.locale == .ar ? "إزالة" : "Detach") {
                        vm.detachTag(conversationId: context.conversationId, tagId: activeTag.id)
                        tagManageContext = nil
                        tagManageSelectedTagId = nil
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .buttonStyle(.plain)

                    Button(vm.locale == .ar ? "تكرار" : "Repeat") {
                        vm.repeatTag(conversationId: context.conversationId, tagId: activeTag.id)
                        tagManageContext = nil
                        tagManageSelectedTagId = nil
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppPalette.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppPalette.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .buttonStyle(.plain)

                    Spacer()

                    Button(vm.locale == .ar ? "إغلاق" : "Close") {
                        tagManageContext = nil
                        tagManageSelectedTagId = nil
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary)
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .presentationDetents([.height(330), .medium])
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

                TextField(tr(vm.locale, .searchContacts), text: $contactSearch)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(AppPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .onChange(of: contactSearch) { _, value in
                        visibleContactCount = 25
                        vm.searchContactsForNewConversation(value)
                    }

                if vm.contactsLoading {
                    ProgressView()
                        .padding(.vertical, 20)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredContacts.prefix(visibleContactCount))) { contact in
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
                                        }
                                        Spacer()
                                        Text(contact.phone)
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppPalette.textMuted)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                                Divider().overlay(AppPalette.border.opacity(0.5))
                            }
                            if visibleContactCount < filteredContacts.count {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .onAppear {
                                    visibleContactCount = min(visibleContactCount + 25, filteredContacts.count)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 360)
                }
                Spacer(minLength: 0)
            }
            .presentationDetents([.large])
        }
        .onChange(of: showNewConversationDialog) { _, open in
            if open {
                visibleContactCount = 25
            }
        }
        .onAppear {
            search = storedSearch
            selectedTab = storedTab
            readFilter = ReadFilter(rawValue: storedReadFilter) ?? .all
            assignmentFilter = AssignmentFilter(rawValue: storedAssignmentFilter) ?? .all
            satisfactionFilter = SatisfactionFilter(rawValue: storedSatisfactionFilter) ?? .all
            sortFilter = SortFilter(rawValue: storedSortFilter) ?? .latest
            selectedTagId = storedTagId > 0 ? storedTagId : nil
        }
        .onChange(of: search) { _, value in storedSearch = value }
        .onChange(of: selectedTab) { _, value in storedTab = value }
        .onChange(of: readFilter) { _, value in storedReadFilter = value.rawValue }
        .onChange(of: assignmentFilter) { _, value in storedAssignmentFilter = value.rawValue }
        .onChange(of: satisfactionFilter) { _, value in storedSatisfactionFilter = value.rawValue }
        .onChange(of: sortFilter) { _, value in storedSortFilter = value.rawValue }
        .onChange(of: selectedTagId) { _, value in storedTagId = value ?? 0 }
    }

    private func quickActionRowLabel(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppPalette.textMuted)
            }
            Spacer()
        }
    }

    private func tagAccentColor(hex: String?) -> Color {
        guard var hex else { return .purple }
        hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard let value = UInt64(hex, radix: 16) else { return .purple }
        switch hex.count {
        case 6:
            let red = Double((value >> 16) & 0xFF) / 255.0
            let green = Double((value >> 8) & 0xFF) / 255.0
            let blue = Double(value & 0xFF) / 255.0
            return Color(red: red, green: green, blue: blue)
        case 8:
            let red = Double((value >> 24) & 0xFF) / 255.0
            let green = Double((value >> 16) & 0xFF) / 255.0
            let blue = Double((value >> 8) & 0xFF) / 255.0
            let alpha = Double(value & 0xFF) / 255.0
            return Color(red: red, green: green, blue: blue, opacity: alpha)
        default:
            return .purple
        }
    }

    private func formatTagHistoryDate(_ raw: String?) -> String {
        guard let raw else { return vm.locale == .ar ? "غير متاح" : "Unavailable" }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return vm.locale == .ar ? "غير متاح" : "Unavailable" }

        let inputPatterns = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss'Z'"
        ]
        let output = DateFormatter()
        output.locale = Locale(identifier: vm.locale == .ar ? "ar_SA" : "en_US_POSIX")
        output.dateFormat = "MMM d, yyyy h:mm a"

        for pattern in inputPatterns {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = pattern
            if let date = formatter.date(from: value) {
                return output.string(from: date)
            }
        }
        return value
    }
}
