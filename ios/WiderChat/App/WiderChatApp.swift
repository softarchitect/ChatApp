import SwiftUI

@main
struct WiderChatApp: App {
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) private var notificationDelegate

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
