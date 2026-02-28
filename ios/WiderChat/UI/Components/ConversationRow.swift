import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation
    let locale: AppLocale
    var isSelected: Bool = false
    var selectionMode: Bool = false
    let onTap: () -> Void
    var onLongPress: (() -> Void)? = nil
    var onQuickAddTag: (() -> Void)? = nil
    var onQuickMarkRead: (() -> Void)? = nil
    var onTagInfo: ((ConversationTag) -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AppPalette.primary.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(initials(for: conversation.customerName))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppPalette.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.customerName)
                        .font(.system(size: 15, weight: conversation.unreadCount > 0 ? .semibold : .medium))
                        .foregroundStyle(AppPalette.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(conversation.lastMessageTime)
                        .font(.system(size: 12))
                        .foregroundStyle(conversation.unreadCount > 0 ? AppPalette.primary : AppPalette.textMuted)
                }
                if let agent = conversation.assignedAgentName, !agent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(agent)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppPalette.primary)
                        .lineLimit(1)
                }
                Text(localizedConversationPreview(conversation.lastMessage))
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.textSecondary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if conversation.status == .closed {
                        StatusPill(text: tr(locale, .closed), color: AppPalette.textMuted.opacity(0.2), textColor: AppPalette.textMuted)
                    }
                    if !conversation.tags.isEmpty {
                        let tag = conversation.tags[0]
                        Button {
                            onTagInfo?(tag)
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
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(tagAccentColor(hex: tag.colorHex))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        if conversation.tags.count > 1 {
                            Text("+\(conversation.tags.count - 1)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppPalette.textMuted)
                        }
                        Button {
                            onTagInfo?(tag)
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(AppPalette.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(AppPalette.primary)
                            .clipShape(Circle())
                    }
                }
                if !selectionMode {
                    HStack(spacing: 8) {
                        if let onQuickAddTag {
                            Button(locale == .ar ? "إضافة وسم" : "Add tag") {
                                onQuickAddTag()
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(red: 0.22, green: 0.19, blue: 0.64))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.93, green: 0.95, blue: 1.0))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .buttonStyle(.plain)
                        }
                        if conversation.unreadCount > 0, let onQuickMarkRead {
                            Button(locale == .ar ? "تحديد كمقروء" : "Mark read") {
                                onQuickMarkRead()
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(red: 0.02, green: 0.37, blue: 0.27))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.93, green: 0.99, blue: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            if selectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? AppPalette.primary : AppPalette.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? AppPalette.primary.opacity(0.10) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.35) {
            onLongPress?()
        }
    }

    private func localizedConversationPreview(_ value: String) -> String {
        guard locale == .ar else { return value }
        switch value.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "Photo": return "صورة"
        case "Video": return "فيديو"
        case "Voice message": return "رسالة صوتية"
        case "Document": return "مستند"
        case "Media": return "وسائط"
        default: return value
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

    private func initials(for name: String) -> String {
        let chars = name.split(separator: " ").compactMap { $0.first }.prefix(2)
        let value = String(chars)
        return value.isEmpty ? String(name.prefix(1)) : value.uppercased()
    }
}

struct StatusPill: View {
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

struct TabChip: View {
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
