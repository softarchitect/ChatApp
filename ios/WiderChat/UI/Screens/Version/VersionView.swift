import SwiftUI

struct VersionView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            AppBackHeader(title: vm.locale == .ar ? "حول وايدرز" : "About Widers") { vm.setScreen(.settings) }

            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 10) {
                        Image("SplashLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 128, height: 128)
                            .clipShape(RoundedRectangle(cornerRadius: 18))

                        Text("Widers")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppPalette.textPrimary)
                        Text("META APPROVED PARTNER")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppPalette.primary)
                        Text(
                            vm.locale == .ar
                                ? "وايدرز منصة معتمدة من ميتا لإدارة محادثات واتساب للأعمال في الوقت الفعلي مع فرق متعددة."
                                : "Widers is a Meta-approved WhatsApp Business Cloud API provider helping teams manage customer conversations at scale."
                        )
                        .font(.system(size: 16))
                        .foregroundStyle(AppPalette.textMuted)
                        .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(AppPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(spacing: 0) {
                        versionInfoRow("Version", "1.0.0")
                        versionInfoRow("Build", "2026.02.25")
                        versionInfoRow("Environment", "Production")
                        versionInfoRow("API Version", "v2.0")
                        versionInfoRow("WhatsApp Cloud API", "v21.0", drawDivider: false)
                    }
                    .background(AppPalette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("KEY FEATURES")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppPalette.textMuted)

                        VStack(spacing: 10) {
                            ForEach(PolicyContent.versionFeatures, id: \.self) { feature in
                                HStack(alignment: .center, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppPalette.primary)
                                    Text(feature)
                                        .font(.system(size: 15))
                                        .foregroundStyle(AppPalette.textPrimary)
                                    Spacer()
                                }
                            }
                        }
                        .padding(14)
                        .background(AppPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private func versionInfoRow(_ key: String, _ value: String, drawDivider: Bool = true) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 14))
                .foregroundStyle(AppPalette.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppPalette.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        if drawDivider {
            Divider().overlay(AppPalette.border.opacity(0.6))
        }
    }
}
