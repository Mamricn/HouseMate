//
//  OnboardingBackground.swift
//  HouseMate
//

import SwiftUI

struct OnboardingBackground: View {

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground)

            LinearGradient(
                colors: [
                    .blue.opacity(0.24),
                    .purple.opacity(0.14),
                    .cyan.opacity(0.09),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.blue.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: 170, y: -330)

            Circle()
                .fill(.purple.opacity(0.13))
                .frame(width: 300, height: 300)
                .blur(radius: 85)
                .offset(x: -175, y: 290)

            Circle()
                .fill(.cyan.opacity(0.09))
                .frame(width: 230, height: 230)
                .blur(radius: 70)
                .offset(x: 145, y: 390)
        }
        .ignoresSafeArea()
    }
}

#Preview("Onboarding Background") {
    OnboardingBackground()
}
