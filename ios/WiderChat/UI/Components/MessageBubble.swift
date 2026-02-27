import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    let darkMode: Bool
    @Environment(\.layoutDirection) private var layoutDirection

    var isAgent: Bool { message.sender == .agent }
    private var locale: AppLocale { layoutDirection == .rightToLeft ? .ar : .en }

    var body: some View {
        VStack(alignment: isAgent ? .trailing : .leading, spacing: 4) {
            if message.type == .note {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tr(locale, .internalNoteBadge)).font(.system(size: 10, weight: .bold)).foregroundStyle(Color.orange)
                    Text(message.content).font(.system(size: 14)).foregroundStyle(darkMode ? Color(red: 0.96, green: 0.91, blue: 0.65) : Color(red: 0.53, green: 0.33, blue: 0.08))
                    Text("\(message.noteAuthor ?? tr(locale, .youLabel)) • \(message.timestamp)").font(.system(size: 11)).foregroundStyle(AppPalette.textMuted)
                }
                .padding(10)
                .background(Color.orange.opacity(darkMode ? 0.25 : 0.16))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 320, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    if message.type == .media, let mediaKind = message.mediaKind {
                        MediaMessageView(
                            mediaKind: mediaKind,
                            mediaUrl: message.mediaUrl,
                            caption: message.content,
                            darkMode: darkMode
                        )
                    } else {
                        Text(message.content)
                            .font(.system(size: 14))
                            .foregroundStyle(isAgent ? (darkMode ? Color(red: 0.95, green: 0.97, blue: 0.99) : Color(red: 0.06, green: 0.09, blue: 0.16)) : AppPalette.textPrimary)
                    }
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
                .background(
                    isAgent
                        ? (darkMode ? Color(red: 0.12, green: 0.23, blue: 0.17) : Color(red: 0.86, green: 0.97, blue: 0.78))
                        : (darkMode ? Color(red: 0.13, green: 0.17, blue: 0.20) : Color.white)
                )
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(isAgent ? .clear : (darkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06)), lineWidth: 1)
                )
                .frame(maxWidth: 308, alignment: isAgent ? .trailing : .leading)
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
