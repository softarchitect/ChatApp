import SwiftUI

enum SatisfactionBadgeVariant {
    case compact
    case regular
}

struct SatisfactionBadge: View {
    let value: ConversationSatisfaction
    let locale: AppLocale
    var variant: SatisfactionBadgeVariant = .compact

    var body: some View {
        let meta = satisfactionBadgeMeta(value: value, locale: locale)
        Text(meta.label)
            .font(.system(size: variant == .compact ? 10 : 11, weight: .semibold))
            .foregroundStyle(meta.color)
            .padding(.horizontal, variant == .compact ? 6 : 8)
            .padding(.vertical, variant == .compact ? 2 : 3)
            .background(meta.color.opacity(0.12))
            .clipShape(Capsule())
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }
}

func satisfactionBadgeMeta(value: ConversationSatisfaction, locale: AppLocale) -> (label: String, color: Color) {
    switch value {
    case .satisfied:
        return (locale == .ar ? "😊 راضٍ" : "😊 Satisfied", Color(red: 0.02, green: 0.59, blue: 0.41))
    case .neutral:
        return (locale == .ar ? "😐 محايد" : "😐 Neutral", Color(red: 0.85, green: 0.47, blue: 0.02))
    case .unsatisfied:
        return (locale == .ar ? "😠 غير راضٍ" : "😠 Unsatisfied", .red)
    case .noRating:
        return (locale == .ar ? "⚪ بدون تقييم" : "⚪ No rating", AppPalette.textMuted)
    }
}
