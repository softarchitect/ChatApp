import SwiftUI

struct PrivacyPolicyView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            AppBackHeader(title: tr(vm.locale, .privacyPolicy)) { vm.setScreen(.settings) }

            ScrollView {
                VStack(spacing: 0) {
                    PolicyHero(
                        date: "February 25, 2026",
                        intro: "Widers is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our WhatsApp Business Cloud API platform and mobile application."
                    )

                    ForEach(Array(PolicyContent.privacySections.enumerated()), id: \.offset) { idx, item in
                        PolicySectionCard(
                            icon: item.icon,
                            iconTint: Color(red: 0.06, green: 0.73, blue: 0.51),
                            title: item.title,
                            text: item.body,
                            index: idx + 1
                        )
                    }
                }
            }
        }
    }
}
