//
//  AppDelegate.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//


import UIKit
import FirebaseCore
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [
            UIApplication.LaunchOptionsKey: Any
        ]? = nil
    ) -> Bool {

        configureFirebase()
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    private func configureFirebase() {
        guard AppEnvironment.current.usesFirebase else {
            return
        }

        guard let fileName =
                AppEnvironment.current.firebaseConfigurationFileName,
              let filePath = Bundle.main.path(
                forResource: fileName,
                ofType: "plist"
              ),
              let options = FirebaseOptions(contentsOfFile: filePath)
        else {
            fatalError(
                """
                Firebase configuration is missing for \
                \(AppEnvironment.current.displayName).
                """
            )
        }

        FirebaseApp.configure(options: options)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        await MainActor.run {
            NotificationCenter.default.post(
                name: .houseMateNotificationOpened,
                object: nil,
                userInfo: userInfo
            )
        }
    }
}
