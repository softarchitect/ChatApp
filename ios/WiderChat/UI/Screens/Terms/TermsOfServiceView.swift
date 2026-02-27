import SwiftUI

struct TermsOfServiceView: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            AppBackHeader(title: tr(vm.locale, .termsOfService)) { vm.setScreen(.settings) }

            ScrollView {
                VStack(spacing: 0) {
                    PolicyHero(
                        date: "February 25, 2026",
                        intro: "These Terms of Service govern your access and use of the Widers platform, including our WhatsApp Business Cloud API services and mobile application."
                    )

                    ForEach(Array(PolicyContent.termsSections.enumerated()), id: \.offset) { idx, item in
                        PolicySectionCard(
                            icon: item.icon,
                            iconTint: Color(red: 0.05, green: 0.65, blue: 0.91),
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
