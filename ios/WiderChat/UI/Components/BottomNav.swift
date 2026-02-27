import SwiftUI

struct BottomNav: View {
    @ObservedObject var vm: AppViewModel

    var body: some View {
        HStack(spacing: 0) {
            navItem(
                selected: vm.screen == .conversations,
                title: tr(vm.locale, .chats),
                icon: "bubble.left.and.bubble.right",
                badge: vm.unreadCount
            ) { vm.setScreen(.conversations) }
            navItem(
                selected: vm.screen == .settings,
                title: tr(vm.locale, .settings),
                icon: "gearshape",
                badge: 0
            ) { vm.setScreen(.settings) }
        }
        .frame(height: 58)
        .background(AppPalette.surface)
        .overlay(alignment: .top) { Rectangle().fill(AppPalette.border).frame(height: 1) }
    }

    @ViewBuilder
    private func navItem(selected: Bool, title: String, icon: String, badge: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Capsule()
                    .fill(selected ? AppPalette.primary : .clear)
                    .frame(width: 18, height: 2)
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(selected ? AppPalette.primary : AppPalette.textMuted)
                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 12, y: -8)
                    }
                }
                Text(title)
                    .font(.system(size: 11, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? AppPalette.primary : AppPalette.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
