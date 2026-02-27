import SwiftUI

struct AppBackHeader: View {
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

struct PolicyHero: View {
    let date: String
    let intro: String
    @Environment(\.layoutDirection) private var layoutDirection

    private var locale: AppLocale {
        layoutDirection == .rightToLeft ? .ar : .en
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Rectangle().fill(AppPalette.border.opacity(0.9)).frame(height: 1)
                Text(tr(locale, .lastUpdated))
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

struct PolicySectionCard: View {
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
