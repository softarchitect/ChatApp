import Foundation
import UIKit
import UserNotifications

final class NotificationAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        requestNotificationAuthorization(application)
        if
            let remotePayload = launchOptions?[.remoteNotification] as? [AnyHashable: Any],
            let chatId = PushNotificationBridge.extractChatId(from: remotePayload)
        {
            PushNotificationBridge.postOpenChat(chatId: chatId)
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        PushNotificationBridge.postToken(token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Keep silent; app should continue if APNS registration fails.
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        if let chatId = PushNotificationBridge.extractChatId(from: userInfo) {
            PushNotificationBridge.postOpenChat(chatId: chatId)
        }
        return .newData
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if let chatId = PushNotificationBridge.extractChatId(from: userInfo) {
            PushNotificationBridge.postOpenChat(chatId: chatId)
        }
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let chatId = PushNotificationBridge.extractChatId(from: userInfo) {
            PushNotificationBridge.postOpenChat(chatId: chatId)
        }
        completionHandler()
    }

    private func requestNotificationAuthorization(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
}
