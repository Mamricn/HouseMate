//
//  HouseMateApp.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI

@main
struct HouseMateApp: App {
    var body: some Scene {
        WindowGroup {
            WelcomeView(viewModel: WelcomeViewModel())
        }
    }
}
