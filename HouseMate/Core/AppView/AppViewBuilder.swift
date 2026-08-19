//
//  AppViewBuilder.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI


struct AppViewBuilder<Tabbar: View, Onboarding: View>: View {
    
    var showTabBar: Bool = false
    @ViewBuilder var tabbar: Tabbar
    @ViewBuilder var onboarding: Onboarding
    
    var body: some View {
        
        ZStack{
            if showTabBar {
                tabbar
                    .transition(.move(edge: .trailing))
            } else {
                onboarding
                    .transition(.move(edge: .leading))
            }

        }
        .animation(.smooth, value: showTabBar)
    }
    
}

private struct PreviewView: View {
    @State private var showTabBar: Bool = false
    
    var body: some View {
        
        AppViewBuilder(
            showTabBar: showTabBar,
            tabbar: {
                ZStack{
                    Color.red.ignoresSafeArea(edges: .all)
                    Text("Tabbar")
                }
            },
            onboarding: {
                ZStack{
                    Color.blue.ignoresSafeArea(edges: .all)
                    Text("Onboarding")
                }
            }
        )
        .onTapGesture {
            showTabBar.toggle()
            
        }

    }
}





#Preview {
    PreviewView()
}
