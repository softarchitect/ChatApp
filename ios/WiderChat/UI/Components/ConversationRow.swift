import SwiftUI

struct ConversationRow: View {
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
                    Text(localizedConversationPreview(conversation.lastMessage))
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
