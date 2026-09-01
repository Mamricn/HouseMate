//
//  HouseMateApp.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//



import SwiftUI

@main
struct HouseMateApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}
