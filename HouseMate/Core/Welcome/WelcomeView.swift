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
        VStack(spacing: 14) {

            Button {

                // Routing do SignUpView

            } label: {
                HStack(spacing: 10) {
                    Text("Create an account")
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .blue,
                                    .cyan
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(
                            color: .blue.opacity(0.3),
                            radius: 14,
                            y: 8
                        )
                }
            }
            .buttonStyle(.plain)

            Button {

                // Routing do LoginView

            } label: {
                Text("Log in")
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(
                                        .white.opacity(0.7),
                                        lineWidth: 1
                                    )
                            }
                    }
            }
            .buttonStyle(.plain)

            Text("By continuing, you agree to our Terms and Privacy Policy.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .frame(maxWidth: 340)
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
    }
}
#Preview {
    WelcomeView(viewModel: WelcomeViewModel())
}
