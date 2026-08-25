//
//  AppDelegate.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//


import UIKit
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [
            UIApplication.LaunchOptionsKey: Any
        ]? = nil
    ) -> Bool {

        configureFirebase()

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
