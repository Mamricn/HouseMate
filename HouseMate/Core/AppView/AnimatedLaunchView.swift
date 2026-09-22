//
//  AnimatedLaunchView.swift
//  HouseMate
//

import SwiftUI

struct AnimatedLaunchView: View {

    @State private var animationProgress: CGFloat = 0

    var body: some View {
        ZStack {
            launchBlue

            ZStack {
                logo
                    .offset(y: -54 * animationProgress)
                    .scaleEffect(0.92 + (0.08 * animationProgress))
                    .opacity(animationProgress)

                Text("HouseMate")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(y: 54 * animationProgress)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                animationProgress = 1
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("HouseMate")
    }

    private var logo: some View {
        ZStack {
            Image(systemName: "house.fill")
                .font(.system(size: 82, weight: .medium))
                .foregroundStyle(.white)

            Image(systemName: "person.2.fill")
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(launchBlue)
                .offset(y: 13)
        }
    }

    private var launchBlue: Color {
        Color(
            red: 23 / 255,
            green: 105 / 255,
            blue: 245 / 255
        )
    }
}

#Preview("Animated Launch") {
    AnimatedLaunchView()
}
