import SwiftUI

struct LoginView: View {
    @ObservedObject var vm: AppViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 32)

                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(tr(vm.locale, .appTagline))
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.textMuted)

                Spacer().frame(height: 10)

                VStack(alignment: .leading, spacing: 8) {
                    Text(tr(vm.locale, .emailLabel)).font(.system(size: 13, weight: .medium)).foregroundStyle(AppPalette.textSecondary)
                    TextField(tr(vm.locale, .emailPlaceholder), text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background(AppPalette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(tr(vm.locale, .passwordLabel)).font(.system(size: 13, weight: .medium)).foregroundStyle(AppPalette.textSecondary)
                    SecureField(tr(vm.locale, .passwordPlaceholder), text: $password)
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background(AppPalette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let error = vm.loginError {
                    Text(error).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    vm.login(email: email, password: password)
                } label: {
                    Group {
                        if vm.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text(tr(vm.locale, .loginButton))
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppPalette.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(vm.isLoading)

                Button(tr(vm.locale, .forgotPassword)) {}
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.primary)

                Button {
                    vm.locale = vm.locale == .en ? .ar : .en
                } label: {
                    Text(vm.locale == .en ? "AR" : "EN")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppPalette.card)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .background(AppPalette.background.ignoresSafeArea())
    }
}
