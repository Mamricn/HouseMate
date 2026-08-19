//
//  AppView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI

struct AppView: View {
    
    var isLoading: Bool = false
    
    @State private var currentScreen: AppScreen = .welcomeScreen
    
    var body: some View {
        if isLoading {
            ProgressView()
        } else {
            screenView
        }
    }
    
    
    
    
    @ViewBuilder
    var screenView: some View {
        switch currentScreen {
        case .welcomeScreen:
            WelcomeView(viewModel: WelcomeViewModel())
            
        case .onboarding:
            SelectView(viewModel: SelectViewModel())
            
        case .mainScreen:
            TabbarView()
        }
    }
    
    private enum AppScreen {
        case welcomeScreen
        case onboarding
        case mainScreen
    }
}

#Preview {
    AppView()
}
