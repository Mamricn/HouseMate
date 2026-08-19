//
//  WelcomeView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI


@Observable
class WelcomeViewModel {
    
    
    init() {
        
    }
    
  
}

struct WelcomeView: View {
    
    @State var viewModel: WelcomeViewModel
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(
                colors: [
                    .blue,
                    .teal,
                    .blue.opacity(0.08),
                    .blue.opacity(0.002),
                    .black.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            
            VStack(spacing: 0) {
                
                pictures
                
                text
               
                
                
                Spacer()
                
                buttons
               
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    
    
    private var pictures: some View {
        GeometryReader { geo in
            
            Image("house1")
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width * 0.80)
                .position(
                    x: geo.size.width * 0.50,
                    y: geo.size.height * 0.50
                )
        }
        .frame(height: 500)
    }
    
    private var text: some View {
        VStack(spacing: 12) {
            Text("Home life,\nmade simple.")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)

            Text("Share bills, manage chores,\nand stay organised together.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.horizontal, 32)
    }
    
    private var buttons: some View {
        VStack(spacing: 20) {
            
            Button {
                
            } label: {
                Text("Login")
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: 300)
            .buttonStyle(.glass)
            
            
            Button {
                
            } label: {
                Text("Sign up")
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: 300)
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}
#Preview {
    WelcomeView(viewModel: WelcomeViewModel())
}
