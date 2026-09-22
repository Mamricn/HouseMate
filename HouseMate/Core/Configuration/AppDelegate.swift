//
//  AppDelegate.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//


import UIKit
import FirebaseAppCheck
import FirebaseCore
import FirebaseMessaging
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [
            UIApplication.LaunchOptionsKey: Any
        ]? = nil
    ) -> Bool {

        StartupDiagnostics.mark("didFinishLaunching started")
        let firebaseStartedAt = StartupDiagnostics.begin("Firebase configure")
        configureFirebase()
        StartupDiagnostics.end(
            "Firebase configure",
            startedAt: firebaseStartedAt
        )
        StartupDiagnostics.mark(
            "Environment: \(AppEnvironment.current.rawValue), "
                + "Firebase project: "
                + (FirebaseApp.app()?.options.projectID ?? "missing")
        )
        UNUserNotificationCenter.current().delegate = self

        if AppEnvironment.current.usesFirebase {
            Messaging.messaging().delegate = self
        }

        StartupDiagnostics.mark("didFinishLaunching finished")
        return true
    }

    private func configureFirebase() {
        guard AppEnvironment.current.usesFirebase else {
            return
        }

        configureAppCheck()

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

    private func configureAppCheck() {
#if DEBUG
        AppCheck.setAppCheckProviderFactory(
            AppCheckDebugProviderFactory()
        )
#else
        AppCheck.setAppCheckProviderFactory(
            AppAttestProviderFactory()
        )
#endif
    }
}

extension AppDelegate: MessagingDelegate {

    func messaging(
        _ messaging: Messaging,
        didReceiveRegistration registrationID: String?
    ) {
        guard let registrationID else { return }

        Task { @MainActor in
            FirebaseRemoteNotificationService.shared
                .receiveRegistrationID(registrationID)
        }
    }
}

extension AppDelegate {

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken

        #if DEBUG
        print("APNs device token received.")
        #endif
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("APNs registration failed: \(error.localizedDescription)")
        #endif
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
            DeepLinkCoordinator.shared.handle(
                notificationUserInfo: userInfo
            )
            NotificationCenter.default.post(
                name: .houseMateNotificationOpened,
                object: nil,
                userInfo: userInfo
            )
        }
    }
}
