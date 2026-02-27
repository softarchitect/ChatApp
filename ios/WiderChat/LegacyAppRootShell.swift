import SwiftUI

// Transitional compatibility file during layered refactor.

struct LegacyAppRootView: View {
    @StateObject private var vm = AppViewModel()

    var body: some View {
        Group {
            if !vm.isLoggedIn || vm.screen == .login {
                LoginView(vm: vm)
            } else {
                MainShellView(vm: vm)
            }
        }
        .environment(\.layoutDirection, vm.locale == .ar ? .rightToLeft : .leftToRight)
        .preferredColorScheme(vm.darkMode ? .dark : .light)
    }
}

struct MainShellView: View {
    @ObservedObject var vm: AppViewModel

    var hideBottomNav: Bool {
        vm.screen == .chat || vm.screen == .privacy || vm.screen == .terms || vm.screen == .version
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppPalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                switch vm.screen {
                case .conversations:
                    ConversationsView(vm: vm)
                case .chat:
                    ChatView(vm: vm)
                case .settings:
                    SettingsView(vm: vm)
                case .privacy:
                    PrivacyPolicyView(vm: vm)
                case .terms:
                    TermsOfServiceView(vm: vm)
                case .version:
                    VersionView(vm: vm)
                case .login:
                    EmptyView()
                }
                if !hideBottomNav {
                    BottomNav(vm: vm)
                }
            }
        }
    }
}

// LoginView and ConversationsView moved to UI/Screens layer.
// ChatView moved to UI/Screens/Chat layer.
// SettingsView moved to UI/Screens layer.
// PrivacyPolicyView, TermsOfServiceView, and VersionView moved to UI/Screens layer.
// Shared policy/header components moved to UI/Components/PolicyComponents.swift.

#Preview {
    AppRootView()
}
